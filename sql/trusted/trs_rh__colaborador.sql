-- trs_rh__colaborador
-- Trusted / sistema RH. Grao: um colaborador. Chave: nome_chave.
--
-- ============================================================================
-- NAO PUBLICADA. A fonte ainda nao existe na Nekt.
-- Esta query nao foi validada por execucao porque a tabela de origem nao
-- existe. NAO fazer deploy antes de:
--   1. o RH publicar a planilha Google com as seis colunas do Farol
--   2. conectar a fonte (google-sheets) gravando na camada Raw, folder rh
--   3. trocar o FROM abaixo pelo nome real da tabela
--   4. executar e conferir os numeros da secao VALIDACAO
-- ============================================================================
--
-- POR QUE nome_chave E A CHAVE, E NAO O E-MAIL
-- O e-mail seria o identificador natural, mas nem todo mundo tem: o quadro traz
-- ao menos um registro com "Sem e-mail" no lugar do endereco. E o cruzamento com
-- o iClips e por NOME -- o iClips nao publica e-mail do executor. Entao o nome
-- normalizado acumula os dois papeis: chave da tabela e chave de juncao.
--
-- A NORMALIZACAO FOI ESCOLHIDA POR MEDICAO, NAO POR GOSTO
-- Medido em 2026-09-17, 123 pessoas do RH contra 101 executores com apontamento
-- no iClips:
--   basica (sem acento, maiuscula, espaco colapsado) .. 72 casam, 0 colisoes
--   sem particulas (de, da, dos, e) ................... 72 casam, 0 colisoes
--   primeiro + ultimo sobrenome ....................... 72 casam, 1 COLISAO
-- Normalizar alem do basico NAO recupera uma pessoa sequer, e a terceira variante
-- funde dois colaboradores distintos num mesmo "JOSE FILHO" -- exatamente o que a
-- R-003 proibe. Por isso a regra para na forma basica.
-- NAO trocar por similaridade de texto (fuzzy). O ganho medido e zero e o risco e
-- juntar pessoas diferentes.

WITH origem AS (
  -- TROCAR pelo nome real da tabela quando a fonte existir.
  SELECT * FROM `vanguardamartech_raw.PLACEHOLDER_rh_quadro_de_pessoal`
),
limpo AS (
  SELECT
    -- identidade
    NULLIF(TRIM(o.nome_completo), '')                                      AS nome_completo,
    -- REGRA 1: chave de juncao. Sem acento, maiusculas, espacos colapsados.
    NULLIF(REGEXP_REPLACE(
      UPPER(REGEXP_REPLACE(NORMALIZE(IFNULL(o.nome_completo, ''), NFD), r'\p{Mn}', '')),
      r'\s+', ' '), '')                                                    AS nome_chave_bruta,
    -- REGRA 2: sentinela de e-mail. "Sem e-mail" e texto, nao endereco.
    NULLIF(LOWER(TRIM(IFNULL(o.email, ''))), '')                           AS email_bruto,

    NULLIF(TRIM(o.cargo), '')                                              AS cargo,
    NULLIF(TRIM(o.setor), '')                                              AS setor,
    NULLIF(TRIM(o.local_fisicamente), '')                                  AS local_fisicamente,

    -- REGRA 4: datas tipadas; texto vazio vira NULL, nunca data zero.
    SAFE_CAST(NULLIF(TRIM(CAST(o.data_inicio AS STRING)), '') AS DATE)       AS data_inicio,
    SAFE_CAST(NULLIF(TRIM(CAST(o.data_desligamento AS STRING)), '') AS DATE) AS data_desligamento,

    CURRENT_TIMESTAMP()                                                    AS _extraido_at,
    TO_HEX(MD5(TO_JSON_STRING(o)))                                         AS _payload_hash
  FROM origem AS o
),
tratada AS (
  SELECT
    l.* EXCEPT(nome_chave_bruta, email_bruto),
    TRIM(l.nome_chave_bruta)                                               AS nome_chave,
    -- sentinela textual no lugar de endereco
    IF(l.email_bruto IN ('sem e-mail', 'sem email', 'n/a', '-'), NULL, l.email_bruto) AS email,
    -- REGRA 3: local fisicamente tambem sem espaco nem pontuacao, para comparacao.
    -- "Amazon Copy" e "AMAZONCOPY" sao o mesmo cliente e ja falharam por causa do espaco.
    NULLIF(REGEXP_REPLACE(
      UPPER(REGEXP_REPLACE(NORMALIZE(IFNULL(l.local_fisicamente, ''), NFD), r'\p{Mn}', '')),
      r'[^A-Z0-9]', ''), '')                                               AS local_chave,
    NULLIF(REGEXP_REPLACE(
      UPPER(REGEXP_REPLACE(NORMALIZE(IFNULL(l.setor, ''), NFD), r'\p{Mn}', '')),
      r'\s+', ' '), '')                                                    AS setor_chave
  FROM limpo l
)
SELECT
  t.nome_chave,
  t.nome_completo,
  t.email,
  t.cargo,
  t.setor,
  t.setor_chave,
  t.local_fisicamente,
  t.local_chave,
  t.data_inicio,
  t.data_desligamento,

  -- REGRA 5: situacao derivada da data, nao de um campo de status.
  -- Quem saiu PERMANECE na tabela -- o trabalho feito antes da saida conta.
  t.data_desligamento IS NULL                                              AS esta_ativo,
  t.data_desligamento IS NOT NULL                                          AS foi_desligado,

  -- sinalizacao de completude, para quem for cruzar
  t.email IS NULL                                                          AS sem_email,
  t.setor IS NULL                                                          AS sem_setor,
  t.local_fisicamente IS NULL                                              AS sem_local,
  t.data_inicio IS NULL                                                    AS sem_data_inicio,

  t._extraido_at,
  'America/Sao_Paulo'                                                      AS _fuso,
  'rh.quadro_de_pessoal'                                                   AS _fonte,
  t._payload_hash
FROM tratada t
WHERE t.nome_chave IS NOT NULL
