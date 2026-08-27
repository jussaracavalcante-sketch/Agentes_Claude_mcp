"""Fatiamento de documento em trechos recuperaveis."""

from __future__ import annotations

import re

# Aproximacao suficiente para dimensionar chunk: portugues gira em torno de
# 4 caracteres por token. Nao substitui contagem real do tokenizador do modelo.
CHARS_PER_TOKEN = 4

_PARAGRAPH = re.compile(r"\n\s*\n")
_SENTENCE = re.compile(r"(?<=[.!?])\s+")


def estimate_tokens(text: str) -> int:
    return max(1, len(text) // CHARS_PER_TOKEN)


def chunk_text(text: str, chunk_size: int = 800, overlap: int = 80) -> list[str]:
    """Divide o texto em trechos de ate `chunk_size` tokens, com sobreposicao.

    Quebra por paragrafo primeiro e por frase depois: cortar no meio de uma
    frase degrada a recuperacao mais do que um chunk levemente maior.
    """
    text = text.strip()
    if not text:
        return []

    limit = max(1, chunk_size) * CHARS_PER_TOKEN
    overlap_chars = min(max(0, overlap) * CHARS_PER_TOKEN, limit // 2)

    units: list[str] = []
    for paragraph in _PARAGRAPH.split(text):
        paragraph = paragraph.strip()
        if not paragraph:
            continue
        if len(paragraph) <= limit:
            units.append(paragraph)
            continue
        # Paragrafo maior que o limite: desce para frases.
        for sentence in _SENTENCE.split(paragraph):
            sentence = sentence.strip()
            if not sentence:
                continue
            while len(sentence) > limit:
                units.append(sentence[:limit])
                sentence = sentence[limit - overlap_chars :]
            if sentence:
                units.append(sentence)

    chunks: list[str] = []
    buffer = ""
    for unit in units:
        candidate = f"{buffer}\n\n{unit}" if buffer else unit
        if len(candidate) <= limit:
            buffer = candidate
            continue
        if buffer:
            chunks.append(buffer)
            # A sobreposicao e desejavel, mas nao ao custo de estourar o limite:
            # `tail + unit` pode passar de `limit` e furar o orcamento de contexto
            # que o chamador pediu. Nesse caso, abre-se o trecho sem sobreposicao.
            tail = buffer[-overlap_chars:] if overlap_chars else ""
            candidato = f"{tail}\n\n{unit}".strip() if tail else unit
            buffer = candidato if len(candidato) <= limit else unit
        else:
            buffer = unit

    if buffer:
        chunks.append(buffer)
    return chunks
