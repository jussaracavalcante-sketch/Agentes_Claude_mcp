-- rfn_operacao__dominio_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um dominio (tabela de rotulos) do VJOB. Le: trs_vjob__dominio. Gatilho: evento em query-OEnU. Identidade (07/10/2026): 406 itens = 406 · 34 dominios.
-- R1 O flag ativo so existe em 15 dos 406 itens (391 NULOS): NULO nao e inativo; qtd_sem_flag_ativo mostra o tamanho. R2 39 itens tem pai fora do dominio de origem (flag_pai_nao_catalogado).
-- R3 Esta tabela descreve o CATALOGO (quantos rotulos cada dominio tem), nao o uso: nao ha contagem de quem usa cada rotulo. Nome do item nao atravessa.
WITH d AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__dominio`
),
final AS (
  SELECT
    dominio AS id_dominio,
    COUNT(*) AS qtd_itens,
    COUNT(DISTINCT tabela_origem) AS qtd_tabelas_origem,
    COUNTIF(ativo IS TRUE) AS qtd_ativos,
    COUNTIF(ativo IS FALSE) AS qtd_inativos,
    COUNTIF(ativo IS NULL) AS qtd_sem_flag_ativo,
    COUNTIF(id_pai IS NOT NULL) AS qtd_com_pai,
    COUNTIF(flag_pai_nao_catalogado) AS qtd_pai_nao_catalogado,
    COUNTIF(flag_sem_nome) AS qtd_sem_nome,
    COUNTIF(codigo IS NOT NULL) AS qtd_com_codigo,
    'L2_INTERNAL' AS classificacao_dado
  FROM d
  GROUP BY 1
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
