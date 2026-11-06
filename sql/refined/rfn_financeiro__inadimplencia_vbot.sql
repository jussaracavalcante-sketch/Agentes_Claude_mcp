-- rfn_financeiro__inadimplencia_vbot  ·  query-bZT5  ·  213 linhas  ·  L4 PERSONAL_DATA
-- Refined / financeiro. Grao: um TITULO A RECEBER da VBOT (cobranca em aberto ou negociada).
-- Chave: id_titulo. Origem: trs_conexa__cobranca + trs_conexa__cliente.
-- Gatilho: evento em query-rbJW (ultimo elo da cadeia Conexa). Cadencia: diaria.
--
-- FECHA A QUARTA DAS CINCO PERGUNTAS ORFAS DA CAMADA SEMANTICA. O documento do Financeiro
-- (a034ca75) e o 1-pager de 25/09 declaravam que a inadimplencia da VBOT so existia em
-- raw.supabase_public_vw_inad_titulos_vbot — camada Raw, que a §18 proibe a IA de consultar.
-- A rfn_financeiro__fluxo_caixa cobre BRM e VD e declarava explicitamente que NAO cobria a
-- VBOT. Esta cobre. Continua sem resposta so turnover/tempo de casa, que depende de uma fonte
-- de RH nao conectada.
--
-- REGRA 1 — A INADIMPLENCIA DA VBOT E R$ 54.198,56, NAO R$ 198.511,44, E A DIFERENCA E UM
--   FILTRO. Sobre os titulos vencidos, medido em 2026-09-25:
--     vigentes na origem ... 30 titulos ... R$  54.198,56   <- a inadimplencia
--     APAGADOS no Conexa ... 63 titulos ... R$ 144.312,88   <- fantasma
--   Somar sem filtrar da 3,7x o numero real. `is_inadimplencia` exige vencido E vigente, e
--   `valor_inadimplente` sai NULL quando qualquer uma falha. Os apagados CONTINUAM na tabela,
--   marcados — marcar, nunca apagar.
-- REGRA 2 — A SITUACAO VEM DA DATA, nunca do rotulo de status (mesma doutrina da
--   rfn_financeiro__fluxo_caixa, onde 285 de 395 vencidas nao carregavam `ATRASADO`).
-- REGRA 3 — `NEGOCIADA` NAO E QUITADA E ENTRA: 20 cobrancas, R$ 37.920,45, que um filtro
--   status = 'unpaid' deixaria de fora.
-- REGRA 4 — O AGING VIGENTE (2026-09-25): A_VENCER 111 titulos / 62 clientes / R$ 143.535,73 ·
--   01_30 16/12/R$ 27.046,86 · 31_60 2/2/R$ 4.137,72 · 61_90 5/4/R$ 8.841,04 ·
--   91_180 7/6/R$ 14.172,94. NAO HA TITULO VIGENTE COM MAIS DE 180 DIAS DE ATRASO.
-- REGRA 5 — AS COLUNAS RELATIVAS A HOJE SAO RELATIVAS A DATA DA CARGA. Para corte historico
--   estavel, comparar data_vencimento contra a data escolhida, nunca guardar a flag.
-- REGRA 6 — `flag_cliente_nunca_viu` e sinal de COBRANCA, nao de pagamento: o Conexa conta
--   quantas vezes o cliente abriu a fatura; zero indica que o titulo talvez nao chegou a ele.
--
-- FUSO: data_vencimento e data_competencia sao DATE na origem — nao ha fuso a tratar.
--
-- LIMITACOES — NAO CONTORNE
--   1. NAO SOMAR COM rfn_financeiro__fluxo_caixa: aquela e BRM e VD (razao Conta Azul), esta e
--      VBOT (Conexa). Sao operacoes diferentes, e a casa ja registrou pelo menos um caso de
--      cobranca da VBOT aparecendo tambem no financeiro do iClips.
--   2. `saldo_a_receber` usa valor_atual e cai para valor_original — nao e saldo com baixas
--      parciais descontadas, porque o Conexa nao publica baixa individual.
--   3. NAO HA BOLETO NEM LINHA DIGITAVEL AQUI, de proposito: a view da Raw carrega
--      linha_digitavel, boleto_url e fatura_url; sao instrumento de cobranca com acesso ao
--      pagamento, nao indicador. Quem cobra usa o sistema; quem mede usa esta tabela.
--   4. O cliente resolve pela trs_conexa__cliente (133 cadastros, cobre a base inteira) —
--      flag_cliente_nao_catalogado existe por prevencao e deve ser zero.
--
-- L4 por LINHAGEM: 4 dos 133 clientes sao PF com CPF e esta tabela propaga nome e documento.
--   Contato e endereco NAO sao propagados.

