-- trs_vjob__gestor_cliente
-- Gestor atribuido a cada CONTA DE ATENDIMENTO do VJOB. Origem: tbgestoresclientes (234)
-- + tbgestores (15, denormalizada).
--
-- O `id_cliente` da origem e a CONTA DE ATENDIMENTO, nao o cadastro juridico --
-- provado por teste A/B em 2026-09-25: 26,63% dos gestores batem com um papel ja
-- registrado na propria conta (49 de 184), contra 0,88% pelo cadastro juridico
-- (1 de 114). Trinta vezes. Contagem de orfaos sozinha nao teria decidido:
-- 39 contra 115, e 95 ids existem nos dois.
--
-- `id_gestor` aponta para DOIS catalogos e a tabela NAO escolhe por linha ambigua.
WITH origem AS (
  SELECT
    id                                                          AS id_gestor_cliente,
    id_cliente                                                  AS id_atendimento,
    id_gestor                                                   AS id_gestor_na_origem,
    NULLIF(id_gestor, 0)                                        AS id_gestor
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgestoresclientes`
),
catalogo_gestores AS (
  SELECT DISTINCT id AS id_gestor, NULLIF(TRIM(nomegestor), '') AS nome
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbgestores`
),
cadastro_usuario AS (
  SELECT DISTINCT id_usuario, NULLIF(TRIM(nome), '') AS nome
  FROM `vanguardamartech_trusted`.`trs_vjob__usuario`
),
conta AS (
  SELECT
    id_atendimento,
    nome_conta,
    id_cliente                                                  AS id_cliente_juridico,
    is_ativo                                                    AS conta_is_ativa,
    -- os 15 papeis que a conta ja registra, para conferir se o gestor e um deles
    [ id_customer_success, id_analista_mkt, id_analista_mkt_google, id_analista_mkt_meta,
      id_analista_seo, id_analista_social, id_storymaker, id_sac, id_assistente,
      id_criacao, id_criacao_2, id_criacao_3, id_redacao, id_redacao_2, id_redacao_3 ]
                                                                AS papeis_da_conta
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
prep AS (
  SELECT
    o.id_gestor_cliente,
    o.id_atendimento,
    o.id_gestor_na_origem,
    o.id_gestor,
    c.nome_conta,
    c.id_cliente_juridico,
    c.conta_is_ativa,
    c.papeis_da_conta,
    cg.nome                                                     AS nome_no_catalogo_gestores,
    cu.nome                                                     AS nome_no_cadastro_usuario,
    (cg.id_gestor IS NOT NULL)                                  AS existe_no_catalogo_gestores,
    (cu.id_usuario IS NOT NULL)                                 AS existe_no_cadastro_usuario,
    (c.id_atendimento IS NULL)                                  AS conta_ausente
  FROM origem o
  LEFT JOIN conta             c  ON c.id_atendimento = o.id_atendimento
  LEFT JOIN catalogo_gestores cg ON cg.id_gestor     = o.id_gestor
  LEFT JOIN cadastro_usuario  cu ON cu.id_usuario    = o.id_gestor
),
tratado AS (
  SELECT
    p.id_gestor_cliente,

    -- REGRA 1 - identidade da conta, provada por teste A/B, nunca pelo nome da coluna
    p.id_atendimento,
    p.nome_conta,
    p.id_cliente_juridico,
    p.conta_is_ativa,

    -- REGRA 2 - zero e sentinela de "sem gestor", nao id. Mesmo tratamento do
    -- `tb_logs_squad` e do `id_cidade` do cadastro.
    p.id_gestor_na_origem,
    p.id_gestor,
    (p.id_gestor IS NULL)                                       AS flag_sem_gestor,

    -- REGRA 3 - o universo do id, declarado linha a linha. A tabela NAO escolhe
    -- quando os dois catalogos respondem: o id 24 e `Layane` no catalogo de gestores
    -- e `Kethlen Nascimento` no cadastro de usuario -- PESSOAS DIFERENTES.
    CASE
      WHEN p.id_gestor IS NULL                                        THEN 'SEM_GESTOR'
      WHEN p.existe_no_catalogo_gestores AND p.existe_no_cadastro_usuario
                                                                      THEN 'AMBIGUO'
      WHEN p.existe_no_catalogo_gestores                              THEN 'CATALOGO_GESTORES'
      WHEN p.existe_no_cadastro_usuario                               THEN 'CADASTRO_USUARIO'
      ELSE 'NAO_CATALOGADO'
    END                                                         AS universo_do_gestor,

    -- REGRA 4 - o nome so sai quando UM catalogo responde. Em AMBIGUO sai NULL, e os
    -- dois lados ficam visiveis ao lado para revisao humana -- mesma doutrina do
    -- `candidato_sk_por_nome`: pista fora da chave, nunca dentro dela.
    CASE
      WHEN p.id_gestor IS NULL                                        THEN NULL
      WHEN p.existe_no_catalogo_gestores AND p.existe_no_cadastro_usuario
                                                                      THEN NULL
      WHEN p.existe_no_catalogo_gestores                              THEN p.nome_no_catalogo_gestores
      WHEN p.existe_no_cadastro_usuario                               THEN p.nome_no_cadastro_usuario
      ELSE NULL
    END                                                         AS gestor_nome,
    p.nome_no_catalogo_gestores,
    p.nome_no_cadastro_usuario,

    -- REGRA 5 - o gestor ja e um dos 15 papeis que a conta registra? E o sinal que
    -- provou a identidade da conta, e fica na tabela como evidencia auditavel.
    (p.id_gestor IS NOT NULL
      AND p.papeis_da_conta IS NOT NULL
      AND p.id_gestor IN UNNEST(p.papeis_da_conta))             AS flag_gestor_ja_e_papel_na_conta,

    p.conta_ausente                                             AS flag_conta_nao_catalogada,
    (p.id_gestor IS NOT NULL
      AND NOT p.existe_no_catalogo_gestores
      AND NOT p.existe_no_cadastro_usuario)                     AS flag_gestor_nao_catalogado
  FROM prep p
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
