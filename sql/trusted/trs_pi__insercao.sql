-- trs_pi__insercao
-- Trusted de PI (Pedido de Insercao) de midia. Grao: um PI. Chave: id_pi.
-- TODA a informacao de PI da base numa tabela so, por pedido de 18/09/2026.
--
-- QUATRO ORIGENS, TODAS NO GRAO PI, JUNTADAS POR ID:
--   1. raw.supabase_silver_pi_insercao      - o cadastro do PI (base, 3.348 linhas)
--   2. raw.supabase_gold_vw_pi_monitoramento - acompanhamento financeiro (3.063)
--   3. raw.supabase_gold_vw_pi_ca_evento     - eventos do Conta Azul (3.063)
--   4. trusted.trs_projetos__projeto         - contexto do projeto no iClips
--
-- ENCAIXE MEDIDO EM 18/09/2026, antes de escrever:
--   - monitoramento e ca_evento: 3.063 PIs cada, ZERO orfaos dos dois lados, 1:1 no
--     grao PI. O LEFT JOIN nao multiplica linha -- a contagem de saida e 3.348, igual
--     a da base.
--   - 285 PIs da base NAO tem acompanhamento, e isso tem causa: os 228 CANCELADOS
--     estao todos ai (o monitoramento do Supabase exclui cancelado -- zero cancelado
--     do outro lado). Sobram 57 nao cancelados sem acompanhamento, R$ 394 mil.
--
-- O ICLIPS NAO TEM PI, E ISSO FOI VERIFICADO, NAO SUPOSTO. A fonte rest-api-73hk tem
-- 14 streams, todos de projeto (idProjeto, nomeProjeto, statusProjeto, verba, datas,
-- responsaveis, cliente, grupoCliente, pecas, tarefas). Nenhum de PI. Toda informacao
-- de PI da base entra pelo Supabase.
-- O QUE LIGA OS DOIS E numero_projeto, preenchido em 100% dos 3.348 PIs, e ele E o
-- idProjeto do iClips -- confirmado comparando o nome: batem caractere a caractere,
-- inclusive o espaco duplo de "FOGAS | CAMPANHAS ANUAIS  2026" e o espaco final de
-- "MURANO | AGOSTO ". Nao e coincidencia de numeracao.
--
-- COBERTURA DO LADO ICLIPS E BAIXA, E O MOTIVO E JANELA, NAO CHAVE. A trs_projetos__projeto
-- viva tem 106 projetos; os PIs citam 238 projetos distintos em 24 meses. Casam 11 PIs
-- (0,3%), medido em 18/09/2026 -- e os 11 batem o nome do projeto EXATAMENTE, zero
-- divergencia, o que confirma a chave. A API do iClips ja traz 520 projetos em 13 janelas
-- de 30 dias, entao a cobertura sobe sozinha quando a trs_projetos__projeto passar a
-- consolidar as 13 janelas -- hoje ela consolida so parte. Declare a cobertura ao usar
-- as colunas projeto_*, e nao confunda tem_projeto_no_iclips=false com "PI sem projeto":
-- 100% dos PIs TEM numero_projeto; o que falta e o projeto na base, nao no PI.
--
-- CUIDADO -- EXISTEM DUAS trs_projetos__projeto. A de
-- `vanguardamartech_gestao_de_projetos_do_iclips` esta ORFA: 98 projetos, ultima carga
-- em 21/08/2026. A viva e a de `vanguardamartech_trusted`: 106 projetos, carga de
-- 18/09/2026. Esta query le a VIVA. Nao troque pelo nome da camada.
--
-- FUSO -- NAO ADICIONE TIMEZONE EM data_aprovacao_proposta. Ela e TIMESTAMP na origem,
-- mas ZERO das 3.348 linhas tem hora diferente de 00:00:00: e uma DATA guardada como
-- instante. `DATE(ts)` sem argumento interpreta em UTC e devolve o dia certo.
-- `DATE(ts, 'America/Sao_Paulo')` jogaria 1.968 aprovacoes um dia para tras, porque
-- meia-noite UTC e 21h do dia anterior em SP. Medido. E a mesma armadilha que custou
-- seis tabelas do iClips, de cabeca para baixo.
--
-- AS DUAS COLUNAS dt_nf_* NAO SAO A MESMA COISA, E NENHUMA FOI CONVERTIDA. Medido em
-- 18/09/2026: dt_nf_fornecedor tem ZERO linhas com hora -- e data disfarcada de instante.
-- dt_nf_agencia tem 301 linhas COM hora -- e instante de verdade. As duas passam como a
-- origem entrega, em TIMESTAMP, porque o fuso da origem NAO foi medido contra referencia
-- externa. Antes de ler a hora de dt_nf_agencia, meca. Herdar suposicao de fuso e
-- exatamente o que custou seis tabelas do iClips.
--
-- UNICIDADE PROVADA em 18/09/2026: 3.348 linhas, 3.348 id_pi distintos, zero vazio.
-- Sem deduplicacao defensiva de proposito -- se a origem passar a duplicar, a contagem
-- sobe e aparece, em vez de ser escondida por um QUALIFY que ninguem revisita.
--
-- PI CANCELADO CONTINUA AQUI, DELIBERADAMENTE. Sao 228 cancelados, dos quais 223 com
-- valor maior que zero, somando R$ 2.087.562,09 de R$ 47.083.182,87 (4,4%). Quem somar
-- valor_negociado sem filtrar is_cancelado infla o faturamento em dois milhoes.
-- Trusted nao escolhe regra de negocio -- a linha fica, a flag fica, quem le decide.
--
-- METRICA DERIVADA PASSA COMO A ORIGEM ENTREGA. desc_padrao_pct, valor_comissao_veiculo,
-- valor_liquido, desc_padrao_negociado_*, valor_faturado_cliente e pi_comissao NAO sao
-- recalculados.
--
-- OS INDICADORES DO MONITORAMENTO SAO RELATIVOS AO DIA DA EXTRACAO -- LEIA COM DATA.
-- proxima_acao, acao_prazo, concluido e os cinco ind_* nascem de uma comparacao com
-- CURRENT_DATE dentro da view do Supabase. Materializados aqui, eles CONGELAM no dia
-- em que a view rodou e envelhecem em silencio. A coluna `hoje` da view foi
-- DESCARTADA justamente para nao parecer data de hoje. Use _extraido_at como a data
-- de referencia real desses campos.
--
-- DOCUMENTO -- O CNPJ DO VEICULO QUE PERDEU O ZERO A ESQUERDA (corrigido 2026-09-23)
--   A suite de qualidade acusava 606 de 3.120 PIs nao cancelados (19,4%) sem CNPJ de
--   veiculo. MEDIDO: 507 deles NAO estao sem CNPJ -- tem CNPJ de 13 DIGITOS, guardado
--   como numero em algum ponto do caminho, que comeu o zero inicial. Sao 4 veiculos, e
--   os quatro foram confirmados contra a razao social do financeiro:
--     04382099000194  TV A Critica ................ Televisao A Critica Ltda.
--     04642799000170  Radio Jovem Pan FM - 104,1 .. Radio Taruma Ltda.
--     04486636000146  RADIO POP FM ................ TRANSMISSAO DE RADIO E TV DO NORDESTE
--     07625810000182  GRUPO INTELICOM | NORTE OUT . INTELICOM COMUNICACAO E MARKETING
--   DOIS DELES SAO OS MESMOS ja corrigidos no financeiro no mesmo dia -- duas fontes
--   independentes com o mesmo defeito, o que confirma que o problema e de armazenamento
--   numerico num ponto comum, nao digitacao.
--   A REGRA NAO ADIVINHA: o LPAD so vale quando o valor corrigido JA EXISTE entre os
--   CNPJs de 14 digitos que a casa conhece (o proprio PI mais o financeiro).
--   `cnpj_veiculo_origem` preserva o TEXTO CRU, com mascara, e
--   `flag_cnpj_veiculo_repadronizado` marca onde houve correcao.
--   MUDANCA DE FORMA A DECLARAR: `cnpj_veiculo` passa a sair em DIGITOS, nao no texto
--   formatado da origem (2.571 das 3.245 linhas preenchidas vinham com pontuacao, do
--   tipo `60.628.369/0009-22`). E a coluna de JUNCAO -- comparar com pontuacao ja tinha
--   produzido falso conflito na ponte do iClips com o Facebook. Quem quiser exibir usa
--   `cnpj_veiculo_origem`.
--   MEDIDO ANTES DO DEPLOY: 3.348 linhas e 3.348 chaves (o join nao multiplicou nada),
--   533 PIs repadronizados, 4 documentos, R$ 5.630.847,04 de valor negociado, e a
--   cobertura de veiculo por CNPJ nos nao cancelados sobe de **80,6% para 96,8%**
--   (2.514 -> 3.021 de 3.120). Os 99 que sobram nao tem CNPJ mesmo: 2 veiculos,
--   GLOBO NEGOCIOS _ NORDESTE E CENTRO OESTE e M3 COMUNICACAO.
--   O `cliente_cnpj` do monitoramento NAO tem esse defeito -- medido: so 14 digitos
--   (2.977), CPF de 11 (15) e vazio (71).
--
-- IDENTIDADE DE VEICULO E FRAGIL: 100 rotulos, 97 razoes sociais, 94 CNPJs, 103 linhas
-- sem CNPJ. Resolver veiculo por rotulo funde ou separa errado. Junte por cnpj_veiculo
-- quando houver e declare a cobertura.
--
-- mes_competencia e DERIVADO: bate com o mes de data_inicio em 100% das 3.348 linhas.
-- Preservado por fidelidade; mes_referencia entrega o mesmo recorte como DATE.
-- 212 PIs tem veiculacao que ATRAVESSA o mes -- a competencia e a do inicio, entao
-- somar por competencia nao e somar por periodo veiculado.
--
-- LIMITACAO DE ATUALIZACAO -- NAO E DEFEITO DESTA QUERY. A origem esta parada: maior PI
-- 22930, ultima aprovacao em 06/08/2026, competencia 2026-09 com 34 linhas e 14 clientes
-- na base inteira. O carregamento da silver.pi_insercao e feito por worker do lado do
-- Supabase, fora da Nekt. Ate destravar, esta tabela reflete o iClips ate 06/08/2026.
--
-- Gatilho: evento na fonte supabase-x0tz (cron 00:00 America/Manaus), regra any.
WITH
-- A AUTORIDADE DO DOCUMENTO: todo CNPJ de 14 digitos que a casa conhece, do proprio
-- PI e do financeiro. E o que autoriza o LPAD abaixo -- ver o bloco DOCUMENTO.
docs_de_14 AS (
  SELECT DISTINCT REGEXP_REPLACE(cnpj_veiculo, r'[^0-9]','') AS d14
  FROM `vanguardamartech_raw`.`supabase_silver_pi_insercao`
  WHERE LENGTH(REGEXP_REPLACE(COALESCE(cnpj_veiculo,''), r'[^0-9]','')) = 14
  UNION DISTINCT
  SELECT DISTINCT REGEXP_REPLACE(cpf_cnpj, r'[^0-9]','')
  FROM `vanguardamartech_raw`.`supabase_public_fato_movimento_financeiro`
  WHERE LENGTH(REGEXP_REPLACE(COALESCE(cpf_cnpj,''), r'[^0-9]','')) = 14
),
bruto AS (
  SELECT
    'supabase-x0tz' AS _fonte,
    TO_HEX(MD5(TO_JSON_STRING(x))) AS _payload_hash,
    NULLIF(REGEXP_REPLACE(COALESCE(x.cnpj_veiculo,''), r'[^0-9]',''),'') AS doc_veiculo_origem,
    x.*
  FROM `vanguardamartech_raw`.`supabase_silver_pi_insercao` x
),
projeto AS (
  SELECT
    id_projeto,
    nome_projeto,
    status_nome,
    verba,
    cliente_efetivo_nome,
    grupo_cliente_nome,
    responsavel_principal_nome,
    data_entrada,
    data_conclusao,
    qtd_pecas,
    qtd_tarefas,
    qtd_apontamentos
  FROM `vanguardamartech_trusted`.`trs_projetos__projeto`
)
SELECT
  -- ===== chave =====
  NULLIF(TRIM(b.pi), '')                              AS id_pi,

  -- ===== cliente e projeto (cadastro) =====
  NULLIF(TRIM(b.cliente), '')                         AS cliente,
  NULLIF(TRIM(b.numero_projeto), '')                  AS numero_projeto,
  NULLIF(TRIM(b.nome_projeto), '')                    AS nome_projeto,

  -- ===== contexto do projeto no iClips (cobertura baixa - ver cabecalho) =====
  p.nome_projeto                                      AS projeto_nome_iclips,
  p.status_nome                                       AS projeto_status,
  p.verba                                             AS projeto_verba,
  p.cliente_efetivo_nome                              AS projeto_cliente,
  p.grupo_cliente_nome                                AS projeto_grupo_cliente,
  p.responsavel_principal_nome                        AS projeto_responsavel,
  p.data_entrada                                      AS projeto_data_entrada,
  p.data_conclusao                                    AS projeto_data_conclusao,
  p.qtd_pecas                                         AS projeto_qtd_pecas,
  p.qtd_tarefas                                       AS projeto_qtd_tarefas,
  p.qtd_apontamentos                                  AS projeto_qtd_apontamentos,
  (p.id_projeto IS NOT NULL)                          AS tem_projeto_no_iclips,

  -- ===== midia e veiculo =====
  NULLIF(TRIM(b.tipo_midia), '')                      AS tipo_midia,
  NULLIF(TRIM(b.tipo_midia_raw), '')                  AS tipo_midia_origem,
  NULLIF(TRIM(b.veiculo), '')                         AS veiculo,
  NULLIF(TRIM(b.razao_social_veiculo), '')            AS razao_social_veiculo,
  -- CNPJ do veiculo repadronizado quando a origem comeu o zero a esquerda.
  -- Ver o bloco DOCUMENTO no cabecalho: 533 PIs, 4 veiculos, R$ 5,63 mi.
  COALESCE(d.d14, b.doc_veiculo_origem)               AS cnpj_veiculo,
  NULLIF(TRIM(b.cnpj_veiculo), '')                    AS cnpj_veiculo_origem,
  (d.d14 IS NOT NULL)                                 AS flag_cnpj_veiculo_repadronizado,
  NULLIF(TRIM(b.praca), '')                           AS praca,
  NULLIF(TRIM(m.bucket), '')                          AS bucket_midia,

  -- ===== periodo =====
  b.data_inicio,
  b.data_fim,
  NULLIF(TRIM(b.mes_competencia), '')                 AS mes_competencia,
  DATE_TRUNC(b.data_inicio, MONTH)                    AS mes_referencia,
  NULLIF(TRIM(b.periodo_raw), '')                     AS periodo_origem,
  NULLIF(TRIM(b.prazo), '')                           AS prazo,

  -- ===== volume e valores, como a origem entrega =====
  b.insercoes,
  b.valor_negociado,
  b.desc_padrao_pct,
  b.valor_comissao_veiculo,
  b.valor_liquido,
  b.desc_padrao_negociado_pct,
  b.desc_padrao_negociado_rs,
  b.valor_faturado_cliente,
  m.pi_comissao,

  -- ===== proposta =====
  NULLIF(TRIM(b.responsavel), '')                     AS responsavel,
  NULLIF(NULLIF(TRIM(b.numero_proposta), ''), '0')    AS numero_proposta,
  NULLIF(TRIM(b.status_proposta), '')                 AS status_proposta,
  DATE(b.data_aprovacao_proposta)                     AS data_aprovacao_proposta,
  NULLIF(TRIM(b.status_midia), '')                    AS status_midia,

  -- ===== faturamento (cadastro) =====
  NULLIF(TRIM(b.faturamento), '')                     AS faturamento,
  NULLIF(TRIM(b.tipo_faturamento), '')                AS tipo_faturamento,
  NULLIF(TRIM(b.enviar_fatura), '')                   AS enviar_fatura,
  NULLIF(TRIM(b.faturar), '')                         AS faturar,
  NULLIF(TRIM(b.nf_agencia), '')                      AS nf_agencia,
  b.is_faturado,
  b.is_cancelado,

  -- ===== acompanhamento financeiro (monitoramento) =====
  (m.pi IS NOT NULL)                                  AS tem_acompanhamento,
  m.billed                                            AS mon_faturado,
  NULLIF(TRIM(m.fonte), '')                           AS mon_fonte,
  NULLIF(TRIM(m.mon_tipo), '')                        AS mon_tipo,
  NULLIF(TRIM(m.nf_status), '')                       AS nf_status,
  NULLIF(TRIM(m.titulo_status), '')                   AS titulo_status,
  NULLIF(TRIM(m.boleto_status), '')                   AS boleto_status,
  NULLIF(TRIM(m.faturamento_tipo), '')                AS mon_faturamento_tipo,
  NULLIF(TRIM(m.nf_fornecedor), '')                   AS nf_fornecedor,
  m.dt_nf_fornecedor,
  m.dt_nf_agencia,
  NULLIF(TRIM(m.nf_doc), '')                          AS nf_doc,
  NULLIF(TRIM(m.cliente_cnpj), '')                    AS cliente_cnpj,
  m.vencimento_titulo,
  m.recebimento_em,
  m.nf_veiculo_cobrada_em,
  m.nf_veiculo_recebida_em,
  m.nf_enviada_cliente_em,
  m.contato_veiculo_em,
  m.boleto_veiculo_vencimento,
  m.cliente_pagou_veiculo,
  m.nf_veiculo_ok,
  m.enviado_ok,
  m.nf_agencia_ok,
  m.recebido_ok,
  m.corte_dia,
  NULLIF(TRIM(m.mon_resp), '')                        AS mon_responsavel,
  NULLIF(TRIM(m.mon_obs), '')                         AS mon_observacao,
  NULLIF(TRIM(m.faturamento_obs), '')                 AS faturamento_observacao,

  -- ===== indicadores do monitoramento: relativos ao dia da extracao =====
  m.prazo_cobrar_nf,
  m.prazo_nf_envio,
  m.prazo_contato,
  m.venda_venc_alvo,
  NULLIF(TRIM(m.proxima_acao), '')                    AS proxima_acao,
  NULLIF(TRIM(m.acao_area), '')                       AS acao_area,
  m.acao_prazo,
  m.concluido                                         AS acao_concluida,
  m.ind_prazo_recebimento,
  m.ind_prazo_nf_veiculo,
  m.ind_prazo_boleto_veiculo,
  m.ind_float_receb_boleto,
  m.ind_dias_nf_agencia,

  -- ===== Conta Azul =====
  (c.pi IS NOT NULL)                                  AS tem_conta_azul,
  c.n_eventos                                         AS ca_n_eventos,
  c.n_vendas                                          AS ca_n_vendas,
  c.ca_valor,
  c.valor_aberto                                      AS ca_valor_aberto,
  c.tem_boleto                                        AS ca_tem_boleto,
  c.tem_nf                                            AS ca_tem_nf,
  c.vencimento                                        AS ca_vencimento,
  c.periodo_inicio                                    AS ca_periodo_inicio,
  c.periodo_fim                                       AS ca_periodo_fim,

  -- ===== linhagem =====
  CURRENT_TIMESTAMP()                                 AS _extraido_at,
  b._fonte,
  b._payload_hash
FROM bruto b
LEFT JOIN `vanguardamartech_raw`.`supabase_gold_vw_pi_monitoramento` m ON m.pi = b.pi
LEFT JOIN `vanguardamartech_raw`.`supabase_gold_vw_pi_ca_evento`      c ON c.pi = b.pi
LEFT JOIN projeto                                                      p ON p.id_projeto = b.numero_projeto
LEFT JOIN docs_de_14                                                   d
       ON LENGTH(b.doc_veiculo_origem) IN (12, 13)
      AND d.d14 = LPAD(b.doc_veiculo_origem, 14, '0')