WITH titulo AS (
  SELECT
    c.id_cobranca,
    c.id_cliente,
    c.status_canonico,
    c.status_origem,
    c.is_vigente,
    c.flag_apagado_na_origem,
    c.data_vencimento,
    c.data_competencia,
    c.mes_referencia,
    c.forma_recebimento,
    c.tipo_cobranca,
    c.numero_nfse,
    c.tem_nfse,
    c.valor_original,
    c.valor_atual,
    COALESCE(c.valor_atual, c.valor_original)       AS saldo_a_receber,
    c.visualizacoes_do_cliente,
    c.qtd_vendas_na_cobranca
  FROM `vanguardamartech_trusted`.`trs_conexa__cobranca` c
  WHERE c.status_canonico IN ('EM_ABERTO', 'NEGOCIADA')
),
final AS (
  SELECT
    t.id_cobranca                                   AS id_titulo,
    t.id_cliente,
    cl.nome                                         AS cliente,
    cl.documento                                    AS cliente_documento,
    cl.is_pj                                        AS cliente_is_pj,
    cl.segmento                                     AS cliente_segmento,
    cl.uf                                           AS cliente_uf,
    cl.is_ativo                                     AS cliente_is_ativo,
    cl.is_bloqueado                                 AS cliente_is_bloqueado,
    (cl.id_cliente IS NULL)                         AS flag_cliente_nao_catalogado,

    t.is_vigente,
    t.flag_apagado_na_origem,

    t.status_canonico,
    t.status_origem,
    t.tipo_cobranca,
    t.forma_recebimento,

    t.data_vencimento,
    t.data_competencia,
    t.mes_referencia,
    DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), t.data_vencimento, DAY) AS dias_desde_o_vencimento,

    IF(t.data_vencimento < CURRENT_DATE('America/Sao_Paulo'), 'VENCIDO', 'A_VENCER')
                                                    AS situacao,
    CASE
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), t.data_vencimento, DAY) <=   0 THEN 'A_VENCER'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), t.data_vencimento, DAY) <=  30 THEN '01_30'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), t.data_vencimento, DAY) <=  60 THEN '31_60'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), t.data_vencimento, DAY) <=  90 THEN '61_90'
      WHEN DATE_DIFF(CURRENT_DATE('America/Sao_Paulo'), t.data_vencimento, DAY) <= 180 THEN '91_180'
      ELSE '181_MAIS'
    END                                             AS faixa_aging,

    (t.is_vigente AND t.data_vencimento < CURRENT_DATE('America/Sao_Paulo'))
                                                    AS is_inadimplencia,
    IF(t.is_vigente AND t.data_vencimento < CURRENT_DATE('America/Sao_Paulo'),
       t.saldo_a_receber, NULL)                     AS valor_inadimplente,
    IF(t.is_vigente AND t.data_vencimento >= CURRENT_DATE('America/Sao_Paulo'),
       t.saldo_a_receber, NULL)                     AS valor_a_vencer,

    t.saldo_a_receber,
    t.valor_original,
    t.valor_atual,
    ROUND(COALESCE(t.valor_atual, 0) - COALESCE(t.valor_original, 0), 2) AS acrescimo_sobre_o_original,

    t.numero_nfse,
    t.tem_nfse,
    t.visualizacoes_do_cliente,
    (COALESCE(t.visualizacoes_do_cliente, 0) = 0)   AS flag_cliente_nunca_viu,
    t.qtd_vendas_na_cobranca
  FROM titulo t
  LEFT JOIN `vanguardamartech_trusted`.`trs_conexa__cliente` cl
    ON cl.id_cliente = t.id_cliente
)
SELECT
  f.*,
  'VBOT'                                        AS operacao,
  'L4_PERSONAL_DATA'                            AS classificacao_dado,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'supabase-x0tz'                               AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(f)))                AS _payload_hash
FROM final f
