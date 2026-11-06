-- rfn_operacao__job_horas_mensal  ·  Refined / operacao  ·  L2 INTERNAL
-- Grao: mes de abertura do job x filial x status, do fato de horas por job do iClips (derivado Supabase).
-- Le: trs_iclips__job_horas (query-hDS9, L3). Gatilho: evento em query-hDS9. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 2.899 jobs = 2.899 · 288 linhas, 288 chaves · 21.017,74 h realizadas ·
--   681,14 h estimadas em 214 jobs · 527 jobs com projeto nao catalogado · 45 meses (2017-04 a 2026-09) · 15 filiais · 4 status.
-- R1 O responsavel (nome) NAO atravessa: sai so qtd_responsaveis_distintos. Cliente sai so como contagem distinta de id.
-- R2 horas_estimadas e NULL quando nenhum job do grupo tem estimativa (224 das 288 linhas): zero seria lido como "estimou zero".
--    media_horas_por_job_com_hora divide pelos jobs COM hora > 0 (exclui NULL e zero), nunca pelo total de jobs.
-- R3 Hora realizada e medida declarada pelo derivado, nao auditada (ver Trusted); NAO vira custo (a casa decidiu custo por peca).
-- R4 filial e status NULL virariam '(sem filial)'/'(sem status)' (nao ha hoje).
-- LIMITACAO -- NAO CONTORNE: nao ha valor, custo nem prazo; horas_realizadas NAO se reconcilia com trs_iclips__apontamento
--   (janela movel de 2 meses, 2.334,7 h). O mes e o de ABERTURA do job, nao o de execucao da hora.
WITH j AS (SELECT * FROM `vanguardamartech_trusted`.`trs_iclips__job_horas`),
agg AS (
  SELECT
    DATE_TRUNC(data_abertura, MONTH) AS mes_abertura,
    IFNULL(filial, '(sem filial)') AS filial,
    IFNULL(status, '(sem status)') AS status,
    COUNT(*) AS qtd_jobs,
    COUNT(DISTINCT id_cliente_iclips) AS qtd_clientes_distintos,
    COUNT(DISTINCT responsavel) AS qtd_responsaveis_distintos,
    IF(COUNTIF(horas_realizadas IS NOT NULL) = 0, NULL, SUM(horas_realizadas)) AS horas_realizadas,
    COUNTIF(horas_realizadas IS NULL) AS qtd_sem_horas_realizadas,
    COUNTIF(horas_realizadas = 0) AS qtd_horas_realizadas_zero,
    MAX(horas_realizadas) AS maior_job_horas_realizadas,
    IF(COUNTIF(tem_horas_estimadas) = 0, NULL, SUM(horas_estimadas)) AS horas_estimadas,
    COUNTIF(tem_horas_estimadas) AS qtd_com_horas_estimadas,
    COUNTIF(flag_projeto_nao_catalogado) AS qtd_projeto_nao_catalogado,
    MAX(derivado_atualizado_em) AS derivado_atualizado_em
  FROM j
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(FORMAT_DATE('%Y-%m', mes_abertura), '|', filial, '|', status) AS id_job_horas_mensal,
         a.*,
         SAFE_DIVIDE(horas_realizadas, NULLIF(qtd_jobs - qtd_sem_horas_realizadas - qtd_horas_realizadas_zero, 0)) AS media_horas_por_job_com_hora,
         'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
