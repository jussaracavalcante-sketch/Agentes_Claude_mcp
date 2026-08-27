"""Recuperacao de conhecimento.

O caso de acerto no top-1 e uma avaliacao, nao um teste de unidade: ele fixa a
qualidade minima da recuperacao contra o conhecimento do seed. Se uma mudanca no
tokenizador, no radicalizador ou no chunking piorar o ranking, o teste cai.
"""

from fastapi.testclient import TestClient

from app.rag.chunking import chunk_text
from app.rag.embedding import HashingEmbedder, cosine_similarity, fold, stem, tokenize

# (consulta, titulo do documento que deve vir em primeiro)
CASOS_TOP1 = [
    ("prazo de veiculacao em Manaus", "Prazos de veiculação por praça"),
    ("quando escalonar para humano", "Critério de escalonamento"),
    ("qual a verba minima de campanha", "Verba mínima por campanha"),
    ("multa de rescisao contratual", "Cláusula de rescisão"),
    ("posso mandar dado de cliente para IA externa?", "Política de uso de IA"),
    ("o que significa autonomia N4", "Níveis de autonomia"),
    ("onde fica a assinatura da marca", "Uso da assinatura"),
    ("como emitir segunda via de boleto", "Segunda via de boleto"),
    ("preciso confirmar CNPJ do cliente?", "Identificação do cliente"),
    ("quando o contrato renova", "Vigência e renovação"),
]

# Piso de qualidade. Abaixo disso a recuperacao nao sustenta um agente.
ACERTO_MINIMO = 0.8


def test_fold_remove_acento_e_caixa():
    assert fold("Verba Mínima por Campanha") == "verba minima por campanha"
    assert fold("Rescisão") == "rescisao"


def test_stem_unifica_familia_morfologica():
    assert stem("escalonamento") == stem("escalonar")
    assert stem("renovacao") == stem("renova")
    assert stem("veiculacao") == stem("veicular")


def test_stem_preserva_radical_minimo():
    # Cortar abaixo de quatro caracteres destruiria a palavra.
    assert stem("mes") == "mes"
    assert stem("ano") == "ano"


def test_tokenize_descarta_palavra_funcional():
    tokens = tokenize("a verba mínima para a campanha")
    assert "para" not in tokens
    assert "verba" in tokens


def test_embedder_normaliza_e_nao_estoura_em_colisao():
    embedder = HashingEmbedder(dimensions=64)  # dimensao baixa força colisão
    vetor = embedder.embed_one(" ".join(f"palavra{i}" for i in range(500)))
    assert len(vetor) == 64
    assert abs(sum(v * v for v in vetor) ** 0.5 - 1.0) < 1e-6


def test_similaridade_reconhece_texto_proximo_e_distante():
    embedder = HashingEmbedder()
    prazo = embedder.embed_one("prazo de veiculacao na praca de Manaus e de 5 dias")
    consulta = embedder.embed_one("qual o prazo de veiculacao em Manaus")
    distante = embedder.embed_one("a assinatura da marca fica no canto inferior")
    assert cosine_similarity(prazo, consulta) > cosine_similarity(prazo, distante)


def test_chunk_respeita_o_limite_e_nao_perde_conteudo():
    texto = "\n\n".join(f"Paragrafo {i}. " + ("palavra " * 60) for i in range(6))
    pedacos = chunk_text(texto, chunk_size=100, overlap=10)
    assert len(pedacos) > 1
    assert all(len(pedaco) <= 100 * 4 for pedaco in pedacos)
    assert "Paragrafo 0" in pedacos[0]
    assert any("Paragrafo 5" in pedaco for pedaco in pedacos)


def test_chunk_de_texto_vazio():
    assert chunk_text("") == []
    assert chunk_text("   \n\n  ") == []


def test_seed_indexa_o_conhecimento(client: TestClient, auth):
    bases = client.get("/api/v1/knowledge", headers=auth).json()
    assert bases, "o seed precisa criar bases de conhecimento"
    assert all(base["document_count"] > 0 for base in bases)


def test_recuperacao_acerta_o_documento_no_top1(client: TestClient, auth):
    acertos = []
    for consulta, esperado in CASOS_TOP1:
        response = client.post(
            "/api/v1/knowledge/retrieve",
            headers=auth,
            json={"query": consulta, "top_k": 1},
        )
        assert response.status_code == 200, response.text
        chunks = response.json()["chunks"]
        obtido = chunks[0]["document_title"] if chunks else None
        acertos.append((consulta, esperado, obtido))

    corretos = [caso for caso in acertos if caso[1] == caso[2]]
    taxa = len(corretos) / len(acertos)
    falhas = "\n".join(
        f"  {consulta!r}: esperado {esperado!r}, veio {obtido!r}"
        for consulta, esperado, obtido in acertos
        if esperado != obtido
    )
    assert taxa >= ACERTO_MINIMO, (
        f"acerto no top-1 caiu para {taxa:.0%} (piso {ACERTO_MINIMO:.0%}):\n{falhas}"
    )


def test_recuperacao_nao_atravessa_tenant(client: TestClient, auth):
    resposta = client.post(
        "/api/v1/knowledge/retrieve",
        headers=auth,
        json={"query": "prazo", "base_uids": ["base-de-outro-tenant"]},
    )
    assert resposta.status_code == 200
    assert resposta.json()["hits"] == 0


def test_indexar_exige_permissao(client: TestClient, auditor_auth):
    bases = client.get("/api/v1/knowledge", headers=auditor_auth).json()
    resposta = client.post(
        f"/api/v1/knowledge/{bases[0]['uid']}/index",
        headers=auditor_auth,
        json={"embedder": "hashing"},
    )
    assert resposta.status_code == 403
