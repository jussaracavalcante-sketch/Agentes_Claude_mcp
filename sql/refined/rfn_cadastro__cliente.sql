-- rfn_cadastro__cliente
-- Refined / dominio Cadastro. Grao: um cliente. Chave: id_cliente.
-- Le trs_iclips__projeto e trs_iclips__peca_atributo.

WITH fonte AS (
  SELECT
    id_projeto,
    CAST(NULL AS STRING)                                          AS id_job_peca,
    cliente_id,
    cliente_nome,
    REGEXP_REPLACE(IFNULL(cliente_cnpj, ''), r'[^0-9]', '')       AS cnpj_digitos,
    data_entrada                                                  AS momento
  FROM `vanguardamartech_trusted.trs_iclips__projeto`
  UNION ALL
  SELECT
    CAST(NULL AS STRING),
    id_job_peca,
    id_cliente_iclips,
    cliente_nome,
    IFNULL(cliente_cnpj, ''),
    etapa_amostrada_play_inicio
  FROM `vanguardamartech_trusted.trs_iclips__peca_atributo`
),
norm AS (
  SELECT
    f.*,
    IF(LENGTH(f.cnpj_digitos) = 14, f.cnpj_digitos, NULL)         AS cnpj_ok,
    NULLIF(TRIM(f.cliente_nome), '')                              AS nome_ok
  FROM fonte f
),
-- REGRA 2: o CNPJ visto em QUALQUER linha do cliente vale para todas as dele.
cnpj_por_id AS (
  SELECT cliente_id, ANY_VALUE(cnpj_ok) AS cnpj_do_id
  FROM norm
  WHERE cliente_id IS NOT NULL AND cnpj_ok IS NOT NULL
  GROUP BY cliente_id
),
chaveado AS (
  SELECT
    n.*,
    COALESCE(n.cnpj_ok, c.cnpj_do_id)                             AS cnpj,
    -- REGRA 1: chave com fallback declarado. CNPJ quando existe; id do iClips quando nao.
    CASE
      WHEN COALESCE(n.cnpj_ok, c.cnpj_do_id) IS NOT NULL
        THEN CONCAT('CNPJ:', COALESCE(n.cnpj_ok, c.cnpj_do_id))
      WHEN n.cliente_id IS NOT NULL
        THEN CONCAT('ICLIPS:', n.cliente_id)
    END                                                           AS id_cliente,
    IF(COALESCE(n.cnpj_ok, c.cnpj_do_id) IS NOT NULL, 'CNPJ', 'ID_ICLIPS') AS chave_por
  FROM norm n
  LEFT JOIN cnpj_por_id c USING (cliente_id)
),
valido AS (SELECT * FROM chaveado WHERE id_cliente IS NOT NULL),
-- REGRA 3: nome canonico por frequencia; empate pelo mais longo, depois alfabetico.
nome_canonico AS (
  SELECT id_cliente, nome_ok AS nome, COUNT(*) AS n
  FROM valido WHERE nome_ok IS NOT NULL GROUP BY 1, 2
),
nome_escolhido AS (
  SELECT id_cliente,
         ARRAY_AGG(nome ORDER BY n DESC, LENGTH(nome) DESC, nome ASC LIMIT 1)[OFFSET(0)] AS cliente_nome,
         COUNT(*)                                                 AS qtd_nomes_conhecidos,
         STRING_AGG(nome, ' | ' ORDER BY n DESC, nome ASC)        AS nomes_conhecidos
  FROM nome_canonico GROUP BY id_cliente
),
agregado AS (
  SELECT
    id_cliente,
    ANY_VALUE(chave_por)                                          AS chave_por,
    ANY_VALUE(cnpj)                                               AS cnpj,
    COUNT(DISTINCT cliente_id)                                    AS qtd_ids_iclips,
    STRING_AGG(DISTINCT cliente_id, ', ')                         AS ids_iclips,
    COUNT(DISTINCT id_projeto)                                    AS qtd_projetos,
    COUNT(DISTINCT id_job_peca)                                   AS qtd_pecas,
    MIN(momento)                                                  AS primeira_atividade_em,
    MAX(momento)                                                  AS ultima_atividade_em
  FROM valido
  GROUP BY id_cliente
)
SELECT
  a.id_cliente,
  a.chave_por,
  a.cnpj,
  n.cliente_nome,
  n.nomes_conhecidos,
  IFNULL(n.qtd_nomes_conhecidos, 0)                               AS qtd_nomes_conhecidos,
  IFNULL(n.qtd_nomes_conhecidos, 0) > 1                           AS nome_tem_variacao,

  a.ids_iclips,
  a.qtd_ids_iclips,
  -- REGRA 4: o iClips cadastra a mesma empresa mais de uma vez. Isso e sinalizado,
  -- nao corrigido -- corrigir e no cadastro de origem, nao aqui.
  a.qtd_ids_iclips > 1                                            AS multiplos_cadastros_no_iclips,

  a.qtd_projetos,
  a.qtd_pecas,
  a.primeira_atividade_em,
  a.ultima_atividade_em,
  DATE(a.ultima_atividade_em)                                     AS data_ultima_atividade,

  a.chave_por = 'CNPJ'                                            AS identidade_juridica_resolvida,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'America/Sao_Paulo'                                             AS _fuso,
  'trs_iclips__projeto + trs_iclips__peca_atributo'               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))                                  AS _payload_hash
FROM agregado a
LEFT JOIN nome_escolhido n USING (id_cliente)
