-- rfn_fiscal__simples_vbot_mensal  ·  query-hJmB  ·  Refined  ·  gatilho: evento all nas seis Trusted fiscais  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Refined / fiscal. Grao: um PERIODO (mes) da SIMULACAO do Simples Nacional da VBOT, com as seis Trusted fiscais lado a lado: a simulacao do mes, a soma da
-- simulacao por cliente, a faixa do Anexo III, a receita declarada transcrita, a defasagem de nota fiscal e as excecoes de NF agregadas.
-- Le: trs_fiscal__simples_vbot_mes (18), trs_fiscal__simples_vbot_cliente_mes (619), trs_fiscal__simples_anexo3_faixa (6), trs_fiscal__simples_receita_declarada (13),
-- trs_fiscal__simples_vbot_nf_mes (12), trs_fiscal__simples_vbot_nf_excecao (260). Gatilho: evento "all" nas seis. Nivel: L3 CONFIDENTIAL (fiscal da casa;
-- nenhum cliente nem cobranca atravessa, so contagem e soma).
--
-- ISTO E SIMULACAO, NAO APURACAO. NAO APRESENTAR COMO TRIBUTO DEVIDO. A tabela de faixas esta NAO CONFERIDA em 5 das 6 faixas (is_faixa_conferida so na
-- faixa 4, apuracao 06/2026). O unico dado declarado e receita_declarada (13 periodos); o unico pago e das_pago (9 periodos, informado a mao).
--
-- REGRA 1 DOIS METODOS DE DAS, DECLARADOS LADO A LADO E NUNCA SOMADOS: das_simulado_conexa (do mes) aplica a suspensao de PIS/COFINS da Zona Franca a
--   RECEITA INTEIRA; das_simulado_soma_clientes aplica a suspensao so aos clientes ZFM (81 de 110). Por isso a soma dos clientes e MAIOR em 11 de 12
--   periodos (dif_das_mes_menos_clientes negativa, de -R$ 52,01 (2025-12) a -R$ 1.051,32 (2026-07) nos 11 periodos com diferenca; 2026-11 fecha em zero (3 linhas, so ha clientes ZFM)). E diferenca de metodo da origem.
-- REGRA 2 IDENTIDADES MEDIDAS EM 2026-10-19: receita_conexa_clientes = receita_conexa do mes nos 12 periodos com clientes (zero divergencias);
--   receita_declarada_rpa = receita_declarada do mes nos 13 periodos transcritos; qtd_pago_sem_nf_excecao = qtd_pago_sem_nf e valor_pago_sem_nf_excecao =
--   valor_pago_sem_nf em 11 de 11 periodos a partir de 2026-01 (2025-12 tem 5 pagos sem NF na defasagem e nenhuma excecao listada).
-- REGRA 3 BACKLOG: backlog_a_emitir_origem INCLUI cobranca cancelada (bate com qtd_backlog_origem = todas as 'ABERTO SEM NF', 8 de 8). valor_backlog_vigente
--   e qtd_backlog_vigente excluem cancelada (86 cobrancas, R$ 95.985,78 no total); valor_backlog_cancelado mostra o que a origem contou a mais (R$ 18.213,86).
-- REGRA 4 Zero que e ausencia sai NULL: das_simulado_conexa, dif_* e as agregacoes de cliente e excecao sao NULL quando o periodo nao tem a origem
--   (2025-06 a 2025-11 nao tem Conexa; 2026-07 em diante nao tem declaracao; 2025-12 nao tem excecao listada).
-- LIMITACAO - NAO CONTORNE: receita_conexa aqui e receita bruta de assinatura e servico do Conexa (operacao VBOT), nao a receita contabil; nao soma com
--   rfn_financeiro__receita_vbot_mensal nem com rfn_financeiro__fluxo_caixa; 2026-11 e periodo futuro parcial; o DAS pago cobre 2025-12 a 2026-08.
WITH m AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_mes`
),
cli AS (
  SELECT periodo,
         COUNT(*)                                             AS qtd_clientes,
         COUNTIF(is_zfm)                                      AS qtd_clientes_zfm,
         COUNTIF(flag_margem_negativa)                        AS qtd_clientes_margem_negativa,
         ROUND(SUM(receita_conexa), 2)                        AS receita_conexa_clientes,
         ROUND(SUM(margem_liquida), 2)                        AS margem_liquida_clientes,
         ROUND(SUM(simples_simulado), 2)                      AS das_simulado_soma_clientes,
         ROUND(SUM(IF(is_zfm, simples_simulado, 0)), 2)       AS das_simulado_clientes_zfm,
         ROUND(SUM(IF(NOT is_zfm, simples_simulado, 0)), 2)   AS das_simulado_clientes_nao_zfm,
         ROUND(SUM(margem_pos_tributo), 2)                    AS margem_pos_tributo_clientes
  FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_cliente_mes`
  GROUP BY periodo
),
a3 AS (
  SELECT faixa, aliquota_nominal_pct, parcela_deduzir, rbt12_ate, is_conferida_na_apuracao
  FROM `vanguardamartech_trusted`.`trs_fiscal__simples_anexo3_faixa`
),
rpa AS (
  SELECT periodo, receita_declarada AS receita_declarada_rpa, receita_iss_retido AS receita_iss_retido_rpa, fonte_documento
  FROM `vanguardamartech_trusted`.`trs_fiscal__simples_receita_declarada`
),
nf AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_nf_mes`
),
exc AS (
  SELECT periodo,
         COUNT(*)                                             AS qtd_excecoes,
         COUNTIF(tipo_excecao = 'PAGO_SEM_NF')                AS qtd_pago_sem_nf_excecao,
         ROUND(SUM(IF(tipo_excecao = 'PAGO_SEM_NF', valor, 0)), 2) AS valor_pago_sem_nf_excecao,
         COUNTIF(is_backlog_vigente)                          AS qtd_backlog_vigente,
         ROUND(SUM(IF(is_backlog_vigente, valor, 0)), 2)      AS valor_backlog_vigente,
         COUNTIF(tipo_excecao = 'ABERTO_SEM_NF' AND is_cancelada) AS qtd_backlog_cancelado,
         ROUND(SUM(IF(tipo_excecao = 'ABERTO_SEM_NF' AND is_cancelada, valor, 0)), 2) AS valor_backlog_cancelado
  FROM `vanguardamartech_trusted`.`trs_fiscal__simples_vbot_nf_excecao`
  GROUP BY periodo
),
final AS (
  SELECT
    m.periodo                                                     AS id_periodo,
    m.periodo,
    m.mes_referencia,
    'SIMULACAO_NAO_CONFERIDA'                                     AS natureza,
    m.fonte_rbt12,
    m.is_sem_declaracao,
    m.meses_janela,
    m.is_janela_completa,
    m.rbt12,
    m.is_rbt12_proporcionalizado,
    m.faixa_anexo3,
    a3.aliquota_nominal_pct,
    a3.parcela_deduzir,
    a3.rbt12_ate                                                  AS faixa_rbt12_ate,
    a3.is_conferida_na_apuracao                                   AS is_faixa_conferida,
    m.aliquota_efetiva_pct,
    m.aliq_pis_cofins_pct,
    m.aliq_sem_pis_cofins_pct,
    m.aliq_iss_pct,
    m.receita_declarada,
    m.receita_iss_retido,
    rpa.receita_declarada_rpa,
    (rpa.periodo IS NOT NULL)                                     AS flag_declaracao_transcrita,
    rpa.fonte_documento                                           AS fonte_documento_declaracao,
    m.receita_conexa,
    cli.receita_conexa_clientes,
    cli.qtd_clientes,
    cli.qtd_clientes_zfm,
    cli.qtd_clientes_margem_negativa,
    cli.margem_liquida_clientes,
    m.das_simulado_declarada,
    m.das_simulado_conexa,
    cli.das_simulado_soma_clientes,
    cli.das_simulado_clientes_zfm,
    cli.das_simulado_clientes_nao_zfm,
    IF(m.das_simulado_conexa IS NULL OR cli.das_simulado_soma_clientes IS NULL, NULL,
       ROUND(m.das_simulado_conexa - cli.das_simulado_soma_clientes, 2))  AS dif_das_mes_menos_clientes,
    cli.margem_pos_tributo_clientes,
    m.pis_cofins_suspenso,
    m.das_pago,
    m.das_pago_em,
    m.flag_das_pago_informado,
    m.dif_pago_simulado,
    m.dif_receita_conexa_declarada,
    nf.regime_nf,
    nf.is_regime_competencia,
    nf.is_comparavel                                              AS is_nf_comparavel,
    nf.is_aguardando_apuracao,
    nf.valor_com_nf,
    nf.backlog_a_emitir_origem,
    nf.qtd_backlog_origem,
    nf.valor_pago_sem_nf,
    nf.qtd_pago_sem_nf,
    nf.qtd_pago,
    nf.qtd_pago_com_nf,
    nf.pct_pago_com_nf,
    exc.qtd_excecoes,
    exc.qtd_pago_sem_nf_excecao,
    exc.valor_pago_sem_nf_excecao,
    exc.qtd_backlog_vigente,
    exc.valor_backlog_vigente,
    exc.qtd_backlog_cancelado,
    exc.valor_backlog_cancelado,
    'L3_CONFIDENTIAL'                                             AS classificacao_dado
  FROM m
  LEFT JOIN cli ON cli.periodo = m.periodo
  LEFT JOIN a3  ON a3.faixa = m.faixa_anexo3
  LEFT JOIN rpa ON rpa.periodo = m.periodo
  LEFT JOIN nf  ON nf.periodo = m.periodo
  LEFT JOIN exc ON exc.periodo = m.periodo
)
SELECT x.*,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte,
  'America/Sao_Paulo'                                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(x)))                                  AS _payload_hash
FROM final x
