-- rfn_operacao__auditoria_ciclo_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: um mes de FINALIZACAO do ciclo de auditoria (ou 'EM_ABERTO'). Le: trs_vjob__auditoria_ciclo. Gatilho: evento em query-w4wL.
-- Identidade (07/10/2026): 58 ciclos · 3.117 itens · 1.654 ativos · 1.571 feitos · 55 arquivos — iguais a Trusted.
-- R1 taxa_conclusao = feitos / itens ATIVOS (item inativo saiu do checklist, nao e atraso); NULL sem item ativo.
-- R2 2 ciclos tem mais feitos que ativos (marcacao sobre item inativo): qtd_ciclos_feitos_acima_dos_ativos torna visivel, nada e cortado — por isso taxa_conclusao pode passar de 1 numa linha (maximo medido 1,0141).
-- R3 qtd_contas e distinto DENTRO da linha; nao soma entre linhas. R4 36 dos 58 ciclos nao registram quem abriu; so contagem, nome nao atravessa.
-- R5 O ciclo ja e agregado (grao do ciclo); aqui ele so ganha o eixo mensal.
WITH c AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_ciclo`
),
agg AS (
  SELECT
    DATE_TRUNC(DATE(finalizado_em), MONTH) AS mes_finalizacao,
    is_finalizado,
    COUNT(*) AS qtd_ciclos,
    SUM(qtd_itens) AS qtd_itens,
    SUM(qtd_itens_ativos) AS qtd_itens_ativos,
    SUM(qtd_itens_feitos) AS qtd_itens_feitos,
    COUNTIF(qtd_itens_feitos > qtd_itens_ativos) AS qtd_ciclos_feitos_acima_dos_ativos,
    SUM(qtd_arquivos) AS qtd_arquivos,
    COUNTIF(flag_sem_autor) AS qtd_ciclos_sem_autor,
    COUNTIF(flag_sem_evidencia) AS qtd_ciclos_sem_evidencia,
    COUNT(DISTINCT id_atendimento) AS qtd_contas,
    COUNTIF(flag_conta_nao_catalogada) AS qtd_ciclos_conta_nao_catalogada,
    COUNTIF(flag_status_sem_carimbo) AS qtd_ciclos_status_sem_carimbo
  FROM c
  GROUP BY 1, 2
),
final AS (
  SELECT
    CONCAT(IFNULL(CAST(mes_finalizacao AS STRING), 'EM_ABERTO'), '|', CAST(is_finalizado AS STRING)) AS id_ciclo_mensal,
    a.*,
    IF(qtd_itens_ativos = 0, NULL, ROUND(SAFE_DIVIDE(qtd_itens_feitos, qtd_itens_ativos), 4)) AS taxa_conclusao,
    'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
