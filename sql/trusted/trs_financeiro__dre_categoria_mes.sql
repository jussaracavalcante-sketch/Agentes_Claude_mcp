-- trs_financeiro__dre_categoria_mes
-- Trusted / Financeiro. Grao: uma LINHA DE DRE (ordem + rotulo + tipo) de uma operacao em um mes de competencia, calculada pelo Supabase sobre o razao do Conta Azul.
-- Chave: id_dre_mes = <operacao>|<mes>|<ordem>|<dre_linha>|<tipo_categoria> (353 linhas, 353 chaves; 1 linha chega com ordem, rotulo e tipo NULOS e entra como SEM_CLASSIFICACAO).
-- Origem: vanguardamartech_raw.supabase_conta_azul_vw_dre_mensal (fonte supabase-x0tz, diaria). Cadencia desta Trusted: semanal (segunda 06:35 America/Manaus).
-- Nivel: L3 CONFIDENTIAL (resultado por operacao).
-- MEDIDO (2026-10-19): 9 linhas de DRE (ordens 1, 2, 4, 5, 6, 7, 90, 91), 2 operacoes, 2026-06 a 2033-07 (265 linhas em mes posterior a hoje: parcelas futuras do razao) ·
--   SUM(resultado) R$ 732.951,25 · SUM(valor_bruto) R$ 32.121.761,33 · 5.157 parcelas.
-- SINAL: `resultado` = +valor_bruto nas linhas RECEITA e = -valor_bruto nas 264 linhas DESPESA (zero excecoes) - somar `resultado` da o resultado do DRE; somar `valor_bruto` da o volume.
-- A DIVERGENCIA DE PARCELAS ESTA EXPLICADA: as 5.157 parcelas desta view sao EXATAMENTE as parcelas vigentes de trs_contazul__movimento com competencia >= 2026-06 (5.157 = 5.157
--   em 2026-10-19). O "3.073 do fechamento" da triagem de 18/10 era outro recorte (so parcelas com classificacao DRE no fechamento); as linhas 90/91 "nao classificadas"
--   carregam 165 linhas e a maior parte da diferenca. NAO e erro de extracao.
-- LIMITACOES - NAO CONTORNE: competencia, nao caixa; comeca em 2026-06 (handoff iClips -> Conta Azul: nao soma com trs_financeiro__dre_lancamento, que e o DRE do iClips);
--   as ordens 90 e 91 sao parcela SEM classificacao de DRE e NAO sao resultado operacional; a cadencia semanal pode atrasar ate 6 dias contra a view diaria.
WITH origem AS (
  SELECT
    d.*,
    NULLIF(REGEXP_REPLACE(IFNULL(d.cnpj, ''), r'[^0-9]', ''), '')   AS cnpj_operacao_digitos
  FROM `vanguardamartech_raw`.`supabase_conta_azul_vw_dre_mensal` d
),
final AS (
  SELECT
    CONCAT(operacao, '|', CAST(mes AS STRING), '|', IFNULL(CAST(ordem AS STRING), '~'), '|', IFNULL(dre_linha, 'SEM_CLASSIFICACAO'), '|', IFNULL(tipo_categoria, '~'))
                                                                    AS id_dre_mes,
    operacao,
    cnpj_operacao_digitos                                           AS cnpj_operacao,
    mes                                                             AS mes_referencia,
    ordem,
    NULLIF(TRIM(dre_linha), '')                                     AS dre_linha,
    tipo_categoria,
    (tipo_categoria = 'RECEITA')                                    AS is_receita,
    (tipo_categoria = 'DESPESA')                                    AS is_despesa,
    (ordem IN (90, 91))                                             AS flag_nao_classificada_no_dre,
    (ordem IS NULL OR dre_linha IS NULL OR tipo_categoria IS NULL)  AS flag_linha_sem_classificacao,
    resultado,
    valor_bruto,
    (ABS(ABS(resultado) - ABS(valor_bruto)) > 0.005)                AS flag_resultado_diverge_do_bruto,
    qtd_parcelas
  FROM origem
)
SELECT
  f.*,
  'L3_CONFIDENTIAL'                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                AS _extraido_at,
  'supabase-x0tz'                    AS _fonte,
  'America/Sao_Paulo'                AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))     AS _payload_hash
FROM final f
