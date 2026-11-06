-- rfn_qualidade__regra_linkedin · 13 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Cobre as 2 Trusted e as 2 Refined do LinkedIn (fonte linkedin-X9nQ, AC Display).
-- Gatilho: evento (regra all) nas duas Refined, que ja esperam as duas Trusted. Alerta de falha ligado. Cadencia SEMANAL (a fonte roda segunda 00:00 America/Manaus).
-- Suite propria pelo mesmo motivo das anteriores: a principal esta em 57 KB e update_transformation substitui o codigo inteiro.
-- Contrato de colunas identico ao das outras suites (UNION ALL entre elas da o painel unico; `familia` diz a origem).
WITH d AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linkedin__pagina_dia`),
t AS (SELECT * FROM `vanguardamartech_trusted`.`trs_linkedin__pagina_total`),
m AS (SELECT * FROM `vanguardamartech_refined`.`rfn_social__linkedin_pagina_mensal`),
s AS (SELECT * FROM `vanguardamartech_refined`.`rfn_social__linkedin_pagina_resumo`),
r AS (
  SELECT 'trs_linkedin__pagina_dia.id_unico' AS id_regra, 'Trusted' AS camada, 'trs_linkedin__pagina_dia' AS tabela, 'LinkedIn' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pagina_dia e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pagina_dia) + COUNTIF(id_pagina_dia IS NULL) AS linhas_falha FROM d
  UNION ALL
  SELECT 'trs_linkedin__pagina_dia.data_preenchida', 'Trusted', 'trs_linkedin__pagina_dia', 'LinkedIn', 'COMPLETUDE',
         'data nunca nula (a chave nasce dela)', 'BLOQUEANTE', 1.00, COUNT(*), COUNTIF(data IS NULL) FROM d
  UNION ALL
  SELECT 'trs_linkedin__pagina_dia.data_nao_futura', 'Trusted', 'trs_linkedin__pagina_dia', 'LinkedIn', 'VALIDADE',
         'data nao e posterior ao dia seguinte da carga (margem de um dia: o fuso de corte do LinkedIn nao e declarado)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data > DATE_ADD(DATE(_extraido_at, 'America/Sao_Paulo'), INTERVAL 1 DAY)) FROM d
  UNION ALL
  SELECT 'trs_linkedin__pagina_dia.flags_concordam', 'Trusted', 'trs_linkedin__pagina_dia', 'LinkedIn', 'VALIDADE',
         'flag_sem_post_analytics acende exatamente quando impressoes e nulo, e flag_sem_seguidores quando seguidores_novos e nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_post_analytics <> (impressoes IS NULL) OR flag_sem_seguidores <> (seguidores_novos IS NULL)) FROM d
  UNION ALL
  SELECT 'trs_linkedin__pagina_dia.medidas_nao_negativas', 'Trusted', 'trs_linkedin__pagina_dia', 'LinkedIn', 'VALIDADE',
         'impressoes, reacoes, comentarios, compartilhamentos, salvamentos e envios nunca negativos (seguidores_novos e liquido e pode ser)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(impressoes < 0 OR reacoes < 0 OR comentarios < 0 OR compartilhamentos < 0 OR salvamentos < 0 OR envios < 0) FROM d
  UNION ALL
  SELECT 'trs_linkedin__pagina_total.uma_linha_por_pagina', 'Trusted', 'trs_linkedin__pagina_total', 'LinkedIn', 'UNICIDADE',
         'uma linha por fonte (fotografia FULL_SYNC)', 'BLOQUEANTE', 1.00,
         COUNT(DISTINCT _fonte), COUNT(*) - COUNT(DISTINCT _fonte) FROM t
  UNION ALL
  -- Alcance deduplicado nao pode passar das impressoes; se passar, o total veio com colunas trocadas.
  SELECT 'trs_linkedin__pagina_total.alcance_nao_excede_impressoes', 'Trusted', 'trs_linkedin__pagina_total', 'LinkedIn', 'VALIDADE',
         'membros_alcancados nao excede impressoes_acumuladas (625 de 3.355 na medicao)', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(membros_alcancados > impressoes_acumuladas) FROM t
  UNION ALL
  SELECT 'rfn_social__linkedin_pagina_mensal.id_unico', 'Refined', 'rfn_social__linkedin_pagina_mensal', 'LinkedIn', 'UNICIDADE',
         'id_pagina_mes e unico e nunca nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_pagina_mes) + COUNTIF(id_pagina_mes IS NULL) FROM m
  UNION ALL
  -- Identidades entre camadas (grao de 1 linha: total contra total). A Refined agrega e nao filtra.
  SELECT 'rfn_social__linkedin_pagina_mensal.dias_reproduzem_a_trusted', 'Refined', 'rfn_social__linkedin_pagina_mensal', 'LinkedIn', 'INTEGRIDADE',
         'soma de qtd_dias nos meses = numero de dias da Trusted', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_dias) FROM m) = (SELECT COUNT(*) FROM d), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_social__linkedin_pagina_mensal.impressoes_reproduzem_a_trusted', 'Refined', 'rfn_social__linkedin_pagina_mensal', 'LinkedIn', 'INTEGRIDADE',
         'soma de impressoes e de seguidores_novos nos meses = soma da Trusted', 'BLOQUEANTE', 1.00,
         1, IF(IFNULL((SELECT SUM(impressoes) FROM m), 0) = IFNULL((SELECT SUM(impressoes) FROM d), 0)
               AND IFNULL((SELECT SUM(seguidores_novos) FROM m), 0) = IFNULL((SELECT SUM(seguidores_novos) FROM d), 0), 0, 1) FROM UNNEST([1])
  UNION ALL
  SELECT 'rfn_social__linkedin_pagina_resumo.uma_linha_por_pagina', 'Refined', 'rfn_social__linkedin_pagina_resumo', 'LinkedIn', 'UNICIDADE',
         'uma linha por fonte e o mesmo numero de paginas da Trusted de total', 'BLOQUEANTE', 1.00,
         (SELECT COUNT(*) FROM t), IF((SELECT COUNT(*) FROM s) = (SELECT COUNT(*) FROM t) AND (SELECT COUNT(DISTINCT fonte) FROM s) = (SELECT COUNT(*) FROM s), 0, 1) FROM UNNEST([1])
  UNION ALL
  -- A serie diaria e subconjunto do acumulado: se as impressoes dela passarem do acumulado, o total e outro periodo ou a coluna esta trocada.
  SELECT 'rfn_social__linkedin_pagina_resumo.serie_nao_excede_o_acumulado', 'Refined', 'rfn_social__linkedin_pagina_resumo', 'LinkedIn', 'INTEGRIDADE',
         'impressoes da serie diaria nao excedem as acumuladas (3 de 3.355 na medicao)', 'ALERTA', 1.00,
         COUNTIF(impressoes_na_serie IS NOT NULL), COUNTIF(impressoes_na_serie > impressoes_acumuladas) FROM s
  UNION ALL
  -- Frescor: as duas Trusted vem da mesma fonte e do mesmo gatilho; data de carga diferente = uma delas ficou numa passada anterior.
  SELECT 'linkedin.carga_do_mesmo_dia', 'Trusted', 'trs_linkedin__pagina_dia+pagina_total', 'LinkedIn', 'INTEGRIDADE',
         'as duas Trusted foram escritas no mesmo dia', 'BLOQUEANTE', 1.00,
         1, IF((SELECT MAX(DATE(_extraido_at)) FROM d) = (SELECT MAX(DATE(_extraido_at)) FROM t), 0, 1) FROM UNNEST([1])
  -- Sem LIMIT: no ultimo ramo de um UNION ALL ele vale para a uniao inteira.
),
avaliado AS (
  SELECT r.*, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'LinkedIn' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'linkedin-X9nQ' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
