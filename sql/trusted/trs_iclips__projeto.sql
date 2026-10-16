-- trs_iclips__projeto  (query-8nEt)
-- Trusted do iClips: um projeto por linha. Chave id_projeto.
-- Historico profundo do bronze + ponta viva do notebook, deduplicados.
--
-- ATENCAO: ate 29/09/2026 este arquivo DIVERGIA do deploy -- faltava a coluna
-- `_fuso`, acrescentada na correcao de 16/09. Recuperado de get_code e regravado
-- hoje. O deploy e a autoridade; o arquivo e a copia.
--
-- POR QUE ESTA TABELA EXISTE
-- A trs_projetos__projeto (query-hamR) tem 156 linhas porque le so a saida do
-- notebook, que extrai por janelas moveis. Mas o historico do iClips JA ESTAVA
-- na base, nao extraido: 14.670 payloads em supabase_bronze_iclips__projetos,
-- cobrindo 2021 a 2026. Nao foi preciso buscar nada na API -- foi preciso
-- PARSEAR o que ja tinha sido trazido.
--
-- AS DUAS FONTES SAO COMPLEMENTARES, NAO CONCORRENTES -- medido em 2026-09-15
--   bronze  : 2021-01-04 a 2026-08-05, 14.670 linhas / 12.069 projetos distintos
--   notebook: 2026-07-17 a 2026-09-14, 156 projetos, dos quais 36 NAO estao no bronze
--
-- REGRA DE DESEMPATE. Quando o mesmo id_projeto existe nos dois lados vence o
-- NOTEBOOK. origem_do_registro declara a procedencia linha a linha.
--
-- CNPJ SOBREVIVE AO DESEMPATE. O payload do bronze traz cliente.cnpj; a tabela do
-- notebook NAO tem essa coluna. Por isso o CNPJ e recuperado por id_projeto
-- DEPOIS do desempate, de um mapa construido sobre o bronze inteiro.
--
-- O DOCUMENTO SAI EM DIGITOS -- CORRIGIDO EM 2026-09-29, E ATE ESSA DATA ESTA
-- TABELA NAO JUNTAVA COM NADA. O payload entrega o CNPJ COM MASCARA
-- (`84.466.424/0001-36`) e coluna de juncao nao compara com pontuacao. Medido
-- antes do conserto: 11.468 das 11.568 linhas com documento traziam pontuacao;
-- dos 367 documentos distintos so 3 casavam com trs_iclips__peca_atributo -- do
-- MESMO sistema -- e 3 com rfn_cadastro__cliente_sk; em digitos, 174 e 359. No
-- grao da linha, 100 viram 8.603 (86x). Ver a descricao na Nekt, regra 2-B.
--
-- SENTINELA 1800-01-01 -> NULL em todas as datas.
--
-- FUSO -- CORRIGIDO EM 16/09/2026: o iClips JA entrega America/Sao_Paulo e
-- TIMESTAMP(dt,'America/Sao_Paulo') SOMA 3 horas a um dado que ja e local.
-- Conferido contra supabase_public_fato_atividade: 4.094 de 4.094 com delta
-- ZERO depois da correcao. NAO reintroduzir conversao.
--
-- LIMITACAO -- NAO CONTORNE
-- qtd_apontamentos so existe no lado do notebook; no bronze vem NULL. NAO ler
-- NULL como zero. verba vem 0 em todo o bronze. O historico NAO avanca sozinho:
-- o bronze depende da supabase-x0tz.
WITH bronze_bruto AS (
  SELECT
    JSON_VALUE(payload, '$.idProjeto')                                     AS id_projeto,
    JSON_VALUE(payload, '$.nomeProjeto')                                   AS nome_projeto,
    JSON_VALUE(payload, '$.statusProjeto')                                 AS status_projeto_raw,
    SAFE_CAST(JSON_VALUE(payload, '$.verba') AS FLOAT64)                   AS verba,
    JSON_VALUE(payload, '$.cliente.id')                                    AS cliente_id,
    NULLIF(JSON_VALUE(payload, '$.cliente.cnpj'), '')                      AS cliente_cnpj,
    JSON_VALUE(payload, '$.cliente.nome')                                  AS cliente_nome,
    JSON_VALUE(payload, '$.grupoCliente')                                  AS grupo_cliente_nome,
    JSON_VALUE(payload, '$.responsaveis.principal.id')                     AS responsavel_principal_id,
    JSON_VALUE(payload, '$.responsaveis.principal.nome')                   AS responsavel_principal_nome,
    JSON_VALUE(payload, '$.responsaveis.auxiliar.id')                      AS responsavel_auxiliar_id,
    JSON_VALUE(payload, '$.responsaveis.auxiliar.nome')                    AS responsavel_auxiliar_nome,
    SAFE_CAST(JSON_VALUE(payload, '$.datas.entrada')           AS DATETIME) AS dt_entrada,
    SAFE_CAST(JSON_VALUE(payload, '$.datas.aprovacao')         AS DATETIME) AS dt_aprovacao,
    SAFE_CAST(JSON_VALUE(payload, '$.datas.conclusao')         AS DATETIME) AS dt_conclusao,
    SAFE_CAST(JSON_VALUE(payload, '$.datas.alteracaoStatus')   AS DATETIME) AS dt_alteracao,
    SAFE_CAST(JSON_VALUE(payload, '$.datas.conclusaoEstimada') AS DATETIME) AS dt_conclusao_est,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(payload, '$.pecas'))                     AS qtd_pecas,
    ARRAY_LENGTH(JSON_QUERY_ARRAY(payload, '$.tarefas'))                   AS qtd_tarefas,
    CAST(NULL AS INT64)                                                    AS qtd_apontamentos,
    fetched_at                                                             AS extraido_em
  FROM `vanguardamartech_raw.supabase_bronze_iclips__projetos`
),
bronze AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT b.*, ROW_NUMBER() OVER (PARTITION BY id_projeto ORDER BY extraido_em DESC) AS rn
    FROM bronze_bruto b
  ) WHERE rn = 1
),
cnpj_map AS (
  SELECT id_projeto, ANY_VALUE(cliente_cnpj) AS cnpj_do_bronze
  FROM bronze WHERE cliente_cnpj IS NOT NULL GROUP BY id_projeto
),
nb AS (
  SELECT
    id_projeto, nome_projeto, status_projeto_raw, verba, cliente_id,
    CAST(NULL AS STRING) AS cliente_cnpj, cliente_nome, grupo_cliente_nome,
    responsavel_principal_id, responsavel_principal_nome,
    responsavel_auxiliar_id, responsavel_auxiliar_nome,
    DATETIME(data_entrada, 'UTC')            AS dt_entrada,
    DATETIME(data_aprovacao, 'UTC')          AS dt_aprovacao,
    CAST(NULL AS DATETIME)                   AS dt_conclusao,
    DATETIME(data_alteracao_status, 'UTC')   AS dt_alteracao,
    DATETIME(data_conclusao_estimada, 'UTC') AS dt_conclusao_est,
    qtd_pecas, qtd_tarefas, qtd_apontamentos, extraido_em
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`projetos`
),
uniao AS (
  SELECT 'BRONZE_HISTORICO' AS origem_do_registro, * FROM bronze
  UNION ALL
  SELECT 'NOTEBOOK_VIVO',    * FROM nb
),
escolhida AS (
  SELECT * EXCEPT(rn) FROM (
    SELECT u.*, ROW_NUMBER() OVER (
      PARTITION BY id_projeto
      ORDER BY IF(origem_do_registro = 'NOTEBOOK_VIVO', 0, 1), extraido_em DESC
    ) AS rn FROM uniao u
  ) WHERE rn = 1
),
-- O documento vem do desempate OU do mapa do bronze -- calculado UMA vez aqui,
-- para que a regra de forma abaixo nao repita a expressao quatro vezes.
com_doc AS (
  SELECT e.*, COALESCE(e.cliente_cnpj, c.cnpj_do_bronze) AS cnpj_origem
  FROM escolhida e
  LEFT JOIN cnpj_map c USING (id_projeto)
),
tratada AS (
  SELECT
    e.id_projeto,
    e.nome_projeto,
    e.status_projeto_raw,
    e.verba,
    e.cliente_id,
    -- DOCUMENTO EM DIGITOS -- CORRIGIDO EM 2026-09-29.
    -- O payload do iClips traz o CNPJ COM MASCARA (`84.466.424/0001-36`), e
    -- coluna de juncao nao compara com pontuacao. MEDIDO antes do conserto:
    -- dos 367 documentos distintos, so 3 casavam com trs_iclips__peca_atributo
    -- (que ja guardava digitos) e 3 com rfn_cadastro__cliente_sk; em digitos,
    -- 174 e 359. No grao da linha, 100 viravam 8.603 -- 86x mais.
    -- So e documento o que tem 14 digitos (CNPJ) ou 11 (CPF). Uma linha traz a
    -- mascara do formulario em branco (`__.___.___/____-__`), que nao e documento.
    -- Mesmo conserto ja feito no cnpj_veiculo da trs_pi__insercao.
    e.cnpj_origem                                                         AS cliente_cnpj_origem,
    IF(LENGTH(REGEXP_REPLACE(IFNULL(e.cnpj_origem, ''), r'[^0-9]', '')) IN (14, 11),
       REGEXP_REPLACE(e.cnpj_origem, r'[^0-9]', ''), NULL)                AS cliente_cnpj,
    e.cnpj_origem IS NOT NULL
      AND LENGTH(REGEXP_REPLACE(e.cnpj_origem, r'[^0-9]', '')) NOT IN (14, 11)
                                                                          AS flag_cnpj_invalido,
    LENGTH(REGEXP_REPLACE(IFNULL(e.cnpj_origem, ''), r'[^0-9]', '')) = 11  AS cliente_is_pf,
    e.cliente_nome,
    e.grupo_cliente_nome,
    e.responsavel_principal_id,
    e.responsavel_principal_nome,
    e.responsavel_auxiliar_id,
    e.responsavel_auxiliar_nome,
    -- FUSO: o iClips ja entrega America/Sao_Paulo. TIMESTAMP() sem fuso preserva o
    -- relogio de parede. Ver bloco FUSO na descricao -- NAO reintroduzir conversao.
    IF(DATE(e.dt_entrada)       = DATE '1800-01-01', NULL, TIMESTAMP(e.dt_entrada))       AS data_entrada,
    IF(DATE(e.dt_aprovacao)     = DATE '1800-01-01', NULL, TIMESTAMP(e.dt_aprovacao))     AS data_aprovacao,
    IF(DATE(e.dt_conclusao)     = DATE '1800-01-01', NULL, TIMESTAMP(e.dt_conclusao))     AS data_conclusao,
    IF(DATE(e.dt_alteracao)     = DATE '1800-01-01', NULL, TIMESTAMP(e.dt_alteracao))     AS data_alteracao_status,
    IF(DATE(e.dt_conclusao_est) = DATE '1800-01-01', NULL, TIMESTAMP(e.dt_conclusao_est)) AS data_conclusao_estimada,
    e.qtd_pecas,
    e.qtd_tarefas,
    e.qtd_apontamentos,
    e.origem_do_registro,
    e.origem_do_registro = 'BRONZE_HISTORICO'                             AS registro_historico,
    -- sem_cnpj passa a significar SEM DOCUMENTO VALIDO, nao "campo vazio":
    -- 538 -> 539, porque a mascara em branco deixa de contar como documento.
    LENGTH(REGEXP_REPLACE(IFNULL(e.cnpj_origem, ''), r'[^0-9]', '')) NOT IN (14, 11)
                                                                          AS sem_cnpj,
    e.extraido_em                                                         AS _extraido_at,
    'America/Sao_Paulo'                                                   AS _fuso,
    IF(e.origem_do_registro = 'NOTEBOOK_VIVO', 'notebook-Rbpo',
       'supabase_bronze_iclips__projetos')                                AS _fonte
  FROM com_doc e
)
SELECT
  t.*,
  DATE(t.data_entrada)                            AS data_entrada_dia,
  DATE_TRUNC(DATE(t.data_entrada), MONTH)         AS mes_referencia,
  TO_HEX(MD5(TO_JSON_STRING(t)))                  AS _payload_hash
FROM tratada t
