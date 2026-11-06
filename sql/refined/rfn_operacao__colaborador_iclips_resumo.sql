-- rfn_operacao__colaborador_iclips_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: fonte de cadastro x departamento de cadastro x situacao (ATIVO/INATIVO) do colaborador do iClips.
-- Le: trs_iclips__colaborador (query-Zelv, L4). Gatilho: evento em query-Zelv. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 850 colaboradores = 850 · 36 linhas, 36 chaves · 185 ativos ·
--   128 com custo/hora · 190 com departamento por nome · 44 com nome repetido · 39.842 atividades.
-- R1 NADA PESSOAL ATRAVESSA: nome, nome_chave e o VALOR do custo/hora ficam na Trusted. Aqui so contagem. Media ou soma de
--    custo/hora por grupo exporia remuneracao individual em grupos de 1 ou 2 pessoas (18 das 36 linhas tem <= 3 colaboradores):
--    por isso nao sao emitidas. qtd_com_custo_hora e o que se pode saber.
-- R2 departamento_cadastro NULL vira o balde '(sem departamento)' (50 colaboradores, todos da fonte 'fato_atividade only').
-- R3 soma_atividades e NULL quando nenhum colaborador do grupo tem atividade registrada (616 de 850 vem sem total_atividades):
--    zero seria contado como "nao trabalhou"; NULL e ausencia de registro.
-- R4 is_ativo NULL (nao ha hoje) sairia como 'SEM_FLAG', nunca como inativo.
-- LIMITACAO -- NAO CONTORNE: o departamento por nome (flag_departamento_por_nome) e HIPOTESE declarada na Trusted, nao prova;
--   custo/hora cobre 15% da base e NAO e o custo da casa (rfn_operacao__custo_peca); 3 valores implausiveis (> R$ 500/h) e 38
--   inativos com custo seguem marcados, nunca corrigidos. Historico do derivado Supabase, atualizado em 07/04/2026.
WITH c AS (SELECT * FROM `vanguardamartech_trusted`.`trs_iclips__colaborador`),
agg AS (
  SELECT
    IFNULL(fonte_cadastro, '(sem fonte)') AS fonte_cadastro,
    IFNULL(departamento_cadastro, '(sem departamento)') AS departamento_cadastro,
    CASE WHEN is_ativo IS NULL THEN 'SEM_FLAG' WHEN is_ativo THEN 'ATIVO' ELSE 'INATIVO' END AS situacao,
    COUNT(*) AS qtd_colaboradores,
    COUNTIF(departamento_cadastro IS NULL) AS qtd_sem_departamento_cadastro,
    COUNTIF(departamento_operacional IS NOT NULL) AS qtd_com_departamento_operacional,
    COUNTIF(departamento_mapa IS NOT NULL) AS qtd_com_departamento_mapa,
    COUNTIF(flag_departamento_por_nome) AS qtd_departamento_por_nome,
    COUNTIF(custo_hora IS NOT NULL) AS qtd_com_custo_hora,
    COUNTIF(flag_custo_hora_implausivel) AS qtd_custo_hora_implausivel,
    COUNTIF(flag_custo_em_inativo) AS qtd_custo_em_inativo,
    COUNTIF(flag_nome_repetido) AS qtd_nome_repetido,
    COUNTIF(total_atividades IS NOT NULL) AS qtd_com_atividade_registrada,
    SUM(total_atividades) AS soma_atividades,
    MIN(primeira_atividade) AS primeira_atividade,
    MAX(ultima_atividade) AS ultima_atividade,
    MAX(derivado_atualizado_em) AS derivado_atualizado_em
  FROM c
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(fonte_cadastro, '|', departamento_cadastro, '|', situacao) AS id_colaborador_resumo,
         a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
