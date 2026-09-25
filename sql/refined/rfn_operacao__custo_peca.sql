-- rfn_operacao__custo_peca
-- Refined / dominio Operacao. Grao: uma peca de job do iClips. Chave: id_job_peca.
-- Le rfn_operacao__peca, trs_iclips__peca, trs_iclips__peca_tipo e trs_financeiro__movimento.
--
-- PARA QUE SERVE
--   E a base de CUSTO POR PECA. A rfn_operacao__peca diz, na propria descricao, que
--   NAO responde custo, porque hora apontada existe em 1,2% das pecas. Esta tabela
--   troca o caminho: em vez de medir o esforco de cada peca, ela rateia o custo
--   operacional REAL do mes sobre as pecas daquele mes, usando o valor de tabela da
--   peca como peso de complexidade. Cobertura do peso: 43,3% das pecas. Cobertura do
--   custo: 100% das pecas de mes fechado -- porque quem nao tem peso recebe o rateio
--   simples, e a soma continua fechando no centavo.
--
-- CLASSIFICACAO: **L3 -- CONFIDENTIAL** (ADR-0010 sec. 31: "contratos, custos,
--   margens, propostas comerciais"). Acrescentado em 2026-09-23. A tabela inteira e
--   custo da casa atribuido a cliente -- nao vai para painel de cliente. **NAO e L4**:
--   le a `trs_financeiro__movimento` (que e L4, por carregar folha nominal) apenas
--   AGREGADA POR MES, entao nenhum CPF de colaborador chega aqui. O unico
--   identificador que viaja e o CNPJ do cliente.
--
-- REGRAS DE NEGOCIO
--
-- R1 -- `valor_tabela_peca` E PRECO E NAO ENTRA NO CUSTO.
--   Ela vem do catalogo do iClips e diz quanto a peca VALE, nao quanto CUSTA. Aqui
--   ela e usada SO como peso relativo dentro do mes. Quem somar valor_tabela_peca
--   esta somando receita potencial, nao custo -- e as duas colunas convivem na
--   mesma linha exatamente para que a diferenca fique visivel.
--
-- R2 -- MES SEM DESPESA COMPLETA NAO RECEBE CUSTO, E NAO RECEBE ZERO.
--   A despesa da casa esta completa ate a competencia 2026-05. 2026-06 tem 7
--   lancamentos e 2026-07 em diante tem ZERO, enquanto a base de pecas segue ate
--   2026-09. Somar assim mostraria o custo desabando e a margem explodindo.
--   O corte NAO e uma data escrita a mao: o mes e considerado fechado quando tem ao
--   menos 30% da MEDIANA de lancamentos dos meses de 2023 em diante. Medido em
--   2026-09-23 a mediana e 379, o piso e 114, e o criterio separa exatamente o que
--   se esperava: fecha 2022-12 a 2026-05 e deixa de fora 2021-01 a 2022-11 (quando a
--   despesa ainda nao era lancada, 0 a 33 linhas por mes) e 2026-06 em diante
--   (2026-06 tem 6 lancamentos, 2026-07 a 2026-09 tem zero). O criterio continua
--   valendo quando a base andar -- nenhuma data precisa ser reescrita.
--   Mes aberto ou peca sem mes: `custo_peca` sai NULL e `motivo_sem_custo` diz qual
--   dos dois. NULL obriga a decidir; zero seria somado.
--
-- R3 -- O RATEIO TEM DUAS ROTAS E A SOMA FECHA EXATAMENTE NO CUSTO DO MES.
--   Seja, no mes m: C = custo operacional realizado, n = pecas do mes,
--   k = pecas com valor de tabela, V = soma dos valores de tabela do mes.
--     peca COM valor v ....... custo = C * (k/n) * (v/V)   -> soma C*(k/n)
--     peca SEM valor ......... custo = C / n               -> soma C*(n-k)/n
--   Total = C, sempre. A parcela do custo que cabe ao subconjunto precificado e
--   proporcional ao TAMANHO desse subconjunto, e so dentro dele o valor pesa.
--   A alternativa NAO tomada era distribuir C inteiro so entre as pecas com valor:
--   isso encareceria cada uma delas em ~2,5 vezes e zeraria as outras 57%.
--   A outra alternativa NAO tomada era imputar valor para quem nao tem, pela mediana
--   da categoria. Ela foi descartada com numero: Social Media tem 70.257 pecas e so
--   23,1% precificadas -- imputar a mediana de R$ 95 inventaria peso para 54 mil
--   pecas. Aqui nada e imputado; `origem_do_custo` declara a rota linha a linha.
--
-- R4 -- O CUSTO E DA PECA REGISTRADA NO MES, NAO DA PECA ENTREGUE.
--   Nao ha como provar entrega nesta base: `status_peca_codigo` tem 5 valores
--   (5, -1, 6, 12, 13) e NAO existe tabela de dominio que diga qual e "concluida".
--   O rateio e sobre a peca que existe no mes de referencia. Dizer "entregue" seria
--   afirmar o que a base nao afirma.
--
-- R5 -- CLIENTE E O CNPJ, HERDADO DA REGRA 1 DA rfn_operacao__peca.
--   O CNPJ e o unico identificador juridico de cliente do iClips. NAO ha unificacao
--   por nome nem por grupo (R-003). `cliente_sk` NAO entra aqui de proposito: a
--   rfn_cadastro__cliente_sk anda na cadeia semanal do VJOB e esta cadeia anda com o
--   iClips -- amarrar as duas faria uma quebrar a outra. Quem quiser a identidade
--   entre sistemas junta por `cliente_cnpj` = `documento` na leitura.
--
-- R6 -- O CUSTO POR HORA CONTINUA NA LINHA, SO PARA COMPARACAO.
--   `custo_apontado_hora` cobre 1.050 pecas de 134.751 (0,8%). Ele fica ao lado do
--   custo rateado para que a diferenca de cobertura seja verificavel, nao para ser
--   somado. As duas colunas NUNCA se somam: sao o mesmo custo por dois caminhos.
--
-- LIMITACOES -- NAO CONTORNE
--   1. O rateio e uma ATRIBUICAO, nao uma medicao. Ele responde "quanto do custo da
--      casa coube a esta peca", nao "quanto esta peca consumiu". Cliente com muitas
--      pecas baratas e cliente com poucas pecas caras recebem custo pela regra R3, e
--      a regra e uma escolha declarada -- nao um fato medido.
--   2. O peso cobre 43,3% das pecas, e a concentracao NAO e uniforme: Off 95%,
--      Inbound 97%, Dev 99%, contra Social Media 23% -- e Social Media e 52% da base.
--      Na pratica o peso diferencia bem o que e OFF e mal o que e social.
--   3. Custo de MIDIA nao esta aqui e nao deve ser somado a isto. Veiculacao e
--      impulsionamento por conta e ordem sao repasse, ficam fora de
--      `is_custo_operacional` na Trusted e nao pertencem ao custo de producao.
--   4. A JANELA UTIL E 2022-12 A 2026-05, 42 meses. Fora dela o custo e NULL por
--      construcao: antes, porque a despesa nao era lancada; depois, porque ainda nao
--      foi carregada. Isso deixa 85.539 das 134.751 pecas com custo (63,5%) --
--      49.212 ficam sem, e o motivo esta escrito em `motivo_sem_custo`, nunca em
--      um zero.
WITH peca AS (
  SELECT
    r.id_job_peca,
    p.id_peca,
    r.cliente_nome,
    r.cliente_cnpj,
    r.cliente_identificado,
    r.mes_referencia,
    r.data_inicio,
    r.registro_confiavel,
    r.nome_peca,
    r.status_peca,
    r.qtd_etapas,
    r.origem_do_retrabalho,
    r.teve_retrabalho,
    r.qtd_retrabalho,
    r.tempo_estimado_horas,
    r.tempo_real_horas,
    r.custo_apontado          AS custo_apontado_hora,
    r.custo_incompleto        AS flag_custo_hora_incompleto
  FROM `vanguardamartech_refined`.`rfn_operacao__peca` r
  -- INNER: o id do TIPO de peca so existe na Trusted; sem ele nao ha peso possivel.
  -- Medido em 2026-09-23: as duas tabelas tem o mesmo grao e a juncao nao perde linha.
  JOIN `vanguardamartech_trusted`.`trs_iclips__peca` p
    ON p.id_job_peca = r.id_job_peca
),
tipo AS (
  SELECT
    id_peca,
    nome_peca                AS nome_tipo_peca,
    categoria                AS categoria_tipo_peca,
    categoria_normalizada    AS categoria_tipo_peca_normalizada,
    valor_tabela             AS valor_tabela_peca,
    id_peca_canonica,
    peca_canonica,
    grupo_canonico,
    prefixo_canonico
  FROM `vanguardamartech_trusted`.`trs_iclips__peca_tipo`
),
peca_tipada AS (
  SELECT pc.*, t.* EXCEPT (id_peca)
  FROM peca pc
  LEFT JOIN tipo t ON t.id_peca = pc.id_peca
),
-- R2: custo operacional realizado por competencia, com a contagem de lancamentos
-- ao lado, que e o que denuncia mes incompleto.
custo_mes_bruto AS (
  SELECT
    mes_competencia          AS mes,
    SUM(valor_abs)           AS custo_operacional_mes,
    COUNT(*)                 AS qtd_lancamentos_mes
  FROM `vanguardamartech_trusted`.`trs_financeiro__movimento`
  WHERE is_custo_operacional
  GROUP BY 1
),
referencia_lancamentos AS (
  SELECT APPROX_QUANTILES(qtd_lancamentos_mes, 2)[OFFSET(1)] AS mediana_lancamentos
  FROM custo_mes_bruto
  WHERE mes >= '2023-01-01'
),
custo_mes AS (
  SELECT
    c.mes,
    c.custo_operacional_mes,
    c.qtd_lancamentos_mes,
    r.mediana_lancamentos,
    (c.qtd_lancamentos_mes >= 0.3 * r.mediana_lancamentos) AS is_mes_fechado
  FROM custo_mes_bruto c
  CROSS JOIN referencia_lancamentos r
),
-- R3: os denominadores do rateio, um por mes.
peso_mes AS (
  SELECT
    mes_referencia                       AS mes,
    COUNT(*)                             AS qtd_pecas_no_mes,
    COUNTIF(valor_tabela_peca IS NOT NULL) AS qtd_pecas_com_valor_no_mes,
    SUM(valor_tabela_peca)               AS soma_valor_tabela_no_mes
  FROM peca_tipada
  WHERE mes_referencia IS NOT NULL
  GROUP BY 1
),
calculado AS (
  SELECT
    pt.*,
    cm.custo_operacional_mes,
    cm.qtd_lancamentos_mes,
    COALESCE(cm.is_mes_fechado, FALSE)   AS is_mes_com_custo_fechado,
    pm.qtd_pecas_no_mes,
    pm.qtd_pecas_com_valor_no_mes,
    pm.soma_valor_tabela_no_mes,
    CASE
      WHEN pt.mes_referencia IS NULL                       THEN 'SEM_MES_REFERENCIA'
      WHEN cm.mes IS NULL                                  THEN 'MES_SEM_DESPESA_NA_BASE'
      WHEN NOT cm.is_mes_fechado                           THEN 'MES_SEM_CUSTO_FECHADO'
      WHEN pt.valor_tabela_peca IS NOT NULL
       AND pm.soma_valor_tabela_no_mes > 0                 THEN 'RATEIO_PONDERADO_POR_VALOR'
      ELSE                                                      'RATEIO_SIMPLES_SEM_VALOR'
    END                                                    AS origem_do_custo
  FROM peca_tipada pt
  LEFT JOIN custo_mes cm ON cm.mes = pt.mes_referencia
  LEFT JOIN peso_mes  pm ON pm.mes = pt.mes_referencia
),
final AS (
  SELECT
    c.id_job_peca,
    c.id_peca,
    c.nome_peca,
    c.nome_tipo_peca,
    c.categoria_tipo_peca,
    c.categoria_tipo_peca_normalizada,
    c.id_peca_canonica,
    c.peca_canonica,
    c.grupo_canonico,
    c.prefixo_canonico,

    c.cliente_nome,
    c.cliente_cnpj,
    c.cliente_identificado,

    c.mes_referencia,
    EXTRACT(YEAR  FROM c.mes_referencia)          AS ano,
    EXTRACT(MONTH FROM c.mes_referencia)          AS mes,
    c.data_inicio,
    c.registro_confiavel,
    c.status_peca,

    -- R1: preco, nao custo
    c.valor_tabela_peca,
    (c.valor_tabela_peca IS NULL)                 AS flag_peca_sem_valor_tabela,

    -- R3: o custo
    CASE c.origem_do_custo
      WHEN 'RATEIO_PONDERADO_POR_VALOR' THEN
        c.custo_operacional_mes
          * SAFE_DIVIDE(c.qtd_pecas_com_valor_no_mes, c.qtd_pecas_no_mes)
          * SAFE_DIVIDE(c.valor_tabela_peca, c.soma_valor_tabela_no_mes)
      WHEN 'RATEIO_SIMPLES_SEM_VALOR' THEN
        SAFE_DIVIDE(c.custo_operacional_mes, c.qtd_pecas_no_mes)
      ELSE NULL
    END                                           AS custo_peca,
    c.origem_do_custo,
    IF(c.origem_do_custo IN ('SEM_MES_REFERENCIA','MES_SEM_DESPESA_NA_BASE','MES_SEM_CUSTO_FECHADO'),
       c.origem_do_custo, NULL)                   AS motivo_sem_custo,

    -- contexto do rateio na propria linha: quem le o custo ve o denominador
    c.custo_operacional_mes,
    c.qtd_lancamentos_mes,
    c.is_mes_com_custo_fechado,
    c.qtd_pecas_no_mes,
    c.qtd_pecas_com_valor_no_mes,
    c.soma_valor_tabela_no_mes,
    SAFE_DIVIDE(c.qtd_pecas_com_valor_no_mes, c.qtd_pecas_no_mes) AS cobertura_valor_no_mes,

    -- R6: o caminho antigo, so para comparacao. NAO somar com custo_peca.
    c.custo_apontado_hora,
    c.flag_custo_hora_incompleto,
    c.tempo_estimado_horas,
    c.tempo_real_horas,

    c.qtd_etapas,
    c.teve_retrabalho,
    c.qtd_retrabalho,
    c.origem_do_retrabalho
  FROM calculado c
)
SELECT
  f.*,
  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'supabase-x0tz'                                 AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                  AS _payload_hash
FROM final f
