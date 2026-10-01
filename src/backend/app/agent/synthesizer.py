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


def _get_system_prompt_for_profile(profile_type: Optional[str] = "ALUNO") -> str:
    p = (profile_type or "ALUNO").upper()
    if "PROFESSOR" in p:
        return """Você é o assistente inteligente do ASA Connect+ para o corpo docente da FECAP.
Sua missão é prestar apoio rápido a professores sobre calendários, avaliações, PEDP, processos de acolhimento e sinalização preventiva de alunos em risco ao ASA.
Diretrizes: Tom acadêmico, colaborativo, claro e focado nas diretrizes pedagógicas e regulatórias da FECAP."""
    elif "RESPONSAVEL" in p:
        return """Você é o assistente oficial do ASA Connect+ para pais e responsáveis financeiros dos estudantes da FECAP.
Sua missão é esclarecer com transparência, segurança e respeito à LGPD questões financeiras (boletos, mensalidades, declarações IRPF) e procedimentos administrativos institucionais.
Diretrizes: Tom acolhedor, formal, respeitoso e focado em regulamentos contratuais e financeiros."""
    elif "COLABORADOR" in p or "ADMIN" in p:
        return """Você é o assistente institucional do ASA Connect+ para colaboradores e equipes de atendimento da FECAP.
Sua missão é fornecer consultas rápidas aos 311 manuais de procedimentos, prazos, taxas e fluxos internos de validação documental e protocolos.
Diretrizes: Tom profissional, altamente técnico, objetivo e preciso quanto a normas institucionais."""
    return ALVARISTA_SYSTEM_PROMPT


def _generate_with_gemini(query: str, context: str, api_key: str, profile_type: Optional[str] = "ALUNO") -> Optional[str]:
    """Chama a API do Google Gemini via HTTP REST com fallback automático de modelos."""
    system_prompt = _get_system_prompt_for_profile(profile_type)
    models_to_try = [
        getattr(settings, "LLM_MODEL", None) or "gemini-flash-lite-latest",
        "gemini-flash-lite-latest",
        "gemini-3.1-flash-lite",
        "gemini-flash-latest",
        "gemini-2.5-flash-lite",
        "gemini-3.6-flash",
    ]
    models_to_try = list(dict.fromkeys([m for m in models_to_try if m]))

    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {
                        "text": f"{system_prompt}\n\nContexto Oficial da FECAP:\n{context}\n\nPergunta do Usuário:\n{query}"
                    }
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 800,
        }
    }

    for model in models_to_try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        try:
            with httpx.Client(timeout=8.0) as client:
                resp = client.post(url, json=payload)
                if resp.status_code == 200:
                    data = resp.json()
                    candidates = data.get("candidates", [])
                    if candidates and candidates[0].get("content", {}).get("parts"):
                        text = candidates[0]["content"]["parts"][0].get("text", "")
                        clean_text = text.strip()
                        # Validação de integridade: não aceita fragmentos interrompidos
                        if len(clean_text) >= 80 and not clean_text.endswith(("**", "R$", "em:", "no: ")):
                            return clean_text
        except Exception:
            continue
    return None


def _generate_with_openai(query: str, context: str, api_key: str, base_url: str = "https://api.openai.com/v1", profile_type: Optional[str] = "ALUNO") -> Optional[str]:
    """Chama API compatível com OpenAI (OpenAI ou Groq)."""
    system_prompt = _get_system_prompt_for_profile(profile_type)
    url = f"{base_url.rstrip('/')}/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "gpt-4o-mini" if "openai" in base_url else "llama-3.3-70b-versatile",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Contexto Oficial FECAP:\n{context}\n\nPergunta do Usuário:\n{query}"}
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


