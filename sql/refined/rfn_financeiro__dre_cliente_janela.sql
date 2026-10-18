-- rfn_financeiro__dre_cliente_janela
-- Refined / financeiro. Grao: metodo de DRE x cliente (grupo_key ou nome) x escopo x setor, SOMADO sobre a janela de meses ja
-- ocorridos (mes_referencia <= mes da carga). Le trs_financeiro__dre_cliente. Nivel: L3 CONFIDENTIAL (receita, custo e margem por cliente).
-- REGRA 1: SEMPRE filtrar por metodo (SERVICO_PECAS, SERVICO_TEMPO, PI, DIRETO). Os metodos nao se somam: SERVICO_PECAS e SERVICO_TEMPO
--          dao o mesmo total e diferem so no rateio de overhead; PI cobre menos receita; DIRETO nao rateia overhead.
-- REGRA 2: a janela exclui meses futuros (projecao): o corte e o mes de DATE(_extraido_at), nunca o relogio de quem le; os meses excluidos
--          aparecem em qtd_meses_futuros_excluidos.
-- REGRA 3: ranking de cliente usa ESTA tabela (janela), nao o mes isolado: receita e custo caem em meses diferentes.
-- REGRA 4: posicao_ranking_resultado ordena por resultado (SERVICO_*, PI) ou margem_direta (DIRETO) so entre linhas atribuidas;
--          linha nao atribuida (eh_nao_atribuido) tem posicao NULL. Colunas que o metodo nao tem saem NULL.
-- LIMITACOES - NAO CONTORNE: grupo_key e o agrupamento do Supabase (raiz de CNPJ, grupo, nome), nao da casa (R-003); nao soma com
--   rfn_financeiro__rentabilidade_cliente nem com rfn_financeiro__receita_cliente_mensal (metodologia propria); o rateio de overhead e do Supabase.
WITH d AS (
  SELECT *, DATE_TRUNC(DATE(_extraido_at), MONTH) AS mes_corte
  FROM vanguardamartech_trusted.trs_financeiro__dre_cliente
),
j AS (
  SELECT
    metodo,
    IFNULL(grupo_key, IFNULL(grupo_nome, '-')) AS chave_cliente,
    ANY_VALUE(grupo_key)                       AS grupo_key,
    ANY_VALUE(grupo_nome)                      AS grupo_nome,
    IFNULL(escopo, '-')                        AS escopo_chave,
    ANY_VALUE(escopo)                          AS escopo,
    setor_id,
    LOGICAL_OR(IFNULL(eh_nao_atribuido, FALSE)) AS eh_nao_atribuido,
    COUNTIF(mes_referencia <= mes_corte)       AS qtd_meses_na_janela,
    COUNTIF(mes_referencia > mes_corte)        AS qtd_meses_futuros_excluidos,
    MIN(IF(mes_referencia <= mes_corte, mes_referencia, NULL)) AS mes_inicial,
    MAX(IF(mes_referencia <= mes_corte, mes_referencia, NULL)) AS mes_final,
    SUM(IF(mes_referencia <= mes_corte, receita_cliente, NULL)) AS receita_cliente,
    SUM(IF(mes_referencia <= mes_corte, receita_bv, NULL))      AS receita_bv,
    SUM(IF(mes_referencia <= mes_corte, receita_total, NULL))   AS receita_total,
    SUM(IF(mes_referencia <= mes_corte, deducao, NULL))         AS deducao,
    SUM(IF(mes_referencia <= mes_corte, custo_direto, NULL))    AS custo_direto,
    SUM(IF(mes_referencia <= mes_corte, custo_servico, NULL))   AS custo_servico,
    SUM(IF(mes_referencia <= mes_corte, overhead, NULL))        AS overhead,
    SUM(IF(mes_referencia <= mes_corte, margem_servico, NULL))  AS margem_servico,
    SUM(IF(mes_referencia <= mes_corte, margem_direta, NULL))   AS margem_direta,
    SUM(IF(mes_referencia <= mes_corte, resultado, NULL))       AS resultado
  FROM d
  GROUP BY metodo, chave_cliente, escopo_chave, setor_id
)
SELECT
  CONCAT(metodo, '|', chave_cliente, '|', escopo_chave, '|', IFNULL(CAST(setor_id AS STRING), '-')) AS id_dre_janela,
  metodo,
  grupo_key,
  grupo_nome,
  escopo,
  setor_id,
  eh_nao_atribuido,
  qtd_meses_na_janela,
  qtd_meses_futuros_excluidos,
  mes_inicial,
  mes_final,
  receita_cliente,
  receita_bv,
  receita_total,
  deducao,
  custo_direto,
  custo_servico,
  overhead,
  margem_servico,
  margem_direta,
  resultado,
  SAFE_DIVIDE(IFNULL(resultado, margem_direta), NULLIF(receita_total, 0)) AS margem_pct,
  IF(eh_nao_atribuido, NULL,
     RANK() OVER (PARTITION BY metodo, eh_nao_atribuido ORDER BY IFNULL(resultado, margem_direta) DESC)) AS posicao_ranking_resultado,
  'L3_CONFIDENTIAL'                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                            AS _extraido_at,
  'supabase-x0tz'                                AS _fonte
FROM j
