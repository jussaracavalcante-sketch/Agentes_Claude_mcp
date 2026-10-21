-- trs_vjob__auditoria_ciclo  ·  query-w4wL  ·  56 linhas  ·  L2 INTERNAL
-- Trusted / VJOB. Grao: uma rodada de auditoria de uma conta. Chave: id_auditoria.
-- Origem: tbauditorias (56) + tbarquivosauditoria (54) + tbauditoriaclientes (agregado).
-- Gatilho: evento em query-TkGA.
--
-- E o pai que a trs_vjob__auditoria_cliente declarou nao existir no catalogo.
-- COBERTURA TOTAL NOS DOIS SENTIDOS: 56 ciclos somam exatamente 3.025 itens e nenhum
--   ciclo esta vazio.
-- O CICLO SEMPRE DATA O FECHAMENTO: 54 finalizados = 54 com data, zero excecoes.
-- 36 DOS 56 (64%) NAO REGISTRAM QUEM ABRIU; os 20 restantes sao da mesma pessoa.
-- UM ARQUIVO DE 54 E ORFAO: qtd_arquivos soma 53. 3 ciclos sem arquivo.
WITH a AS (
  SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbauditorias`
),
arq AS (
  SELECT id_auditoria, COUNT(*) AS n, MAX(datahora) AS ultimo
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbarquivosauditoria`
  GROUP BY id_auditoria
),
itens AS (
  SELECT id_auditoria, COUNT(*) AS n, COUNTIF(status = 1) AS feitos, COUNTIF(ativo = 1) AS ativos
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbauditoriaclientes`
  GROUP BY id_auditoria
),
contas AS (
  SELECT DISTINCT id_atendimento, id_cliente, nome_conta, cnpj_digitos
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
u AS (SELECT DISTINCT id_usuario FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
tratado AS (
  SELECT
    a.id                                        AS id_auditoria,
    a.id_cliente                                AS id_atendimento,
    ct.id_cliente                               AS id_cliente_juridico,
    ct.nome_conta                               AS cliente_nome,
    ct.cnpj_digitos                             AS cnpj_digitos,
    (a.status = 1)                              AS is_finalizado,
    a.criado_em,
    a.finalizado_em,
    a.criado_por,
    COALESCE(i.n, 0)                            AS qtd_itens,
    COALESCE(i.ativos, 0)                       AS qtd_itens_ativos,
    COALESCE(i.feitos, 0)                       AS qtd_itens_feitos,
    COALESCE(arq.n, 0)                          AS qtd_arquivos,
    arq.ultimo                                  AS ultimo_arquivo_em,
    ((a.status = 1) <> (a.finalizado_em IS NOT NULL)) AS flag_status_sem_carimbo,
    (ct.id_atendimento IS NULL)                 AS flag_conta_nao_catalogada,
    (a.criado_por IS NULL)                      AS flag_sem_autor,
    (a.criado_por IS NOT NULL AND u.id_usuario IS NULL) AS flag_autor_nao_catalogado,
    (COALESCE(arq.n, 0) = 0)                    AS flag_sem_evidencia
  FROM a
  LEFT JOIN arq    ON arq.id_auditoria = a.id
  LEFT JOIN itens i ON i.id_auditoria  = a.id
  LEFT JOIN contas ct ON ct.id_atendimento = a.id_cliente
  LEFT JOIN u      ON u.id_usuario     = a.criado_por
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
