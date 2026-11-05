import os
import yaml
from typing import Dict, Any, Tuple
from app.core.config import settings


def load_rag_config() -> Dict[str, Any]:
    """Carrega o arquivo de configuração dinâmico do RAG (RF04)."""
    config_path = os.path.join(os.path.dirname(__file__), "rag_config.yaml")
    if os.path.exists(config_path):
        with open(config_path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    return {
        "rag": {"confidence_threshold": settings.RAG_CONFIDENCE_THRESHOLD},
        "abstention": {
            "message": "Não encontrei uma informação oficial e confiável sobre este tópico na base institucional. Prefiro te conectar diretamente com um atendente humano do ASA."
        },
    }


def should_abstain(max_similarity: float, custom_threshold: float = None) -> Tuple[bool, str]:
    """
    Regra de Abstenção do Agente ASA (RF04):
    Compara o score de similaridade de cosseno máximo com o limiar configurado.
    Retorna (deve_abster: bool, motivo: str).
    """
    config = load_rag_config()
    threshold = custom_threshold or config.get("rag", {}).get("confidence_threshold", settings.RAG_CONFIDENCE_THRESHOLD)
    
    if max_similarity < threshold:
        reason = (
            f"Score de similaridade obtido ({max_similarity:.2f}) ficou abaixo do limiar de segurança ({threshold:.2f}). "
            "Para evitar alucinação ou orientação incorreta de prazos/procedimentos, o agente optou pela abstenção segura."
        )
        return True, reason

    return False, f"Score de similaridade ({max_similarity:.2f}) suficiente para resposta autorizada."
