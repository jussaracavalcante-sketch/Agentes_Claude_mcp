-- rfn_social__audiencia_conta  ·  Refined / social  ·  L2
-- Grao: uma CONTA, uma DIMENSAO (IDADE, GENERO, PAIS, CIDADE) e um VALOR.
-- Chave: id_audiencia_conta = <id_conta>:<dimensao>:<valor>.
-- Origem: trs_instagram__audiencia_seguidor + trs_instagram__conta. Gatilho: evento (regra
-- all) nas duas. Fotografia SEM data: nao ha serie. L2 (contagem por segmento).
-- Regras numeradas, validacao e limitacoes: na descricao da transformacao.
--
-- R1 as dimensoes nao se somam entre si · R2 DOIS denominadores, os dois explicitos: a soma
-- da dimensao e os seguidores da conta · R3 PAIS e CIDADE sao top 45: a participacao dentro
-- da dimensao superestima, e a flag diz isso · R4 cobertura da dimensao sobre seguidores.
WITH a AS (
  SELECT
    id_conta, dimensao, valor_dimensao, qtd_seguidores, flag_lista_truncada_no_top,
    SUM(qtd_seguidores) OVER (PARTITION BY id_conta, dimensao)  AS soma_da_dimensao,
    RANK() OVER (PARTITION BY id_conta, dimensao ORDER BY qtd_seguidores DESC) AS posicao_na_dimensao
  FROM `vanguardamartech_trusted`.`trs_instagram__audiencia_seguidor`
)
SELECT
  CONCAT(a.id_conta, ':', a.dimensao, ':', a.valor_dimensao) AS id_audiencia_conta,
  a.id_conta,
  c.usuario,
  a.dimensao,
  a.valor_dimensao,
  a.qtd_seguidores,
  a.posicao_na_dimensao,
  -- R2 - participacao dentro da dimensao (denominador = soma dos valores listados).
  a.soma_da_dimensao,
  ROUND(SAFE_DIVIDE(a.qtd_seguidores, NULLIF(a.soma_da_dimensao, 0)), 4) AS participacao_na_dimensao,
  -- R2 - participacao sobre os seguidores da conta (denominador = seguidores da fotografia).
  c.seguidores                                             AS seguidores_da_conta,
  ROUND(SAFE_DIVIDE(a.qtd_seguidores, NULLIF(c.seguidores, 0)), 4) AS participacao_nos_seguidores,
  -- R4 - quanto da base a dimensao cobre.
  ROUND(SAFE_DIVIDE(a.soma_da_dimensao, NULLIF(c.seguidores, 0)), 4) AS cobertura_da_dimensao_sobre_seguidores,
  -- R3 - lista cortada no top 45: a cauda nao existe aqui.
  a.flag_lista_truncada_no_top,
  c.data_snapshot_seguidores,
  CURRENT_TIMESTAMP()                                      AS _extraido_at,
  'instagram'                                              AS _fonte
FROM a
LEFT JOIN `vanguardamartech_trusted`.`trs_instagram__conta` c ON c.id_conta = a.id_conta
