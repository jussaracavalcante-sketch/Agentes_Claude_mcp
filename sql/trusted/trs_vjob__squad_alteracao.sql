-- trs_vjob__squad_alteracao
-- Trusted / VJOB. Grao: uma troca de responsavel de squad numa CONTA DE ATENDIMENTO.
-- Chave: id_alteracao. Origem: mysql-yIOn, `tb_logs_squad` (2.332). L2 INTERNAL.
--
-- CORRECAO 2026-09-24: a primeira versao juntava `cliente_id` com `trs_vjob__cliente`
--   (cadastro JURIDICO) e chamava as 923 linhas sem par (39,6%) de "buraco de cadastro
--   da origem". Era FK ERRADA. O pai e `trs_vjob__cliente_atendimento`: ZERO orfaos.
--   Ver a descricao da transformacao.
--
-- ELA E O LOG; `trs_vjob__cliente_atendimento` E O ESTADO. As duas se leem juntas.
--
-- ZERO E SENTINELA DE "SEM RESPONSAVEL", NAO UM ID -- 572 anteriores e 125 novos.
-- O EVENTO TEM TRES FORMAS QUE NAO SE SOMAM: ATRIBUICAO 520 · TROCA 1.687 ·
--   REMOCAO 73 · SEM_EFEITO 52.
-- FUSO: relogio local da intranet. NAO CONVERTER.
WITH base AS (
  SELECT id, user_id, cliente_id, coluna, valor_antigo, valor_novo, data_hora
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tb_logs_squad`
),
-- O PAI CERTO. Medido nos dois sentidos antes de trocar: 0 orfaos aqui, 923 em
-- `trs_vjob__cliente`.
contas AS (
  SELECT DISTINCT id_atendimento, id_cliente, nome_conta, is_ativo
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
usuarios AS (SELECT DISTINCT id_usuario FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
prep AS (
  SELECT
    b.id                                                        AS id_alteracao,
    b.cliente_id                                                AS id_atendimento,
    NULLIF(b.user_id, 0)                                        AS id_alterado_por,
    NULLIF(TRIM(b.coluna), '')                                  AS papel,
    -- ZERO E SENTINELA DE VAZIO, nao id de pessoa.
    NULLIF(SAFE_CAST(NULLIF(TRIM(b.valor_antigo), '') AS INT64), 0) AS id_responsavel_anterior,
    NULLIF(SAFE_CAST(NULLIF(TRIM(b.valor_novo), '')   AS INT64), 0) AS id_responsavel_novo,
    b.data_hora                                                 AS alterado_em,
    a.id_atendimento                                            AS conta_ok,
    a.id_cliente                                                AS id_cliente,
    a.nome_conta                                                AS nome_conta,
    a.is_ativo                                                  AS is_conta_ativa,
    u.id_usuario                                                AS usr_ok
  FROM base b
  LEFT JOIN contas a   ON a.id_atendimento = b.cliente_id
  LEFT JOIN usuarios u ON u.id_usuario = b.user_id
),
tratado AS (
  SELECT
    p.id_alteracao,
    p.id_atendimento,
    p.id_cliente,
    p.nome_conta,
    p.is_conta_ativa,
    p.id_alterado_por,
    p.papel,
    p.id_responsavel_anterior,
    p.id_responsavel_novo,

    -- Tres movimentos diferentes que nao se somam. Ver o bloco do cabecalho.
    CASE
      WHEN p.id_responsavel_anterior IS NULL AND p.id_responsavel_novo IS NOT NULL THEN 'ATRIBUICAO'
      WHEN p.id_responsavel_anterior IS NOT NULL AND p.id_responsavel_novo IS NULL THEN 'REMOCAO'
      WHEN p.id_responsavel_anterior IS NOT NULL AND p.id_responsavel_novo IS NOT NULL THEN 'TROCA'
      ELSE 'SEM_EFEITO'
    END                                                         AS tipo_evento,

    -- FUSO: relogio local. Nao converter.
    p.alterado_em,

    -- Hoje FALSE em 2.332 de 2.332. Se voltar a acender, o cadastro de atendimento
    -- perdeu linha -- e ai sim e buraco da origem.
    (p.conta_ok IS NULL)                                        AS flag_conta_nao_catalogada,
    (p.conta_ok IS NOT NULL AND p.id_cliente IS NULL)           AS flag_sem_ponte_cadastro_juridico,
    (p.id_alterado_por IS NOT NULL AND p.usr_ok IS NULL)        AS flag_autor_nao_catalogado,
    -- ANTI-JOIN, nao `NOT EXISTS` correlacionado: esta base ja registrou que o
    -- correlacionado nao roda no BigQuery quando o lado direito cresce. O `DISTINCT`
    -- nas CTEs e obrigatorio, senao o join multiplica a linha da esquerda.
    (p.id_responsavel_anterior IS NOT NULL AND ua.id_usuario IS NULL)
                                                                AS flag_anterior_nao_catalogado,
    (p.id_responsavel_novo IS NOT NULL AND un.id_usuario IS NULL)
                                                                AS flag_novo_nao_catalogado
  FROM prep p
  LEFT JOIN usuarios ua ON ua.id_usuario = p.id_responsavel_anterior
  LEFT JOIN usuarios un ON un.id_usuario = p.id_responsavel_novo
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                                AS _payload_hash
FROM tratado t
