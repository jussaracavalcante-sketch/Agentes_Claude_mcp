"""Camada 5 — recuperacao de conhecimento (RAG)."""

from app.rag.chunking import chunk_text
from app.rag.embedding import EMBEDDERS, Embedder, get_embedder
from app.rag.retrieval import RetrievedChunk, index_document, reindex_base, retrieve

__all__ = [
    "chunk_text",
    "Embedder",
    "EMBEDDERS",
    "get_embedder",
    "index_document",
    "reindex_base",
    "retrieve",
    "RetrievedChunk",
]
