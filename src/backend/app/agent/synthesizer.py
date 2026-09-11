import os
import re
from typing import List, Dict, Any, Optional
import httpx
from app.core.config import settings


ALVARISTA_SYSTEM_PROMPT = """Você é a assistente de IA oficial do ASA Connect+ (Área do Sucesso Alvarista da FECAP).
Sua missão é responder às dúvidas acadêmicas, financeiras e institucionais dos estudantes da FECAP com empatia, agilidade e total clareza.

Diretrizes Obrigatórias:
1. Baseie-se ESTRITAMENTE nas informações oficiais fornecidas no contexto institucional recuperado. NUNCA invente prazos, valores ou procedimentos.
2. Mantenha o "Tom Alvarista": amigável, acolhedor, objetivo, encorajador e profissional.
3. Use formatação limpa: use bullet points (•) para listas e negrito (**termo**) apenas para dar destaque.
4. Quando a dúvida envolver procedimentos, apresente um passo a passo numerado, claro e direto no Portal do Aluno.
5. Sempre destaque prazos em dias úteis e valores/taxas de serviços quando houver.
6. Nunca inclua blocos de cabeçalhos brutos, metadados ou listas genéricas de canais de atendimento na resposta.
"""


def _generate_with_gemini(query: str, context: str, api_key: str) -> Optional[str]:
    """Chama a API do Google Gemini via HTTP REST de forma leve e rápida."""
    model = settings.LLM_MODEL or "gemini-2.0-flash"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {
                        "text": f"{ALVARISTA_SYSTEM_PROMPT}\n\nContexto Oficial da FECAP:\n{context}\n\nPergunta do Estudante:\n{query}"
                    }
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 800,
        }
    }
    try:
        with httpx.Client(timeout=6.0) as client:
            resp = client.post(url, json=payload)
            if resp.status_code == 200:
                data = resp.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"]
                return text.strip()
    except Exception:
        pass
    return None


def _generate_with_openai(query: str, context: str, api_key: str, base_url: str = "https://api.openai.com/v1") -> Optional[str]:
    """Chama API compatível com OpenAI (OpenAI ou Groq)."""
    url = f"{base_url.rstrip('/')}/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "gpt-4o-mini" if "openai" in base_url else "llama-3.3-70b-versatile",
        "messages": [
            {"role": "system", "content": ALVARISTA_SYSTEM_PROMPT},
            {"role": "user", "content": f"Contexto Oficial FECAP:\n{context}\n\nPergunta do Aluno:\n{query}"}
        ],
        "temperature": 0.2,
        "max_tokens": 800,
    }
    try:
        with httpx.Client(timeout=6.0) as client:
            resp = client.post(url, json=payload, headers=headers)
            if resp.status_code == 200:
                data = resp.json()
                return data["choices"][0]["message"]["content"].strip()
    except Exception:
        pass
    return None


