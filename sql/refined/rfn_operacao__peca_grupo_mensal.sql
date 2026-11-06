-- rfn_operacao__peca_grupo_mensal
-- Refined / operacao. Grao: um MES de referencia x um GRUPO de cliente (grupo_key). Chave: id_peca_grupo_mensal (mes ou 'SEM_MES' | grupo_key).
-- Le trs_iclips__peca_grupo_cliente (uma linha por peca). Nivel: L2 INTERNAL -- o executor vira CONTAGEM DISTINTA; nenhum nome atravessa.
-- REGRA 1: qtd_pecas conta pecas da ponte do Supabase (52.342 em 2026-10-19), que cobre 2024-2026 e NAO e o universo de rfn_operacao__peca
--          (134.883 desde 2020). 7.908 pecas da ponte nao existem na Trusted de peca (qtd_pecas_nao_catalogadas).
-- REGRA 2: o mes e o da ponte, que difere do mes_referencia da peca em 6.961 de 44.434 pares. Para serie de PRODUCAO use rfn_operacao__peca;
--          esta tabela responde "quantas pecas o Supabase atribui a cada GRUPO economico por mes".
-- REGRA 3: mes NULL (ano sentinela 1799, 1.300 pecas) vira a chave 'SEM_MES' e flag_sem_mes -- marcar, nunca apagar nem inventar data.
-- REGRA 4: tipo_chave_grupo separa GRUPO (G:), CNPJ_RAIZ (8 digitos), CPF, NOME e SENTINELA ('(cliente sem receita)', '(peca sem CNPJ)',
--          '(producao interna)'). SENTINELA e nao atribuivel: entra na tabela e no denominador de participacao_no_mes, de proposito --
--          quem quiser so o atribuivel filtra atribuivel = TRUE.
-- REGRA 5: qtd_executores_distintos conta nomes normalizados distintos; 5.562 pecas tem executor fora da pessoa canonica
--          (qtd_pecas_executor_fora_da_canonica) e podem ser a mesma pessoa com grafia diferente -- e piso de pessoas, nao teto.
-- LIMITACOES - NAO CONTORNE: a atribuicao a grupo e regra do Supabase (de-para em supabase_meta_peca_cliente_depara), nao desta casa; nao soma com
--   rfn_operacao__custo_peca (grao e janela diferentes); CNPJ_RAIZ agrupa filiais da mesma PJ, nao e grupo economico declarado.
-- VALIDACAO 2026-10-19 (query inteira rodada sobre a Trusted materializada): 1.341 linhas, 1.341 chaves e hashes, soma de qtd_pecas = 52.342, 116 grupos,
--   64 linhas e 1.300 pecas em SEM_MES, 2.272 pecas nao atribuiveis em 67 linhas, participacao somando 1 por mes (desvio maximo 8e-16).
WITH agg AS (
  SELECT
    mes_referencia,
    grupo_key,
    ANY_VALUE(grupo_nome)                                            AS grupo_nome,
    ANY_VALUE(tipo_chave_grupo)                                      AS tipo_chave_grupo,
    ANY_VALUE(atribuivel)                                            AS atribuivel,
    ANY_VALUE(cnpj_raiz)                                             AS cnpj_raiz,
    COUNT(*)                                                         AS qtd_pecas,
    COUNT(DISTINCT executor_norm)                                    AS qtd_executores_distintos,
    COUNT(DISTINCT id_peca_tipo)                                     AS qtd_tipos_de_peca,
    COUNTIF(flag_peca_nao_catalogada)                                AS qtd_pecas_nao_catalogadas,
    COUNTIF(flag_executor_fora_da_pessoa_canonica)                   AS qtd_pecas_executor_fora_da_canonica,
    COUNTIF(flag_mes_sentinela)                                      AS qtd_pecas_mes_sentinela,
    MAX(_extraido_at)                                                AS _extraido_trusted
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_grupo_cliente`
  GROUP BY mes_referencia, grupo_key
),
calc AS (
  SELECT
    CONCAT(IFNULL(CAST(a.mes_referencia AS STRING), 'SEM_MES'), '|', a.grupo_key) AS id_peca_grupo_mensal,
    a.*,
    (a.mes_referencia IS NULL)                                                   AS flag_sem_mes,
    SAFE_DIVIDE(a.qtd_pecas, SUM(a.qtd_pecas) OVER (PARTITION BY a.mes_referencia)) AS participacao_no_mes
  FROM agg a
)
SELECT c.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c))) AS _payload_hash
FROM calc c
