-- trs_financeiro__lancamento_destino
-- Trusted / Financeiro. Grao: um LANCAMENTO do financeiro do iClips com o DESTINO nominal (quem recebe ou paga: nome e CPF/CNPJ) resolvido pelo Supabase.
-- Chave: id_lancamento = codigo do lancamento (44.142 linhas, 44.142 chaves; medido em 2026-10-19). E o mesmo `codigo` que e id_movimento em trs_financeiro__movimento.
-- Origem: vanguardamartech_raw.supabase_meta_iclips_entry_destino (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 07:00 America/Manaus).
-- Nivel: L4 PERSONAL_DATA (nome e CPF do destino: 6.484 lancamentos com CPF; inclui folha e socios).
-- MEDIDO (2026-10-19): 44.034 de 44.142 (99,76%) casam com trs_financeiro__movimento por codigo; os 108 sem par sao todos `A Receber` (flag_lancamento_nao_catalogado) ·
--   1.394 destinos distintos · tipo: Saída 27.973 · Entrada 14.401 · A Receber 941 · A Pagar 827 (o tipo concorda com o sentido do movimento em 100% dos casados) ·
--   documento: 32.627 CNPJ (14) · 6.484 CPF (11) · 5.031 sem documento (4.537 vazios na origem; o resto e o documento so com pontuacao nao-numerica) · ZERO com 13 digitos ou outra forma (nao ha repadronizacao a fazer) · 2.767 sem nome ·
--   fetched_at de 2026-07-12 a 2026-09-29 (UTC; horas 08 e 19-22 UTC = rotina de extracao, nao evento de negocio).
-- LIMITACOES - NAO CONTORNE: nao traz valor nem data do lancamento (isso esta em trs_financeiro__movimento: junte por id_lancamento = id_movimento); o destino e o CADASTRO
--   do iClips na data da extracao; NAO publicar em painel sem filtrar is_pf = FALSE quando o assunto for fornecedor (CPF aqui e folha/socio/PF).
WITH origem AS (
  SELECT
    e.*,
    NULLIF(REGEXP_REPLACE(IFNULL(e.destino_doc, ''), r'[^0-9]', ''), '')   AS documento_origem
  FROM `vanguardamartech_raw`.`supabase_meta_iclips_entry_destino` e
),
mov AS (
  SELECT DISTINCT id_movimento FROM `vanguardamartech_trusted`.`trs_financeiro__movimento`
),
final AS (
  SELECT
    CAST(o.codigo AS STRING)                                         AS id_lancamento,
    o.destino_id                                                     AS id_destino,
    NULLIF(TRIM(o.destino_nome), '')                                 AS destino_nome,
    IF(LENGTH(o.documento_origem) IN (11, 14), o.documento_origem, NULL) AS documento,
    o.documento_origem,
    (o.documento_origem IS NOT NULL AND LENGTH(o.documento_origem) NOT IN (11, 14)) AS flag_documento_invalido,
    (o.documento_origem IS NULL)                                     AS flag_sem_documento,
    o.tipo                                                           AS tipo_origem,
    CASE o.tipo
      WHEN 'A Pagar'   THEN 'SAIDA'
      WHEN 'Saída'     THEN 'SAIDA'
      WHEN 'A Receber' THEN 'ENTRADA'
      WHEN 'Entrada'   THEN 'ENTRADA'
    END                                                              AS sentido,
    (o.tipo IN ('A Pagar', 'A Receber'))                             AS is_titulo_em_aberto_na_origem,
    o.fetched_at,
    DATETIME(o.fetched_at, 'America/Sao_Paulo')                      AS fetched_at_local,
    (m.id_movimento IS NULL)                                         AS flag_lancamento_nao_catalogado
  FROM origem o
  LEFT JOIN mov m ON m.id_movimento = CAST(o.codigo AS STRING)
)
SELECT
  f.*,
  (LENGTH(f.documento) = 14)         AS is_pj,
  (LENGTH(f.documento) = 11)         AS is_pf,
  'L4_PERSONAL_DATA'                 AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
