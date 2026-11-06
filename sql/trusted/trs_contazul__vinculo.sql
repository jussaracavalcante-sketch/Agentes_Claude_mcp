-- trs_contazul__vinculo  ·  query-PdzT  ·  10 linhas  ·  L2 INTERNAL
-- Trusted / Conta Azul. Grao: um vinculo de-para VJOB <-> Conta Azul. Chave: id_vinculo.
-- Origem: mysql-yIOn, contazul_vinculos (10). Gatilho: evento em query-y2xj.
--
-- POR QUE EXISTE, COM 10 LINHAS: e o unico lugar desta base onde alguem declarou, a mao,
--   que o cliente X do VJOB e o cliente Y do Conta Azul. Sem ela a unica ponte seria o
--   rotulo — e os rotulos NAO batem. Medido em 2026-09-25: 10 de 10 resolvem dos dois lados
--   (ZERO orfaos) e em SEIS o nome difere nas duas pontas:
--     VANGUARDA COMUNICACAO   -> VANGUARDA COMUNICACAO DIGITAL LTDA
--     OLA CASA NOVA           -> FIT PONTA NEGRA - OLA CASA NOVA
--     Veiculacao de Midia     -> [MIDIA PERFORMANCE] Comissao Midia On - RT
--     VEICULACAO DE MIDIA ON  -> [MIDIA PERFORMANCE] Comissao Midia On
--     Manutencao de site      -> [DEV] Manutencao de Site
--     TIKTOK ADS / META ADS   -> [MIDIA PERFORMANCE] Impulsionamento - ...
--   E a prova pratica da doutrina: identidade por id, nunca por rotulo. Casamento por nome
--   encontraria no maximo 4 dos 10.
--
-- REGRA 1 — TERCEIRA CONFIRMACAO INDEPENDENTE de que o cadastro operacional do VJOB e
--   `tbclientesatedimentos`, nao `tbclientes`: os tres vinculos de tipo `cliente` apontam
--   para ela (ids 34, 85, 340) e resolvem 3 de 3. A integracao que a propria casa escreveu
--   escolheu essa tabela — evidencia independente da contagem de orfaos e do nome.
-- REGRA 2 — `tipo` nomeia o conceito do VJOB, nao o do Conta Azul. Os dois de
--   `impulsionamento` apontam para `tbfornecedorescronograma` de um lado e para um SERVICO
--   do outro. `papeis_contaazul` diz o que a entidade e do outro lado, medido.
-- REGRA 3 — QUATRO TABELAS-PAI: tbclientesatedimentos (3), tbservicoscronograma (3),
--   tbusuariointranet (2), tbfornecedorescronograma (2). O usuario da intranet e lido pela
--   trs_vjob__usuario (id e nome): a tabela crua e L5 (senha, CPF, prontuario de RH).
-- REGRA 4 — 10 de 10 MANUAL e 10 de 10 ativos. Nao ha vinculo automatico nem desativado.
--
-- FUSO: sem conversao — MySQL `vjob_2024`, hora local ja medida.
--
-- LIMITACOES — NAO CONTORNE
--   1. DEZ VINCULOS NAO SAO UMA PONTE. O VJOB tem 310 contas de atendimento e o Conta Azul
--      1.828 entidades; o de-para cobre 3 clientes. Para escala a chave e o DOCUMENTO
--      (trs_contazul__entidade.documento), que cobre 1.052 das 1.828.
--   2. O lado Conta Azul le o espelho MySQL, nao a trs_contazul__entidade, porque inclui
--      SERVICO, que nao e entidade de pessoa e nao esta naquela tabela.
--   3. Sem historico: a origem guarda o estado atual, sem log de alteracao.

WITH v AS (
  SELECT id, empresa_chave, tipo, contaazul_id, vjob_tabela, vjob_id,
         origem_vinculo, ativo, criado_em, atualizado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_vinculos`
),
ca AS (
  SELECT contaazul_id, nome, documento, 'CLIENTE' AS papel
    FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_clientes`
  UNION ALL
  SELECT contaazul_id, nome, documento, 'FORNECEDOR'
    FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_fornecedores`
  UNION ALL
  SELECT contaazul_id, nome, documento, 'VENDEDOR'
    FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_vendedores`
  UNION ALL
  SELECT contaazul_id, nome, CAST(NULL AS STRING), 'SERVICO'
    FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_contazul_servicos`
),
ca_uniq AS (
  SELECT contaazul_id,
         MAX(nome)       AS nome,
         MAX(documento)  AS documento,
         STRING_AGG(DISTINCT papel, '+' ORDER BY papel) AS papeis
  FROM ca GROUP BY contaazul_id
),
final AS (
  SELECT
    CAST(v.id AS STRING)                                    AS id_vinculo,
    v.tipo                                                  AS tipo_vinculo,

    v.vjob_tabela,
    CAST(v.vjob_id AS STRING)                               AS vjob_id,
    COALESCE(cli.nomecliente, sv.nomeservico, fo.nomefornecedor, us.nome)
                                                            AS rotulo_vjob,
    (COALESCE(cli.nomecliente, sv.nomeservico, fo.nomefornecedor, us.nome) IS NULL)
                                                            AS flag_vjob_nao_resolvido,
    cli.id_tbclientes                                       AS vjob_id_cliente_juridico,

    v.contaazul_id                                          AS id_entidade_contaazul,
    c.nome                                                  AS rotulo_contaazul,
    c.papeis                                                AS papeis_contaazul,
    NULLIF(REGEXP_REPLACE(COALESCE(c.documento, ''), r'[^0-9]', ''), '') AS documento_contaazul,
    (c.contaazul_id IS NULL)                                AS flag_contaazul_nao_resolvido,

    -- o de-para existe porque o rotulo NAO bate: isto mede quanto
    (c.nome IS NOT NULL
      AND COALESCE(cli.nomecliente, sv.nomeservico, fo.nomefornecedor, us.nome) IS NOT NULL
      AND UPPER(TRIM(REGEXP_REPLACE(NORMALIZE(c.nome, NFD), r'\pM', '')))
        != UPPER(TRIM(REGEXP_REPLACE(NORMALIZE(
             COALESCE(cli.nomecliente, sv.nomeservico, fo.nomefornecedor, us.nome), NFD), r'\pM', ''))))
                                                            AS flag_rotulos_divergem,

    v.origem_vinculo,
    (v.origem_vinculo = 'MANUAL')                           AS is_vinculo_manual,
    (v.ativo = 1)                                           AS is_ativo,
    v.empresa_chave,
    v.criado_em,
    v.atualizado_em
  FROM v
  LEFT JOIN ca_uniq c
    ON c.contaazul_id = v.contaazul_id
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientesatedimentos` cli
    ON v.vjob_tabela = 'tbclientesatedimentos' AND cli.id = v.vjob_id
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbservicoscronograma` sv
    ON v.vjob_tabela = 'tbservicoscronograma' AND sv.id = v.vjob_id
  LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbfornecedorescronograma` fo
    ON v.vjob_tabela = 'tbfornecedorescronograma' AND fo.id = v.vjob_id
  LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__usuario` us
    ON v.vjob_tabela = 'tbusuariointranet' AND us.id_usuario = v.vjob_id
)
SELECT
  f.*,
  'L2_INTERNAL'                                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'mysql-yIOn'                                  AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
