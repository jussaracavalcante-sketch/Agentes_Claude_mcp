-- trs_contazul__categoria  ·  query-y2xj  ·  382 linhas  ·  L2 INTERNAL
-- Trusted / Conta Azul. Grao: uma categoria do plano de contas. Chave: id_categoria.
-- Origem: mysql-yIOn, contazul_categorias (382). Gatilho: evento em query-kwIs.
--
-- POR QUE EXISTE: e a dimensao de categoria do fato financeiro do Conta Azul
--   (ca_fato_evento_financeiro.id_categoria). Resolve 5.525 de 6.768 eventos (81,6%);
--   os 1.243 restantes usam 53 categorias que este espelho nao tem, porque ele parou de
--   sincronizar em 17/08/2026 e o fato recebe dado ate 15/09. Por isso a Trusted de
--   movimento usa esta tabela como COMPLEMENTO do nome que ja vem no evento.
--
-- REGRA 1 — SETE NOMES APARECEM DUAS VEZES, COM IDS DIFERENTES. 382 categorias, 376 nomes
--   distintos, 375 apos normalizar caixa e acento. Os pares: "Custo com time",
--   "Custo com freelancer", "Ajustes", "Ferramenta", "Sistemas",
--   "Outras Despesas Administrativas" (grafias IDENTICAS, dois UUIDs) e
--   "Transferência entre contas" / "Transferência entre Contas" (so a caixa muda).
--   Agrupar custo por `id_categoria` PARTE "Custo com time" em dois; agrupar por `nome` os
--   junta. A tabela nao escolhe: emite id, nome cru, nome_normalizado e
--   `flag_nome_duplicado` com `qtd_categorias_com_este_nome`.
-- REGRA 2 — o nome normalizado NAO substitui o cru. Normalizar antes de medir apaga o unico
--   sintoma visivel do cadastro duplicado (mesma doutrina de `Off`/`OFF`).
-- REGRA 3 — `id_legado`, `codigo`, `documento` e `email` sao NULL nas 382 e ficam de fora.
--   O esquema e compartilhado com as tabelas de pessoa; nesta entidade nao se aplica.
-- REGRA 4 — `ativo` nao separa nada: 382 de 382 ativas.
--
-- FUSO: sem conversao — MySQL `vjob_2024`, hora local ja medida.
--
-- LIMITACOES — NAO CONTORNE
--   1. NAO HA HIERARQUIA. O Conta Azul tem categoria pai e filha; o espelho trouxe lista
--      plana. Nao existe agrupamento por grupo de conta nesta base.
--   2. NAO HA CLASSE FINANCEIRA AQUI — ela e regra de negocio e vive na
--      trs_contazul__movimento, declarada e numerada.
--   3. ESPELHO CONGELADO em 17/08/2026: categoria criada depois disso nao esta aqui.

WITH bruto AS (
  SELECT
    contaazul_id,
    nome,
    ativo,
    empresa_chave,
    sincronizado_em,
    criado_em,
    atualizado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_categorias`
),
normalizado AS (
  SELECT
    b.*,
    TRIM(REGEXP_REPLACE(
      LOWER(REGEXP_REPLACE(NORMALIZE(b.nome, NFD), r'\pM', '')),
      r'\s+', ' ')) AS nome_normalizado
  FROM bruto b
),
com_duplicata AS (
  SELECT
    n.*,
    COUNT(*) OVER (PARTITION BY n.nome_normalizado) AS qtd_categorias_com_este_nome
  FROM normalizado n
),
final AS (
  SELECT
    c.contaazul_id                                  AS id_categoria,
    c.nome,
    c.nome_normalizado,
    c.qtd_categorias_com_este_nome,
    (c.qtd_categorias_com_este_nome > 1)            AS flag_nome_duplicado,
    (c.ativo = 1)                                   AS is_ativa,
    c.empresa_chave,
    e.documento                                     AS empresa_documento,
    e.nome_fantasia                                 AS empresa_nome_fantasia,
    c.criado_em,
    c.atualizado_em,
    c.sincronizado_em
  FROM com_duplicata c
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_empresas` e
    ON e.chave = c.empresa_chave
)
SELECT
  f.*,
  'L2_INTERNAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'mysql-yIOn'                                  AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
