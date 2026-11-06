-- rfn_financeiro__extrato_sweep_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (movimento entre contas proprias por empresa e mes)
-- Grao: empresa (BRM | VD) x MES do sweep x status do casamento (CASOU | FORA_COBERTURA_DESTINO).
-- Le: trs_financeiro__extrato_sweep (query-NODC). Gatilho: evento em query-NODC.
-- Identidade (19/10/2026): 84 sweeps = 84 · R$ 1.978.275,23 · 54 CASOU + 30 FORA_COBERTURA_DESTINO · 2 contas IP (ca_ip_brm, ca_ip_vd) · 4 destinos · 2026-01-02 a 2026-08-06.
-- R1 SWEEP E MOVIMENTO ENTRE CONTAS PROPRIAS (da conta IP do Conta Azul para a operacional): nao e receita nem despesa e nao entra em resultado.
-- R2 FORA_COBERTURA_DESTINO nao e divergencia: e ausencia de prova (o extrato da conta de destino nao cobre a data). Por isso o status esta no grao e nao vira taxa de erro:
--    2026-07 BRM tem 36 sweeps e 16 casaram; 2026-08 nenhum casou nos dois lados -- o extrato de agosto ainda nao tinha chegado quando o casamento foi feito.
-- R3 O casamento foi feito no Supabase (gold_vw_eb_sweep_match) e nao se reproduz aqui; a tabela descreve o resultado dele.
-- R4 2026-01 tem 5 sweeps de BRM e depois so 2026-06 em diante (virada do ERP): fevereiro a maio e ausencia de dado, nao ausencia de sweep -- nao interpolar.
-- LIMITACAO -- NAO CONTORNE: nao soma com rfn_financeiro__contazul_transferencia_mensal (outro registro do mesmo tipo de movimento) nem com o extrato (o sweep ja esta dentro dos lancamentos).
WITH s AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__extrato_sweep`
),
agg AS (
  SELECT
    empresa,
    DATE_TRUNC(DATE(data_sweep), MONTH)        AS mes_sweep,
    status_casamento,
    COUNT(*)                                   AS qtd_sweeps,
    ROUND(SUM(valor), 2)                       AS valor_sweep,
    ROUND(MAX(valor), 2)                       AS maior_sweep,
    COUNT(DISTINCT conta_ip)                   AS qtd_contas_ip,
    COUNT(DISTINCT destino)                    AS qtd_destinos,
    COUNT(DISTINCT casou_conta)                AS qtd_contas_casadas,
    COUNT(DISTINCT DATE(data_sweep))           AS qtd_dias_com_sweep,
    MIN(DATE(data_sweep))                      AS primeiro_sweep,
    MAX(DATE(data_sweep))                      AS ultimo_sweep
  FROM s
  GROUP BY empresa, DATE_TRUNC(DATE(data_sweep), MONTH), status_casamento
),
final AS (
  SELECT CONCAT(empresa, '|', CAST(mes_sweep AS STRING), '|', status_casamento) AS id_sweep_mensal, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
