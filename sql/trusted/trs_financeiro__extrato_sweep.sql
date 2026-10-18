-- trs_financeiro__extrato_sweep
-- Trusted / Financeiro. Grao: um sweep (varredura automatica de saldo da conta IP para a conta operacional) e o resultado do casamento com o extrato
-- da conta de destino. 84 linhas (medido em 2026-10-18): 54 CASOU e 30 FORA_COBERTURA_DESTINO; R$ 1.978.275,23; empresas BRM e VD.
-- Origem: vanguardamartech_raw.supabase_gold_vw_eb_sweep_match (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL.
-- Sem chave natural: id_linha = hash do conteudo + ordinal da duplicata. Sweep e movimento entre contas PROPRIAS: nao e receita nem despesa e nao entra em resultado.
-- FORA_COBERTURA_DESTINO = o extrato da conta de destino nao cobre a data do sweep: nao e divergencia, e ausencia de prova.
SELECT
  CONCAT(hash_conteudo, '-', CAST(ROW_NUMBER() OVER (PARTITION BY hash_conteudo ORDER BY data_sweep) AS STRING)) AS id_linha,
  empresa,
  conta_ip,
  data_sweep,
  valor,
  NULLIF(TRIM(destino), '')                      AS destino,
  casou_conta,
  casou_data,
  status                                         AS status_casamento,
  (status = 'CASOU')                             AS is_casou,
  'L3_CONFIDENTIAL'                              AS classificacao_dado,
  CURRENT_TIMESTAMP()                            AS _extraido_at,
  'supabase-x0tz'                                AS _fonte,
  hash_conteudo                                  AS _payload_hash
FROM (
  SELECT m.*, TO_HEX(MD5(TO_JSON_STRING(m))) AS hash_conteudo
  FROM vanguardamartech_raw.supabase_gold_vw_eb_sweep_match m
)
