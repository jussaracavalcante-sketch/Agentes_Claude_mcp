-- trs_vjob__cliente_atendimento  ·  query-BuYc  ·  310 linhas  ·  L2 INTERNAL
-- Trusted / VJOB. Grao: uma conta de atendimento. Chave: id_atendimento.
-- Origem: mysql-yIOn, `tbclientesatedimentos`. Gatilho: evento em query-MZdN.
--
-- O ACHADO: o VJOB tem DOIS cadastros de cliente e metade dos modulos aponta para
--   ESTE, nao para `tbclientes`. Orfaos vs ESTA / vs trs_vjob__cliente:
--     tbauditoriaclientes 3.025 ->    0 / 1.372      tb_logs_squad 2.332 ->   0 / 923
--     tbauditorias 56     ->    0 /    28            tbarquivosauditoria 54 -> 0 /  28
--     tbblogs 1.323       ->    2 /   252            checklist_diario 2.748 -> 5 / 214
--   NAO vale para todos: tbetapasxclientes2 tem 1.856 orfaos aqui contra 882 la, e
--   tbescopofinal ja fora provado por NOME que pertence a tbclientes. Escopo e etapa
--   ficam como estao.
--
-- A ponte e `id_tbclientes`: 310 de 310 preenchidos, 6 sem correspondente.
-- ELA E O ESTADO; trs_vjob__squad_alteracao E O LOG.
-- Zero e sentinela de "sem responsavel" nos 15 papeis; 55 contas sem papel nenhum.
-- 105 ativas, 104 desativadas. FUSO: relogio local, NAO CONVERTER.
WITH base AS (
  SELECT * FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientesatedimentos`
),
cli AS (SELECT DISTINCT id_cliente, cnpj_digitos, cliente FROM `vanguardamartech_trusted`.`trs_vjob__cliente`),
usr AS (SELECT DISTINCT id_usuario FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
prep AS (
  SELECT
    b.id                            AS id_atendimento,
    NULLIF(TRIM(b.nomecliente), '') AS nome_conta,
    NULLIF(TRIM(b.grupo), '')       AS grupo_na_origem,
    NULLIF(TRIM(b.classe), '')      AS classe,
    NULLIF(b.id_tbclientes, 0)      AS id_cliente,
    (b.status = 1)                  AS is_ativo,
    (b.cronograma = 1)              AS tem_cronograma,
    NULLIF(b.carteira, 0)           AS id_carteira,
    (b.retencao_iss = 1)            AS tem_retencao_iss,
    b.datacadastro                  AS cadastrado_em,
    b.datacontrato                  AS contrato_em,
    b.desativado_em                 AS desativado_em,
    NULLIF(b.quemcadastrou, 0)      AS cadastrado_por,
    NULLIF(b.desativado_por, 0)     AS desativado_por,
    NULLIF(b.customersuccess, 0)    AS id_customer_success,
    NULLIF(b.analistamkt, 0)        AS id_analista_mkt,
    NULLIF(b.analistamktgoogle, 0)  AS id_analista_mkt_google,
    NULLIF(b.analistamktmeta, 0)    AS id_analista_mkt_meta,
    NULLIF(b.analistaseo, 0)        AS id_analista_seo,
    NULLIF(b.analistasocial, 0)     AS id_analista_social,
    NULLIF(b.storymaker, 0)         AS id_storymaker,
    NULLIF(b.sac, 0)                AS id_sac,
    NULLIF(b.assistente, 0)         AS id_assistente,
    NULLIF(b.criacao, 0)            AS id_criacao,
    NULLIF(b.criacao2, 0)           AS id_criacao_2,
    NULLIF(b.criacao3, 0)           AS id_criacao_3,
    NULLIF(b.redacao, 0)            AS id_redacao,
    NULLIF(b.redacao2, 0)           AS id_redacao_2,
    NULLIF(b.redacao3, 0)           AS id_redacao_3
  FROM base b
),
tratado AS (
  SELECT
    p.*,
    (SELECT COUNT(*) FROM UNNEST([
       p.id_customer_success, p.id_analista_mkt, p.id_analista_mkt_google,
       p.id_analista_mkt_meta, p.id_analista_seo, p.id_analista_social,
       p.id_storymaker, p.id_sac, p.id_assistente,
       p.id_criacao, p.id_criacao_2, p.id_criacao_3,
       p.id_redacao, p.id_redacao_2, p.id_redacao_3]) v
     WHERE v IS NOT NULL)                                AS qtd_papeis_preenchidos,
    c.cnpj_digitos                                       AS cnpj_digitos,
    c.cliente                                            AS nome_no_cadastro_juridico,
    (p.id_cliente IS NULL)                               AS flag_sem_ponte_cadastro,
    (p.id_cliente IS NOT NULL AND c.id_cliente IS NULL)  AS flag_cliente_nao_catalogado,
    (p.desativado_em IS NOT NULL)                        AS flag_desativado,
    (u1.id_usuario IS NULL AND p.cadastrado_por IS NOT NULL) AS flag_autor_nao_catalogado
  FROM prep p
  LEFT JOIN cli c  ON c.id_cliente = p.id_cliente
  LEFT JOIN usr u1 ON u1.id_usuario = p.cadastrado_por
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
