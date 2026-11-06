-- rfn_financeiro__contazul_transferencia_mensal  ·  Refined / financeiro  ·  L3 CONFIDENTIAL (movimento entre contas proprias por empresa e mes)
-- Grao: operacao x MES, com os DOIS registros de transferencia lado a lado: o FATO dedicado (trs_contazul__transferencia, um lado so) e o RAZAO
-- (trs_contazul__movimento, classe TRANSFERENCIA, vigente, lancado dos dois lados). Le: query-62fG + query-rtu2. Gatilho: evento em query-62fG.
-- Identidade (19/10/2026): fato 286 transferencias = 286 · R$ 7.134.234,92 (BRM 253 / R$ 6.556.020,45; VD 33 / R$ 578.214,47) · 286 contas de origem e 286 de destino resolvem em trs_contazul__apoio.
--    razao vigente: ENTRADA 82 / R$ 1.306.692,83 · SAIDA 70 / R$ 1.067.293,31.
-- R1 TRANSFERENCIA NAO E RECEITA NEM CUSTO: nao entra em resultado. Esta tabela existe para medir o movimento entre contas, nao para soma-lo a nada.
-- R2 OS DOIS LADOS DO RAZAO NAO BATEM, E ISSO E REMEDIDO AQUI A CADA CARGA: em 25/09 a diferenca era R$ 309.813,52 sobre 115 linhas; em 19/10 e
--    R$ 239.399,52 sobre 152 (entrada maior). `diferenca_razao_entrada_saida` sai por mes com sinal; NADA e pareado nem corrigido -- um lado sem par e artefato de lancamento, nao dinheiro.
-- R3 O FATO E O RAZAO NAO SAO O MESMO REGISTRO: o fato soma R$ 7,13 mi e o razao (um lado) R$ 1,3 mi; o fato vem do endpoint de transferencia da API e o razao so
--    pega parcelas categorizadas como 'transferencia entre contas' (tres grafias). Juncao por (operacao, mes) e so para leitura comparada: FULL OUTER, mes com um lado so fica com o outro NULL.
-- R4 O fato comeca em 2026-01 (5 linhas) e o grosso e 2026-06 em diante (virada do ERP). Mes do fato = data_transferencia; mes do razao = data_competencia.
--    9 linhas: 7 com os dois lados, 2 so no fato (flag_so_no_fato), 0 so no razao.
-- LIMITACAO -- NAO CONTORNE: a descricao da transferencia (texto livre) nao atravessa; sweep da conta IP esta em outra tabela (rfn_financeiro__extrato_sweep_mensal) e nao se soma a esta.
WITH fato AS (
  SELECT operacao, DATE_TRUNC(data_transferencia, MONTH) AS mes,
         COUNT(*) AS qtd_transferencias, ROUND(SUM(valor), 2) AS valor_transferido,
         COUNT(DISTINCT id_conta_origem) AS qtd_contas_origem, COUNT(DISTINCT id_conta_destino) AS qtd_contas_destino,
         COUNT(DISTINCT CONCAT(id_conta_origem, '>', id_conta_destino)) AS qtd_pares_conta,
         ROUND(MAX(valor), 2) AS maior_transferencia
  FROM `vanguardamartech_trusted`.`trs_contazul__transferencia`
  GROUP BY 1, 2
),
razao AS (
  SELECT operacao, mes_competencia AS mes,
         COUNTIF(sentido = 'ENTRADA') AS qtd_razao_entrada, ROUND(SUM(IF(sentido = 'ENTRADA', valor, 0)), 2) AS valor_razao_entrada,
         COUNTIF(sentido = 'SAIDA') AS qtd_razao_saida, ROUND(SUM(IF(sentido = 'SAIDA', valor, 0)), 2) AS valor_razao_saida
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  WHERE classe_financeira = 'TRANSFERENCIA' AND is_vigente
  GROUP BY 1, 2
),
agg AS (
  SELECT
    COALESCE(f.operacao, r.operacao) AS operacao,
    COALESCE(f.mes, r.mes)           AS mes,
    f.qtd_transferencias, f.valor_transferido, f.qtd_contas_origem, f.qtd_contas_destino, f.qtd_pares_conta, f.maior_transferencia,
    r.qtd_razao_entrada, r.valor_razao_entrada, r.qtd_razao_saida, r.valor_razao_saida,
    IF(r.operacao IS NOT NULL, ROUND(r.valor_razao_entrada - r.valor_razao_saida, 2), NULL) AS diferenca_razao_entrada_saida,
    (f.operacao IS NULL)             AS flag_so_no_razao,
    (r.operacao IS NULL)             AS flag_so_no_fato
  FROM fato f FULL OUTER JOIN razao r ON r.operacao = f.operacao AND r.mes = f.mes
),
final AS (
  SELECT CONCAT(operacao, '|', CAST(mes AS STRING)) AS id_transferencia_mensal, g.*, 'L3_CONFIDENTIAL' AS classificacao_dado FROM agg g
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
