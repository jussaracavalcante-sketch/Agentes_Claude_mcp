-- trs_linear__rotulo
-- Trusted do Linear: um ROTULO (label) de issue por linha. Chave id_rotulo.
-- Fonte: linear-byrt, stream `issue_labels`, camada `Linear Vanguarda`,
-- tabela `vanguardamartech_linear_vanguarda.linear_vanguardaissue_labels`.
-- Nivel: L4 PERSONAL_DATA de intensidade baixa (criador como id + nome, nunca e-mail), igual a trs_linear__issue.
--
-- VOLUME E UNICIDADE -- medido em 2026-10-18
--   8 linhas, 8 `id` distintos. Grao = rotulo. 5 dos 8 estao em uso nas 230 issues (49 aplicacoes):
--   data 20, ui 17, documentation 5, infrastructure 4, Bug 3. `Feature`, `Improvement` e `validacao` existem
--   e nao tem uma aplicacao (o uso se mede na Refined, nao aqui).
--
-- FUSO: createdAt/updatedAt sao instantes UTC -> DATETIME(ts,'America/Sao_Paulo'), nunca TIMESTAMP(dt,'America/Sao_Paulo').
--
-- LIMITACOES -- NAO CONTORNE
--   1. 3 dos 8 rotulos (Bug, Feature, Improvement) sao do WORKSPACE, sem equipe e sem criador: sao os padroes do
--      Linear (`documentation`, de julho, tem equipe VAN e tambem nao traz criador). `flag_rotulo_de_workspace` os marca; `id_equipe` NULL ali e ausencia de equipe, nao erro de join.
--   2. `parent`/`children` existem no schema e estao VAZIOS (0 de 8): nao ha hierarquia de rotulo nesta base.
--   3. `archivedAt` e NULL em 8 de 8. `description` esta vazia em 3 de 8 (sai NULL, nunca '').
--   4. Rotulo NAO e categoria de negocio: sao 4 rotulos tecnicos do projeto BI Hub (infrastructure, data, ui,
--      validacao), `documentation` e os 3 padroes do Linear. Nao ligar a cliente ou servico.
--   5. O Linear parou de ser usado (ultima issue criada 28/07/2026): a tabela e historico.
WITH base AS (
  SELECT 'linear-byrt' AS _fonte, l.id, l.name, l.description, l.color, l.createdAt, l.updatedAt,
         l.archivedAt, l.creator, l.team, l.parent, l.children
  FROM `vanguardamartech_linear_vanguarda`.`linear_vanguardaissue_labels` l
)
SELECT
  b.id                                         AS id_rotulo,
  NULLIF(TRIM(b.name), '')                     AS nome,
  NULLIF(TRIM(IFNULL(b.description, '')), '')  AS descricao,
  NULLIF(b.color, '')                          AS cor,
  b.team.id                                    AS id_equipe,
  b.team.key                                   AS equipe_sigla,
  (b.team.id IS NULL)                          AS flag_rotulo_de_workspace,
  b.parent.id                                  AS id_rotulo_pai,
  IFNULL(ARRAY_LENGTH(b.children.nodes), 0)    AS qtd_rotulos_filhos,
  b.creator.id                                 AS id_criador,
  b.creator.name                               AS criador_nome,
  DATETIME(b.createdAt,  'America/Sao_Paulo')  AS criado_em,
  DATETIME(b.updatedAt,  'America/Sao_Paulo')  AS atualizado_em,
  DATETIME(b.archivedAt, 'America/Sao_Paulo')  AS arquivado_em,
  CURRENT_TIMESTAMP()                          AS _extraido_at,
  b._fonte,
  TO_HEX(MD5(TO_JSON_STRING(b)))               AS _payload_hash
FROM base b
