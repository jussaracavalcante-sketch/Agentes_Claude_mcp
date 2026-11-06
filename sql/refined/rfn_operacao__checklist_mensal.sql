-- rfn_operacao__checklist_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um mes do dia PREVISTO (dt_previsto) e uma atividade do checklist de implantacao.
-- Le: trs_vjob__checklist_diario (2.748). Gatilho: evento em query-OFX4 (a propria Trusted).
--
-- AGREGA, NAO FILTRA: toda linha da Trusted cai em um grupo. Identidade medida em 07/10/2026:
-- 2.748 itens · 2.715 marcados · 33 com carimbo e status zero · 2.667 marcados no dia previsto ·
-- 48 depois · zero antes (2.667 + 48 = 2.715).
--
-- O QUE ESTE INSTRUMENTO E: checklist de IMPLANTACAO de conta nova (agendar treinamento, mensagens
-- pre-setup, criar conta, vincular canal de WhatsApp, classificacoes de atendimento) — 8 atividades
-- de uma unica fase, 46 contas. NAO e indicador de operacao da agencia.
--
-- R1  taxa_marcacao = marcados / itens, e e NULL no mes em que NENHUM item foi marcado
--     (flag_mes_sem_marcacao: 2025-04, 2025-11 e 2026-02; 5 linhas). Zero de conclusao em mes sem registro
--     nao e zero medido — e ausencia de uso; zero seria somado, NULL obriga a decidir.
-- R2  taxa_pontualidade = marcados no dia previsto / marcados. O denominador e o MARCADO, nunca o
--     previsto; NULL sem marcado.
-- R3  Marcado = status 1. As 33 linhas com carimbo e status zero (marcado e desmarcado) NAO contam
--     como marcadas e ficam em qtd_desmarcados.
-- R4  Dia da marcacao e DATE(marcado_em) SEM argumento de fuso: o VJOB grava hora local, e converter
--     de novo subtrairia 3 horas.
-- R5  O mes e o do dia PREVISTO, nunca o da marcacao.
-- R6  Conta nao catalogada (5 itens) segue contada; qtd_itens_conta_nao_catalogada torna o caso visivel.
--
-- LIMITES: MODULO PARADO — janela 30/04/2025 a 04/02/2026, 88,7% do volume em 2025-05 e 2025-06 · fase
-- constante (nao e dimensao) · 8 das 34 atividades do catalogo usadas · taxa de marcacao saturada
-- (98,8%) e por isso nao discrimina nada; pontualidade tambem (98,2% no dia, e as 48 tardias tem
-- exatamente 1 dia de atraso, maximo 1) · nao ha responsavel por atividade aqui.
WITH c AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__checklist_diario`
),
agg AS (
  SELECT
    DATE_TRUNC(dt_previsto, MONTH) AS mes_referencia,
    id_atividade,
    COALESCE(nome_atividade, '(atividade nao catalogada)') AS nome_atividade,
    ANY_VALUE(fase) AS fase,
    COUNT(*) AS qtd_itens,
    COUNTIF(is_marcado) AS qtd_marcados,
    COUNTIF(flag_carimbo_sem_status) AS qtd_desmarcados,
    COUNTIF(is_marcado AND DATE(marcado_em) = dt_previsto) AS qtd_marcados_no_dia,
    COUNTIF(is_marcado AND DATE(marcado_em) > dt_previsto) AS qtd_marcados_depois,
    COUNTIF(is_marcado AND DATE(marcado_em) < dt_previsto) AS qtd_marcados_antes,
    ROUND(AVG(IF(is_marcado AND DATE(marcado_em) > dt_previsto, DATE_DIFF(DATE(marcado_em), dt_previsto, DAY), NULL)), 2) AS atraso_medio_dias,
    MAX(IF(is_marcado, DATE_DIFF(DATE(marcado_em), dt_previsto, DAY), NULL)) AS atraso_maximo_dias,
    COUNT(DISTINCT id_atendimento) AS qtd_contas,
    COUNT(DISTINCT IF(is_marcado, marcado_por, NULL)) AS qtd_pessoas_que_marcaram,
    COUNTIF(flag_conta_nao_catalogada) AS qtd_itens_conta_nao_catalogada,
    MIN(dt_previsto) AS primeiro_dia_previsto,
    MAX(dt_previsto) AS ultimo_dia_previsto
  FROM c
  GROUP BY 1, 2, 3
),
mes AS (
  SELECT
    a.*,
    SUM(qtd_marcados) OVER (PARTITION BY mes_referencia) AS marcados_no_mes
  FROM agg a
),
final AS (
  SELECT
    CONCAT(CAST(mes_referencia AS STRING), '|', CAST(id_atividade AS STRING)) AS id_checklist_mensal,
    mes_referencia, id_atividade, nome_atividade, fase,
    qtd_itens, qtd_marcados, qtd_desmarcados,
    qtd_marcados_no_dia, qtd_marcados_depois, qtd_marcados_antes,
    atraso_medio_dias, atraso_maximo_dias,
    IF(marcados_no_mes = 0, NULL, ROUND(SAFE_DIVIDE(qtd_marcados, qtd_itens), 4)) AS taxa_marcacao,
    IF(qtd_marcados = 0, NULL, ROUND(SAFE_DIVIDE(qtd_marcados_no_dia, qtd_marcados), 4)) AS taxa_pontualidade,
    qtd_contas, qtd_pessoas_que_marcaram, qtd_itens_conta_nao_catalogada,
    primeiro_dia_previsto, ultimo_dia_previsto,
    (marcados_no_mes = 0) AS flag_mes_sem_marcacao,
    'L2_INTERNAL' AS classificacao_dado
  FROM mes
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
