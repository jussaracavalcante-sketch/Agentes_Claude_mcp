-- trs_fiscal__simples_vbot_cliente_mes  ·  query-RD2A  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / FISCAL (VBOT). Grao: um CLIENTE (cliente_key) em um PERIODO (mes) da SIMULACAO do Simples Nacional da VBOT: receita do Conexa,
-- margem liquida (receita menos custo do white-label), se o cliente e da Zona Franca (ZFM), aliquota e DAS simulado e margem pos-tributo.
-- Chave (periodo, cliente_key): 619 distintos em 619 linhas, 12 periodos (2025-12 a 2026-11), 110 clientes, medido em 2026-10-19.
-- Nivel: L3 CONFIDENTIAL (receita e tributo simulado por cliente).
--
-- ISTO E SIMULACAO, NAO APURACAO: o Simples e apurado pela PJ (VBOT) sobre a receita bruta total, nunca por cliente. O rateio por cliente
-- e exercicio gerencial da origem, com tabela de faixas NAO CONFERIDA (ver trs_fiscal__simples_vbot_mes). NAO APRESENTAR COMO TRIBUTO.
--
-- ORIGEM: supabase_gold_vw_simples_vbot_cliente (619; o catalogo dizia 618). As 619 existem em trs_vbot__margem_cliente por (periodo, cliente_key).
-- METODO DA ORIGEM, MEDIDO (nao recalculado): aliquota_efetiva e a do mes (619 de 619 iguais a trs_fiscal__simples_vbot_mes);
--   simples_simulado = receita_conexa x aliquota_APLICADA/100, onde a aplicada e aliq_sem_pis_cofins do mes para cliente ZFM (suspensao de
--   PIS/COFINS) e aliquota_efetiva cheia para os demais: reproduz em 619 de 619. margem_pos_tributo = margem_liquida - simples_simulado (619 de 619).
--   aliquota_aplicada_pct vem do JOIN com a view do mes e e emitida para a leitura nao precisar refazer essa escolha.
-- ZFM: 463 linhas e 81 clientes marcados ZFM; nenhum cliente muda de ZFM entre periodos; zfm_incerto = FALSE nas 619 (campo sem uso hoje).
-- A SOMA POR PERIODO NAO FECHA COM O DAS DO MES (11 de 12 periodos), porque a view do mes aplica a suspensao a receita inteira e esta so aos
--   clientes ZFM: diferenca de metodo da origem, declarada e nao corrigida. Quem quiser o total use trs_fiscal__simples_vbot_mes.
-- LIMITACAO - NAO CONTORNE: a ligacao cliente -> custo e por NOME (herdada de trs_vbot__margem_cliente); margem_liquida ja desconta o
--   custo do white-label e NAO desconta outros custos da VBOT; 2026-11 e periodo futuro parcial (3 linhas).
SELECT
  CONCAT(s.periodo, '|', s.cliente_key)                          AS id_cliente_mes,
  s.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(s.periodo, '-01'))          AS mes_referencia,
  'SIMULACAO_NAO_CONFERIDA'                                      AS natureza,
  s.cliente_key,
  NULLIF(TRIM(s.cliente), '')                                    AS cliente,
  s.receita_conexa,
  s.margem_liquida,
  s.zfm                                                          AS is_zfm,
  s.zfm_incerto                                                  AS is_zfm_incerto,
  s.aliquota_efetiva                                             AS aliquota_efetiva_pct,
  IF(s.zfm, m.aliq_sem_pis_cofins, s.aliquota_efetiva)           AS aliquota_aplicada_pct,
  s.simples_simulado,
  s.margem_pos_tributo,
  (s.margem_liquida < 0)                                         AS flag_margem_negativa,
  (s.margem_pos_tributo < 0)                                     AS flag_margem_pos_tributo_negativa,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(s)))                                 AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_gold_vw_simples_vbot_cliente` s
LEFT JOIN `vanguardamartech_raw`.`supabase_gold_vw_simples_vbot_mes` m
  ON m.periodo = s.periodo
