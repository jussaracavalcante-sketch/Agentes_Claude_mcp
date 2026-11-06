-- trs_linear__equipe
-- Trusted do Linear: uma EQUIPE por linha. Chave id_equipe (sigla `key` tambem unica).
-- Fonte: linear-byrt, stream `teams`, camada `Linear Vanguarda`,
-- tabela `vanguardamartech_linear_vanguarda.linear_vanguardateams`.
-- Nivel: L2 INTERNAL (nome e configuracao de equipe; nenhuma pessoa).
--
-- VOLUME E UNICIDADE -- medido em 2026-10-18
--   1 linha: `Vanguarda Martech` (VAN), id 0bfb72fa-..., criada em 2026-04-01. Todas as 230 issues e os
--   5 rotulos com equipe apontam para ela (zero orfaos nas issues). Unica equipe: `team` nao e dimensao util hoje.
--
-- EMITIDO: so identidade e as configuracoes que descrevem COMO a equipe usa o Linear (ciclos, triagem,
--   estimativa, estado padrao). Nao saem as ~25 chaves de comportamento de tela (ordenacao, templates,
--   workflow states auxiliares), que nao sao informacao de negocio.
--
-- FUSO: createdAt/updatedAt sao instantes UTC -> DATETIME(ts,'America/Sao_Paulo').
--
-- LIMITACOES -- NAO CONTORNE
--   1. `cyclesEnabled = FALSE`, `triageEnabled = FALSE` e `issueEstimationType = 'notUsed'`: a equipe nao usa ciclo,
--      triagem nem estimativa. Por isso `cycles` (0 linhas) e `estimate` (0%) nao tem Trusted: confere com a config.
--   2. `updatedAt` (2026-10-13) NAO e atividade de trabalho: a ultima issue foi criada em 28/07/2026. Mexer em
--      configuracao de equipe atualiza o carimbo.
--   3. Uma linha so: nao ha o que agregar numa Refined.
WITH base AS (
  SELECT 'linear-byrt' AS _fonte, t.id, t.key, t.name, t.description, t.private, t.createdAt, t.updatedAt,
         t.archivedAt, t.cyclesEnabled, t.triageEnabled, t.issueEstimationType, t.defaultIssueState, t.organization
  FROM `vanguardamartech_linear_vanguarda`.`linear_vanguardateams` t
)
SELECT
  b.id                                         AS id_equipe,
  b.key                                        AS sigla,
  NULLIF(TRIM(b.name), '')                     AS nome,
  NULLIF(TRIM(IFNULL(b.description, '')), '')  AS descricao,
  b.private                                    AS is_privada,
  b.cyclesEnabled                              AS usa_ciclos,
  b.triageEnabled                              AS usa_triagem,
  NULLIF(b.issueEstimationType, '')            AS tipo_estimativa,
  b.defaultIssueState.name                     AS estado_padrao_nome,
  b.organization.id                            AS id_organizacao,
  NULLIF(TRIM(b.organization.name), '')        AS organizacao_nome,
  DATETIME(b.createdAt,  'America/Sao_Paulo')  AS criada_em,
  DATETIME(b.updatedAt,  'America/Sao_Paulo')  AS atualizada_em,
  DATETIME(b.archivedAt, 'America/Sao_Paulo')  AS arquivada_em,
  CURRENT_TIMESTAMP()                          AS _extraido_at,
  b._fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))               AS _payload_hash
FROM base b
