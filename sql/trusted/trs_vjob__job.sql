-- trs_vjob__job
-- Trusted / VJOB. Grao: um job. Chave: (origem, id_job) -- tambem exposta em id_job_unico.
-- Origem: mysql-yIOn (VJOB real), tabelas mysql_vjobvjob_2024_tbjobs e __tbjobsgeral.
--
-- REESCRITA EM 2026-09-23 -- TROCOU DE SUJEITO E CONSERTOU UM ERRO DE 3 HORAS.
--
-- 1. SUJEITO. Ate hoje esta tabela lia o DERIVADO Supabase, que e informacao ja
--    tratada e empurrada para a plataforma, nao o sistema. Agora le o VJOB real.
--    O volume bate exatamente: 1.354 + 160 = 1.514, o mesmo que o derivado entregava.
--
-- 2. FUSO -- A SETIMA TABELA COM A ARMADILHA, E ESTA PASSOU DESPERCEBIDA EM 16/09.
--    O codigo antigo fazia `TIMESTAMP(PARSE_DATETIME(...), 'America/Sao_Paulo')` sobre
--    um relogio que JA E local. Essa funcao nao converte de UTC: ela interpreta o
--    relogio como se fosse SP e devolve o instante absoluto -- ou seja, SOMA 3 horas.
--    Medido contra o sistema: **1.354 de 1.354** registros com `data_cadastro`
--    exatamente +3h, **zero iguais**; `checado_em` +3h em 1.051 e `aprovado_em` em
--    1.340. O ultimo cadastro real e 2026-08-24 **11**:15:59, nao 14:15:59.
--    A ironia esta na descricao antiga, que dizia a coisa certa ("a intranet grava
--    hora local") e usava a funcao errada. Aqui as colunas ja vem TIMESTAMP do MySQL
--    e **nao se converte nada**.
--
-- 3. `id_job` SOZINHO NAO E CHAVE: 147 ids aparecem nas DUAS tabelas de origem.
--
-- NAO EMITE `public_token`, `public_enabled`, `public_generated_at` nem
--    `public_expires_at`. O sistema tem as quatro e **182 jobs carregam
--    `public_token`** -- um token de acesso publico ao job. Token nao entra em camada
--    tratada (ADR-0010 sec. 31: secret e L5 e nao deve estar no Data Lake).
--
-- PRESERVADO DA VERSAO ANTERIOR, porque continua verdadeiro:
--   - `id_projeto` NAO e FK de cliente. No sistema o campo e STRING, entao saem os
--     dois: `projeto` (cru) e `id_projeto` (SAFE_CAST), com flag.
--   - `id_setor` e constante 1 e nao resolve contra `tbsetor` (que comeca no id 11).
--     Campo morto, mantido por fidelidade. So existe em `tbjobsgeral`.
--
-- O MODULO DE JOB ESTA PARADO: ultimo cadastro 24/08/2026, ultima aprovacao
--   02/09/2026. Quem medir producao da casa aqui conclui que a agencia parou -- o que
--   esta vivo e o ESCOPO (`trs_vjob__escopo`).
WITH base AS (
  SELECT 'tbjobs' AS origem, id, projeto, tipo, atividade, data_entrada, data_entrega, status,
         checado_por, checado_em, aprovado, aprovado_por, aprovado_em, observacao,
         quemcadastrou, data_cadastro, CAST(NULL AS INT64) AS id_setor
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobs`
  UNION ALL
  SELECT 'tbjobsgeral', id, projeto, tipo, atividade, data_entrada, data_entrega, status,
         checado_por, checado_em, aprovado, aprovado_por, aprovado_em, observacao,
         quemcadastrou, data_cadastro, id_setor
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbjobsgeral`
),
tratado AS (
  SELECT
    b.origem,
    b.id                                            AS id_job,
    CONCAT(b.origem, ':', CAST(b.id AS STRING))     AS id_job_unico,

    NULLIF(TRIM(b.projeto), '')                     AS projeto,
    SAFE_CAST(NULLIF(TRIM(b.projeto), '') AS INT64) AS id_projeto,
    (NULLIF(TRIM(b.projeto), '') IS NOT NULL
      AND SAFE_CAST(NULLIF(TRIM(b.projeto), '') AS INT64) IS NULL)
                                                    AS flag_projeto_nao_numerico,

    NULLIF(TRIM(b.tipo), '')                        AS tipo_codigo,
    NULLIF(TRIM(b.atividade), '')                   AS atividade,
    NULLIF(TRIM(b.status), '')                      AS status_job,
    NULLIF(TRIM(b.observacao), '')                  AS observacao,

    b.data_entrada,
    b.data_entrega,
    -- FUSO: o MySQL ja devolve o relogio local da intranet. NAO CONVERTER.
    -- Aplicar TIMESTAMP(dt,'America/Sao_Paulo') aqui soma 3 horas -- foi o defeito
    -- que esta reescrita corrigiu.
    b.data_cadastro,
    b.checado_em,
    b.aprovado_em,

    (b.aprovado = 1)                                AS aprovado,
    NULLIF(b.checado_por, 0)                        AS id_checado_por,
    NULLIF(b.aprovado_por, 0)                       AS id_aprovado_por,
    NULLIF(b.quemcadastrou, 0)                      AS id_quem_cadastrou,

    b.id_setor
  FROM base b
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                               AS _extraido_at,
  'mysql-yIOn'                                      AS _fonte,
  'America/Sao_Paulo'                               AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                    AS _payload_hash
FROM tratado t
