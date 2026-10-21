-- rfn_financeiro__preco_wl_resumo  ·  query-nuwZ  ·  Refined  ·  gatilho: evento em query-pOn6  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Refined / financeiro. Grao: um COMPONENTE da tabela de preco do white-label (usuario, canal, infra, app_transcricao, app_asaas, app_ia, ambiente,
-- ambiente_automacao, zapi). Le: trs_vbot__preco_wl (16). Gatilho: evento em query-pOn6. Nivel: L3 CONFIDENTIAL (preco do parceiro).
-- Identidade (2026-10-19): 16 faixas = 16 · 9 componentes · 3 faixas de cortesia · 4 faixas abertas.
-- R1 Agrega o catalogo, nao usa: nao ha contagem de quem paga cada faixa (isso esta em trs_vbot__uso_wl_conta_mes, por faixa de usuario e canal).
-- R2 valor_min_cobrado exclui a cortesia (valor 0); valor_max_cobrado e o maior preco unitario. Nao somar valores entre componentes (unidades diferentes).
-- R3 limite_cortesia e a quantidade gratuita (faixa 0): 3 usuarios, 1 canal, 5.000 atendimentos; NULL nos componentes sem cortesia.
-- LIMITACAO - NAO CONTORNE: uma unica vigencia (2026-01-01); nao ha preco anterior nem posterior.
WITH p AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vbot__preco_wl`
),
final AS (
  SELECT
    componente                                                    AS id_componente,
    componente,
    COUNT(*)                                                      AS qtd_faixas,
    COUNTIF(flag_cortesia)                                        AS qtd_faixas_cortesia,
    COUNTIF(flag_faixa_aberta)                                    AS qtd_faixas_abertas,
    MAX(IF(faixa = 0, limite_quantidade_na_faixa, NULL))          AS limite_cortesia,
    MIN(IF(valor_unitario > 0, valor_unitario, NULL))             AS valor_min_cobrado,
    MAX(valor_unitario)                                           AS valor_max_cobrado,
    MIN(vigente_desde)                                            AS vigente_desde,
    MAX(atualizado_em_local)                                      AS ultima_atualizacao_local,
    STRING_AGG(CONCAT(CAST(faixa AS STRING), ': ', IFNULL(descricao, '(sem descricao)'), ' = ', CAST(valor_unitario AS STRING)), ' | ' ORDER BY faixa) AS faixas_descritas,
    'L3_CONFIDENTIAL'                                             AS classificacao_dado
  FROM p
  GROUP BY componente
)
SELECT x.*,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte,
  'America/Sao_Paulo'                                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(x)))                                  AS _payload_hash
FROM final x
