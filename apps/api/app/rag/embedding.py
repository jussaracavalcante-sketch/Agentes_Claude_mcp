"""Embedders plugaveis.

Dois caminhos, pela mesma interface:

* `hashing` — determinístico, local, sem rede e sem custo. É o padrão em
  desenvolvimento e em teste: permite exercitar o RAG de ponta a ponta sem
  contratar provedor. Não tem qualidade semântica de um modelo treinado.
* `http` — chama um endpoint de embeddings compatível com o formato
  `{"input": [...], "model": "..."}` → `{"data": [{"embedding": [...]}]}`,
  que é o adotado pela maioria dos provedores. A URL, o modelo e a credencial
  vêm da configuração do provedor no banco, nunca de valor fixo no código.
"""

from __future__ import annotations

import hashlib
import math
import re
import unicodedata
from abc import ABC, abstractmethod

import httpx

DEFAULT_DIMENSIONS = 1024
_TOKEN = re.compile(r"[a-zà-ú0-9]+", re.IGNORECASE)

# Palavras funcionais do portugues. Sem IDF, um termo ubiquo como "para" faz um
# trecho curto e irrelevante vencer um trecho longo e pertinente — o vies de
# documento curto do cosseno. Descartar essas palavras corrige a maior parte
# disso a custo zero.
STOPWORDS = frozenset(
    """
    a ao aos as à às até com como da das de dela delas dele deles do dos e ela
    elas ele eles em entre era eram essa essas esse esses esta estas este estes
    eu foi foram há isso isto já lhe lhes mais mas me mesmo meu meus muito na
    nas nem no nos nossa nossas nosso nossos num numa o os ou para pela pelas
    pelo pelos por qual quando que quem se sem ser seu seus so só sua suas
    também te tem tinha to um uma umas uns você vocês
    devo deve devem posso pode podem quero queria fazer faco
    """.split()
)


def fold(text: str) -> str:
    """Minusculas sem acento.

    Quem consulta digita "verba minima"; o documento diz "verba mínima". Sem
    dobrar o acento, sao tokens diferentes e a recuperacao erra o alvo.
    """
    normalized = unicodedata.normalize("NFKD", text.lower())
    return "".join(char for char in normalized if not unicodedata.combining(char))


# Sufixos do portugues, do mais longo para o mais curto. Radicalizar resolve
# "escalonar" x "escalonamento" e "contratual" x "contrato", que um casamento
# literal perde. A lista e curta de proposito: cortar demais gera falso positivo.
_SUFFIXES = (
    "amentos", "amento", "imentos", "imento",
    "acoes", "acao", "coes", "cao",
    "adoras", "adores", "adora", "ador",
    "antes", "ante", "ancia",
    "aveis", "avel", "iveis", "ivel",
    "issimo", "issima",
    "mente",
    "aram", "arao", "ariam", "aria", "ando", "ados", "adas", "ado", "ada",
    "endo", "indo", "iram", "irao",
    "ares", "ar", "er", "ir",
    "oes", "aes", "eis",
    "as", "os", "es", "s",
    # Vogal final de conjugacao ("renova" -> "renov", que casa com
    # "renovacao" -> "renov"). Conflaciona palavras distintas as vezes, mas de
    # forma simetrica: consulta e documento passam pelo mesmo radicalizador.
    "a", "o", "e",
)

# Radical minimo: abaixo disso o corte destroi a palavra.
_MIN_STEM = 4


def stem(token: str) -> str:
    """Remove um sufixo comum, preservando um radical minimo."""
    if len(token) <= _MIN_STEM or token.isdigit():
        return token
    for suffix in _SUFFIXES:
        if token.endswith(suffix) and len(token) - len(suffix) >= _MIN_STEM:
            return token[: -len(suffix)]
    return token


def tokenize(text: str) -> list[str]:
    return [
        token
        for match in _TOKEN.finditer(fold(text))
        if (token := match.group(0)) not in STOPWORDS
    ]


def cosine_similarity(left: list[float], right: list[float]) -> float:
    if not left or not right or len(left) != len(right):
        return 0.0
    dot = sum(a * b for a, b in zip(left, right, strict=True))
    norm_left = math.sqrt(sum(a * a for a in left))
    norm_right = math.sqrt(sum(b * b for b in right))
    if norm_left == 0.0 or norm_right == 0.0:
        return 0.0
    return dot / (norm_left * norm_right)


class Embedder(ABC):
    """Contrato de um gerador de embeddings."""

    name: str
    dimensions: int

    @abstractmethod
    def embed(self, texts: list[str]) -> list[list[float]]:
        """Devolve um vetor por texto, na mesma ordem."""

    def embed_one(self, text: str) -> list[float]:
        return self.embed([text])[0]


class HashingEmbedder(Embedder):
    """Projeção por hash com peso sublinear de frequência.

    Não é um modelo de linguagem: aproxima similaridade léxica. Serve para o
    RAG funcionar em desenvolvimento, teste e demonstração sem provedor.
    """

    name = "hashing"

    def __init__(self, dimensions: int = DEFAULT_DIMENSIONS) -> None:
        self.dimensions = dimensions

    def embed(self, texts: list[str]) -> list[list[float]]:
        return [self._embed_single(text) for text in texts]

    def _embed_single(self, text: str) -> list[float]:
        counts: dict[int, float] = {}
        for token in tokenize(text):
            digest = hashlib.blake2b(stem(token).encode(), digest_size=8).digest()
            bucket = int.from_bytes(digest[:4], "big") % self.dimensions
            # Contagem sem sinal: com sinal, dois termos colidindo no mesmo bucket
            # se cancelam e o trecho certo passa a marcar zero de similaridade —
            # perde-se a correspondência real, que é pior que o viés de colisão.
            counts[bucket] = counts.get(bucket, 0.0) + 1.0

        vector = [0.0] * self.dimensions
        for bucket, raw in counts.items():
            # Peso sublinear: um termo repetido não domina o vetor.
            vector[bucket] = 1.0 + math.log(raw)

        norm = math.sqrt(sum(value * value for value in vector))
        if norm == 0.0:
            return vector
        return [value / norm for value in vector]


class HttpEmbedder(Embedder):
    """Adaptador para endpoint de embeddings de um provedor."""

    name = "http"

    def __init__(
        self,
        base_url: str,
        model: str,
        api_key: str | None = None,
        dimensions: int = DEFAULT_DIMENSIONS,
        timeout: float = 30.0,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.api_key = api_key
        self.dimensions = dimensions
        self.timeout = timeout

    def embed(self, texts: list[str]) -> list[list[float]]:
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        response = httpx.post(
            f"{self.base_url}/embeddings",
            headers=headers,
            json={"input": texts, "model": self.model},
            timeout=self.timeout,
        )
        response.raise_for_status()
        payload = response.json()

        vectors = [item["embedding"] for item in payload.get("data", [])]
        if len(vectors) != len(texts):
            raise ValueError(
                f"Provedor devolveu {len(vectors)} vetores para {len(texts)} textos."
            )
        if vectors:
            self.dimensions = len(vectors[0])
        return vectors


EMBEDDERS: dict[str, type[Embedder]] = {
    "hashing": HashingEmbedder,
    "http": HttpEmbedder,
}


def get_embedder(kind: str = "hashing", **options) -> Embedder:
    try:
        factory = EMBEDDERS[kind]
    except KeyError as exc:
        known = ", ".join(sorted(EMBEDDERS))
        raise ValueError(f"Embedder '{kind}' desconhecido. Disponíveis: {known}.") from exc
    return factory(**options)
