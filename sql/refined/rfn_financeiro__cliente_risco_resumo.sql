-- rfn_financeiro__cliente_risco_resumo  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (classificacao de inadimplencia por GRUPO devedor; documento, razao social e observacao NAO atravessam)
-- Grao: classificacao x grupo da lista curada de risco de recebimento, com o movimento financeiro das contrapartes somado.
-- Le: trs_financeiro__cliente_risco (query-ZNA3) + trs_financeiro__movimento (por contraparte_documento). Gatilho: evento em query-ZNA3.
-- Identidade (19/10/2026): 14 clientes = 14 · 3 linhas · recuperacao_especial 5 (WD/CIESA 1, GRUPO KING 4; 5 encerrados, 5 com expectativa) · pagador_cronico 9 (score de 2026-06-09 em 9 de 9)
--    · movimento financeiro das 14 contrapartes: 686 lancamentos, R$ 2.252.646,51 (abs), R$ 1.818.306,37 realizados, ultima competencia 2026-12.
-- R1 E CLASSIFICACAO HUMANA, nao medida: o score (media de dias de atraso 11,2; 81,9% de atraso em 6 meses; 102 titulos pagos) vale na data score_atualizado_em e nao e recalculado.
--    media_dias_atraso e pct_atraso saem como MEDIA dos clientes do grupo e so onde existem (NULL para recuperacao_especial, nunca zero).
-- R2 O movimento financeiro entra por documento (14 de 14 existem como contraparte em trs_financeiro__movimento): qtd_lancamentos, valor_abs e valor_realizado sao de TODO o historico,
--    nao da janela de 6 meses do score -- as duas medidas respondem perguntas diferentes.
-- R3 Nenhum CPF: is_pf = 0 em 14 de 14; mesmo assim documento nao atravessa, porque o grao e o grupo e a Refined nao precisa dele.
-- LIMITACAO -- NAO CONTORNE: lista curta e curada, NAO e a carteira inadimplente -- inadimplencia mede-se por titulo em rfn_financeiro__fluxo_caixa (BRM e VD) e
--    rfn_financeiro__inadimplencia_vbot (VBOT). Ausencia aqui nao e bom pagador. grupo 'PAGADOR CRONICO' e rotulo, nao grupo economico.
WITH r AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__cliente_risco`
),
mv AS (
  SELECT contraparte_documento AS documento, COUNT(*) AS qtd_lancamentos, SUM(valor_abs) AS valor_abs,
         SUM(IF(is_realizado, valor_abs, 0)) AS valor_realizado, MAX(mes_competencia) AS ultima_competencia
  FROM `vanguardamartech_trusted`.`trs_financeiro__movimento`
  WHERE contraparte_documento IS NOT NULL
  GROUP BY 1
),
j AS (
  SELECT r.*, (mv.documento IS NOT NULL) AS tem_mov, IFNULL(mv.qtd_lancamentos, 0) AS ql, IFNULL(mv.valor_abs, 0) AS va, IFNULL(mv.valor_realizado, 0) AS vr, mv.ultima_competencia
  FROM r LEFT JOIN mv ON mv.documento = r.documento
),
agg AS (
  SELECT
    classificacao,
    IFNULL(grupo, '(sem grupo)')               AS grupo,
    COUNT(*)                                   AS qtd_clientes,
    COUNTIF(is_pf)                             AS qtd_pf,
    COUNTIF(is_contrato_encerrado)             AS qtd_contrato_encerrado,
    COUNTIF(tem_expectativa_recuperacao)       AS qtd_com_expectativa_recuperacao,
    COUNTIF(is_pagador_cronico)                AS qtd_pagador_cronico,
    COUNTIF(flag_cronico_sem_score)            AS qtd_cronico_sem_score,
    ROUND(AVG(media_dias_atraso_6m), 1)        AS media_dias_atraso_6m,
    ROUND(AVG(pct_atraso_6m), 2)               AS pct_atraso_6m_medio,
    SUM(titulos_pagos_6m)                      AS titulos_pagos_6m,
    MIN(score_atualizado_em)                   AS score_mais_antigo,
    MAX(score_atualizado_em)                   AS score_mais_recente,
    COUNTIF(tem_mov)                           AS qtd_com_movimento_financeiro,
    SUM(ql)                                    AS qtd_lancamentos,
    ROUND(SUM(va), 2)                          AS valor_abs,
    ROUND(SUM(vr), 2)                          AS valor_realizado,
    MAX(ultima_competencia)                    AS ultima_competencia,
    MIN(cadastrado_em)                         AS cadastrado_em
  FROM j
  GROUP BY classificacao, IFNULL(grupo, '(sem grupo)')
),
final AS (
  SELECT CONCAT(classificacao, '|', grupo) AS id_cliente_risco_resumo, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
