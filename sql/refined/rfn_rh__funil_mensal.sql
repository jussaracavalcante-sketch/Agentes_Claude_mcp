-- rfn_rh__funil_mensal  ·  Refined / rh (recrutamento, Quickin)  ·  L2 INTERNAL
-- Grao: mes do evento x transicao (etapa anterior -> etapa nova) de aplicacao no funil de recrutamento.
-- Le: trs_quickin__funil_evento (query-A8RA, L3) e trs_quickin__dominio (query-A4uG, so ETAPA_FUNIL, para a posicao da etapa).
-- Gatilho: evento com regra "all" em query-A8RA e query-A4uG (as duas disparam na supabase-x0tz, diaria).
-- Identidade (19/10/2026, contra a Trusted materializada): 149 eventos = 149 · 57 linhas, 57 chaves · 93 aplicacoes distintas ·
--   140 AVANCO + 3 RETORNO + 6 MESMA_POSICAO + 0 INDETERMINADO = 149 · 2026-06 a 2026-09.
-- R1 sentido compara a POSICAO cadastrada da etapa (ordem do dominio, 0 = Candidatura ... 8 = Contratacao): AVANCO se a nova esta
--    adiante, RETORNO se atras, MESMA_POSICAO se igual. 'Teste pratico' e 'Triagem' compartilham a posicao 1 na origem: as 6
--    transicoes Triagem -> Teste pratico saem MESMA_POSICAO, nao AVANCO. E leitura da posicao cadastrada, nao julgamento.
-- R2 Nenhum dado do candidato entra (a Trusted de evento ja nao o traz); id de aplicacao vira contagem distinta.
-- R3 Etapa sem nome viraria '(sem etapa)' e posicao desconhecida 'INDETERMINADO' (nao ha hoje).
-- LIMITACAO -- NAO CONTORNE: a captura de movimentacao comecou em 15/06/2026 e cobre 149 eventos para 4.013 aplicacoes: ausencia
--   de evento NAO e ausencia de movimentacao. Nao e taxa de conversao do funil; e contagem de transicoes capturadas.
WITH e AS (SELECT * FROM `vanguardamartech_trusted`.`trs_quickin__funil_evento`),
etapa AS (
  SELECT id_origem AS id_etapa, SAFE_CAST(ordem AS INT64) AS posicao
  FROM `vanguardamartech_trusted`.`trs_quickin__dominio` WHERE dominio = 'ETAPA_FUNIL'
),
base AS (
  SELECT e.*, pa.posicao AS posicao_anterior, pn.posicao AS posicao_nova,
         CASE WHEN pa.posicao IS NULL OR pn.posicao IS NULL THEN 'INDETERMINADO'
              WHEN pn.posicao > pa.posicao THEN 'AVANCO'
              WHEN pn.posicao < pa.posicao THEN 'RETORNO'
              ELSE 'MESMA_POSICAO' END AS sentido
  FROM e
  LEFT JOIN etapa pa ON pa.id_etapa = e.id_etapa_anterior
  LEFT JOIN etapa pn ON pn.id_etapa = e.id_etapa_nova
),
agg AS (
  SELECT
    DATE_TRUNC(data_evento, MONTH) AS mes_evento,
    IFNULL(etapa_anterior, '(sem etapa)') AS etapa_anterior,
    IFNULL(tipo_etapa_anterior, '(sem tipo)') AS tipo_etapa_anterior,
    IFNULL(etapa_nova, '(sem etapa)') AS etapa_nova,
    IFNULL(tipo_etapa_nova, '(sem tipo)') AS tipo_etapa_nova,
    sentido,
    COUNT(*) AS qtd_eventos,
    COUNT(DISTINCT id_aplicacao) AS qtd_aplicacoes_distintas,
    COUNT(DISTINCT data_evento) AS qtd_dias_com_evento,
    MIN(ocorrido_em) AS primeiro_evento_em,
    MAX(ocorrido_em) AS ultimo_evento_em
  FROM base
  GROUP BY 1, 2, 3, 4, 5, 6
),
final AS (
  SELECT CONCAT(FORMAT_DATE('%Y-%m', mes_evento), '|', etapa_anterior, '>', etapa_nova) AS id_funil_mensal,
         a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
