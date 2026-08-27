"""Indexacao e recuperacao de trechos de conhecimento.

A busca tenta primeiro o operador de distancia do pgvector; se a extensao nao
estiver instalada (ou o banco for SQLite), cai para similaridade de cosseno
calculada na aplicacao. O resultado e o mesmo ranking; o que muda e onde o
custo e pago.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

from sqlalchemy import select, text
from sqlalchemy.exc import DatabaseError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import KnowledgeBase, KnowledgeChunk, KnowledgeDocument
from app.rag.chunking import chunk_text, estimate_tokens
from app.rag.embedding import Embedder, cosine_similarity, get_embedder

logger = logging.getLogger("vkb.rag")

# Teto de trechos trazidos do banco quando a ordenacao acontece na aplicacao.
APP_SIDE_SCAN_LIMIT = 2_000


@dataclass(frozen=True)
class RetrievedChunk:
    chunk_uid: str
    document_uid: str
    document_title: str
    base_uid: str
    ordinal: int
    content: str
    score: float


def default_embedder() -> Embedder:
    """Embedder usado quando o chamador nao informa um.

    Sem credencial configurada o padrao e o `hashing`: local, deterministico e
    sem custo. Trocar para um provedor real e questao de passar outro embedder.
    """
    return get_embedder("hashing")


def index_document(
    db: Session,
    document: KnowledgeDocument,
    *,
    embedder: Embedder | None = None,
    chunk_size: int | None = None,
    overlap: int = 80,
) -> list[KnowledgeChunk]:
    """(Re)indexa um documento: apaga os trechos antigos e grava os novos."""
    embedder = embedder or default_embedder()
    base = db.get(KnowledgeBase, document.base_uid)
    size = chunk_size or (base.chunk_size if base else 800)

    for existing in list(document.chunks):
        db.delete(existing)
    db.flush()

    pieces = chunk_text(document.content, chunk_size=size, overlap=overlap)
    if not pieces:
        document.chunk_count = 0
        document.status = "empty"
        db.flush()
        return []

    # O titulo entra no texto vetorizado, mas nao no conteudo devolvido: ele
    # costuma trazer o termo que o usuario digita ("escalonamento", "renovacao")
    # e que o corpo do trecho as vezes nao repete.
    titulo = document.title.strip()
    vectors = embedder.embed(
        [f"{titulo}\n\n{piece}" if titulo else piece for piece in pieces]
    )
    chunks: list[KnowledgeChunk] = []
    for ordinal, (piece, vector) in enumerate(zip(pieces, vectors, strict=True)):
        chunk = KnowledgeChunk(
            base_uid=document.base_uid,
            document_uid=document.uid,
            ordinal=ordinal,
            content=piece,
            token_count=estimate_tokens(piece),
            embedder=embedder.name,
            dimensions=len(vector),
            embedding_json=vector,
        )
        db.add(chunk)
        chunks.append(chunk)

    document.chunk_count = len(chunks)
    document.status = "indexed"
    db.flush()
    return chunks


def reindex_base(
    db: Session, base: KnowledgeBase, *, embedder: Embedder | None = None
) -> int:
    """Reindexa todos os documentos da base. Devolve o total de trechos."""
    embedder = embedder or default_embedder()
    total = 0
    for document in base.documents:
        total += len(index_document(db, document, embedder=embedder))
    return total


def retrieve(
    db: Session,
    query: str,
    *,
    tenant_uid: str,
    base_uids: list[str] | None = None,
    top_k: int = 5,
    min_score: float = 0.0,
    embedder: Embedder | None = None,
) -> list[RetrievedChunk]:
    """Recupera os `top_k` trechos mais proximos da consulta."""
    query = query.strip()
    if not query:
        return []

    embedder = embedder or default_embedder()
    query_vector = embedder.embed_one(query)

    scoped = _scoped_base_uids(db, tenant_uid, base_uids)
    if not scoped:
        return []

    if not settings.is_sqlite:
        native = _retrieve_pgvector(db, query_vector, scoped, top_k, min_score)
        if native is not None:
            return native

    return _retrieve_in_app(db, query_vector, scoped, top_k, min_score, embedder.name)


def _scoped_base_uids(
    db: Session, tenant_uid: str, base_uids: list[str] | None
) -> list[str]:
    """Bases visiveis ao tenant — a fronteira de isolamento da recuperacao."""
    stmt = select(KnowledgeBase.uid).where(
        KnowledgeBase.tenant_uid == tenant_uid, KnowledgeBase.is_enabled.is_(True)
    )
    if base_uids:
        stmt = stmt.where(KnowledgeBase.uid.in_(base_uids))
    return list(db.scalars(stmt).all())


def _retrieve_pgvector(
    db: Session,
    query_vector: list[float],
    base_uids: list[str],
    top_k: int,
    min_score: float,
) -> list[RetrievedChunk] | None:
    """Ordena no banco via pgvector. Devolve None se a extensao nao existir."""
    literal = "[" + ",".join(f"{value:.6f}" for value in query_vector) + "]"
    sql = text(
        """
        SELECT c.uid, c.document_uid, d.title, c.base_uid, c.ordinal, c.content,
               1 - ((c.embedding_json #>> '{}')::vector <=> (:vec)::vector) AS score
        FROM knowledge_chunks c
        JOIN knowledge_documents d ON d.uid = c.document_uid
        WHERE c.base_uid = ANY(:bases)
        ORDER BY (c.embedding_json #>> '{}')::vector <=> (:vec)::vector
        LIMIT :limit
        """
    )
    try:
        rows = db.execute(
            sql, {"vec": literal, "bases": base_uids, "limit": top_k}
        ).all()
    except DatabaseError:
        # Extensao ausente ou tipo indisponivel: a transacao precisa ser limpa
        # antes de seguir pelo caminho da aplicacao.
        db.rollback()
        logger.info("pgvector indisponivel; usando similaridade na aplicacao")
        return None

    return [
        RetrievedChunk(
            chunk_uid=row[0],
            document_uid=row[1],
            document_title=row[2],
            base_uid=row[3],
            ordinal=row[4],
            content=row[5],
            score=float(row[6]),
        )
        for row in rows
        if float(row[6]) >= min_score
    ]


def _retrieve_in_app(
    db: Session,
    query_vector: list[float],
    base_uids: list[str],
    top_k: int,
    min_score: float,
    embedder_name: str,
) -> list[RetrievedChunk]:
    """Similaridade de cosseno calculada na aplicacao."""
    rows = db.execute(
        select(
            KnowledgeChunk.uid,
            KnowledgeChunk.document_uid,
            KnowledgeDocument.title,
            KnowledgeChunk.base_uid,
            KnowledgeChunk.ordinal,
            KnowledgeChunk.content,
            KnowledgeChunk.embedding_json,
            KnowledgeChunk.embedder,
        )
        .join(KnowledgeDocument, KnowledgeDocument.uid == KnowledgeChunk.document_uid)
        .where(KnowledgeChunk.base_uid.in_(base_uids))
        .limit(APP_SIDE_SCAN_LIMIT)
    ).all()

    scored: list[RetrievedChunk] = []
    skipped = 0
    for row in rows:
        # Comparar vetores de embedders diferentes produz ranking sem sentido.
        if row[7] != embedder_name:
            skipped += 1
            continue
        score = cosine_similarity(query_vector, row[6] or [])
        if score < min_score:
            continue
        scored.append(
            RetrievedChunk(
                chunk_uid=row[0],
                document_uid=row[1],
                document_title=row[2],
                base_uid=row[3],
                ordinal=row[4],
                content=row[5],
                score=score,
            )
        )

    if skipped:
        logger.warning(
            "%d trecho(s) ignorado(s): indexados por outro embedder que '%s'. "
            "Reindexe a base para uniformizar.",
            skipped,
            embedder_name,
        )

    scored.sort(key=lambda item: item.score, reverse=True)
    return scored[:top_k]
