-- rfn_operacao__job
-- Refined / dominio Operacao. Grao: um job, chave (origem, id_job).
-- Le trs_vjob__job e trs_vjob__usuario.
--
-- CORRIGIDO EM 2026-09-23 -- DOIS ERROS DE FUSO QUE SE CANCELAVAM.
--   Esta query fazia `DATE(data_cadastro, 'America/Sao_Paulo')`, que SUBTRAI 3 horas
--   de um relogio que ja e local. Ate hoje o resultado saia certo POR ACIDENTE: a
--   `trs_vjob__job` SOMAVA 3 horas e esta aqui subtraia as mesmas 3. Dois defeitos se
--   anulando. Ao consertar a Trusted contra o VJOB real, o valor passou a chegar
--   certo -- e a conversao daqui, sozinha, passaria a ERRAR: 13 dos 1.514 jobs foram
--   cadastrados entre 00:00 e 03:00 e mudariam de dia, arrastando junto
--   `mes_referencia` e `flag_entrega_antes_cadastro`.
--   **Erro compensado e o pior tipo, porque consertar metade quebra o todo.**
WITH base AS (
  SELECT
    j.origem,
    j.id_job,
    NULLIF(j.tipo_codigo, '')                                     AS tipo_codigo,
    j.status_job                                                  AS status_origem,
    CASE j.status_job
      WHEN 'Feito'        THEN 'concluido'
      WHEN 'Em andamento' THEN 'em_andamento'
      WHEN 'A fazer'      THEN 'pendente'
      WHEN 'Cancelado'    THEN 'cancelado'
      ELSE 'desconhecido'
    END                                                           AS status_canonico,
    j.atividade,
    j.data_entrada,
    j.data_entrega,
    -- FUSO: o VJOB grava hora local e a Trusted a entrega intacta. DATE() SEM
    -- argumento. Passar 'America/Sao_Paulo' aqui subtrai 3 horas -- ver o bloco acima.
    DATE(j.data_cadastro)                                         AS data_cadastro_local,
    DATE_TRUNC(DATE(j.data_cadastro), MONTH)                      AS mes_referencia,
    j.data_cadastro,
    j.checado_em,
    j.aprovado_em,
    j.aprovado,
    j.id_quem_cadastrou,
    j.id_checado_por,
    j.id_aprovado_por,
    j._extraido_at,
    j._fonte
  FROM `vanguardamartech_trusted`.`trs_vjob__job` j
),
calc AS (
  SELECT
    b.*,
    DATE_DIFF(b.data_entrega, b.data_entrada, DAY)          AS prazo_bruto_dias,
    COALESCE(b.data_entrega < b.data_entrada, FALSE)        AS flag_prazo_invalido,
    COALESCE(b.data_entrega < b.data_cadastro_local, FALSE) AS flag_entrega_antes_cadastro
  FROM base b
)
SELECT
  c.origem, c.id_job, c.tipo_codigo, c.status_origem, c.status_canonico, c.atividade,
  c.data_cadastro_local, c.mes_referencia, c.data_entrada, c.data_entrega,
  IF(c.flag_prazo_invalido, NULL, c.prazo_bruto_dias)                 AS prazo_planejado_dias,
  ROUND(TIMESTAMP_DIFF(c.checado_em,  c.data_cadastro, HOUR) / 24, 2) AS dias_ate_checagem,
  ROUND(TIMESTAMP_DIFF(c.aprovado_em, c.data_cadastro, HOUR) / 24, 2) AS dias_ate_aprovacao,
  c.checado_em IS NOT NULL                                            AS foi_checado,
  c.aprovado IS TRUE                                                  AS foi_aprovado,
  c.id_quem_cadastrou, uc.nome AS quem_cadastrou_nome,
  c.id_checado_por,    uk.nome AS checado_por_nome,
  c.id_aprovado_por,   ua.nome AS aprovado_por_nome,
  c.flag_prazo_invalido,
  c.flag_entrega_antes_cadastro,
  (c.status_canonico = 'concluido' AND c.aprovado IS NOT TRUE)        AS flag_concluido_sem_aprovacao,
  NOT (c.flag_prazo_invalido OR c.flag_entrega_antes_cadastro)        AS registro_confiavel,
  c._extraido_at, c._fonte
FROM calc c
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` uc ON uc.id_usuario = c.id_quem_cadastrou
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` uk ON uk.id_usuario = c.id_checado_por
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` ua ON ua.id_usuario = c.id_aprovado_por
