-- trs_projetos__projeto (query-hamR) · Trusted de projetos do iClips · SUPERADA pela trs_iclips__projeto (query-8nEt)
-- Recuperado de get_code em 18/10/2026: o arquivo nunca tinha sido gravado no repositorio. O codigo abaixo e identico ao deploy;
-- so este cabecalho de comentarios foi acrescentado. Gatilho: evento em notebook-Rbpo. Alerta de falha ligado.
-- Medido em 18/10/2026: grava vanguardamartech_trusted.trs_projetos__projeto, 87 linhas, ultima carga 2026-10-18 13:01 UTC.
-- ATENCAO: existe outra tabela com o mesmo nome em vanguardamartech_gestao_de_projetos_do_iclips (98 linhas, ultima carga 21/08/2026),
-- gravada pela query-ir9k (aposentada). Quem resolve pelo nome da camada pega a morta.
-- Nao construir nada novo sobre esta tabela; a descricao completa (fuso corrigido em 16/09, sentinela 1800-01-01) esta no deploy.
WITH base AS (
  SELECT
    id_projeto,
    TRIM(nome_projeto) AS nome_projeto,
    codigo_job,
    status_codigo,
    status_nome,
    status_projeto_raw,
    verba,
    tipo_cliente,
    cliente_efetivo_id,
    cliente_efetivo_nome,
    cliente_id,
    cliente_nome,
    grupo_cliente_id,
    grupo_cliente_nome,
    responsavel_principal_id,
    responsavel_principal_nome,
    responsavel_auxiliar_id,
    responsavel_auxiliar_nome,
    -- FUSO: o iClips ja entrega America/Sao_Paulo. Ver bloco FUSO na descricao.
    -- NAO reintroduzir conversao -- ela SOMAVA 3 horas.
    CASE WHEN DATE(data_entrada, 'UTC') = DATE '1800-01-01' THEN NULL
         ELSE data_entrada END AS data_entrada,
    CASE WHEN DATE(data_alteracao_status, 'UTC') = DATE '1800-01-01' THEN NULL
         ELSE data_alteracao_status END AS data_alteracao_status,
    CASE WHEN DATE(data_aprovacao, 'UTC') = DATE '1800-01-01' THEN NULL
         ELSE data_aprovacao END AS data_aprovacao,
    CASE WHEN DATE(data_conclusao_estimada, 'UTC') = DATE '1800-01-01' THEN NULL
         ELSE data_conclusao_estimada END AS data_conclusao_estimada,
    CAST(NULL AS TIMESTAMP) AS data_conclusao,
    qtd_pecas,
    qtd_tarefas,
    qtd_apontamentos,
    janela_origem,
    extraido_em AS _extraido_at,
    'America/Sao_Paulo' AS _fuso,
    'notebook-Rbpo' AS _fonte
  FROM `vanguardamartech_gestao_de_projetos_do_iclips`.`projetos`
)
SELECT * FROM base
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY id_projeto
  ORDER BY _extraido_at DESC, janela_origem DESC
) = 1
