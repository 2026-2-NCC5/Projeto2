import re
import unicodedata
from typing import List, Set
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def normalize_text(text: str) -> str:
    """
    Normaliza texto removendo acentos, caracteres especiais e espaços extras.
    """
    if not text:
        return ""
    text = unicodedata.normalize("NFKD", text)
    text = "".join([c for c in text if not unicodedata.combining(c)])
    text = text.lower()
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


# Stopwords e verbos conversacionais auxiliares em português
STOPWORDS_PT: Set[str] = {
    "a", "o", "as", "os", "um", "uma", "uns", "umas", "de", "do", "da", "dos", "das",
    "em", "no", "na", "nos", "nas", "para", "por", "com", "como", "que", "e", "ou",
    "se", "eu", "meu", "minha", "meus", "minhas", "voce", "ele", "ela", "qual", "quais",
    "onde", "quando", "quem", "quanto", "sobre", "este", "esta", "esse", "essa",
    "posso", "pode", "podem", "consigo", "consegue", "quero", "queria", "gostaria",
    "preciso", "precisa", "faco", "fazer", "saber", "obter", "ter", "ser", "esta", "estao",
    "ola", "bom", "dia", "boa", "tarde", "noite", "ajuda", "ajudar", "favor",
}


def get_stem(word: str) -> str:
    """Extrai radical/stemming simplificado em português para alinhamento semântico."""
    w = normalize_text(word)
    if len(w) <= 3:
        return w
    # Sufixos verbais e nominais comuns em PT
    suffixes = ["coes", "cao", "mentos", "mento", "ando", "endo", "indo", "aram", "erem", "irem", "ado", "ido", "ar", "er", "ir", "as", "es", "os", "s"]
    for s in suffixes:
        if w.endswith(s) and len(w) - len(s) >= 3:
            return w[:-len(s)]
    return w


def extract_keywords(text: str) -> List[str]:
    """Extrai radicais de palavras-chave significativas ignorando termos vazios."""
    normalized = normalize_text(text)
    words = normalized.split()
    stems = []
    for w in words:
        if w not in STOPWORDS_PT and len(w) > 2:
            stems.append(get_stem(w))
    return stems


class TextVectorizer:
    """
    Vetorizador e calculador de relevância semântica calibrado:
    Combina TF-IDF com busca por radicais/stemming das palavras-chave,
    fornecendo alta acurácia semântica e conformidade estrita de abstenção.
    """
    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            preprocessor=normalize_text,
            ngram_range=(1, 2),
            sublinear_tf=True,
            min_df=1,
            norm="l2",
        )
        self.is_fitted = False
        self.corpus_raw: List[str] = []

    def fit_transform(self, corpus: List[str]) -> np.ndarray:
        """Ajusta o vocabulário e gera a matriz TF-IDF."""
        self.corpus_raw = corpus
        if not corpus:
            return np.array([])
        matrix = self.vectorizer.fit_transform(corpus)
        self.is_fitted = True
        return matrix

    def transform(self, texts: List[str]) -> np.ndarray:
        """Vetoriza textos de consulta."""
        if not self.is_fitted:
            raise ValueError("O vetorizador ainda não foi ajustado (fit) ao corpus.")
        return self.vectorizer.transform(texts)

    def compute_similarity(self, query: str, query_vector: np.ndarray, doc_vectors: np.ndarray) -> np.ndarray:
        """
        Calcula o score de relevância calibrado (0.0 a 1.0).
        """
        raw_cos = cosine_similarity(query_vector, doc_vectors)[0]
        calibrated_cos = np.clip(raw_cos * 2.2, 0.0, 1.0)

        q_stems = extract_keywords(query)
        if not q_stems:
            return calibrated_cos

        keyword_scores = []
        for doc_text in self.corpus_raw:
            doc_stems = set(extract_keywords(doc_text))
            matched = sum(1 for stem in q_stems if stem in doc_stems)
            coverage = matched / len(q_stems)
            keyword_scores.append(coverage)

        keyword_arr = np.array(keyword_scores)
        
        # Média ponderada
        final_scores = 0.40 * calibrated_cos + 0.60 * keyword_arr
        return np.clip(final_scores, 0.0, 1.0)
