-- rfn_operacao__config_cliente_resumo  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: uma origem de configuracao recorrente por conta (CHECKIN_SEMANAL, CHECKIN_SOCIAL, CHECKLIST_CLIENTE, ROTINA, DISTRIBUICAO_ESCOPO, AVALIACAO_CS) x estado do flag ativo.
-- Le: trs_vjob__config_cliente. Gatilho: evento em query-IJEg. Identidade (07/10/2026): 164 registros = 164. Titulo nao atravessa.
-- R1 estado_ativo e TRUE/FALSE/NULO e NULO nao e inativo: AVALIACAO_CS e CHECKLIST_CLIENTE nao carregam o flag. R2 qtd_contas e distinto DENTRO da linha.
-- R3 CHECKIN_SEMANAL e CHECKIN_SOCIAL cobrem 61 e 53 contas; as outras origens cobrem 1 ou 2 — configuracao recorrente existe para uma fracao pequena da carteira.
-- R4 qtd_dia_semana_fora = 1 registro com dia da semana fora de 1 a 7 (defeito de origem, marcado e nao corrigido).
WITH c AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__config_cliente`
),
agg AS (
  SELECT
    origem,
    IFNULL(CAST(ativo AS STRING), 'NULO') AS estado_ativo,
    COUNT(*) AS qtd_registros,
    COUNT(DISTINCT id_conta_atendimento) AS qtd_contas,
    COUNTIF(atualizado_em IS NOT NULL) AS qtd_com_atualizacao,
    MAX(atualizado_em) AS ultima_atualizacao,
    COUNTIF(CAST(gera_automaticamente AS STRING) IN ('true', '1')) AS qtd_gera_automaticamente,
    COUNTIF(CAST(obrigatorio AS STRING) IN ('true', '1')) AS qtd_obrigatorio,
    COUNTIF(CAST(feito AS STRING) IN ('true', '1')) AS qtd_feito,
    COUNTIF(flag_dia_semana_fora_de_1_a_7) AS qtd_dia_semana_fora,
    COUNTIF(flag_conta_nao_catalogada) AS qtd_conta_nao_catalogada
  FROM c
  GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(origem, '|', estado_ativo) AS id_config_resumo, a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
