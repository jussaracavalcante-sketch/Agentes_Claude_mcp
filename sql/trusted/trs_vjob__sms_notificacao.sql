-- trs_vjob__sms_notificacao
-- Trusted / VJOB. Grao: um SMS enviado. Chave: id_sms.
-- Origem: mysql-yIOn, `sms_logs` (11.054). **L4 PERSONAL_DATA -- carrega TELEFONE.**
--
-- CLASSIFICACAO: **L4**, e o motivo e uma coluna so. `numero` e telefone celular de
--   pessoa identificavel. Sao **79 numeros distintos** para 11.054 envios -- **56 deles
--   em forma valida** --, media de 140 envios por numero, o que indica **lista fixa de
--   destinatarios internos**, nao base de cliente. Mas telefone e telefone: o nivel sobe
--   pela coluna, nao pelo volume.
--   A `mensagem` tambem carrega **nome de cliente** em texto livre.
--
-- O QUE E: notificacao automatica de **etapa vencida** por cliente -- "Venceu desde
--   (30/04/2025) a etapa Criacao e integracao do RD Station CRM do cliente CONSTROI
--   INCORPORADORA". 2.234 mensagens distintas em 11.054 envios: a mesma notificacao vai
--   para varios destinatarios. Periodo **22/05/2025 20:53:32** a **24/09/2026 09:50:28**
--   -- de hoje, viva.
--
-- ============================================================================
-- **O DDI VEM DUPLICADO EM 1.144 ENVIOS, E MESMO ASSIM NAO SE CORRIGE.**
-- ============================================================================
--   Medido: todos os 11.054 numeros comecam com `55`. Por comprimento de digitos --
--     **13** 9.681 envios (50 numeros) -- celular BR com DDI, forma canonica
--     **15** 784 envios (12 numeros) -- **TODOS comecam com `5555`**
--     **14** 424 envios (10 numeros) -- 360 comecam com `5555`, 64 com `5511`
--     **12** 163 envios (6 numeros) -- fixo BR com DDI, tambem valido
--     **2**  2 envios -- literalmente `55`, so o DDI
--   Os 1.144 que comecam com `5555` sao, pela aritmetica, o DDI gravado duas vezes:
--   tirar os dois primeiros digitos devolve 12 ou 13, que e forma valida.
--
--   **E A BASE NAO CONFIRMA NENHUM DELES.** Dos 1.144 candidatos (21 numeros
--   distintos), **ZERO** existem entre os numeros de forma canonica da propria tabela.
--   A regra desta casa para repadronizar -- escrita no caso do CNPJ com zero a esquerda
--   -- e que **a autoridade e o conjunto de valores validos, nunca a aritmetica
--   sozinha**. La os quatro CNPJs corrigidos existiam na base com 14 digitos e a
--   correcao foi aceita; **aqui nenhum existe, e a correcao e recusada.**
--   A regra vale nas duas direcoes: ela autoriza quando ha prova e proibe quando nao ha.
--
--   Entao `telefone_digitos` sai **so com forma valida (12 ou 13 digitos)**,
--   `telefone_origem` preserva o que veio, `flag_telefone_fora_de_forma` marca os 1.210,
--   e o valor aritmeticamente corrigido reaparece em
--   `candidato_telefone_repadronizado` -- **pista para revisao humana, fora da chave**,
--   exatamente como `candidato_sk_por_documento_parcial` no cadastro.
--
-- **`quemmarcou` ESTA VAZIO EM 3.382 ENVIOS (30,6%)** e tem 48 valores distintos. E
--   texto, nao id -- nao junta com `trs_vjob__usuario` por chave.
--
-- ESTA TABELA DIZ QUE O SMS FOI REGISTRADO, NAO QUE FOI ENTREGUE. Nao ha status de
--   entrega, nem codigo de retorno da operadora, nem custo. Contar linha aqui e contar
--   **tentativa de notificacao**, e dizer "notificamos" e afirmar o que a base nao afirma.
--
-- FUSO: relogio local da intranet. **NAO CONVERTER.**
--
-- MEDIDO EM 2026-09-24: 11.054 linhas · 11.054 chaves · 79 numeros distintos, dos quais
--   **56 em forma valida** · zero linha sem numero e zero sem mensagem · 1.210 fora de
--   forma (1.144 com DDI duplicado, 64 com outro defeito, 2 so com o DDI) ·
--   **ZERO candidatos confirmados na base** · 2.234 mensagens distintas · 3.382 sem
--   marcador.
WITH base AS (
  SELECT id, numero, mensagem, data, quemmarcou
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_sms_logs`
),
prep AS (
  SELECT
    b.id,
    b.mensagem,
    b.data,
    b.quemmarcou,
    NULLIF(TRIM(b.numero), '')                                 AS numero_origem,
    REGEXP_REPLACE(COALESCE(b.numero, ''), r'[^0-9]', '')      AS digitos
  FROM base b
),
-- O conjunto de numeros que a propria base ja tem em forma valida. E ele que autoriza
-- (ou nao) qualquer repadronizacao -- nunca a aritmetica sozinha.
validos AS (
  SELECT DISTINCT digitos FROM prep WHERE LENGTH(digitos) IN (12, 13)
),
tratado AS (
  SELECT
    p.id                                                       AS id_sms,

    -- So sai como telefone o que TEM forma de telefone brasileiro com DDI.
    IF(LENGTH(p.digitos) IN (12, 13), p.digitos, NULL)         AS telefone_digitos,
    p.numero_origem                                            AS telefone_origem,
    (LENGTH(p.digitos) NOT IN (12, 13))                        AS flag_telefone_fora_de_forma,
    -- DDI duplicado: `5555…`. Aritmeticamente corrigivel, mas NAO confirmado pela base.
    (STARTS_WITH(p.digitos, '5555')
     AND LENGTH(p.digitos) IN (14, 15))                        AS flag_ddi_duplicado,
    -- PISTA PARA REVISAO HUMANA, fora da chave. Nao usar em join.
    IF(STARTS_WITH(p.digitos, '5555') AND LENGTH(p.digitos) IN (14, 15),
       SUBSTR(p.digitos, 3), NULL)                             AS candidato_telefone_repadronizado,
    -- Declara se o candidato existe entre os numeros validos da propria base.
    -- Medido em 24/09: FALSE em todos os 1.144 -- por isso nada foi repadronizado.
    (v.digitos IS NOT NULL)                                    AS flag_candidato_confirmado_na_base,

    NULLIF(TRIM(p.mensagem), '')                               AS mensagem,
    LENGTH(NULLIF(TRIM(p.mensagem), ''))                       AS comprimento_mensagem,

    -- Texto livre, NAO id.
    NULLIF(TRIM(p.quemmarcou), '')                             AS marcado_por,
    (NULLIF(TRIM(p.quemmarcou), '') IS NULL)                   AS flag_sem_marcador,

    -- FUSO: relogio local da intranet. Nao converter.
    p.data                                                     AS enviado_em
  FROM prep p
  LEFT JOIN validos v
    ON v.digitos = IF(STARTS_WITH(p.digitos, '5555') AND LENGTH(p.digitos) IN (14, 15),
                      SUBSTR(p.digitos, 3), NULL)
)
SELECT
  t.*,
  CURRENT_TIMESTAMP()                                          AS _extraido_at,
  'mysql-yIOn'                                                 AS _fonte,
  'America/Sao_Paulo'                                          AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t)))                               AS _payload_hash
FROM tratado t