def synthesize_local(query: str, retrieved_chunks: List[Dict[str, Any]], profile_type: Optional[str] = "ALUNO") -> str:
    """
    Sintetizador Local Inteligente do ASA Connect+:
    Formata uma resposta humana, precisa e agradável a partir dos trechos oficiais recuperados,
    sem necessitar de chamadas externas de LLM.
    """
    prof = (profile_type or "ALUNO").upper()
    if not retrieved_chunks:
        if "PROFESSOR" in prof:
            return (
                "Olá, Professor(a)! Não localizei essa informação na base oficial de regulamentos docentes da FECAP. "
                "Recomendo consultar a coordenação de curso ou a Secretaria Geral."
            )
        elif "RESPONSAVEL" in prof:
            return (
                "Olá! Não localizei essa informação na base oficial de serviços e normas da FECAP. "
                "Para orientações sobre contratos, pagamentos ou autorizações, recomendamos contatar a Central de Atendimento ASA."
            )
        elif "COLABORADOR" in prof or "ADMIN" in prof:
            return (
                "Olá, Colega Alvarista! Essa informação não consta diretamente nos manuais indexados. "
                "Consulte os fluxos de trabalho e procedimentos operacionais no Portal Corporativo."
            )
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

    if "PROFESSOR" in prof:
        greeting = "Olá, Professor(a)!"
    elif "RESPONSAVEL" in prof:
        greeting = "Olá! Seja bem-vindo(a) ao atendimento para responsáveis da FECAP."
    elif "COLABORADOR" in prof or "ADMIN" in prof:
        greeting = "Olá, Colega Alvarista!"
    else:
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

    # Conteúdo principal explicativo com busca resiliente
    primary = desc_text or main_body
    if not primary:
        for c in chunks_from_top_doc:
            cl = clean_markdown_snippet(c["content"])
            if cl and len(cl) >= 30:
                primary = cl
                break

    if not primary:
        for c in valid_chunks:
            cl = clean_markdown_snippet(c["content"])
            if cl and len(cl) >= 30:
                primary = cl
                break

    if not primary and top_chunk.get("content"):
        cl = clean_markdown_snippet(top_chunk["content"])
        if cl and len(cl) >= 15:
            primary = cl

    if primary:
        parts.append(primary)
        parts.append("")

    # Sempre inclui Passo a Passo se disponível e não redundante
    if steps_text and steps_text != primary:
        parts.append("**Passo a passo no Portal do Aluno:**")
        parts.append(steps_text)
        parts.append("")

    # Sempre inclui Prazos e Condições se disponível e não redundante
    if prazos_text and prazos_text != primary and prazos_text != steps_text:
        parts.append("**Prazos e Condições Importantes:**")
        parts.append(prazos_text)
        parts.append("")

    # Busca detalhes complementares (prazos específicos de 2026, regras adicionais)
    extra_details = []
    for c in valid_chunks:
        c_text = clean_markdown_snippet(c["content"])
        if not c_text or c_text == primary or c_text == steps_text or c_text == prazos_text:
            continue
        if any(term in c_text.lower() for term in ["2026", "semestre de 2026", "veteranos", "75%", "r$5", "r$ 5"]):
            if c_text not in extra_details and len(c_text) < 500:
                extra_details.append(c_text)

    if extra_details:
        parts.append("**Informações Complementares:**")
        for extra in extra_details[:1]:
            parts.append(extra)
            parts.append("")

    # Se mesmo assim o corpo ficou sem explicações (apenas saudação), insere orientação segura de atendimento:
    if len(parts) <= 2:
        portal_name = "Portal do Professor" if "PROFESSOR" in prof else ("Portal do Responsável" if "RESPONSAVEL" in prof else "Portal do Aluno")
        parts.append(
            f"Para solicitar ou consultar orientações sobre **{doc_title}**, acesse o {portal_name} "
            f"(Menu > Requerimentos) ou dirija-se ao balcão de atendimento da Área do Sucesso Alvarista (ASA) no Campus Liberdade."
        )
        parts.append("")

    parts.append("Se precisar de mais alguma orientação, estou à disposição para ajudar!")

    return "\n".join(parts)


def synthesize_response(query: str, retrieved_chunks: List[Dict[str, Any]], profile_type: Optional[str] = "ALUNO") -> str:
    """
    Ponto de entrada do sintetizador:
    1. Se houver chave de LLM no ambiente, gera resposta generativa com zero alucinação.
    2. Caso contrário, executa o Sintetizador Local Inteligente.
    """
    if not retrieved_chunks:
        return synthesize_local(query, [], profile_type=profile_type)

    context_parts = []
    for i, r in enumerate(retrieved_chunks[:4]):
        c = r["chunk"]
        context_parts.append(
            f"--- Documento [{i+1}]: {c['document_title']} (Seção: {c['section']}) ---\n{clean_markdown_snippet(c['content'])}"
        )
    context_text = "\n\n".join(context_parts)

    gemini_key = getattr(settings, "GEMINI_API_KEY", None) or os.getenv("GEMINI_API_KEY")
    if gemini_key:
        llm_out = _generate_with_gemini(query, context_text, gemini_key, profile_type=profile_type)
        if llm_out:
            return llm_out

    openai_key = getattr(settings, "OPENAI_API_KEY", None) or os.getenv("OPENAI_API_KEY")
    if openai_key:
        llm_out = _generate_with_openai(query, context_text, openai_key, profile_type=profile_type)
        if llm_out:
            return llm_out

    groq_key = getattr(settings, "GROQ_API_KEY", None) or os.getenv("GROQ_API_KEY")
    if groq_key:
        llm_out = _generate_with_openai(query, context_text, groq_key, base_url="https://api.groq.com/openai/v1", profile_type=profile_type)
        if llm_out:
            return llm_out

    return synthesize_local(query, retrieved_chunks, profile_type=profile_type)
