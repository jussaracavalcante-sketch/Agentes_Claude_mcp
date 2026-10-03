-- Refined / dominio Marketing - rfn_marketing__conversao
-- Grao: um evento de conversao. Chave id_conversao (herdada da Trusted).
-- Le trs_rd_station__conversao na Trusted.
WITH base AS (
  SELECT
    c.*,
    CASE
      WHEN c.fonte_trafego_bruta LIKE 'encoded_%' THEN COALESCE(
        SAFE_CONVERT_BYTES_TO_STRING(SAFE.FROM_BASE64(
          REGEXP_REPLACE(SUBSTR(c.fonte_trafego_bruta, 9), r'[^A-Za-z0-9+/=]', ''))),
        c.fonte_trafego_bruta)
      ELSE NULLIF(c.fonte_trafego_bruta, '')
    END AS origem_desembrulhada,
    CASE
      WHEN c.fonte_trafego_bruta LIKE 'encoded_%'                  THEN 'BASE64'
      WHEN c.fonte_trafego_bruta LIKE 'utm_%'
        OR c.fonte_trafego_bruta LIKE '%&utm_%'                    THEN 'QUERY_UTM'
      WHEN REGEXP_CONTAINS(c.fonte_trafego_bruta, r'^https?://')   THEN 'URL'
      WHEN NULLIF(c.fonte_trafego_bruta, '') IS NOT NULL           THEN 'TEXTO'
      ELSE 'AUSENTE'
    END AS formato_origem
  FROM `vanguardamartech_trusted`.`trs_rd_station__conversao` c
),
sessao AS (
  SELECT b.*,
    REGEXP_EXTRACT(b.origem_desembrulhada,
      r'"first_session"\s*:\s*\{\s*"value"\s*:\s*"([^"]*)"')                AS valor_primeira_sessao
  FROM base b
),
extraido AS (
  SELECT s.*,
    COALESCE(NULLIF(s.utm_source, ''),
             REGEXP_EXTRACT(s.origem_desembrulhada,   r'utm_source=([^&"\\,}|]*)'),
             REGEXP_EXTRACT(s.valor_primeira_sessao,  r'utmcsr=([^&"\\,}|]*)')) AS src_cru,
    COALESCE(NULLIF(s.utm_medium, ''), NULLIF(s.meio_trafego, ''),
             REGEXP_EXTRACT(s.origem_desembrulhada,   r'utm_medium=([^&"\\,}|]*)'),
             REGEXP_EXTRACT(s.valor_primeira_sessao,  r'utmcmd=([^&"\\,}|]*)')) AS med_cru,
    COALESCE(NULLIF(s.utm_campaign, ''), NULLIF(s.campanha_trafego, ''),
             REGEXP_EXTRACT(s.origem_desembrulhada,   r'utm_campaign=([^&"\\,}|]*)'),
             REGEXP_EXTRACT(s.valor_primeira_sessao,  r'utmccn=([^&"\\,}|]*)')) AS camp_cru,
    IF(s.formato_origem = 'TEXTO', s.origem_desembrulhada, NULL)               AS texto_cru,
    SAFE_CAST(REGEXP_EXTRACT(s.origem_desembrulhada, r'gad_campaignid=([0-9]+)') AS INT64)
                                                                               AS id_campanha_google,
    REGEXP_EXTRACT(s.origem_desembrulhada, r'gad_source=([0-9]+)')             AS gad_source,
    REGEXP_REPLACE(COALESCE(
      REGEXP_EXTRACT(s.fonte_trafego_bruta,     r'^https?://([^/?#]+)'),
      REGEXP_EXTRACT(s.valor_primeira_sessao,   r'^https?://([^/?#]+)'),
      REGEXP_EXTRACT(s.fonte_trafego_bruta,     r'^android-app://([^/?#]+)'),
      REGEXP_EXTRACT(s.valor_primeira_sessao,   r'^android-app://([^/?#]+)')
    ), r'^(www|m|l)\.', '')                                                    AS host_referencia,
    COALESCE(s.fonte_trafego_bruta    LIKE 'android-app://%'
          OR s.valor_primeira_sessao  LIKE 'android-app://%', FALSE)          AS origem_eh_app
  FROM sessao s
),
decodificado AS (
  SELECT e.*,
    COALESCE(SAFE_CONVERT_BYTES_TO_STRING(SAFE.FROM_HEX((
      SELECT STRING_AGG(IF(i = 0, TO_HEX(CAST(p AS BYTES)),
        IF(REGEXP_CONTAINS(p, r'^[0-9A-Fa-f]{2}'),
           CONCAT(LOWER(SUBSTR(p, 1, 2)), TO_HEX(CAST(SUBSTR(p, 3) AS BYTES))),
           TO_HEX(CAST(CONCAT('%', p) AS BYTES)))), '' ORDER BY i)
      FROM UNNEST(SPLIT(REPLACE(e.src_cru, '+', ' '), '%')) p WITH OFFSET i))),
      e.src_cru)                                                        AS origem,
    COALESCE(SAFE_CONVERT_BYTES_TO_STRING(SAFE.FROM_HEX((
      SELECT STRING_AGG(IF(i = 0, TO_HEX(CAST(p AS BYTES)),
        IF(REGEXP_CONTAINS(p, r'^[0-9A-Fa-f]{2}'),
           CONCAT(LOWER(SUBSTR(p, 1, 2)), TO_HEX(CAST(SUBSTR(p, 3) AS BYTES))),
           TO_HEX(CAST(CONCAT('%', p) AS BYTES)))), '' ORDER BY i)
      FROM UNNEST(SPLIT(REPLACE(e.med_cru, '+', ' '), '%')) p WITH OFFSET i))),
      e.med_cru)                                                        AS meio,
    COALESCE(SAFE_CONVERT_BYTES_TO_STRING(SAFE.FROM_HEX((
      SELECT STRING_AGG(IF(i = 0, TO_HEX(CAST(p AS BYTES)),
        IF(REGEXP_CONTAINS(p, r'^[0-9A-Fa-f]{2}'),
           CONCAT(LOWER(SUBSTR(p, 1, 2)), TO_HEX(CAST(SUBSTR(p, 3) AS BYTES))),
           TO_HEX(CAST(CONCAT('%', p) AS BYTES)))), '' ORDER BY i)
      FROM UNNEST(SPLIT(REPLACE(e.camp_cru, '+', ' '), '%')) p WITH OFFSET i))),
      e.camp_cru)                                                       AS campanha,
    COALESCE(SAFE_CONVERT_BYTES_TO_STRING(SAFE.FROM_HEX((
      SELECT STRING_AGG(IF(i = 0, TO_HEX(CAST(p AS BYTES)),
        IF(REGEXP_CONTAINS(p, r'^[0-9A-Fa-f]{2}'),
           CONCAT(LOWER(SUBSTR(p, 1, 2)), TO_HEX(CAST(SUBSTR(p, 3) AS BYTES))),
           TO_HEX(CAST(CONCAT('%', p) AS BYTES)))), '' ORDER BY i)
      FROM UNNEST(SPLIT(REPLACE(e.texto_cru, '+', ' '), '%')) p WITH OFFSET i))),
      e.texto_cru)                                                      AS origem_texto
  FROM extraido e
),
chave AS (
  SELECT d.*,
    UPPER(REGEXP_REPLACE(NORMALIZE(COALESCE(d.origem, d.origem_texto, ''), NFD),
          r'\p{Mn}|[^A-Za-z0-9]', ''))                                  AS k_origem,
    UPPER(REGEXP_REPLACE(NORMALIZE(COALESCE(d.meio, ''), NFD),
          r'\p{Mn}|[^A-Za-z0-9]', ''))                                  AS k_meio,
    UPPER(REGEXP_REPLACE(NORMALIZE(COALESCE(d.host_referencia, ''), NFD),
          r'\p{Mn}|[^A-Za-z0-9]', ''))                                  AS k_host,
    CASE
      WHEN COALESCE(NULLIF(d.utm_source, ''), NULLIF(d.utm_medium, '')) IS NOT NULL
                                                                        THEN 'UTM_DA_TRUSTED'
      WHEN REGEXP_CONTAINS(COALESCE(d.origem_desembrulhada, ''), r'utm_source=|utm_medium=')
                                                                        THEN 'UTM_NA_ORIGEM'
      WHEN REGEXP_CONTAINS(COALESCE(d.valor_primeira_sessao, ''), r'utmcsr=|utmcmd=')
                                                                        THEN 'COOKIE_UTMZ'
      WHEN d.id_campanha_google IS NOT NULL                             THEN 'AUTOTAG_GOOGLE_ADS'
      WHEN d.host_referencia IS NOT NULL                                THEN 'HOST_REFERENCIA'
      WHEN d.origem_texto IS NOT NULL                                   THEN 'TEXTO_LIVRE'
      WHEN COALESCE(d.valor_primeira_sessao, '') IN ('(none)', '(direct)')
                                                                        THEN 'SEM_CAMPANHA_EXPLICITO'
      WHEN d.formato_origem = 'AUSENTE'                                 THEN 'AUSENTE'
      ELSE 'NAO_RECONHECIDO'
    END                                                                 AS origem_extraida_de
  FROM decodificado d
),
classificado AS (
  SELECT c.*,
    CASE
      WHEN c.k_origem IN ('GOOGLEADS','GADS','GOOGLEADWORDS','ADWORDS')     THEN 'GOOGLE ADS'
      WHEN c.k_origem IN ('GOOGLEMEUNEGOCIO','GMN','GOOGLEMYBUSINESS')      THEN 'GOOGLE MEU NEGOCIO'
      WHEN c.k_origem = 'GOOGLE'                                            THEN 'GOOGLE'
      WHEN c.k_origem IN ('METAADS','FACEBOOKADS','FBADS')                  THEN 'META ADS'
      WHEN c.k_origem IN ('FACEBOOK','FB','META','FACEBOOKCOM')             THEN 'FACEBOOK'
      WHEN c.k_origem IN ('INSTAGRAM','IG','INSTAGRAMCOM')                  THEN 'INSTAGRAM'
      WHEN c.k_origem LIKE 'WHATSAPP%' OR c.k_origem LIKE '%WPP%'
        OR c.k_origem LIKE 'DUOTALK%'                                       THEN 'WHATSAPP'
      WHEN c.k_origem LIKE 'RDSTATION%' OR c.k_origem LIKE '%LINKDABIO%'    THEN 'RD STATION'
      WHEN c.k_origem IN ('DIRECT','NONE','ACESSODIRETO','DIRETO')          THEN 'DIRETO'
      WHEN c.k_origem <> ''                                                 THEN COALESCE(c.origem, c.origem_texto)
      WHEN c.id_campanha_google IS NOT NULL                                 THEN 'GOOGLE ADS'
      WHEN c.k_host LIKE '%INSTAGRAM%'                                      THEN 'INSTAGRAM'
      WHEN c.k_host LIKE '%FACEBOOK%'                                       THEN 'FACEBOOK'
      WHEN c.k_host LIKE '%LINKEDIN%'                                       THEN 'LINKEDIN'
      WHEN c.k_host LIKE '%WHATSAPP%'                                       THEN 'WHATSAPP'
      WHEN c.k_host LIKE '%TELEGRAM%'                                       THEN 'TELEGRAM'
      WHEN c.k_host LIKE '%ANDROIDGM%'                                      THEN 'GMAIL'
      WHEN c.k_host LIKE '%QUICKSEARCHBOX%' OR c.k_host LIKE '%GOOGLE%'     THEN 'GOOGLE'
      WHEN c.k_host <> ''                                                   THEN c.host_referencia
      WHEN COALESCE(c.valor_primeira_sessao, '') IN ('(none)', '(direct)')  THEN 'DIRETO'
      ELSE NULL
    END                                                                     AS origem_canonica,
    CASE
      WHEN c.k_meio IN ('CPC','PPC','CPM','PAID','PAIDSOCIAL','PAIDSEARCH','ADS')
           AND (c.k_origem LIKE 'GOOGLE%' OR c.k_origem IN ('GADS','ADWORDS','BING'))
                                                                            THEN 'PAGO_BUSCA'
      WHEN c.k_meio IN ('CPC','PPC','CPM','PAID','PAIDSOCIAL','PAIDSEARCH','ADS')
           AND (c.k_origem LIKE '%FACEBOOK%' OR c.k_origem LIKE '%META%'
                OR c.k_origem IN ('FB','IG','INSTAGRAM','TIKTOK','LINKEDIN'))
                                                                            THEN 'PAGO_SOCIAL'
      WHEN c.k_meio IN ('CPC','PPC','CPM','PAID','PAIDSOCIAL','PAIDSEARCH','ADS')
                                                                            THEN 'PAGO_OUTRO'
      WHEN c.k_origem IN ('GOOGLEADS','GADS','ADWORDS','GOOGLEADWORDS')     THEN 'PAGO_BUSCA'
      WHEN c.k_origem IN ('METAADS','FACEBOOKADS','FBADS')                  THEN 'PAGO_SOCIAL'
      WHEN c.k_origem IN ('GOOGLE','BING','CHATGPTCOM')                     THEN 'ORGANICO_BUSCA'
      WHEN c.k_origem IN ('FACEBOOK','FB','META','FACEBOOKCOM','INSTAGRAM','IG',
                          'INSTAGRAMCOM','YOUTUBE','LINKEDIN','TIKTOK')     THEN 'ORGANICO_SOCIAL'
      WHEN c.k_origem IN ('GOOGLEMEUNEGOCIO','GMN','GOOGLEMYBUSINESS')      THEN 'GOOGLE_MEU_NEGOCIO'
      WHEN c.k_origem LIKE 'WHATSAPP%' OR c.k_origem LIKE '%WPP%'
        OR c.k_origem LIKE 'DUOTALK%'                                       THEN 'WHATSAPP'
      WHEN c.k_origem LIKE 'RDSTATION%' OR c.k_origem LIKE '%LINKDABIO%'
        OR c.k_meio IN ('EMAIL','NEWSLETTER')                               THEN 'RD_PROPRIO'
      WHEN c.k_origem IN ('DIRECT','NONE','ACESSODIRETO','DIRETO')          THEN 'DIRETO'
      WHEN c.k_origem <> ''                                                 THEN 'OUTRO'
      WHEN c.id_campanha_google IS NOT NULL AND c.gad_source = '1'          THEN 'PAGO_BUSCA'
      WHEN c.id_campanha_google IS NOT NULL                                 THEN 'PAGO_OUTRO'
      WHEN c.k_host LIKE '%ANDROIDGM%' OR c.k_host LIKE '%OUTLOOK%'         THEN 'EMAIL'
      WHEN c.k_host LIKE '%WHATSAPP%'                                       THEN 'WHATSAPP'
      WHEN c.k_host LIKE '%TELEGRAM%' OR c.k_host LIKE '%MESSENGER%'        THEN 'MENSAGEIRO'
      WHEN c.k_host LIKE '%INSTAGRAM%' OR c.k_host LIKE '%FACEBOOK%'
        OR c.k_host LIKE '%LINKEDIN%'  OR c.k_host LIKE '%TIKTOK%'
        OR c.k_host LIKE '%YOUTUBE%'                                        THEN 'ORGANICO_SOCIAL'
      WHEN c.k_host LIKE '%QUICKSEARCHBOX%' OR c.k_host LIKE '%GOOGLE%'
        OR c.k_host LIKE '%BING%'                                           THEN 'ORGANICO_BUSCA'
      WHEN c.origem_eh_app                                                  THEN 'REFERENCIA_APP'
      WHEN c.k_host <> ''                                                   THEN 'REFERENCIA'
      WHEN COALESCE(c.valor_primeira_sessao, '') IN ('(none)', '(direct)')  THEN 'DIRETO'
      ELSE 'DESCONHECIDO'
    END                                                                     AS canal
  FROM chave c
),
-- REGRA 7 - CARGA EM LOTE. Importacao de base para dentro da RD Station gera um evento
-- por contato, todos no dia da carga, e some no relatorio como se fosse conversao. Em
-- 03/09/2026 isso fez setembro parecer 15x agosto. A marcacao NAO usa data no codigo:
-- descreve a forma da carga, entao carga futura ja nasce marcada.
volume_dia AS (
  SELECT cliente, ocorrido_data AS data, COUNT(*) AS n_dia,
         COUNTIF(formato_origem = 'AUSENTE') AS n_sem_origem,
         COUNT(DISTINCT id_contato) AS n_contatos
  FROM base GROUP BY 1, 2
),
mediana_cliente AS (
  SELECT cliente, APPROX_QUANTILES(n_dia, 2)[OFFSET(1)] AS mediana_dia
  FROM volume_dia GROUP BY cliente
),
lote AS (
  SELECT v.cliente, v.data, v.n_dia, m.mediana_dia,
    (v.n_dia >= 500
     AND v.n_dia >= 20 * GREATEST(m.mediana_dia, 1)
     AND SAFE_DIVIDE(v.n_sem_origem, v.n_dia) >= 0.95
     AND v.n_contatos = v.n_dia) AS eh_carga_em_lote
  FROM volume_dia v JOIN mediana_cliente m USING (cliente)
),
com_lote AS (
  SELECT c.*,
    IFNULL(l.eh_carga_em_lote, FALSE) AS carga_em_lote,
    l.n_dia                           AS conversoes_no_dia_do_cliente,
    l.mediana_dia                     AS mediana_diaria_do_cliente
  FROM classificado c
  LEFT JOIN lote l ON l.cliente = c.cliente AND l.data = c.ocorrido_data
)
SELECT
  id_conversao, id_contato, uuid_contato, cliente, _fonte,
  ocorrido_em, ocorrido_data AS data, mes_referencia,
  tipo_evento, familia_evento, identificador_evento, identificador_conversao,
  canal,
  canal IN ('PAGO_BUSCA', 'PAGO_SOCIAL', 'PAGO_OUTRO')                      AS canal_pago,
  origem_canonica,
  origem AS utm_source, meio AS utm_medium, campanha AS utm_campaign,
  id_campanha_google, gad_source, host_referencia, origem_eh_app,
  origem_texto AS origem_em_texto, origem_extraida_de, formato_origem,
  fonte_trafego_bruta AS origem_bruta,
  -- carga em lote (regra 7): NAO e conversao de marketing.
  -- Para leitura de resultado, filtrar carga_em_lote = FALSE.
  carga_em_lote, conversoes_no_dia_do_cliente, mediana_diaria_do_cliente,
  formato_origem = 'AUSENTE'                                                AS sem_origem,
  COALESCE(valor_primeira_sessao, '') IN ('(none)', '(direct)')
    OR k_origem IN ('NONE', 'DIRECT')                                       AS origem_none_explicito,
  canal = 'DESCONHECIDO'                                                    AS canal_indefinido,
  origem_extraida_de = 'NAO_RECONHECIDO'                                    AS formato_nao_reconhecido,
  COALESCE(REGEXP_CONTAINS(CONCAT(COALESCE(origem, ''), COALESCE(meio, ''),
           COALESCE(campanha, ''), COALESCE(origem_texto, '')), r'%[0-9A-Fa-f]{2}'), FALSE)
                                                                            AS escape_nao_tratado,
  NOT (COALESCE(REGEXP_CONTAINS(CONCAT(COALESCE(origem, ''), COALESCE(meio, ''),
       COALESCE(campanha, ''), COALESCE(origem_texto, '')), r'%[0-9A-Fa-f]{2}'), FALSE)
       OR origem_extraida_de = 'NAO_RECONHECIDO')                           AS registro_confiavel,
  campos_conversao_json,
  _extraido_at, _payload_hash
FROM com_lote
