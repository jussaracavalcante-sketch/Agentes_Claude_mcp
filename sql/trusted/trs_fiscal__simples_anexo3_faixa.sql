-- trs_fiscal__simples_anexo3_faixa  ·  query-yC3x  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / FISCAL. Grao: uma FAIXA do Anexo III do Simples Nacional (LC 123) como parametrizada na casa: teto de RBT12, aliquota nominal,
-- parcela a deduzir e a particao percentual do DAS entre IRPJ, CSLL, COFINS, PIS, CPP e ISS. Chave: faixa. 6 distintos em 6 linhas,
-- medido em 2026-10-19. Nivel: L2 INTERNAL (parametro de lei, sem dado de cliente).
-- ORIGEM: supabase_meta_simples_anexo3 (6), tabela de parametro mantida a mao.
-- NAO CONFERIDA: 5 das 6 faixas estao marcadas pela propria origem como 'nao conferida contra apuracao'; so a faixa 4 e 'CONFERIDA na apuracao
--   06/2026 ao centavo'. Toda simulacao que usa esta tabela herda essa ressalva (trs_fiscal__simples_vbot_mes e _cliente_mes).
-- A PARTICAO SOMA 100 NAS 6 FAIXAS (medido). Na faixa 6 o ISS e 0 (fora do DAS, por lei); na faixa 5 a origem avisa do teto de 5% do ISS.
-- LIMITACAO - NAO CONTORNE: e a tabela VIGENTE sem historico de versao; se a LC 123 mudar, nao ha vigencia aqui.
SELECT
  CAST(a.faixa AS INT64)                                         AS faixa,
  CAST(a.rbt12_ate AS FLOAT64)                                   AS rbt12_ate,
  CAST(a.aliquota_nominal AS FLOAT64)                            AS aliquota_nominal_pct,
  CAST(a.parcela_deduzir AS FLOAT64)                             AS parcela_deduzir,
  CAST(a.p_irpj AS FLOAT64)                                      AS pct_irpj,
  CAST(a.p_csll AS FLOAT64)                                      AS pct_csll,
  CAST(a.p_cofins AS FLOAT64)                                    AS pct_cofins,
  CAST(a.p_pis AS FLOAT64)                                       AS pct_pis,
  CAST(a.p_cpp AS FLOAT64)                                       AS pct_cpp,
  CAST(a.p_iss AS FLOAT64)                                       AS pct_iss,
  CAST(a.conferida AS BOOL)                                      AS is_conferida_na_apuracao,
  NULLIF(TRIM(a.obs), '')                                        AS observacao,
  'L2_INTERNAL'                                                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                                 AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_meta_simples_anexo3` a
