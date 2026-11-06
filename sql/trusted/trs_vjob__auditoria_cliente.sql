-- trs_vjob__auditoria_cliente
-- Item de auditoria de servico por CONTA, do VJOB real (mysql-yIOn).
-- Grao: um item auditado. Chave: id_auditoria_item. L2 INTERNAL.
--
-- CORRECAO 2026-09-24: DUAS DIMENSOES ESTAVAM ERRADAS E UMA FALTAVA.
--   1. cliente -> era `tbclientes` (juridico) com 1.372 "orfaos"; e
--      `trs_vjob__cliente_atendimento`: ZERO orfaos.
--   2. setor   -> era `tbsetor` (17) resolvendo 3 de 5; e `tbsetoresauditoria` (5):
--      ZERO orfaos.
--   3. servico -> a versao anterior dizia que NAO existia dimensao. Existe:
--      `trs_vjob__auditoria_servico` (1.387) resolve 3.025 de 3.025. ZERO orfaos.
--   Ver a descricao da transformacao para o antes/depois completo.
--
-- AQUI A CONCLUSAO SEMPRE DATA A ACAO: `status = 1` sao 1.544 e `datahoramarcacao`
--   preenchida sao 1.544, coincidencia exata. Cobertura 100%; o escopo cobre 84%.
--
-- FUSO: NADA SE CONVERTE. Os TIMESTAMP ja sao hora local (America/Sao_Paulo).
WITH a AS (
  SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbauditoriaclientes`
),
-- O PAI CERTO do cliente. Medido nos dois sentidos antes de trocar.
contas AS (
  SELECT DISTINCT id_atendimento, id_cliente, nome_conta, cnpj_digitos, is_ativo
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
-- A dimensao de servico que a versao anterior declarou nao existir.
svc AS (
  SELECT DISTINCT id_servico, nome_servico, id_setor AS id_setor_do_servico,
         nome_setor, id_subservico, nome_subservico, id_categoria, nome_categoria,
         prazo_dias
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_servico`
),
-- O dominio de setor CERTO: tbsetoresauditoria (5), nao o tbsetor geral (17).
st AS (
  SELECT id, NULLIF(TRIM(REPLACE(REPLACE(nome, '\r', ''), '\n', '')), '') AS nome
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsetoresauditoria`
),
tratado AS (
  SELECT
    a.id                                                    AS id_auditoria_item,
    a.id_auditoria,
    -- Valor cru inalterado; o que muda e contra quem ele resolve.
    a.id_cliente,
    ct.nome_conta                                           AS cliente_nome,
    ct.id_cliente                                           AS id_cliente_juridico,
    ct.cnpj_digitos                                         AS cnpj_digitos,
    ct.is_ativo                                             AS is_conta_ativa,
    -- Hoje FALSE em 3.025 de 3.025. Se acender, ai sim e buraco da origem.
    (ct.id_atendimento IS NULL)                             AS flag_cliente_nao_catalogado,

    a.id_servico,
    s.nome_servico,
    s.id_subservico,
    s.nome_subservico,
    s.id_categoria,
    s.nome_categoria,
    s.prazo_dias                                            AS prazo_dias_padrao,
    (s.id_servico IS NULL)                                  AS flag_servico_nao_catalogado,

    -- O setor do ITEM manda; o do catalogo sai ao lado para o conflito ficar visivel.
    a.id_setor,
    st.nome                                                 AS setor,
    s.id_setor_do_servico,
    (a.id_setor IS NOT NULL AND st.id IS NULL)              AS flag_setor_nao_resolvido,
    (s.id_setor_do_servico IS NOT NULL
      AND s.id_setor_do_servico <> a.id_setor)              AS flag_setor_diverge_do_catalogo,

    a.id_sub,
    a.datafinal                                             AS prazo,
    (a.status = 1)                                          AS is_feito,
    (a.ativo = 1)                                           AS is_ativo,
    a.datahoramarcacao                                      AS marcado_em,
    NULLIF(a.quemmarcou, 0)                                 AS quem_marcou,
    NULLIF(a.queminseriu, 0)                                AS quem_inseriu,
    a.datadecadastro                                        AS cadastrado_em,
    NULLIF(TRIM(a.url), '')                                 AS url_evidencia,
    (NULLIF(TRIM(a.url), '') IS NOT NULL)                   AS flag_tem_evidencia,
    -- A invariante da tabela, emitida como coluna para que uma quebra futura seja
    -- visivel sem ninguem precisar lembrar de conferir. Hoje FALSE em 3.025 de 3.025.
    ((a.status = 1) <> (a.datahoramarcacao IS NOT NULL))    AS flag_status_sem_carimbo
  FROM a
  LEFT JOIN contas ct ON ct.id_atendimento = a.id_cliente
  LEFT JOIN svc s     ON s.id_servico      = a.id_servico
  LEFT JOIN st        ON st.id             = a.id_setor
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                       AS _extraido_at,
  'mysql-yIOn'                                              AS _fonte,
  'America/Sao_Paulo'                                       AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                            AS _payload_hash
FROM tratado t
