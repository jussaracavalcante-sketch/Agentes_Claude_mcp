-- trs_vjob__job_comentario
-- Trusted / VJOB. Grao: um comentario em um job. Chave: id_comentario_unico.
-- Origem: mysql-yIOn (VJOB real). L4 PERSONAL_DATA -- texto livre escrito por pessoa
-- identificada sobre cliente identificado; nao se presume o conteudo (mesma doutrina
-- aplicada ao `custom_fields` do RD Station).
--
-- SAO TRES TABELAS DE COMENTARIO, NAO DUAS -- e a terceira eu quase deixei de fora.
--   `tbjobs_comentarios` ........ 656, modulo APOSENTADO
--   `tarefas_tbjobs_comentarios`  620, modulo VIVO
--   `advisory_tbjobs_comentarios`  14, modulo VIVO
--   Total 1.290. A do modulo aposentado nao aparece na busca por nome do modulo vivo;
--   so apareceu ao procurar explicitamente pelo prefixo antigo. **Busca semantica que
--   nao devolve a tabela nao prova que a tabela nao existe** -- ja registrado nesta
--   casa em 24/09, quando eu declarei que `ia_geracoes` nao existia e ela tinha 86
--   linhas. Conferir com `COUNT(*)` antes de afirmar ausencia.
--
-- A CHAVE E COMPOSTA, pelo mesmo motivo do job: cada origem tem sequencia propria de
--   `id` e elas colidem. `id_comentario_unico` = `<origem>:<id>`.
--
-- ZERO ORFAOS NAS TRES ORIGENS -- medido em 2026-09-24 contra a uniao de
--   `trs_vjob__job` (modulo aposentado) e `trs_vjob__job_tarefa` (modulo vivo):
--   1.290 comentarios, 1.290 chaves, **zero** apontando para job inexistente e zero
--   com `job_id` nulo. O join fica LEFT mesmo assim, com flag, porque o buraco de
--   cadastro do VJOB aparece em quase toda outra tabela desta base e INNER esconderia
--   o dia em que aparecer aqui.
--
-- 120 COMENTARIOS ESTAO VAZIOS, e nao e o mesmo em cada modulo.
--   `tbjobs_comentarios` 103 de 656 (**15,7%**) · `tarefas` 17 de 620 (2,7%) ·
--   `advisory` 0 de 14. E vazio de verdade: **nenhum deles tem `conteudo_html`
--   preenchido** -- nao e caso de markup sem texto, e linha sem conteudo nenhum.
--   `flag_comentario_vazio` marca. Contar comentario como sinal de conversa sem
--   descontar estes superestima o modulo aposentado em 15,7%.
--
-- FUSO: o MySQL devolve o relogio local da intranet. **NAO CONVERTER.** Aplicar
--   `TIMESTAMP(dt,'America/Sao_Paulo')` aqui somaria 3 horas -- e a armadilha que ja
--   custou sete tabelas nesta base.
--
-- O QUE SO EXISTE NO MODULO VIVO DE TAREFAS: `editado_em` e `editado_por`. As outras
--   duas origens nao tem as colunas, entao saem NULL -- **ausencia de coluna, nao
--   comentario nao editado**. `flag_edicao_rastreavel` distingue os dois casos: quem
--   somar `flag_editado` sobre as 1.290 mede 21 edicoes sobre um universo de 620, nao
--   de 1.290.
--
-- MEDIDO EM 2026-09-24: 1.290 linhas · 1.290 chaves · 296 jobs comentados no modulo
--   vivo e 429 no aposentado · 34 autores no vivo, 35 no aposentado, **todos resolvem
--   em `trs_vjob__usuario`** · media de 158 caracteres · maximo de 26 comentarios num
--   mesmo job · 21 edicoes, **nenhuma com carimbo anterior a criacao** · ultimo
--   comentario do modulo vivo **23/09/2026 17:39:32** e do aposentado
--   **02/09/2026 11:26:24** -- o mesmo instante da ultima aprovacao de `tbjobs`, que e
--   a confirmacao independente de que aquele modulo parou ali.
WITH base AS (
  SELECT 'tbjobs' AS origem, id, job_id, usuario_id, conteudo_html, conteudo_text,
         criado_em, CAST(NULL AS TIMESTAMP) AS editado_em, CAST(NULL AS INT64) AS editado_por,
         FALSE AS edicao_rastreavel
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs_comentarios`
  UNION ALL
  SELECT 'TAREFAS', id, job_id, usuario_id, conteudo_html, conteudo_text,
         criado_em, editado_em, editado_por, TRUE
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tarefas_tbjobs_comentarios`
  UNION ALL
  SELECT 'ADVISORY', id, job_id, usuario_id, conteudo_html, conteudo_text,
         criado_em, CAST(NULL AS TIMESTAMP), CAST(NULL AS INT64), FALSE
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_advisory_tbjobs_comentarios`
),
jobs AS (
  SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job`
  UNION DISTINCT
  SELECT DISTINCT id_job_unico FROM `vanguardamartech_trusted`.`trs_vjob__job_tarefa`
),
tratado AS (
  SELECT
    CONCAT(b.origem, ':', CAST(b.id AS STRING))            AS id_comentario_unico,
    b.origem,
    b.id                                                   AS id_comentario,
    b.job_id                                               AS id_job,
    CONCAT(b.origem, ':', CAST(b.job_id AS STRING))        AS id_job_unico,
    (b.origem = 'tbjobs')                                  AS is_modulo_aposentado,

    NULLIF(b.usuario_id, 0)                                AS id_autor,
    NULLIF(TRIM(b.conteudo_text), '')                      AS conteudo_texto,
    LENGTH(NULLIF(TRIM(b.conteudo_text), ''))              AS comprimento_texto,
    -- Vazio de verdade: nem texto nem markup. Os 120 casos nao tem `conteudo_html`.
    (NULLIF(TRIM(b.conteudo_text), '') IS NULL
     AND NULLIF(TRIM(b.conteudo_html), '') IS NULL)        AS flag_comentario_vazio,
    -- `conteudo_html` NAO e emitido: e a mesma informacao com markup, e emitir as duas
    -- convidaria a contar comentario duas vezes por caminhos diferentes.

    -- FUSO: relogio local da intranet. Nao converter.
    b.criado_em,
    b.editado_em,
    NULLIF(b.editado_por, 0)                               AS id_editado_por,
    (b.editado_em IS NOT NULL)                             AS flag_editado,
    -- Distingue "nao foi editado" de "a origem nao registra edicao".
    b.edicao_rastreavel                                    AS flag_edicao_rastreavel,

    (j.id_job_unico IS NULL)                               AS flag_job_nao_catalogado
  FROM base b
  LEFT JOIN jobs j
    ON j.id_job_unico = CONCAT(b.origem, ':', CAST(b.job_id AS STRING))
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                      AS _extraido_at,
  'mysql-yIOn'                                             AS _fonte,
  'America/Sao_Paulo'                                      AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                           AS _payload_hash
FROM tratado t
