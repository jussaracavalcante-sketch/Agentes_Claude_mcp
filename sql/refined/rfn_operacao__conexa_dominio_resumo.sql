-- rfn_operacao__conexa_dominio_resumo  ·  query-6Y5l  ·  Refined  ·  gatilho: evento em query-RC2E  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Refined / operacao. Grao: um DOMINIO (tabela de rotulos) do Conexa, sistema da VBOT. Le: trs_conexa__dominio (329). Gatilho: evento em query-RC2E.
-- Nivel: L2 INTERNAL (so contagem; nome, documento, preco e nome de colaborador NAO atravessam).
-- Identidade (2026-10-19): 329 itens = 329 · 8 dominios (CATEGORIA_RECEITA 11, CONTA_FINANCEIRA 9, FORNECEDOR 83, MOTIVO_CHURN 4, PLANO 7, PRODUTO 34,
-- SUBCATEGORIA_DESPESA 86, USUARIO 95).
-- R1 Descreve o CATALOGO (quantos rotulos cada dominio tem e quantos estao ativos), nao o uso: nao ha contagem de quem usa cada rotulo.
-- R2 is_ativo existe em 6 dos 8 dominios; FORNECEDOR (83) e MOTIVO_CHURN (4) tem a flag NULA em todas as linhas (87 itens): NULO nao e inativo; qtd_sem_flag_ativo mostra.
-- R3 qtd_com_documento conta so documento VALIDO (11 ou 14 digitos; 11 fornecedores); qtd_documento_invalido e zero hoje. qtd_sem_nome = 4 (os motivos
--    de churn, cujo nome NAO existe no Conexa publicado).
-- R4 CATEGORIA_RECEITA e SUBCATEGORIA_DESPESA sao planos de contas DIFERENTES e nao se juntam por id (herdado da Trusted).
-- LIMITACAO - NAO CONTORNE: nao somar qtd_com_valor_numerico entre dominios como se fosse faturamento (e preco de catalogo de plano e produto).
WITH d AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_conexa__dominio`
),
final AS (
  SELECT
    dominio                                                       AS id_dominio,
    dominio,
    COUNT(*)                                                      AS qtd_itens,
    COUNTIF(is_ativo IS TRUE)                                     AS qtd_ativos,
    COUNTIF(is_ativo IS FALSE)                                    AS qtd_inativos,
    COUNTIF(is_ativo IS NULL)                                     AS qtd_sem_flag_ativo,
    COUNTIF(flag_sem_nome)                                        AS qtd_sem_nome,
    COUNTIF(id_pai IS NOT NULL)                                   AS qtd_com_pai,
    COUNTIF(valor_numerico IS NOT NULL)                           AS qtd_com_valor_numerico,
    COUNTIF(documento IS NOT NULL)                                AS qtd_com_documento,
    COUNTIF(flag_documento_invalido)                              AS qtd_documento_invalido,
    COUNTIF(exige_nf IS TRUE)                                     AS qtd_exige_nf,
    COUNTIF(sujeita_juros_atraso IS TRUE)                         AS qtd_sujeita_juros_atraso,
    COUNTIF(conta_como_churn IS TRUE)                             AS qtd_conta_como_churn,
    MAX(derivado_atualizado_em)                                   AS derivado_atualizado_em,
    'L2_INTERNAL'                                                 AS classificacao_dado
  FROM d
  GROUP BY dominio
)
SELECT x.*,
  CURRENT_TIMESTAMP()                                             AS _extraido_at,
  'supabase-x0tz'                                                 AS _fonte,
  'America/Sao_Paulo'                                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(x)))                                  AS _payload_hash
FROM final x
