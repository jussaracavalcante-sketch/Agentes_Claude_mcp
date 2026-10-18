-- trs_contazul__venda_item
-- Trusted / Conta Azul. Grao: um item de venda. Chave: id_venda_item (3.454 distintos em 3.454, medido em 2026-10-18).
-- Origem: vanguardamartech_raw.supabase_conta_azul_ca_fato_venda_item (fonte supabase-x0tz). Nivel: L3 CONFIDENTIAL.
-- Zero orfaos contra trs_contazul__venda (3.454 de 3.454 itens encontram a venda). A coluna `custo` da origem e
-- CAMPO MORTO (zero em 3.454 linhas, medido em 2026-10-18) e NAO e emitida: emitida, convidaria a somar e obter zero.
-- valor_total do item NAO soma com o da venda sem conferir (a venda pode ter itens de venda removida).
SELECT
  id_venda_item,
  id_venda,
  operacao,
  seq_item,
  id_produto,
  NULLIF(TRIM(nome), '')                        AS nome_item,
  NULLIF(TRIM(descricao), '')                   AS descricao,
  NULLIF(TRIM(tipo), '')                        AS tipo_item,
  quantidade,
  valor_unitario,
  valor_total,
  id_centro_custo,
  processed_at,
  'L3_CONFIDENTIAL'                             AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(i)))                AS _payload_hash
FROM vanguardamartech_raw.supabase_conta_azul_ca_fato_venda_item i
