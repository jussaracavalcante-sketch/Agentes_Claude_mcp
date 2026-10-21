-- rfn_financeiro__contazul_apoio_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (carrega a soma de saldo_atual por operacao; nome de vendedor e de conta NAO atravessam)
-- Grao: uma ORIGEM de cadastro de apoio do Conta Azul (CENTRO_CUSTO, VENDEDOR, CATEGORIA_DRE, SERVICO, CONTA_FINANCEIRA, CATEGORIA) x operacao.
-- Le: trs_contazul__apoio (query-HhRS). Gatilho: evento em query-HhRS.
-- Identidade (19/10/2026): 906 itens = 906 · 6 origens · 12 linhas (operacao NULL na CATEGORIA_DRE vira '(sem operacao)') · 345 pais nao catalogados · saldo_atual somado R$ 701.241,79.
-- R1 Descreve o CATALOGO (quantos cadastros cada origem tem por operacao), nao o uso no razao. R2 saldo_atual (CONTA_FINANCEIRA) e o saldo
--    no momento da carga, nao historico: BRM R$ 693.945,01 e VD R$ 7.296,78 em 19/10; valor_venda (SERVICO) e zero em 29 de 29 -- sentinela, sai NULL.
-- R3 O pai da CATEGORIA resolve 8 de 353 dentro da propria origem CATEGORIA (medido 19/10): id_categoria_pai aponta para um universo que nao
--    esta nesta base; qtd_pai_nao_catalogado torna isso visivel e NADA e corrigido. CATEGORIA_DRE tem id_pai em 0 de 26.
-- R4 Operacao VGD-BRM existe so em VENDEDOR (6): e codigo de operacao que a dimensao trs_financeiro__operacao nao tem (ver rfn_financeiro__operacao_resumo).
-- LIMITACAO -- NAO CONTORNE: categorias de BRM e VD repetem nome entre operacoes (junte por id, nunca por nome); SERVICO e catalogo de outro negocio.
WITH a AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_contazul__apoio`
),
pai AS (
  SELECT c.origem, c.id_apoio, (p.id_apoio IS NOT NULL) AS pai_resolve
  FROM a c LEFT JOIN a p ON p.origem = c.origem AND p.id_apoio = c.id_pai
  WHERE c.id_pai IS NOT NULL
),
agg AS (
  SELECT
    a.origem,
    IFNULL(a.operacao, '(sem operacao)')                          AS operacao,
    COUNT(*)                                                       AS qtd_itens,
    COUNT(DISTINCT a.id_apoio)                                     AS qtd_ids_distintos,
    COUNTIF(a.nome IS NULL)                                        AS qtd_sem_nome,
    COUNT(DISTINCT a.nome)                                         AS qtd_nomes_distintos,
    COUNT(DISTINCT a.tipo)                                         AS qtd_tipos_distintos,
    COUNTIF(a.status IS NOT NULL)                                  AS qtd_com_status,
    COUNTIF(a.id_pai IS NOT NULL)                                  AS qtd_com_pai,
    COUNTIF(a.id_pai IS NOT NULL AND NOT IFNULL(p.pai_resolve, FALSE)) AS qtd_pai_nao_catalogado,
    COUNTIF(a.codigo IS NOT NULL)                                  AS qtd_com_codigo,
    COUNTIF(a.flag IS TRUE)                                        AS qtd_flag_true,
    COUNTIF(a.valor_num IS NOT NULL)                               AS qtd_com_valor,
    NULLIF(ROUND(SUM(a.valor_num), 2), 0)                          AS valor_num_total,
    MAX(a.data_ref)                                                AS data_ref_maxima
  FROM a LEFT JOIN pai p ON p.origem = a.origem AND p.id_apoio = a.id_apoio
  GROUP BY a.origem, IFNULL(a.operacao, '(sem operacao)')
),
final AS (
  SELECT CONCAT(origem, '|', operacao) AS id_apoio_resumo, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
