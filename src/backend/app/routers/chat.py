import uuid
import os
import base64
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.chat import Conversation, ChatMessage, MessageSender
from app.models.audit import AuditLog
from app.schemas.chat import (
    ChatQueryRequest,
    ChatMessageResponse,
    ConversationSummaryResponse,
    ConversationDetailResponse,
)
from app.agent.rag_pipeline import rag_pipeline
from app.agent.vision_analyzer import vision_analyzer

router = APIRouter(prefix="/chat", tags=["Chat & Agente do Estudante"])


@router.post("", response_model=ChatMessageResponse)
def send_message(
    chat_req: ChatQueryRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint principal de interação com o Agente ASA Connect+ (RF05, RF06, RF07, RF10).
    Recebe a pergunta, executa RAG, calcula abstenção e persiste histórico com explicabilidade.
    """
    query_text = chat_req.query.strip()
    if not query_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pergunta não pode estar vazia.",
        )

    # 1. Recupera ou cria a conversa
    conversation = None
    if chat_req.conversation_id:
        conversation = db.query(Conversation).filter(
            Conversation.id == chat_req.conversation_id,
            Conversation.user_id == current_user.id,  # Segurança multi-tenant
        ).first()
        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversa não encontrada ou não autorizada para o usuário atual.",
            )
    else:
        # Gera título conciso a partir do início da pergunta
        title = query_text[:40] + ("..." if len(query_text) > 40 else "")
        conversation = Conversation(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            title=title,
        )
        db.add(conversation)
        db.commit()
        db.refresh(conversation)

    image_rel_path = None
    vision_info = None

    if chat_req.image_base64:
        try:
            raw_b64 = chat_req.image_base64
            if "," in raw_b64:
                raw_b64 = raw_b64.split(",", 1)[1]
            img_bytes = base64.b64decode(raw_b64)

            upload_dir = os.path.join("uploads", "chat_images", str(current_user.id))
            os.makedirs(upload_dir, exist_ok=True)
            fname = f"{uuid.uuid4().hex[:10]}_{chat_req.image_filename or 'captura_tela.png'}"
            disk_path = os.path.join(upload_dir, fname)
            with open(disk_path, "wb") as f:
                f.write(img_bytes)
            image_rel_path = f"/api/v1/documents/download-chat-image/{current_user.id}/{fname}"

            vision_info = vision_analyzer.analyze_image(
                image_bytes=img_bytes,
                user_comment=query_text,
                filename=chat_req.image_filename,
            )
        except Exception:
            vision_info = None

    # 2. Salva a mensagem do usuário
    user_msg = ChatMessage(
        conversation_id=conversation.id,
        sender=MessageSender.USER,
        content=query_text,
        image_url=image_rel_path,
        agent_version=rag_pipeline.agent_version,
    )
    db.add(user_msg)
    db.commit()

    # 3. Executa o pipeline de RAG com explicabilidade e verificação de abstenção
    search_query = vision_info["search_query"] if vision_info else query_text
    rag_result = rag_pipeline.answer_query(search_query)

    # Enriquecimento da resposta com a análise visual
    if vision_info:
        vision_header = (
            f"🔍 **Análise da Imagem:**\n"
            f"• **Tela Identificada:** {vision_info['screen_title']}\n"
            f"• **Diagnóstico:** {vision_info['detected_issue']}\n\n"
            f"📋 **Orientações e Procedimento Oficial FECAP:**\n"
        )
        if rag_result["is_abstained"]:
            rag_result["is_abstained"] = False
            rag_result["confidence_score"] = vision_info["confidence"]
            rag_result["content"] = (
                f"{vision_header}"
                f"Para este tipo de ocorrência na {vision_info['screen_title']}, o procedimento padrão do ASA é:\n"
                f"• Verifique se há pendências no Portal do Aluno (Menu > Requerimentos ou Financeiro).\n"
                f"• Caso o aviso persista, registre um chamado na Secretaria On-line ou utilize o botão abaixo para atendimento com o ASA.\n"
                f"• O prazo institucional padrão para análise de solicitações é de até 2 a 5 dias úteis."
            )
            rag_result["source_citation"] = "Regulamento Acadêmico e Manual do Aluno FECAP"
        else:
            rag_result["content"] = f"{vision_header}{rag_result['content']}"

    # 4. Salva a resposta do agente com metadados completos (RF06, RF10)
    agent_msg = ChatMessage(
        conversation_id=conversation.id,
        sender=MessageSender.AGENT,
        content=rag_result["content"],
        image_url=None,
        is_abstained=rag_result["is_abstained"],
        confidence_score=rag_result["confidence_score"],
        threshold_used=rag_result["threshold_used"],
        retrieved_chunks=rag_result["retrieved_chunks"],
        source_citation=rag_result["source_citation"],
        suggested_action=rag_result["suggested_action"],
        agent_version=rag_result["agent_version"],
    )
    db.add(agent_msg)
    
    # Atualiza timestamp da conversa
    conversation.updated_at = datetime.now(timezone.utc)
    db.add(conversation)

    # 5. Registro de Auditoria detalhado (RF10)
    audit_action = "ABSTENTION_TRIGGERED" if rag_result["is_abstained"] else "CHAT_QUERY_SUCCESS"
    audit_entry = AuditLog(
        user_id=current_user.id,
        action=audit_action,
        details={
            "conversation_id": conversation.id,
            "query": query_text,
            "confidence_score": rag_result["confidence_score"],
            "threshold_used": rag_result["threshold_used"],
            "is_abstained": rag_result["is_abstained"],
            "source_citation": rag_result["source_citation"],
            "agent_version": rag_result["agent_version"],
        },
        ip_address=request.client.host if request.client else None,
    )
    db.add(audit_entry)
    db.commit()
    db.refresh(agent_msg)

    return agent_msg


@router.get("/conversations", response_model=List[ConversationSummaryResponse])
def list_user_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lista o histórico de conversas do estudante autenticado (Tela de Conversas do Figma).
    """
    conversations = (
        db.query(Conversation)
        .filter(Conversation.user_id == current_user.id)
        .order_by(Conversation.updated_at.desc())
        .all()
    )

    results = []
    for conv in conversations:
        last_msg = (
            db.query(ChatMessage)
            .filter(ChatMessage.conversation_id == conv.id)
            .order_by(ChatMessage.created_at.desc())
            .first()
        )
        results.append(
            ConversationSummaryResponse(
                id=conv.id,
                title=conv.title,
                created_at=conv.created_at,
                updated_at=conv.updated_at,
                last_message=last_msg.content if last_msg else None,
            )
        )

    return results


@router.get("/conversations/{conversation_id}", response_model=ConversationDetailResponse)
def get_conversation_detail(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Retorna o histórico completo de mensagens de uma conversa com chips de fonte e feedbacks.
    """
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id,  # Isolamento de segurança
    ).first()

    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversa não encontrada.",
        )

    return conversation


@router.delete("/conversations/{conversation_id}")
def delete_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Exclui uma conversa e suas mensagens associadas.
    """
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id,
    ).first()

    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversa não encontrada.",
        )

    db.delete(conversation)
    db.commit()
    return {"message": "Conversa removida com sucesso.", "success": True}
