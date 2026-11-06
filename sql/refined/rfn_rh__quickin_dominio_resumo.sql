-- rfn_rh__quickin_dominio_resumo  ·  Refined / rh (recrutamento, Quickin)  ·  L2 INTERNAL
-- Grao: um dominio do Quickin (ETAPA_FUNIL, CANAL_ORIGEM, AVALIADOR, DEPARTAMENTO, TIPO_CONTRATO, EMPRESA).
-- Le: trs_quickin__dominio (query-A4uG; L4 so pelo dominio AVALIADOR). Gatilho: evento em query-A4uG. Cadencia diaria.
-- Identidade (19/10/2026, contra a Trusted materializada): 72 itens = 72 · 6 linhas, 6 chaves · ETAPA_FUNIL 10 (9 ativas, 1 inativa,
--   7 tipos) · CANAL_ORIGEM 15 · AVALIADOR 27 (27 com e-mail) · DEPARTAMENTO 15 · TIPO_CONTRATO 4 · EMPRESA 1.
-- R1 O nome e o e-mail do AVALIADOR NAO atravessam: sai so qtd_com_email. Nome de item nao atravessa em dominio nenhum.
-- R2 Descreve o CATALOGO, nao o uso: quantas etapas/canais/departamentos existem, nao quantas aplicacoes passam por cada um
--    (o uso das etapas esta em rfn_rh__funil_mensal).
-- R3 estado so existe em ETAPA_FUNIL (ATIVA/INATIVA); nos demais e ausencia (qtd_sem_estado), nao "inativo".
-- LIMITACAO -- NAO CONTORNE: nao ha cadastro de motivo de desqualificacao nem de cancelamento de vaga nesta base.
WITH d AS (SELECT * FROM `vanguardamartech_trusted`.`trs_quickin__dominio`),
agg AS (
  SELECT
    dominio,
    COUNT(*) AS qtd_itens,
    COUNT(DISTINCT id_origem) AS qtd_ids_distintos,
    COUNTIF(nome IS NULL) AS qtd_sem_nome,
    COUNTIF(tipo IS NOT NULL) AS qtd_com_tipo,
    COUNT(DISTINCT tipo) AS qtd_tipos_distintos,
    COUNTIF(estado = 'ATIVA') AS qtd_ativas,
    COUNTIF(estado = 'INATIVA') AS qtd_inativas,
    COUNTIF(estado IS NULL) AS qtd_sem_estado,
    COUNTIF(email IS NOT NULL) AS qtd_com_email,
    COUNTIF(criado_em IS NOT NULL) AS qtd_com_data_criacao,
    MIN(criado_em) AS primeiro_criado_em,
    MAX(criado_em) AS ultimo_criado_em
  FROM d
  GROUP BY 1
),
final AS (
  SELECT dominio AS id_dominio, a.*, 'L2_INTERNAL' AS classificacao_dado FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
