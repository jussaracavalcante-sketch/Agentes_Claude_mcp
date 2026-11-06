-- rfn_operacao__auditoria_qualidade_mensal  ·  query-8m13  ·  281 linhas  ·  L2 INTERNAL
-- Refined / operacao. Grao: um MES de prazo, um SETOR, um SUBSERVICO.
-- Chave: id_auditoria_qualidade = <mes ou SEM_PRAZO>:<setor>:<subservico>.
-- Origem: trs_vjob__auditoria_cliente (3.025). Gatilho: evento em query-LQ5u.
--
-- O QUE ELA RESPONDE, e a Refined de conformidade DECLAROU NAO RESPONDER: **qual
--   servico e qual setor falham na auditoria de qualidade.** A
--   `rfn_operacao__conformidade_cliente` deixou `id_servico` fora do grao de proposito
--   ("nao e comparavel entre as origens, 1.339 valores na auditoria contra 67 na etapa")
--   -- entao ela responde por CLIENTE e esta responde por SERVICO. As duas se leem
--   juntas e nao se somam: o mesmo item entra nas duas com recortes diferentes.
--
-- ============================================================================
-- O ACHADO: QUASE TUDO E FEITO, E QUASE NADA E FEITO NO PRAZO.
-- ============================================================================
--   Conclusao sobre item ATIVO: 99,4% no Inbound, 98,4% no Social Media, **100%** em
--   Midia Paga e Blog/SEO, 94,1% no Account. Pontualidade, no mesmo recorte:
--   **526 de 1.541 (34,1%)**. Por setor, atraso medio e mediano dos que atrasaram:
--     INBOUND ....... 699 feitos · 220 no prazo · 479 atrasados · 11,9 / 8 dias · max 78
--     SOCIAL MEDIA .. 566 · 193 · 373 · 14,4 / 9 · max 68
--     MIDIA PAGA .... 129 · 60 · 69 · 14,2 / 12 · max 100
--     ACCOUNT ....... 111 · 38 · 73 · 16,7 / 13 · max 52
--     BLOG e SEO .... 36 · 15 · 21 · 21,5 / 21 · max 49
--   **103 itens atrasaram mais de 30 dias.** O indicador que discrimina aqui e
--   pontualidade, nao conclusao -- conclusao esta saturada perto de 100% e nao separa
--   ninguem.
--
-- REGRA 1 - O MES E O DO PRAZO, NUNCA O DA MARCACAO. Contar pela marcacao inverte o
--   sinal -- erro que o derivado Supabase do escopo ja produziu nesta casa. Os 9 itens
--   sem prazo entram com `mes_referencia` NULL e `flag_sem_prazo` acesa (3 linhas do
--   grao), nunca descartados.
--
-- REGRA 2 - O DENOMINADOR E O ITEM ATIVO. Item inativo nao e item atrasado: saiu do
--   checklist. Sao **1.462 inativos com 2 marcados** contra 1.563 ativos com 1.543.
--   `taxa_conclusao` usa o ativo nos DOIS lados da razao; `qtd_itens` e
--   `qtd_itens_ativos` convivem para quem quiser o outro denominador de olhos abertos.
--   Sem isso a taxa da auditoria cai de 98,7% para 51% sem nada ter deixado de ser feito.
--
-- REGRA 3 - ZERO DE CONCLUSAO NAO E ZERO, E NULL, e o mesmo vale para atraso. Grupo sem
--   nenhuma marcacao recebe `taxa_conclusao` NULL; grupo sem nenhum item atrasado recebe
--   `atraso_medio_dias`, `atraso_mediano_dias` e `atraso_max_dias` **NULL, nunca zero**
--   -- 84 das 281 linhas. Zero seria somado e puxaria qualquer media para baixo.
--
-- REGRA 4 - `taxa_pontualidade` TEM COMO DENOMINADOR O FEITO COM PRAZO, nao o previsto.
--   Item nao feito nao esta atrasado nem pontual; item feito sem prazo nao e avaliavel.
--   Sao 1.545 feitos, 1.541 com prazo.
--
-- REGRA 5 - `SEM_SUBSERVICO` E UM BALDE EXPLICITO, E ELE E A MAIORIA. **1.937 dos 3.025
--   itens (64%) nao tem subservico** -- o catalogo de servico traz subservico zero
--   (sentinela) em 318 dos 1.387 servicos. **BLOG e SEO nao tem NENHUM item com
--   subservico** (272 de 272) e **ACCOUNT nao tem nenhum sem** (135 de 135). Descartar o
--   balde apagaria dois setores inteiros da leitura; por isso ele e chave, com
--   `flag_sem_subservico` acesa.
--
-- REGRA 6 - O SERVICO NAO ENTRA NO GRAO, E ISSO E MEDIDO. Sao **1.339 servicos distintos
--   para 3.025 itens** -- 2,3 itens por servico. Um grao por servico seria quase 1:1 com
--   o item e nao agregaria nada. O subservico (26) e a categoria (4) sao os niveis que
--   agrupam; `qtd_servicos_distintos` preserva a granularidade perdida.
--
-- AS TRES DIMENSOES RESOLVEM 100%, o que nao era verdade ate 24/09: zero servico orfao,
--   zero setor orfao e zero conta orfa em 3.025 itens. **60 itens tem setor diferente do
--   setor do servico no catalogo** -- o do item manda, e `qtd_setor_diverge_do_catalogo`
--   mantem o conflito visivel em vez de escolhido em silencio.
--
-- EVIDENCIA E RARA: **295 dos 3.025 itens (9,8%)** tem URL de evidencia. `taxa_evidencia`
--   existe para que isso apareca; nao confundir com qualidade do que foi auditado.
--
-- LIMITACOES - nao contorne:
--   1. **Atraso aqui e de REGISTRO ou de entrega, e a base nao separa os dois.** A
--      auditoria carimba quando alguem marcou, nao quando o trabalho ficou pronto.
--   2. **46 contas nao sao a base da casa.** Esta auditoria cobre um recorte; nao
--      inferir cobertura de processo a partir daqui.
--   3. **Mes futuro entra, marcado** (`flag_mes_futuro`). Prazo vai ate 30/09/2026.
--      Toda serie precisa de recorte de janela explicito.
--   4. **`qtd_pessoas_marcaram` e contagem distinta, nao lista** -- e por isso a tabela
--      e L2 e nao L4. Quem marcou, individualmente, fica na Trusted.
--   5. **BLOG e SEO tem 272 itens e so 35 ativos.** Qualquer taxa daquele setor repousa
--      sobre 36 conclusoes; a cobertura vai junto com o numero.
--
-- FUSO: NADA SE CONVERTE. A Trusted entrega o relogio local do MySQL intacto.
--
-- MEDIDO EM 2026-09-28 sobre a tabela materializada: 3.025 itens · 281 linhas ·
--   281 chaves · 18 meses de prazo · 5 setores · 26 subservicos · 4 categorias ·
--   1.545 feitos · 1.563 ativos · 1.541 feitos com prazo · 526 no prazo (34,1%) ·
--   1.015 atrasados · 103 com mais de 30 dias · 84 linhas sem atraso (NULL) ·
--   3 linhas sem prazo · zero orfao nas tres dimensoes · zero item com status sem
--   carimbo.
WITH base AS (
  SELECT
    id_auditoria_item, id_auditoria, id_cliente, cnpj_digitos,
    id_servico, id_subservico, nome_subservico, nome_categoria,
    setor, prazo, is_feito, is_ativo, marcado_em, quem_marcou,
    flag_tem_evidencia, flag_setor_diverge_do_catalogo,
    -- REGRA 1 - o mes e o do PRAZO. Item sem prazo nao some; fica com mes NULL.
    DATE_TRUNC(prazo, MONTH)                                    AS mes_referencia,
    -- REGRA 5 - balde explicito, e ele e a maioria (64%).
    IFNULL(nome_subservico, 'SEM_SUBSERVICO')                   AS subservico_chave,
    -- REGRA 4 - so existe atraso para item FEITO e COM prazo.
    IF(is_feito AND prazo IS NOT NULL,
       DATE_DIFF(DATE(marcado_em), prazo, DAY), NULL)           AS atraso_dias
  FROM `vanguardamartech_trusted`.`trs_vjob__auditoria_cliente`
),
-- REGRA 3 - a familia inteira decide se ha registro, nao o mes isolado.
registro AS (
  SELECT setor, subservico_chave, LOGICAL_OR(is_feito) AS tem_registro
  FROM base GROUP BY 1, 2
),
agregado AS (
  SELECT
    b.mes_referencia,
    b.setor,
    b.subservico_chave,
    MAX(b.id_subservico)                                        AS id_subservico,
    MAX(b.nome_categoria)                                       AS nome_categoria,

    COUNT(*)                                                    AS qtd_itens,
    COUNTIF(b.is_ativo)                                         AS qtd_itens_ativos,
    COUNTIF(NOT b.is_ativo)                                     AS qtd_itens_inativos,
    COUNTIF(b.is_feito)                                         AS qtd_feitos,
    -- REGRA 2 - numerador e denominador falam do MESMO conjunto.
    COUNTIF(b.is_feito AND b.is_ativo)                          AS qtd_feitos_ativos,

    COUNTIF(b.prazo IS NOT NULL)                                AS qtd_com_prazo,
    COUNTIF(b.atraso_dias IS NOT NULL)                          AS qtd_feitos_com_prazo,
    COUNTIF(b.atraso_dias <= 0)                                 AS qtd_no_prazo,
    COUNTIF(b.atraso_dias > 0)                                  AS qtd_atrasados,
    COUNTIF(b.atraso_dias > 30)                                 AS qtd_atraso_mais_30d,

    -- REGRA 3 - atraso so de quem atrasou. Sem atrasado, sai NULL, nunca zero.
    ROUND(AVG(IF(b.atraso_dias > 0, b.atraso_dias, NULL)), 1)   AS atraso_medio_dias,
    APPROX_QUANTILES(IF(b.atraso_dias > 0, b.atraso_dias, NULL), 2)[OFFSET(1)]
                                                                AS atraso_mediano_dias,
    MAX(IF(b.atraso_dias > 0, b.atraso_dias, NULL))             AS atraso_max_dias,

    COUNT(DISTINCT b.id_cliente)                                AS qtd_contas,
    COUNT(DISTINCT b.id_auditoria)                              AS qtd_ciclos,
    -- REGRA 6 - a granularidade que o grao nao carrega fica preservada aqui.
    COUNT(DISTINCT b.id_servico)                                AS qtd_servicos_distintos,
    COUNT(DISTINCT b.quem_marcou)                               AS qtd_pessoas_marcaram,

    COUNTIF(b.flag_tem_evidencia)                               AS qtd_com_evidencia,
    COUNTIF(b.flag_setor_diverge_do_catalogo)                   AS qtd_setor_diverge_do_catalogo
  FROM base b
  GROUP BY 1, 2, 3
)
SELECT
  CONCAT(IFNULL(CAST(a.mes_referencia AS STRING), 'SEM_PRAZO'), ':',
         a.setor, ':', a.subservico_chave)                      AS id_auditoria_qualidade,
  a.mes_referencia,
  (a.mes_referencia IS NULL)                                    AS flag_sem_prazo,
  COALESCE(a.mes_referencia > DATE_TRUNC(CURRENT_DATE(), MONTH), FALSE)
                                                                AS flag_mes_futuro,
  a.setor,
  a.id_subservico,
  NULLIF(a.subservico_chave, 'SEM_SUBSERVICO')                  AS nome_subservico,
  a.nome_categoria,
  (a.subservico_chave = 'SEM_SUBSERVICO')                       AS flag_sem_subservico,

  a.qtd_itens,
  a.qtd_itens_ativos,
  a.qtd_itens_inativos,
  a.qtd_feitos,
  a.qtd_feitos_ativos,

  -- REGRA 2 + 3 - denominador ATIVO, e NULL (nunca zero) sem registro nenhum.
  IF(NOT r.tem_registro OR a.qtd_itens_ativos = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_feitos_ativos, a.qtd_itens_ativos), 4))
                                                                AS taxa_conclusao,
  NOT r.tem_registro                                            AS is_grupo_sem_registro,

  a.qtd_com_prazo,
  a.qtd_feitos_com_prazo,
  a.qtd_no_prazo,
  a.qtd_atrasados,
  a.qtd_atraso_mais_30d,
  -- REGRA 4 - denominador e o FEITO COM PRAZO.
  IF(a.qtd_feitos_com_prazo = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_no_prazo, a.qtd_feitos_com_prazo), 4))
                                                                AS taxa_pontualidade,
  a.atraso_medio_dias,
  a.atraso_mediano_dias,
  a.atraso_max_dias,

  a.qtd_contas,
  a.qtd_ciclos,
  a.qtd_servicos_distintos,
  a.qtd_pessoas_marcaram,

  a.qtd_com_evidencia,
  IF(a.qtd_itens = 0, NULL,
     ROUND(SAFE_DIVIDE(a.qtd_com_evidencia, a.qtd_itens), 4))   AS taxa_evidencia,
  a.qtd_setor_diverge_do_catalogo,

  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso
FROM agregado a
JOIN registro r
  ON r.setor = a.setor AND r.subservico_chave = a.subservico_chave
