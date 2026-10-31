-- rfn_financeiro__receita_tipo_mensal
-- Refined / financeiro. Grao: mes x empresa x fonte x tipo de receita (CLIENTE, BV, CONTA_ORDEM) x linha de servico x projecao x pago. Le trs_financeiro__receita_cliente.
-- Nivel: L3 CONFIDENTIAL (agregado; nenhum cliente, documento ou razao social atravessa).
-- REGRA 1: SEMPRE filtrar ou agrupar por tipo_receita. CLIENTE e a receita do cliente; BV e a bonificacao de veiculo (R$ 3,27 mi, iClips + Conta Azul), que NAO e receita do cliente;
--          CONTA_ORDEM e repasse e nao e receita da casa. Somar os tres conta dinheiro de naturezas diferentes.
-- REGRA 2: o mes e o de competencia (DATE(ano, mes, 1) da origem); is_projecao e is_pago vem da origem e ficam no grao: nao se somam como se fossem a mesma coisa.
-- REGRA 3: qtd_clientes e a contagem de chaves de cliente DENTRO da linha e NAO e aditiva (o mesmo cliente aparece em varias linhas): nao somar entre linhas.
-- REGRA 4: qtd_sem_documento conta linhas cujo cliente nao tem CNPJ/CPF valido (chave por nome); qtd_pf conta linhas de pessoa fisica (CPF de 11 digitos).
-- LIMITACOES - NAO CONTORNE: nao soma com rfn_financeiro__receita_cliente_mensal (outra metodologia, por documento), com trs_financeiro__movimento nem com
--   rfn_financeiro__mov_classif_mensal (receita de competencia ali e R$ 66,54 mi; aqui R$ 58,70 mi, so o que se liga a cliente); nao ha documento nem nome aqui;
--   ate 2028 ha projecao (is_projecao).
WITH r AS (
  SELECT * FROM vanguardamartech_trusted.trs_financeiro__receita_cliente
)
SELECT
  CONCAT(CAST(mes_referencia AS STRING), '|', empresa, '|', fonte, '|', IFNULL(tipo_receita, '-'), '|', IFNULL(linha_servico, '-'), '|',
         CAST(is_projecao AS STRING), '|', CAST(is_pago AS STRING)) AS id_receita_tipo_mensal,
  mes_referencia,
  empresa,
  fonte,
  tipo_receita,
  linha_servico,
  is_projecao,
  is_pago,
  COUNT(*)                                           AS qtd_lancamentos,
  SUM(valor)                                         AS valor,
  COUNT(DISTINCT cliente_key)                        AS qtd_clientes,
  COUNTIF(documento IS NULL)                         AS qtd_sem_documento,
  COUNTIF(is_pf)                                     AS qtd_pf,
  'L3_CONFIDENTIAL'                                  AS classificacao_dado,
  CURRENT_TIMESTAMP()                                AS _extraido_at,
  'supabase-x0tz'                                    AS _fonte
FROM r
GROUP BY mes_referencia, empresa, fonte, tipo_receita, linha_servico, is_projecao, is_pago