def clean_markdown_snippet(text: str) -> str:
    """Remove cabeçalhos duplicados, artefatos de metadados e linhas vazias redundantes."""
    if not text:
        return ""
    # Remove blocos de palavras-chave e metadados
    text = re.sub(r'Palavras-chave:.*', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\*\*Fonte Oficial:\*\*.*', '', text)
    text = re.sub(r'\*\*Categoria:\*\*.*', '', text)
    text = re.sub(r'\*\*Setor Responsável:\*\*.*', '', text)
    text = re.sub(r'\*\*Local de Atendimento:\*\*.*', '', text)
    text = re.sub(r'\*\*Horário:\*\*.*', '', text)
    text = re.sub(r'\*\*Área do Sucesso Alvarista.*?\n', '', text)
    text = re.sub(r'\*\*Fale Conosco.*?\n', '', text)
    text = re.sub(r'\*\*Portal Institucional.*?\n', '', text)
    
    # Remove títulos markdown soltos (# Título ou ## Título)
    text = re.sub(r'^#+\s+.*$', '', text, flags=re.MULTILINE)
    text = re.sub(r'^\s*---\s*$', '', text, flags=re.MULTILINE)
    
    # Limpa URLs markdown redundantes [Texto](https://url) -> Texto
    text = re.sub(r'\[([^\]]+)\]\((https?://[^\)]+)\)', r'\1', text)
    
    # Normaliza marcadores de lista (* ou -) para bullet point padrão (•)
    text = re.sub(r'^\s*[\*\-]\s+\*\*(.*?)\*\*', r'• **\1**', text, flags=re.MULTILINE)
    text = re.sub(r'^\s*[\*\-]\s+', r'• ', text, flags=re.MULTILINE)
    
    lines = [l.rstrip() for l in text.split('\n')]
    clean = []
    for l in lines:
        if l:
            clean.append(l)
        elif clean and clean[-1] != '':
            clean.append('')
    return '\n'.join(clean).strip()


def synthesize_local(query: str, retrieved_chunks: List[Dict[str, Any]]) -> str:
    """
    Sintetizador Local Inteligente do ASA Connect+:
    Formata uma resposta humana, precisa e agradável a partir dos trechos oficiais recuperados,
    sem necessitar de chamadas externas de LLM.
    """
    if not retrieved_chunks:
        return (
            "Olá! Não localizei essa informação na base oficial de serviços e normas da FECAP. "
            "Para garantir a precisão de prazos e requerimentos, recomendo abrir um chamado no ASA ou contatar a nossa equipe."
        )

    # Verifica intenção da pergunta
    q_low = query.lower()
    is_procedural = any(w in q_low for w in ["como", "onde", "solicitar", "emitir", "fazer", "passo", "procedimento", "requerimento"])
    
    # Seleciona o melhor documento principal ignorando chunks de canais de atendimento
    valid_chunks = []
    for r in retrieved_chunks:
        sec = r["chunk"]["section"].lower()
        if "canais" not in sec and "contato" not in sec and "atendimento" not in sec:
            valid_chunks.append(r["chunk"])

    if not valid_chunks:
        valid_chunks = [r["chunk"] for r in retrieved_chunks]

    top_chunk = valid_chunks[0]
    top_slug = top_chunk["document_slug"]
    doc_title = top_chunk["document_title"]

    chunks_from_top_doc = [
        c for c in valid_chunks if c["document_slug"] == top_slug
    ]
    if not chunks_from_top_doc:
        chunks_from_top_doc = [top_chunk]

    desc_text = None
    steps_text = None
    prazos_text = None
    main_body = None

    for c in chunks_from_top_doc:
        sec = c["section"].lower()
        cleaned = clean_markdown_snippet(c["content"])
        if not cleaned or len(cleaned) < 30:
            continue
        
        if "passo a passo" in sec or "como solicitar" in sec:
            steps_text = cleaned
        elif "prazo" in sec or "taxa" in sec or "condi" in sec:
            prazos_text = cleaned
        elif "descri" in sec:
            desc_text = cleaned
        elif not main_body or len(cleaned) > len(main_body):
            main_body = cleaned

    greeting = "Olá, Alvarista!"
    
    # Personaliza introdução por contexto
    t_low = doc_title.lower()
    if "atestado" in t_low or "matrícula" in t_low:
        intro = f"{greeting} Para solicitar o seu **{doc_title}**, o procedimento é realizado diretamente pelo Portal do Aluno:"
    elif "biblioteca" in t_low or "multa" in t_low:
        intro = f"{greeting} Sobre as normas da **Biblioteca Paulo Ernesto Tolle** da FECAP:"
    elif "transferência" in t_low:
        intro = f"{greeting} Em relação à **{doc_title}** na FECAP:"
    elif "falta" in t_low or "frequência" in t_low:
        intro = f"{greeting} De acordo com o Regulamento Acadêmico da FECAP e a legislação vigente:"
    elif "cola" in t_low or "plágio" in t_low or "ética" in t_low:
        intro = f"{greeting} Sobre as regras de **Conduta e Integridade Acadêmica** da FECAP:"
    elif "substitutiva" in t_low:
        intro = f"{greeting} Sobre a realização da **Prova Substitutiva (SUB)** na FECAP:"
    else:
        intro = f"{greeting} Sobre **{doc_title}**:"

    parts = [intro, ""]

    # Conteúdo principal explicativo
    primary = desc_text or main_body or clean_markdown_snippet(top_chunk["content"])
    if primary:
        parts.append(primary)
        parts.append("")

    # Apenas inclui Passo a Passo se a pergunta pedir procedimento ou se for serviço direto
    if is_procedural and steps_text and steps_text != primary:
        parts.append("**Passo a passo no Portal do Aluno:**")
        parts.append(steps_text)
        parts.append("")

    # Busca detalhes complementares (prazos específicos de 2026, regras adicionais)
    extra_details = []
    for c in valid_chunks:
        c_text = clean_markdown_snippet(c["content"])
        if not c_text or c_text == primary or c_text == steps_text:
            continue
        if any(term in c_text.lower() for term in ["2026", "semestre de 2026", "veteranos", "75%", "r$5", "r$ 5"]):
            if c_text not in extra_details and len(c_text) < 500:
                extra_details.append(c_text)

    if extra_details:
        parts.append("**Informações Importantes:**")
        for extra in extra_details[:1]:
            parts.append(extra)
            parts.append("")
    elif prazos_text and prazos_text != primary and prazos_text != steps_text and ("prazo" in q_low or "taxa" in q_low or "custo" in q_low):
        parts.append("**Prazos e Condições:**")
        parts.append(prazos_text)
        parts.append("")

    parts.append("Se precisar de mais alguma orientação, estou à disposição para ajudar!")

    return "\n".join(parts)


def synthesize_response(query: str, retrieved_chunks: List[Dict[str, Any]]) -> str:
    """
    Ponto de entrada do sintetizador:
    1. Se houver chave de LLM no ambiente, gera resposta generativa com zero alucinação.
    2. Caso contrário, executa o Sintetizador Local Inteligente.
    """
    if not retrieved_chunks:
        return synthesize_local(query, [])

    context_parts = []
    for i, r in enumerate(retrieved_chunks[:4]):
        c = r["chunk"]
        context_parts.append(
            f"--- Documento [{i+1}]: {c['document_title']} (Seção: {c['section']}) ---\n{clean_markdown_snippet(c['content'])}"
        )
    context_text = "\n\n".join(context_parts)

    gemini_key = getattr(settings, "GEMINI_API_KEY", None) or os.getenv("GEMINI_API_KEY")
    if gemini_key:
        llm_out = _generate_with_gemini(query, context_text, gemini_key)
        if llm_out:
            return llm_out

    openai_key = getattr(settings, "OPENAI_API_KEY", None) or os.getenv("OPENAI_API_KEY")
    if openai_key:
        llm_out = _generate_with_openai(query, context_text, openai_key)
        if llm_out:
            return llm_out

    groq_key = getattr(settings, "GROQ_API_KEY", None) or os.getenv("GROQ_API_KEY")
    if groq_key:
        llm_out = _generate_with_openai(query, context_text, groq_key, base_url="https://api.groq.com/openai/v1")
        if llm_out:
            return llm_out

    return synthesize_local(query, retrieved_chunks)
