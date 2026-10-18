-- trs_custo_wl__instancia_mensal
-- Trusted / Custo white-label (VBOT). Grao: uma INSTANCIA de WhatsApp (Z-API) cobrada em um mes.
-- Chave: id_linha = periodo|conta_key|instancia|n (n desempata chave repetida). Nivel: L3 CONFIDENTIAL.
-- O NUMERO DE TELEFONE (numero_pii) NAO e emitido: so os 4 ultimos digitos (L4 evitado).
--
-- ORIGEM. supabase_silver_custo_wl_instancia (1.218 linhas; 1.200 chaves distintas (periodo, conta_key, instancia)).
-- bronze_custo_wl__instancias_qrcode tem 1.427 linhas para 1.200 chaves (versoes) e nao foi usado.
-- Medido em 18/10/2026: 8 periodos, 60 contas (60 de 60 existem em trs_custo_wl__conta_mensal), 8 linhas com valor <= 0.
--
-- 18 LINHAS REPETEM A CHAVE (periodo, conta_key, instancia), em 6 periodos, com valores distintos entre as
-- repetidas: marcadas com flag_chave_repetida, nenhuma apagada. A soma por periodo NAO fecha com o consolidado
-- em 6 de 8 periodos (diferenca de R$ 2,25 a R$ 18,00 a mais no detalhe; exato em fevereiro e junho) e a
-- deduplicacao por MAX(valor) tambem nao fecha: nao ha regra que concilie, entao a tabela nao escolhe.
-- Ver trs_custo_wl__fatura_mensal.diff_instancias.
--
-- LIMITACAO -- NAO CONTORNE: uso_dias e valor sao o que o parceiro cobrou, nao o uso medido pela casa.
SELECT
  CONCAT(i.periodo, '|', i.conta_key, '|', i.instancia, '|',
         CAST(ROW_NUMBER() OVER (PARTITION BY i.periodo, i.conta_key, i.instancia ORDER BY i.valor, i.uso_dias) AS STRING)) AS id_linha,
  i.periodo,
  SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(i.periodo, '-01'))             AS mes_referencia,
  NULLIF(TRIM(i.empresa), '')                                       AS empresa,
  i.conta_key,
  i.instancia,
  NULLIF(TRIM(i.numero_final4), '')                                 AS numero_final4,
  i.uso_dias,
  i.valor                                                           AS valor,
  (COUNT(*) OVER (PARTITION BY i.periodo, i.conta_key, i.instancia) > 1) AS flag_chave_repetida,
  (i.valor <= 0)                                                    AS flag_valor_zerado,
  DATE(i.fetched_at, 'America/Sao_Paulo')                           AS arquivo_lido_em,
  CURRENT_TIMESTAMP()                                               AS _extraido_at,
  'supabase-x0tz'                                                   AS _fonte,
  'America/Sao_Paulo'                                               AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING((SELECT AS STRUCT i.periodo, i.conta_key, i.instancia, i.uso_dias, i.valor)))) AS _payload_hash
FROM `vanguardamartech_raw`.`supabase_silver_custo_wl_instancia` i
