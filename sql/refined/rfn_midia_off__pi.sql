-- rfn_midia_off__pi
-- Refined / dominio Midia OFF - PI de veiculacao fora do digital. Grao: um PI.
-- Le trusted.trs_pi__insercao (query-iX2P). Gatilho: evento nela.
-- Espelha o Dashboard de Midia OFF do VJOB, mas com as escolhas DECLARADAS.
--
-- ============================ REGRAS DE NEGOCIO ============================
--
-- REGRA 1 - ESCOPO: midia OFF e tudo que NAO e `Internet`.
--   Dos 18 tipos da base, `Internet` (29 PIs, R$ 125.241,02) e o unico digital e fica
--   de fora. DOOH, painel eletronico e TV indoor SAO midia OFF: sao telas fora de casa,
--   nao compra de midia online. Alternativa NAO tomada: montar uma lista branca de
--   tipos OFF -- rejeitada porque tipo novo entraria silenciosamente como OFF errado
--   ou ficaria de fora sem ninguem notar; com lista negra de um item, tipo novo aparece.
--
-- REGRA 2 - PI CANCELADO NAO E EXCLUIDO, E MARCADO. `eh_vigente` = NOT is_cancelado.
--   Sao 228 cancelados na base, 223 com valor, R$ 2.087.562,09 (4,4%). Quem totaliza
--   verba usa `WHERE eh_vigente`. Manter a linha preserva a taxa de cancelamento, que
--   se perde se a Refined apagar.
--
-- REGRA 3 - GRAFIA DE tipo_midia E NORMALIZADA, MIDIA NAO E FUNDIDA.
--   `Front Light` -> `Frontlight` e `Mobilário Urbano` -> `Mobiliário Urbano` (acento
--   que falta na origem). Sao a MESMA midia escrita de dois jeitos, e a diferenca nao e
--   cosmetica: ver a regra 4. `Dooh` e `OOH` NAO sao fundidos - sao midias diferentes.
--   O rotulo cru fica em `tipo_midia_origem` para auditoria.
--
-- REGRA 4 - O MOTIVO DE NAO TER ACOMPANHAMENTO E CALCULADO, NAO CHUTADO.
--   Medido em 18/09/2026: 285 dos 3.348 PIs nao aparecem na gold_vw_pi_monitoramento.
--   228 sao cancelados (a view exclui cancelado, corretamente). Os outros 57 tem causa:
--     - 50 PIs (R$ 363.435,67) tem tipo_midia FORA DA LISTA FIXA da view do Supabase.
--       O caso que denuncia o mecanismo: `Frontlight` tem 4 PIs e 100% de cobertura,
--       `Front Light` tem 3 e ZERO. Um espaco. A view filtra por rotulo literal.
--       Os sete tipos sem cobertura nenhuma: Internet, Dooh, Shopping, Front Light,
--       Acao, Jornal, Mega Banner.
--     - 5 PIs sao CLIENTE TESTE ou VBOT (interno), R$ 30.744,00.
--     - 2 PIs de Mobilário Urbano sem data_inicio, valor zero.
--   `tipo_coberto_no_monitoramento` e calculado DA PROPRIA TABELA (existe pelo menos um
--   PI daquele tipo com acompanhamento?), nao de lista fixa. Se a view do Supabase
--   passar a cobrir um tipo, esta coluna acompanha sozinha -- repetir a lista fixa aqui
--   seria copiar o defeito que ela diagnostica.
--   IMPORTANTE: a cobertura e medida sobre o rotulo CRU, nao o normalizado. Normalizar
--   antes mascararia o caso `Front Light`, que e o unico sintoma visivel do problema.
--   NESTA TABELA aparecem 32 dos 57, nao os 57: os outros 25 sao de `Internet`, que a
--   regra 1 deixa fora do escopo de midia OFF. Validado em 18/09/2026 sobre os 3.319 PIs
--   em escopo: 3.063 cobertos, 224 cancelados, 25 por tipo fora da view, 5 de teste,
--   2 sem data -- e ZERO em "sem causa identificada". Toda linha tem causa.
--
-- REGRA 5 - `sem_periodo_completo` = data_inicio OU data_fim ausente.
--   E o mesmo indicador do painel do VJOB ("inicio ou fim nao informado"). Sao 31 PIs
--   na base inteira. NAO e o mesmo que PI errado: e cronograma por preencher.
--
-- REGRA 6 - CLIENTE DE TESTE E MARCADO, NAO REMOVIDO. `eh_cliente_teste` cobre
--   `CLIENTE TESTE` e `VBOT`. Quem reporta para fora filtra; quem audita precisa ver.
--
-- ===================== LIMITACOES - NAO CONTORNE =====================
--
-- A BASE ESTA PARADA E O NUMERO DAQUI NAO E O NUMERO DA AGENCIA. Comparacao direta com
-- o Dashboard de Midia OFF do VJOB em 18/09/2026, competencia 2026-09:
--     PIs cadastrados      VJOB 113           aqui  32      (28%)
--     Valor total          VJOB R$ 970.799,32 aqui  R$ 218.628,60  (23%)
--     Comissao estimada    VJOB R$ 185.387,31 aqui  R$  43.725,72  (24%)
--     Sem periodo completo VJOB 43            aqui   0
-- Os 43 "sem periodo completo" do painel sao exatamente os PIs novos que nao chegaram:
-- o maior PI da base e 22930 e o painel ja mostra 23009. A causa e o worker que carrega
-- silver.pi_insercao do lado do Supabase, FORA da Nekt. Enquanto nao destravar, NAO use
-- esta tabela para fechar mes -- use para serie historica ate 06/08/2026.
--
-- DOIS INDICADORES DO PAINEL NAO ESTAO AQUI, DE PROPOSITO: "iniciando em ate 3 dias" e
-- "em veiculacao hoje". Os dois dependem de CURRENT_DATE e CONGELAM ao materializar,
-- virando mentira silenciosa no dia seguinte. Calcule na leitura:
--     iniciando_em_3_dias: WHERE eh_vigente AND data_inicio BETWEEN CURRENT_DATE('America/Manaus')
--                                AND DATE_ADD(CURRENT_DATE('America/Manaus'), INTERVAL 3 DAY)
--     em_veiculacao_hoje : WHERE eh_vigente AND CURRENT_DATE('America/Manaus')
--                                BETWEEN data_inicio AND data_fim
-- Pela mesma razao, as colunas proxima_acao / acao_prazo / ind_* da Trusted nao sao
-- trazidas: nascem de CURRENT_DATE dentro da view do Supabase e ja chegam congeladas.
--
-- COMISSAO ESTIMADA E `valor_comissao_veiculo`, COMO A ORIGEM ENTREGA. Nao e recalculada.
-- Conferido contra o painel: a razao comissao/valor da 20,0% aqui e 19,1% no VJOB, o que
-- confirma a coluna. A diferenca e composicao de tipo de midia, nao formula.
WITH base AS (
  SELECT *
  FROM `vanguardamartech_trusted`.`trs_pi__insercao`
  WHERE TRIM(tipo_midia) <> 'Internet'          -- regra 1
),
-- regra 4: cobertura medida sobre o rotulo CRU, da propria tabela, nunca de lista fixa
cobertura_por_tipo AS (
  SELECT
    tipo_midia,
    LOGICAL_OR(tem_acompanhamento) AS tipo_coberto_no_monitoramento
  FROM base
  GROUP BY tipo_midia
)
SELECT
  b.id_pi,
  b.cliente,
  b.numero_projeto,
  b.nome_projeto,
  b.projeto_nome_iclips,
  b.tem_projeto_no_iclips,

  -- regra 3: grafia normalizada, midia nao fundida
  CASE TRIM(b.tipo_midia)
    WHEN 'Front Light'      THEN 'Frontlight'
    WHEN 'Mobilário Urbano' THEN 'Mobiliário Urbano'
    ELSE TRIM(b.tipo_midia)
  END                                            AS tipo_midia,
  b.tipo_midia                                   AS tipo_midia_origem,

  b.veiculo,
  b.razao_social_veiculo,
  b.cnpj_veiculo,
  b.praca,

  b.data_inicio,
  b.data_fim,
  b.mes_competencia,
  b.mes_referencia,

  b.insercoes,
  b.valor_negociado,
  b.valor_comissao_veiculo                       AS comissao_estimada,
  b.valor_liquido,
  b.valor_faturado_cliente,

  b.responsavel,
  b.status_proposta,
  b.data_aprovacao_proposta,
  b.status_midia,
  b.faturamento,
  b.tipo_faturamento,
  b.is_faturado,
  b.is_cancelado,

  -- ===== indicadores declarativos (nao dependem de hoje) =====
  NOT b.is_cancelado                             AS eh_vigente,                 -- regra 2
  (b.data_inicio IS NULL OR b.data_fim IS NULL)  AS sem_periodo_completo,       -- regra 5
  (UPPER(b.cliente) LIKE '%CLIENTE TESTE%'
    OR UPPER(TRIM(b.cliente)) = 'VBOT')          AS eh_cliente_teste,           -- regra 6
  b.tem_acompanhamento                           AS tem_acompanhamento_financeiro,
  c.tipo_coberto_no_monitoramento,

  -- regra 4: a causa, calculada
  CASE
    WHEN b.tem_acompanhamento                              THEN 'coberto'
    WHEN b.is_cancelado                                    THEN 'cancelado (a view exclui, corretamente)'
    WHEN UPPER(b.cliente) LIKE '%CLIENTE TESTE%'
      OR UPPER(TRIM(b.cliente)) = 'VBOT'                   THEN 'cliente de teste ou interno'
    WHEN NOT c.tipo_coberto_no_monitoramento
     AND b.data_inicio IS NULL                             THEN 'tipo de midia fora da view E sem data de inicio'
    WHEN NOT c.tipo_coberto_no_monitoramento               THEN 'tipo de midia fora da view do Supabase'
    WHEN b.data_inicio IS NULL                             THEN 'sem data de inicio'
    ELSE 'sem causa identificada -- investigar'
  END                                            AS motivo_sem_acompanhamento,

  -- ===== acompanhamento financeiro, o que e fato e nao indicador congelado =====
  b.nf_status,
  b.titulo_status,
  b.boleto_status,
  b.nf_agencia,
  b.nf_fornecedor,
  b.vencimento_titulo,
  b.recebimento_em,
  b.nf_veiculo_cobrada_em,
  b.nf_veiculo_recebida_em,
  b.nf_enviada_cliente_em,
  b.cliente_pagou_veiculo,

  -- ===== Conta Azul =====
  b.tem_conta_azul,
  b.ca_valor,
  b.ca_valor_aberto,
  b.ca_n_vendas,

  -- ===== linhagem =====
  CURRENT_TIMESTAMP()                            AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM base b
LEFT JOIN cobertura_por_tipo c ON c.tipo_midia = b.tipo_midia
