-- rfn_midia__alcance_semanal
-- Refined / MIDIA. Grao: CONTA x CAMPANHA x SEMANA (segunda-feira) = o grao da Trusted. Chave id_alcance_semanal.
-- Origem: trs_google_ads__alcance_frequencia_campanha_semanal (Prestex, google-ads-OzfZ). Gatilho: evento em query-aGLk.
-- Espelha rfn_midia__alcance_mensal em SEMANA, sem rollup mensal (usuarios unicos nao somam). Nao soma com a mensal.
-- Regras, limitacoes e validacao: na descricao da transformacao na Nekt.
WITH base AS (
  SELECT * FROM `vanguardamartech_trusted`.`trs_google_ads__alcance_frequencia_campanha_semanal`
)
SELECT
  CONCAT(id_conta, '|', id_campanha, '|', FORMAT_DATE('%Y%m%d', semana_inicio)) AS id_alcance_semanal,
  id_conta, cliente, moeda, id_campanha, campanha, status_campanha,
  semana_inicio, semana_fim,
  impressoes,
  -- REGRA 1 - usuarios unicos NAO somam entre semanas nem entre campanhas (a mesma pessoa conta varias vezes): so leitura por linha.
  usuarios_unicos_na_semana,
  frequencia_media_por_usuario                                      AS frequencia_media_plataforma,
  -- REGRA 2 - frequencia calculada = impressoes / usuarios unicos da propria linha; NULL sem alcance (nunca zero).
  ROUND(SAFE_DIVIDE(impressoes, NULLIF(usuarios_unicos_na_semana, 0)), 4) AS frequencia_calculada,
  -- REGRA 3 - NULL de alcance e legitimo (o Google so reporta alcance com impressao); separa quem tem impressao e nao tem alcance.
  (usuarios_unicos_na_semana IS NULL)                               AS flag_sem_alcance,
  (impressoes > 0 AND usuarios_unicos_na_semana IS NULL)            AS flag_impressao_sem_alcance,
  (SAFE_DIVIDE(impressoes, NULLIF(usuarios_unicos_na_semana, 0)) < 1)  AS flag_frequencia_menor_que_um,
  (SAFE_DIVIDE(impressoes, NULLIF(usuarios_unicos_na_semana, 0)) > 50) AS flag_frequencia_extrema,
  flag_semana_incompleta_na_carga,
  flag_conta_nao_catalogada,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  'trs_google_ads__alcance_frequencia_campanha_semanal'             AS _fonte
FROM base
