-- rfn_operacao__noticia_alcance
-- Refined / operacao. Grao: uma NOTICIA da intranet do VJOB, com lista de distribuicao e leituras lado a lado. Chave: id_noticia.
-- Le trs_vjob__noticia_interacao (LEITURA 462 + DESTINATARIO 3.732 em 2026-10-19). Nivel: L2 INTERNAL -- usuario vira contagem; nenhum id de pessoa atravessa.
-- REGRA 1: qtd_destinatarios e a lista de quem devia ver (tbnoticiasextra2); qtd_leituras e o recibo datado (tbnoticiasextra). Sao fluxos
--          diferentes: nao se somam e nao se dividem um pelo outro sem a REGRA 2.
-- REGRA 2: taxa_leitura_da_lista = destinatarios que leram / destinatarios. NULL (nunca zero) quando a noticia nao tem lista (flag_sem_lista) -- a
--          noticia 5 tem leitura e nenhum destinatario. Leitura de quem NAO estava na lista (36 em 462) fica em qtd_leituras_fora_da_lista e
--          fora do numerador.
-- REGRA 3: flag_noticia_apagada acende quando a noticia nao existe mais em tbnoticias (8 vivas de 54): a interacao sobreviveu ao conteudo. Nao e
--          erro de extracao; e o estado da origem. A noticia viva se le em trs_vjob__intranet_conteudo (origem NOTICIA).
-- REGRA 4: as datas sao de LEITURA (hora local do VJOB, sem conversao). Lista de distribuicao nao tem data: mes_primeira_leitura e o unico eixo temporal.
-- LIMITACOES - NAO CONTORNE: 35 noticias tem a MESMA lista de 58 usuarios e 4 a mesma de 203 -- a lista e "todo mundo da epoca", nao segmentacao;
--   usuario fora do cadastro (qtd_*_usuario_nao_catalogado) e gente que saiu, nao defeito; o conteudo da noticia nao esta aqui.
-- VALIDACAO 2026-10-19 (query inteira rodada sobre a Trusted materializada): 54 noticias, 54 chaves e hashes (40 com leitura, 53 com lista, 39 com as duas,
--   1 sem lista, 46 apagadas), soma de qtd_leituras = 462, de qtd_destinatarios = 3.732, de qtd_destinatarios_que_leram = 426, de qtd_leituras_fora_da_lista = 36,
--   leituras de usuario fora do cadastro 327 e destinatarios 2.397; taxa_leitura_da_lista NULL em 1 noticia e maxima 1,0.
WITH l AS (
  SELECT id_noticia,
    COUNT(*)                                        AS qtd_leituras,
    COUNT(DISTINCT id_usuario)                      AS qtd_leitores_distintos,
    COUNTIF(NOT flag_leitura_fora_da_lista)         AS qtd_leituras_de_destinatario,
    COUNTIF(flag_leitura_fora_da_lista)             AS qtd_leituras_fora_da_lista,
    COUNTIF(flag_usuario_nao_catalogado)            AS qtd_leituras_usuario_nao_catalogado,
    MIN(interagido_em)                              AS primeira_leitura_em,
    MAX(interagido_em)                              AS ultima_leitura_em,
    LOGICAL_OR(flag_noticia_nao_catalogada)         AS flag_apagada_l,
    MAX(_extraido_at)                               AS ex_l
  FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  WHERE tipo_interacao = 'LEITURA'
  GROUP BY id_noticia
),
d AS (
  SELECT id_noticia,
    COUNT(*)                                        AS qtd_destinatarios,
    COUNT(DISTINCT id_usuario)                      AS qtd_destinatarios_distintos,
    COUNTIF(flag_destinatario_leu)                  AS qtd_destinatarios_que_leram,
    COUNTIF(flag_usuario_nao_catalogado)            AS qtd_destinatarios_usuario_nao_catalogado,
    LOGICAL_OR(flag_noticia_nao_catalogada)         AS flag_apagada_d,
    MAX(_extraido_at)                               AS ex_d
  FROM `vanguardamartech_trusted`.`trs_vjob__noticia_interacao`
  WHERE tipo_interacao = 'DESTINATARIO'
  GROUP BY id_noticia
),
agg AS (
  SELECT
    COALESCE(l.id_noticia, d.id_noticia)                              AS id_noticia,
    IFNULL(d.qtd_destinatarios, 0)                                    AS qtd_destinatarios,
    IFNULL(d.qtd_destinatarios_distintos, 0)                          AS qtd_destinatarios_distintos,
    IFNULL(d.qtd_destinatarios_que_leram, 0)                          AS qtd_destinatarios_que_leram,
    IFNULL(d.qtd_destinatarios_usuario_nao_catalogado, 0)             AS qtd_destinatarios_usuario_nao_catalogado,
    IFNULL(l.qtd_leituras, 0)                                         AS qtd_leituras,
    IFNULL(l.qtd_leitores_distintos, 0)                               AS qtd_leitores_distintos,
    IFNULL(l.qtd_leituras_de_destinatario, 0)                         AS qtd_leituras_de_destinatario,
    IFNULL(l.qtd_leituras_fora_da_lista, 0)                           AS qtd_leituras_fora_da_lista,
    IFNULL(l.qtd_leituras_usuario_nao_catalogado, 0)                  AS qtd_leituras_usuario_nao_catalogado,
    SAFE_DIVIDE(d.qtd_destinatarios_que_leram, NULLIF(d.qtd_destinatarios, 0)) AS taxa_leitura_da_lista,
    (d.id_noticia IS NULL)                                            AS flag_sem_lista,
    (l.id_noticia IS NULL)                                            AS flag_sem_leitura,
    COALESCE(l.flag_apagada_l, d.flag_apagada_d)                      AS flag_noticia_apagada,
    l.primeira_leitura_em,
    l.ultima_leitura_em,
    DATE_TRUNC(DATE(l.primeira_leitura_em), MONTH)                    AS mes_primeira_leitura,
    IF(l.primeira_leitura_em IS NULL, NULL, DATE_DIFF(DATE(l.ultima_leitura_em), DATE(l.primeira_leitura_em), DAY)) AS dias_entre_primeira_e_ultima_leitura,
    GREATEST(IFNULL(l.ex_l, TIMESTAMP '1970-01-01'), IFNULL(d.ex_d, TIMESTAMP '1970-01-01')) AS _extraido_trusted
  FROM l
  FULL OUTER JOIN d ON d.id_noticia = l.id_noticia
)
SELECT CAST(a.id_noticia AS STRING) AS id_noticia_alcance, a.*, 'L2_INTERNAL' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at,
  'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM agg a
