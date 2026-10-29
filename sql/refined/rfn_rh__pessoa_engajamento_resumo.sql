-- rfn_rh__pessoa_engajamento_resumo
-- Refined / rh. Grao: um RECORTE da base de pessoas do Qulture x situacao no Qulture -- DEPARTAMENTO, NIVEL ou FAIXA_CASA, cada um x is_ativo.
-- Chave: id_resumo (dimensao | chave | ATIVO/INATIVO). Le trs_rh__pessoa (query-eDO3, L4). AGREGA, NAO FILTRA. Nivel: L3 CONFIDENTIAL -- so contagem, soma e
-- media; nome, e-mail, cargo, gestor e a pessoa que deu ou recebeu feedback/elogio NAO atravessam.
-- REGRA 1: os tres recortes NAO se somam entre si (a mesma pessoa esta nos tres). Dentro de um recorte as linhas ATIVO e INATIVO somam as 165 pessoas.
-- REGRA 2: DEPARTAMENTO com menos de 5 pessoas (ativas + inativas) vira o rotulo '(departamentos com menos de 5 pessoas)'. O corte e por departamento, nao
--          por linha, para que a soma de engajamento de um departamento de 1 ou 2 pessoas nao seja o engajamento de uma pessoa identificavel.
-- REGRA 3: 'Nao mapeado' e departamento real da origem (58 de 165) e e mantido; nivel NULL vira '(sem nivel)' e faixa NULL vira '(sem faixa)'.
-- REGRA 4: engajamento = contagens que a origem entrega (feedbacks, elogios, PDIs, reunioes 1:1). ZERO nao e engajamento nulo: a pessoa pode nao ter usado o
--          modulo. qtd_sem_nenhum_uso conta quem tem as seis contagens em zero. Medias sao por pessoa do recorte (soma / pessoas), nao por evento.
-- REGRA 5: flag_celula_pequena marca recorte com menos de 3 pessoas; a linha fica, marcada.
-- LIMITACOES - NAO CONTORNE: o Qulture NAO e o RH formal (165 contra 293 no headcount de rfn_rh__turnover_mensal): is_ativo aqui e o do Qulture e nao soma com
--   headcount nem com desligamento; nao ha data de cada feedback, elogio ou 1:1 nesta tabela (so o acumulado), logo nao ha serie temporal de engajamento;
--   feedback e elogio dados e recebidos sao contagens separadas e nao se compensam (a soma dos dados nao e a dos recebidos); equipes (array) nao entra.
WITH p AS (
  SELECT
    t.*,
    IFNULL(t.departamento, '(sem departamento)') AS depto_k,
    IFNULL(t.nivel, '(sem nivel)')               AS nivel_k,
    IFNULL(t.faixa_casa, '(sem faixa)')          AS faixa_k
  FROM `vanguardamartech_trusted`.`trs_rh__pessoa` t
),
depto_n AS (SELECT depto_k, COUNT(*) AS n FROM p GROUP BY depto_k),
expandido AS (
  SELECT 'DEPARTAMENTO' AS dimensao,
    IF(dn.n < 5, '(departamentos com menos de 5 pessoas)', p.depto_k) AS chave,
    p.is_ativo, p.gestor, p.is_email_corporativo, p.qtd_equipes, p.feedbacks_dados, p.feedbacks_recebidos, p.elogios_dados, p.elogios_recebidos,
    p.pdis, p.reunioes_1a1, p.tem_engajamento, p._extraido_at
  FROM p JOIN depto_n dn ON dn.depto_k = p.depto_k
  UNION ALL
  SELECT 'NIVEL', nivel_k, is_ativo, gestor, is_email_corporativo, qtd_equipes, feedbacks_dados, feedbacks_recebidos, elogios_dados, elogios_recebidos,
    pdis, reunioes_1a1, tem_engajamento, _extraido_at
  FROM p
  UNION ALL
  SELECT 'FAIXA_CASA', faixa_k, is_ativo, gestor, is_email_corporativo, qtd_equipes, feedbacks_dados, feedbacks_recebidos, elogios_dados, elogios_recebidos,
    pdis, reunioes_1a1, tem_engajamento, _extraido_at
  FROM p
),
agg AS (
  SELECT
    dimensao, chave, is_ativo,
    COUNT(*)                                                  AS qtd_pessoas,
    COUNTIF(gestor IS NOT NULL)                               AS qtd_com_gestor,
    COUNTIF(is_email_corporativo)                             AS qtd_email_corporativo,
    COUNTIF(qtd_equipes > 0)                                  AS qtd_em_equipe,
    COUNTIF(tem_engajamento)                                  AS qtd_com_registro_de_engajamento,
    COUNTIF(IFNULL(pdis, 0) > 0)                              AS qtd_com_pdi,
    COUNTIF(IFNULL(reunioes_1a1, 0) > 0)                      AS qtd_com_1a1,
    COUNTIF(IFNULL(feedbacks_dados, 0) + IFNULL(feedbacks_recebidos, 0) + IFNULL(elogios_dados, 0) + IFNULL(elogios_recebidos, 0)
            + IFNULL(pdis, 0) + IFNULL(reunioes_1a1, 0) = 0)  AS qtd_sem_nenhum_uso,
    SUM(feedbacks_dados)                                      AS soma_feedbacks_dados,
    SUM(feedbacks_recebidos)                                  AS soma_feedbacks_recebidos,
    SUM(elogios_dados)                                        AS soma_elogios_dados,
    SUM(elogios_recebidos)                                    AS soma_elogios_recebidos,
    SUM(pdis)                                                 AS soma_pdis,
    SUM(reunioes_1a1)                                         AS soma_reunioes_1a1,
    ROUND(AVG(pdis), 2)                                       AS media_pdis_por_pessoa,
    ROUND(AVG(reunioes_1a1), 2)                               AS media_reunioes_1a1_por_pessoa,
    MAX(_extraido_at)                                         AS _extraido_trusted
  FROM expandido
  GROUP BY dimensao, chave, is_ativo
),
calc AS (
  SELECT
    CONCAT(dimensao, '|', chave, '|', IF(is_ativo IS NULL, 'SEM_STATUS', IF(is_ativo, 'ATIVO', 'INATIVO'))) AS id_resumo,
    a.*,
    (qtd_pessoas < 3)                                         AS flag_celula_pequena
  FROM agg a
)
SELECT
  c.*,
  'L3_CONFIDENTIAL'                                           AS classificacao_dado,
  CURRENT_TIMESTAMP()                                         AS _extraido_at,
  'supabase-x0tz'                                             AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(c)))                              AS _payload_hash
FROM calc c
