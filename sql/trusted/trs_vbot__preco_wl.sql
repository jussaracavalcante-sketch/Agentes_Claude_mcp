-- trs_vbot__preco_wl  ·  query-pOn6  ·  Trusted  ·  gatilho: cron segunda 06:00 America/Manaus  ·  alerta de falha ligado  ·  frente H1 (19/10/2026)
-- Trusted / VBOT (white-label). Grao: uma FAIXA DE PRECO de um componente do white-label (usuario, canal, infra, apps, ambiente, Z-API).
-- Chave (componente, faixa): 16 distintos em 16 linhas, 9 componentes, UMA vigencia (2026-01-01), medido em 2026-10-19.
-- Nivel: L3 CONFIDENTIAL (tabela de preco do parceiro white-label, custo da VBOT).
-- ORIGEM: supabase_meta_custo_wl_preco (16), tabela de parametro mantida a mao (atualizado_por ORI-535, 2 atualizacoes em 29/07/2026).
-- `limite` e a QUANTIDADE QUE A FAIXA COMPORTA ALEM DAS ANTERIORES, nao o teto acumulado (ex.: usuario faixa 1 = 17 = do 4o ao 20o,
--   porque os 3 primeiros sao cortesia). NULL em 4 linhas = faixa ABERTA (sem teto): flag_faixa_aberta; nao e ausencia de dado.
-- `valor` = 0 em 3 linhas e CORTESIA/FRANQUIA (canal 0, usuario 0, infra 0 = 5.000 atendimentos): zero e preco real, flag_cortesia marca.
-- `faixa` = 0 e a faixa de cortesia; nao e sentinela.
-- NAO E FATO: nao somar valor entre linhas (R$ por unidade, por conta ou por atendimento conforme o componente, em `obs`).
-- LIMITACAO - NAO CONTORNE: nao ha vigencia fechada (vigente_ate), entao preco anterior a 2026-01 nao existe aqui; a unidade de app_*
--   em trs_vbot__uso_wl_conta_mes NAO e a unidade deste preco (medido: nao reproduz custo_apps).
SELECT
  CONCAT(p.componente, '|', CAST(p.faixa AS STRING))             AS id_preco,
  p.componente,
  p.faixa,
  p.limite                                                       AS limite_quantidade_na_faixa,
  p.valor                                                        AS valor_unitario,
  p.vigente_desde,
  NULLIF(TRIM(p.obs), '')                                        AS descricao,
  NULLIF(TRIM(p.atualizado_por), '')                             AS atualizado_por,
  p.atualizado_em,
  DATETIME(p.atualizado_em, 'America/Sao_Paulo')                 AS atualizado_em_local,
  (p.limite IS NULL)                                             AS flag_faixa_aberta,
  (p.valor = 0)                                                  AS flag_cortesia,
  'L3_CONFIDENTIAL'                                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                                            AS _extraido_at,
  'supabase-x0tz'                                                AS _fonte,
  'America/Sao_Paulo'                                            AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(p)))                                 AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_meta_custo_wl_preco` p
