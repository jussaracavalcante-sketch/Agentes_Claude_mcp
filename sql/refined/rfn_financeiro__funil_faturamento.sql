-- rfn_financeiro__funil_faturamento
-- Refined / financeiro. Grao: operacao x mes de competencia x estagio do funil. Le trs_contazul__funil_faturamento.
-- Nivel: L3 CONFIDENTIAL (valor agregado por operacao e estagio; nenhum cliente, e-mail ou telefone atravessa).
-- REGRA 1: `estagio` e o da origem (recebida, faturada, enviada, nf, gerado) e nao se recalcula nem se ordena aqui.
-- REGRA 2: valor e valor_nao_pago somam sobre a parcela; `qtd_vencidas_com_saldo` compara o vencimento com a DATA DA CARGA
--          (DATE(_extraido_at)), nunca com o relogio de quem le.
-- REGRA 3: contagens de is_* sao independentes (uma parcela pode ser faturada e enviada); nao somar entre elas.
-- LIMITACOES - NAO CONTORNE: nao define 'por faturar' (a origem nao diz qual estagio e anterior a faturar); 278 de 2.087 parcelas
--   sem pessoa; nao soma com trs_contazul__movimento (mesmo dinheiro); so BRM e VD.
WITH f AS (
  SELECT *, IFNULL(estagio, '(sem estagio)') AS estagio_nome FROM vanguardamartech_trusted.trs_contazul__funil_faturamento
)
SELECT
  CONCAT(operacao, '|', IFNULL(CAST(mes_competencia AS STRING), 'sem_mes'), '|', estagio_nome) AS id_funil_mensal,
  operacao,
  mes_competencia,
  estagio_nome                                           AS estagio,
  COUNT(*)                                               AS qtd_parcelas,
  SUM(valor)                                             AS valor,
  SUM(valor_nao_pago)                                    AS valor_nao_pago,
  COUNTIF(is_faturado)                                   AS qtd_faturadas,
  COUNTIF(is_enviada)                                    AS qtd_enviadas,
  COUNTIF(is_nf_emitida)                                 AS qtd_nf_emitida,
  COUNTIF(is_pago)                                       AS qtd_pagas,
  COUNTIF(valor_nao_pago > 0)                            AS qtd_com_saldo,
  COUNTIF(valor_nao_pago > 0 AND data_vencimento < DATE(_extraido_at)) AS qtd_vencidas_com_saldo,
  SUM(IF(valor_nao_pago > 0 AND data_vencimento < DATE(_extraido_at), valor_nao_pago, 0)) AS valor_vencido_com_saldo,
  COUNTIF(is_recorrente)                                 AS qtd_recorrentes,
  COUNTIF(is_migrado)                                    AS qtd_migradas,
  COUNTIF(flag_sem_pessoa)                               AS qtd_sem_pessoa,
  COUNTIF(tem_cobranca_url)                              AS qtd_com_cobranca_url,
  'L3_CONFIDENTIAL'                                      AS classificacao_dado,
  CURRENT_TIMESTAMP()                                    AS _extraido_at,
  'supabase-x0tz'                                        AS _fonte
FROM f
GROUP BY operacao, mes_competencia, estagio_nome
