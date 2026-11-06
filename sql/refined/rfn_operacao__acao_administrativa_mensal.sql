-- rfn_operacao__acao_administrativa_mensal (query-zch1)
-- Refined / OPERACAO. Grao: mes, tipo de alvo, tabela de alvo. Origem: trs_vjob__acao_administrativa.
-- Regras numeradas, limitacoes e medicao: na descricao da transformacao na Nekt.
WITH base AS (
  SELECT *, DATE_TRUNC(DATE(ocorrido_em), MONTH) AS mes_referencia,
    IFNULL(tabela_alvo, '(nao se aplica)')       AS tabela_alvo_rotulo
  FROM `vanguardamartech_trusted`.`trs_vjob__acao_administrativa`
)
SELECT
  CONCAT(FORMAT_DATE('%Y-%m', mes_referencia), '|', alvo_tipo, '|', tabela_alvo_rotulo)  AS id_acao_mensal,
  mes_referencia,
  alvo_tipo,
  tabela_alvo_rotulo                                                            AS tabela_alvo,
  COUNT(*)                                                                      AS qtd_acoes,
  COUNTIF(verbo_canonico = 'ATIVOU')                                            AS qtd_ativou,
  COUNTIF(verbo_canonico = 'DESATIVOU')                                         AS qtd_desativou,
  COUNTIF(verbo_canonico = 'DELETOU')                                           AS qtd_deletou,
  COUNTIF(verbo_canonico = 'ATIVOU') - COUNTIF(verbo_canonico = 'DESATIVOU')    AS saldo_ativacoes,
  COUNT(DISTINCT id_usuario)                                                    AS qtd_autores_distintos,
  COUNT(DISTINCT COALESCE(CAST(id_atendimento AS STRING), CAST(id_cliente_juridico AS STRING), CAST(id_gestor_alvo AS STRING), CAST(id_registro_alvo AS STRING))) AS qtd_alvos_distintos,
  COUNTIF(flag_autor_nao_catalogado)                                            AS qtd_autor_nao_catalogado,
  COUNTIF(flag_padrao_nao_reconhecido)                                          AS qtd_padrao_nao_reconhecido,
  CURRENT_TIMESTAMP()                                                           AS _extraido_at,
  MAX(_extraido_at)                                                             AS _extraido_trusted
FROM base
GROUP BY mes_referencia, alvo_tipo, tabela_alvo_rotulo
