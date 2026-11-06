-- rfn_financeiro__dicionario_resumo  ·  Refined / financeiro  ·  L2 INTERNAL (a Trusted e L3; chave, valor, CNPJ de veiculo e grupo de cliente NAO atravessam -- so contagens)
-- Grao: uma ORIGEM (tabela meta_* de de-para ou parametro da gestao financeira do Supabase), 17 origens.
-- Le: trs_financeiro__dicionario (query-ieUJ). Gatilho: evento em query-ieUJ.
-- Identidade (19/10/2026): 1.749 entradas = 1.749 · 17 origens · 9 sem chave (todas CADASTRO_CLIENTE_ICLIPS, CNPJ vazio) · 20 sem valor (17 VBOT_GRUPO_CLIENTE por desenho, 2 DEPARA_CLIENTE, 1 DRE_NAO_RECORRENTE) · 3 chaves repetidas (ordinal > 1).
-- R1 Descreve o CATALOGO de parametros (tamanho, cobertura de chave e valor, status, manutencao), nao o uso: nao ha contagem de quantos lancamentos cada de-para classifica.
-- R2 status e texto livre da origem: ativo (PARAM_NO, PARAM_DEPARA, CLIENTE_GRUPO, FIN_VEICULO, DRE_NAO_RECORRENTE, DEPARA_CLIENTE), revisar (CLIENTE_HOUSING 22), sem_match (DEPARA_CLIENTE); as demais origens nao tem status -- NULL e ausencia de coluna, nao 'inativo'.
-- R3 atualizado_em so existe em parte das origens (PARAM_DEPARA 404 de 629, PARAM_NO 441 de 507, DRE_CLIENTE_CRITERIO 15 de 57, CLIENTE_HOUSING 3 de 22); ultima_atualizacao da origem e 2026-09-04.
-- R4 qtd_chave_repetida e o que a chave composta (origem, chave, chave_2) nao segura sozinha: 3 linhas receberam ordinal 2 -- a Trusted preserva as duas; aqui so se conta.
-- LIMITACAO -- NAO CONTORNE: grupo de cliente aqui e decisao do SUPABASE e nao vale como chave de conta (R-003); esta Refined nao emite grupo nenhum.
WITH d AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_financeiro__dicionario`
),
agg AS (
  SELECT
    origem,
    COUNT(*)                                                      AS qtd_entradas,
    COUNT(DISTINCT CONCAT(IFNULL(chave, ''), '|', IFNULL(chave_2, ''))) AS qtd_chaves_distintas,
    COUNTIF(chave IS NULL)                                        AS qtd_sem_chave,
    COUNTIF(chave_2 IS NOT NULL)                                  AS qtd_com_chave_2,
    COUNTIF(valor IS NULL)                                        AS qtd_sem_valor,
    COUNTIF(valor_2 IS NOT NULL)                                  AS qtd_com_valor_2,
    COUNTIF(status = 'ativo')                                     AS qtd_status_ativo,
    COUNTIF(status = 'inativo')                                   AS qtd_status_inativo,
    COUNTIF(status = 'revisar')                                   AS qtd_status_revisar,
    COUNTIF(status = 'sem_match')                                 AS qtd_status_sem_match,
    COUNTIF(status IS NULL)                                       AS qtd_sem_status,
    COUNTIF(obs IS NOT NULL)                                      AS qtd_com_obs,
    COUNTIF(atributos_json IS NOT NULL)                           AS qtd_com_atributos_json,
    COUNTIF(atualizado_em IS NOT NULL)                            AS qtd_com_atualizacao,
    MAX(DATE(atualizado_em, 'America/Sao_Paulo'))                 AS ultima_atualizacao,
    COUNTIF(NOT ENDS_WITH(id_linha, '|1'))                        AS qtd_chave_repetida
  FROM d
  GROUP BY origem
),
final AS (
  SELECT origem AS id_dicionario_resumo, g.*, 'L2_INTERNAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
