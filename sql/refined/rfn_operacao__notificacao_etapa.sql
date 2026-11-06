-- rfn_operacao__notificacao_etapa  ·  Refined / operacao  ·  2.283 linhas  ·  L4
-- Grao: um TIPO de notificacao, um cliente, uma etapa, um mes de envio.
-- Chave: id_notificacao_mensal = <tipo>:<mes>:<cliente>|<etapa>.
-- Origem: trs_vjob__sms_notificacao (11.068) + trs_vjob__cliente_atendimento (pista).
-- Gatilho: evento em query-UpoG. As regras numeradas, os numeros da validacao e o
-- bloco de limitacoes estao na descricao da transformacao, que e parte da entrega.
--
-- A DESCRICAO DA TRUSTED ESTAVA ERRADA: ela dizia "sao notificacoes de etapa vencida".
--   Sao DUAS familias e a de vencimento e a MENOR -- CONCLUSAO 7.920 (71,6%, viva ate
--   25/09/2026) e VENCIMENTO 3.148 (28,4%, MORTA desde 16/06/2025). O parser cobre
--   11.068 de 11.068, zero nao reconhecidas.
--
-- O ACHADO: o alerta de vencimento funcionou 25 DIAS e foi desligado -- 3.148 envios
--   para 164 situacoes, 19,2 por situacao, cobranca diaria. E nao e falta de etapa
--   vencida: a `rfn_operacao__conformidade_cliente` mede 60,8% das marcacoes depois do
--   prazo. **Parou o aviso, nao o atraso.**
--
-- R1 envio != destino (2.058 duplicados, so na CONCLUSAO) · R2 cliente e etapa sao
-- ROTULO, e o id sai so quando o nome e unico · R3 a etapa nao tem dominio nesta base
-- (conferido: tbetapas 4 linhas, tbetapas2 5, e 67 ids na etapa) · R4 `venceu_em` so
-- na familia de vencimento, nunca data inventada · R5 o mes e o do ENVIO.
--
-- FUSO: relogio local da intranet. NAO CONVERTER.
WITH bruto AS (
  SELECT
    id_sms, enviado_em, mensagem, telefone_digitos, telefone_origem,
    DATE(enviado_em)                                             AS dia,
    DATE_TRUNC(DATE(enviado_em), MONTH)                          AS mes_referencia,
    -- O parser: duas familias, e elas cobrem 11.068 de 11.068.
    CASE
      WHEN REGEXP_CONTAINS(mensagem, r'^Olá, .+\. A etapa .+ já foi finalizada\.$')
        THEN 'CONCLUSAO'
      WHEN REGEXP_CONTAINS(mensagem, r'^Venceu desde \(\d{2}/\d{2}/\d{4}\) a etapa .+ do cliente .+$')
        THEN 'VENCIMENTO'
      ELSE 'NAO_RECONHECIDO'
    END                                                          AS tipo_notificacao,
    COALESCE(
      REGEXP_EXTRACT(mensagem, r'^Olá, (.+?)\. A etapa '),
      REGEXP_EXTRACT(mensagem, r' do cliente ([^.]+)$'))         AS cliente_rotulo,
    COALESCE(
      REGEXP_EXTRACT(mensagem, r'^Olá, .+?\. A etapa (.+) já foi finalizada\.$'),
      REGEXP_EXTRACT(mensagem, r'^Venceu desde \(\d{2}/\d{2}/\d{4}\) a etapa (.+) do cliente .+$'))
                                                                 AS etapa_rotulo,
    -- R4 - so na familia de vencimento; na outra fica NULL, nunca data inventada.
    SAFE.PARSE_DATE('%d/%m/%Y',
      REGEXP_EXTRACT(mensagem, r'^Venceu desde \((\d{2}/\d{2}/\d{4})\)')) AS venceu_em,
    IFNULL(NULLIF(telefone_digitos, ''), telefone_origem)        AS destino
  FROM `vanguardamartech_trusted`.`trs_vjob__sms_notificacao`
),
-- R1 - duplicidade se mede no grao (situacao, dia), nunca no mes.
por_situacao_dia AS (
  SELECT
    tipo_notificacao, cliente_rotulo, etapa_rotulo, mes_referencia, dia, venceu_em,
    COUNT(*)                       AS envios_no_dia,
    COUNT(DISTINCT destino)        AS destinos_no_dia
  FROM bruto
  GROUP BY 1, 2, 3, 4, 5, 6
),
dup AS (
  SELECT
    tipo_notificacao, cliente_rotulo, etapa_rotulo, mes_referencia,
    SUM(envios_no_dia - destinos_no_dia)              AS qtd_envios_duplicados,
    MAX(envios_no_dia)                                AS max_envios_num_dia,
    MAX(destinos_no_dia)                              AS max_destinos_num_dia
  FROM por_situacao_dia
  GROUP BY 1, 2, 3, 4
),
-- R2 - o id da conta so sai quando o casamento por nome e UNICO. 3 rotulos casam com
--   mais de uma conta, e a R-003 proibe fundir conta por nome parecido.
conta_por_nome AS (
  SELECT
    UPPER(TRIM(nome_conta))        AS nome_upper,
    ANY_VALUE(id_atendimento)      AS id_atendimento,
    COUNT(DISTINCT id_atendimento) AS qtd_contas_com_este_nome
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
  WHERE nome_conta IS NOT NULL
  GROUP BY 1
),
agregado AS (
  SELECT
    b.tipo_notificacao,
    b.mes_referencia,
    b.cliente_rotulo,
    b.etapa_rotulo,
    COUNT(*)                                          AS qtd_envios,
    COUNT(DISTINCT b.destino)                         AS qtd_destinos_distintos,
    COUNT(DISTINCT b.dia)                             AS qtd_dias_com_envio,
    COUNT(DISTINCT b.venceu_em)                       AS qtd_vencimentos_distintos,
    MIN(b.enviado_em)                                 AS primeiro_envio_em,
    MAX(b.enviado_em)                                 AS ultimo_envio_em,
    MIN(b.venceu_em)                                  AS venceu_em_min,
    MAX(b.venceu_em)                                  AS venceu_em_max,
    COUNTIF(b.telefone_digitos IS NULL OR b.telefone_digitos = '')
                                                      AS qtd_sem_telefone,
    -- O corpo da mensagem NAO e emitido; so o comprimento. Ver a classificacao.
    MAX(LENGTH(b.mensagem))                           AS comprimento_max_mensagem
  FROM bruto b
  GROUP BY 1, 2, 3, 4
)
SELECT
  CONCAT(a.tipo_notificacao, ':', CAST(a.mes_referencia AS STRING), ':',
         a.cliente_rotulo, '|', a.etapa_rotulo)       AS id_notificacao_mensal,
  a.tipo_notificacao,
  (a.tipo_notificacao = 'NAO_RECONHECIDO')            AS flag_padrao_nao_reconhecido,
  a.mes_referencia,

  -- R2 - rotulo, nunca chave. O id e pista, e so quando o nome e unico.
  a.cliente_rotulo,
  a.etapa_rotulo,
  IF(c.qtd_contas_com_este_nome = 1, c.id_atendimento, NULL)
                                                      AS candidato_id_atendimento_por_nome,
  (c.qtd_contas_com_este_nome > 1)                    AS flag_nome_ambiguo,
  (c.nome_upper IS NULL)                              AS flag_nome_sem_correspondente,

  a.qtd_envios,
  a.qtd_destinos_distintos,
  a.qtd_dias_com_envio,
  a.qtd_vencimentos_distintos,
  -- R1 - o defeito fica visivel sem ninguem precisar refazer a conta.
  d.qtd_envios_duplicados,
  (d.qtd_envios_duplicados > 0)                       AS flag_envio_duplicado,
  d.max_envios_num_dia,
  d.max_destinos_num_dia,

  a.primeiro_envio_em,
  a.ultimo_envio_em,
  a.venceu_em_min,
  a.venceu_em_max,
  IF(a.venceu_em_min IS NULL, NULL,
     DATE_DIFF(DATE(a.ultimo_envio_em), a.venceu_em_min, DAY))
                                                      AS dias_ate_a_ultima_cobranca,

  a.qtd_sem_telefone,
  a.comprimento_max_mensagem,

  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  'mysql-yIOn'                                        AS _fonte,
  'America/Sao_Paulo'                                 AS _fuso
FROM agregado a
LEFT JOIN dup d
  ON  d.tipo_notificacao = a.tipo_notificacao
  AND d.cliente_rotulo   = a.cliente_rotulo
  AND d.etapa_rotulo     = a.etapa_rotulo
  AND d.mes_referencia   = a.mes_referencia
LEFT JOIN conta_por_nome c
  ON c.nome_upper = UPPER(TRIM(a.cliente_rotulo))
