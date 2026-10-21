-- rfn_financeiro__dre_ca_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL
-- Grao: operacao x mes de competencia x tipo (RECEITA/DESPESA) x balde (CLASSIFICADA / NAO_CLASSIFICADA_NO_DRE / SEM_CLASSIFICACAO). Le: trs_financeiro__dre_categoria_mes (query-5bfz).
-- Gatilho: evento em query-5bfz. Cadencia herdada: semanal (segunda 06:35 America/Manaus).
-- VALIDACAO (2026-10-19): 275 linhas, 275 chaves; 353 linhas de DRE, resultado R$ 732.951,25, bruto R$ 32.121.761,33 e 5.157 parcelas (= Trusted); 265 linhas de DRE em mes posterior a carga; resultado do balde CLASSIFICADA R$ 7.119.226,61.
-- REGRA 1 - AGREGA, NAO FILTRA: soma das linhas = Trusted (353 linhas de DRE, resultado R$ 732.951,25, bruto R$ 32.121.761,33, 5.157 parcelas em 19/10/2026).
-- REGRA 2 - O RESULTADO SO E OPERACIONAL NO BALDE CLASSIFICADA. As ordens 90 e 91 (receita e despesa NAO classificadas no DRE) e a linha sem classificacao ficam em baldes
--   proprios e nunca se misturam com as ordens 1 a 7; `resultado_classificado` de uma leitura e a soma so do balde CLASSIFICADA.
-- REGRA 3 - SINAL: `resultado` e +bruto em RECEITA e -bruto em DESPESA (medido, zero excecoes); somar `resultado` da o resultado, somar `valor_bruto` da o volume.
-- REGRA 4 - `is_mes_posterior_a_carga` compara o mes com o mes da CARGA da Trusted (DATE de _extraido_at), nunca com o relogio: 265 das 353 linhas de DRE sao meses futuros
--   (parcelas futuras do razao, ate 2033-07) e nao sao resultado realizado.
-- LIMITACOES - NAO CONTORNE: competencia, nao caixa; comeca em 2026-06 (handoff iClips -> Conta Azul), nao soma com rfn_financeiro__dre_gerencial_mensal (iClips); a divergencia contra o
--   "3.073 do fechamento" esta explicada na Trusted (5.157 = parcelas vigentes de trs_contazul__movimento com competencia >= 2026-06).
WITH t AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__dre_categoria_mes`
),
g AS (
  SELECT
    operacao,
    mes_referencia,
    tipo_categoria,
    CASE WHEN flag_linha_sem_classificacao THEN 'SEM_CLASSIFICACAO'
         WHEN flag_nao_classificada_no_dre THEN 'NAO_CLASSIFICADA_NO_DRE'
         ELSE 'CLASSIFICADA' END                              AS balde_dre,
    COUNT(*)                                                  AS qtd_linhas_dre,
    ROUND(SUM(resultado), 2)                                  AS resultado,
    ROUND(SUM(valor_bruto), 2)                                AS valor_bruto,
    SUM(qtd_parcelas)                                         AS qtd_parcelas,
    MAX(DATE(_extraido_at, 'America/Sao_Paulo'))              AS data_carga_trusted
  FROM t
  GROUP BY operacao, mes_referencia, tipo_categoria, balde_dre
),
final AS (
  SELECT
    CONCAT(operacao, '|', CAST(mes_referencia AS STRING), '|', IFNULL(tipo_categoria, '~'), '|', balde_dre) AS id_dre_ca_mensal,
    g.*,
    (mes_referencia > DATE_TRUNC(data_carga_trusted, MONTH))  AS is_mes_posterior_a_carga,
    'L3_CONFIDENTIAL'                                         AS classificacao_dado
  FROM g
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
