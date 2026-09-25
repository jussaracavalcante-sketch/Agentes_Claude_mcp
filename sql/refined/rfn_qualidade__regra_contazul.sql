-- rfn_qualidade__regra_contazul  ·  query-AQjU  ·  19 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Gatilho: evento em query-FDpl. Alerta ligado.
--
-- POR QUE EXISTE UMA SEGUNDA TABELA DE QUALIDADE, E POR QUE ISSO NAO E DUPLICACAO
--   A suite principal (`rfn_qualidade__regra`, query-wD6c, 61 regras) dispara em
--   `query-dGga`, que roda TODO DIA ~07:10. A familia Conta Azul dispara em `mysql-yIOn`,
--   que roda DOMINGO. Duas consequencias, e as duas decidem:
--   1. As cinco tabelas do Conta Azul NAO EXISTEM ainda — publicadas em 25/09, depois da
--      ultima carga da `mysql-yIOn` (24/09 12:43). Referenciar tabela nao materializada
--      DERRUBA A QUERY INTEIRA. Somar estas 19 regras a suite principal a faria falhar
--      amanha as 07:10 e levaria as 61 regras junto, todo dia, ate domingo.
--   2. Aqui as regras rodam como GATE DE POS-CARGA: o gatilho e o ultimo elo da cadeia do
--      Conta Azul, entao elas medem a tabela no instante em que ela acabou de ser
--      reescrita — nao seis dias depois.
--   O CONTRATO DE COLUNAS E IDENTICO ao da suite principal, de proposito: um UNION ALL
--   entre as duas da o painel unico, e `familia` diz de onde veio cada linha. Fundir e
--   opcao futura; hoje seria trocar 61 regras diarias por um erro.
--
-- AS 19 REGRAS, MEDIDAS EM 2026-09-25 ANTES DE PUBLICAR (sobre a Raw e o espelho,
-- reproduzindo a logica das Trusted, porque as tabelas ainda nao existem).
-- Resultado esperado na primeira execucao: 19 CONFORMES, ZERO FALHAS.
--   ENTIDADE (4) — id_entidade unico 1.828/1.828 · cadastros_nao_divergem 0 de 1.828 ·
--     documento_tem_forma 1 falha em 1.053 com digitos (99,91%) · tem_documento 1.052 de
--     1.828 (57,6%, limiar 0,55).
--   CATEGORIA (2) — id_categoria unico 382/382 · nome_preenchido 0 falhas.
--   VINCULO (2) — os dois lados do de-para resolvem, 10 de 10 em cada.
--   MOVIMENTO (6) — id_movimento unico 6.768/6.768 · valor >= 0 zero negativos ·
--     classe_conhecida zero fora da lista · data_competencia zero nulas ·
--     contraparte_resolvida 5.395 de 6.768 (79,7%, limiar 0,75) · categoria_com_nome
--     6.314 de 6.768 (93,3%, limiar 0,90).
--   FLUXO (5) — id_fluxo unico 5.237/5.237 · data_caixa_preenchida zero nulas ·
--     data_caixa_nao_estimada 1 em 3.205 realizados (99,97%) · movimento_existe zero
--     orfaos · e a identidade contabil, abaixo.
--
-- A REGRA MAIS IMPORTANTE DESTA LEVA E UMA IDENTIDADE CONTABIL:
--   `rfn_financeiro__fluxo_caixa.caixa_reproduz_o_razao`. O fluxo promete que a soma de
--   cada regime reproduz o razao — REALIZADO = SUM(valor_pago) e PREVISTO =
--   SUM(valor_nao_pago) das parcelas vigentes. Ate aqui era AFIRMACAO NA DESCRICAO, medida
--   a mao uma vez. Agora e teste, com grao REGIME: 2 linhas avaliadas, diferenca ZERO nas
--   duas (R$ 21.227.444,68 e R$ 9.793.507,73 dos dois lados). BLOQUEANTE, limiar 1,00 — se
--   falhar, todo numero de caixa desta casa esta errado. Irma da
--   rfn_operacao__custo_peca.rateio_fecha_no_centavo.
--
-- DOIS LIMIARES SAO LINHA DE BASE DE PROPOSITO, NAO META
--   - entidade.tem_documento em 0,55 contra 57,6%: 42% do cadastro nao tem documento e isso
--     e da ORIGEM. Limiar apertado ali so ensinaria a ignorar a suite.
--   - movimento.contraparte_resolvida em 0,75 contra 79,7%: E A UNICA REGRA DA LEVA QUE
--     EXISTE PARA PIORAR. O espelho de entidades parou de sincronizar em 17/08/2026 e o
--     razao recebe dado ate hoje, entao a cobertura cai sozinha a cada semana. Cruzar o
--     limiar significa que a sincronizacao precisa voltar — nao que o tratamento quebrou.
--
-- GUARDA DE VOCABULARIO: movimento.classe_conhecida dispara se qualquer classe_financeira
--   fora dos 10 valores declarados aparecer. Categoria nova na origem cai no default
--   (OPERACIONAL ou RECEITA) em silencio e nada na contagem denuncia. Mesmo papel do
--   rfn_operacao__job.status_canonico_conhecido.
--
-- A QUARENTENA DA §14 CONTINUA NAO FEITA, pela mesma razao da suite principal: esta tabela
--   MEDE E DENUNCIA, nao desvia. O registro invalido continua entrando, marcado com a flag
--   que a Trusted dele ja emite.
--
-- O QUE NAO VIROU REGRA, E POR QUE — hipotese testada e REPROVADA
--   A candidata obvia era "transferencia entre contas bate nos dois lados". MEDIDO: NAO
--   BATE. Nas 115 linhas vigentes de TRANSFERENCIA a entrada soma R$ 1.145.265,94 e a
--   saida R$ 835.452,42 — R$ 309.813,52 de diferenca, um lado sem par. Publicar como regra
--   seria criar falha permanente que ninguem pode resolver, que e o que ensina a ignorar a
--   suite. Fica como ACHADO: somar a classe TRANSFERENCIA da um liquido de R$ 309 mil que e
--   artefato de pareamento, nao dinheiro — e reforca por que is_caixa_operacional a exclui.

-- ---------- ENTIDADE ----------
WITH r_entidade AS (
  SELECT 'trs_contazul__entidade.id_entidade_unico'       AS id_regra,
         'Trusted'                                        AS camada,
         'trs_contazul__entidade'                         AS tabela,
         'Conta Azul'                                     AS sistema,
         'UNICIDADE'                                      AS dimensao,
         'id_entidade e unico (contaazul_id)'             AS regra,
         'BLOQUEANTE'                                     AS severidade,
         1.00                                             AS limiar,
         COUNT(*)                                         AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_entidade)           AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__entidade`
  UNION ALL
  -- A INVARIANTE DA DEDUPLICACAO: 1.980 cadastros viram 1.828 entidades porque 152 tem
  -- dois papeis. Isso so e seguro porque os cadastros do mesmo contaazul_id concordam em
  -- documento, nome e ativo. Se um dia divergirem, o MAX() da Trusted escolhe um dos dois
  -- em silencio e nada na contagem denuncia.
  SELECT 'trs_contazul__entidade.cadastros_nao_divergem', 'Trusted', 'trs_contazul__entidade',
         'Conta Azul', 'VALIDADE',
         'cadastros do mesmo contaazul_id concordam em documento, nome e ativo',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_cadastros_divergem)
  FROM `vanguardamartech_trusted`.`trs_contazul__entidade`
  UNION ALL
  -- Avaliada SO sobre quem tem digitos: quem nao tem documento nao e caso de forma.
  SELECT 'trs_contazul__entidade.documento_tem_forma', 'Trusted', 'trs_contazul__entidade',
         'Conta Azul', 'VALIDADE',
         'documento presente tem 14 digitos (CNPJ) ou 11 (CPF)', 'ALERTA', 0.99,
         COUNTIF(documento_digitos_origem IS NOT NULL),
         COUNTIF(flag_documento_invalido)
  FROM `vanguardamartech_trusted`.`trs_contazul__entidade`
  UNION ALL
  -- LINHA DE BASE: 42% do cadastro nao tem documento e isso e da origem. O limiar existe
  -- para detectar PIORA, nao para reclamar do que a casa ja sabe.
  SELECT 'trs_contazul__entidade.tem_documento', 'Trusted', 'trs_contazul__entidade',
         'Conta Azul', 'COMPLETUDE', 'entidade tem documento valido', 'ALERTA', 0.55,
         COUNT(*), COUNTIF(documento IS NULL)
  FROM `vanguardamartech_trusted`.`trs_contazul__entidade`
),
-- ---------- CATEGORIA ----------
r_categoria AS (
  SELECT 'trs_contazul__categoria.id_categoria_unico'     AS id_regra,
         'Trusted'                                        AS camada,
         'trs_contazul__categoria'                        AS tabela,
         'Conta Azul'                                     AS sistema,
         'UNICIDADE'                                      AS dimensao,
         'id_categoria e unico'                           AS regra,
         'BLOQUEANTE'                                     AS severidade,
         1.00                                             AS limiar,
         COUNT(*)                                         AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_categoria)          AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__categoria`
  UNION ALL
  SELECT 'trs_contazul__categoria.nome_preenchido', 'Trusted', 'trs_contazul__categoria',
         'Conta Azul', 'COMPLETUDE', 'categoria tem nome', 'ALERTA', 1.00,
         COUNT(*), COUNTIF(NULLIF(TRIM(nome), '') IS NULL)
  FROM `vanguardamartech_trusted`.`trs_contazul__categoria`
),
-- ---------- VINCULO ----------
r_vinculo AS (
  SELECT 'trs_contazul__vinculo.contaazul_resolvido'      AS id_regra,
         'Trusted'                                        AS camada,
         'trs_contazul__vinculo'                          AS tabela,
         'Conta Azul'                                     AS sistema,
         'INTEGRIDADE'                                    AS dimensao,
         'o lado Conta Azul do de-para existe no espelho' AS regra,
         'BLOQUEANTE'                                     AS severidade,
         1.00                                             AS limiar,
         COUNT(*)                                         AS linhas_avaliadas,
         COUNTIF(flag_contaazul_nao_resolvido)            AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__vinculo`
  UNION ALL
  SELECT 'trs_contazul__vinculo.vjob_resolvido', 'Trusted', 'trs_contazul__vinculo',
         'Conta Azul', 'INTEGRIDADE',
         'o lado VJOB do de-para existe na tabela-pai que vjob_tabela nomeia',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_vjob_nao_resolvido)
  FROM `vanguardamartech_trusted`.`trs_contazul__vinculo`
),
-- ---------- MOVIMENTO ----------
r_movimento AS (
  SELECT 'trs_contazul__movimento.id_movimento_unico'     AS id_regra,
         'Trusted'                                        AS camada,
         'trs_contazul__movimento'                        AS tabela,
         'Conta Azul'                                     AS sistema,
         'UNICIDADE'                                      AS dimensao,
         'id_movimento e unico (id_parcela)'              AS regra,
         'BLOQUEANTE'                                     AS severidade,
         1.00                                             AS limiar,
         COUNT(*)                                         AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_movimento)          AS linhas_falha
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  UNION ALL
  SELECT 'trs_contazul__movimento.valor_nao_negativo', 'Trusted', 'trs_contazul__movimento',
         'Conta Azul', 'VALIDADE',
         'valor >= 0 -- a direcao esta em sentido, nunca no sinal', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(valor < 0)
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  UNION ALL
  -- GUARDA DE VOCABULARIO: se a origem criar categoria que nao casa com nenhum padrao, ela
  -- cai no default (OPERACIONAL ou RECEITA) em silencio. Esta regra dispara se qualquer
  -- classe FORA da lista aparecer -- o mesmo papel do status_canonico_conhecido do job.
  SELECT 'trs_contazul__movimento.classe_conhecida', 'Trusted', 'trs_contazul__movimento',
         'Conta Azul', 'VALIDADE',
         'classe_financeira esta entre os 10 valores declarados', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(classe_financeira NOT IN ('SEM_CATEGORIA','TRANSFERENCIA','SOCIOS','FINANCEIRO',
                                           'REPASSE_CONTA_ORDEM','TRIBUTO_RETIDO','DEVOLUCAO',
                                           'NAO_OPERACIONAL','OPERACIONAL','RECEITA'))
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  UNION ALL
  SELECT 'trs_contazul__movimento.data_competencia_preenchida', 'Trusted', 'trs_contazul__movimento',
         'Conta Azul', 'COMPLETUDE', 'data_competencia preenchida', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data_competencia IS NULL)
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  UNION ALL
  -- O ALARME DO ESPELHO CONGELADO. O espelho de entidades parou em 17/08/2026 e o razao
  -- recebe dado ate hoje: esta cobertura SO PIORA enquanto a sincronizacao nao voltar.
  -- Limiar 0,75 contra os 79,7% de hoje -- quando cruzar, o espelho precisa voltar.
  SELECT 'trs_contazul__movimento.contraparte_resolvida', 'Trusted', 'trs_contazul__movimento',
         'Conta Azul', 'COMPLETUDE',
         'a contraparte do lancamento resolve no espelho de entidades', 'ALERTA', 0.75,
         COUNT(*), COUNTIF(flag_sem_contraparte OR flag_contraparte_nao_catalogada)
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
  UNION ALL
  SELECT 'trs_contazul__movimento.categoria_com_nome', 'Trusted', 'trs_contazul__movimento',
         'Conta Azul', 'COMPLETUDE',
         'o lancamento tem nome de categoria, pelo evento ou pelo espelho', 'ALERTA', 0.90,
         COUNT(*), COUNTIF(flag_sem_categoria)
  FROM `vanguardamartech_trusted`.`trs_contazul__movimento`
),
-- ---------- FLUXO DE CAIXA ----------
r_fluxo AS (
  SELECT 'rfn_financeiro__fluxo_caixa.id_fluxo_unico'     AS id_regra,
         'Refined'                                        AS camada,
         'rfn_financeiro__fluxo_caixa'                    AS tabela,
         'Conta Azul'                                     AS sistema,
         'UNICIDADE'                                      AS dimensao,
         'id_fluxo e unico (id_movimento + regime)'       AS regra,
         'BLOQUEANTE'                                     AS severidade,
         1.00                                             AS limiar,
         COUNT(*)                                         AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_fluxo)              AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__fluxo_caixa`
  UNION ALL
  SELECT 'rfn_financeiro__fluxo_caixa.data_caixa_preenchida', 'Refined',
         'rfn_financeiro__fluxo_caixa', 'Conta Azul', 'COMPLETUDE',
         'toda linha tem data_caixa -- sem ela a linha nao entra em serie nenhuma',
         'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(data_caixa IS NULL)
  FROM `vanguardamartech_refined`.`rfn_financeiro__fluxo_caixa`
  UNION ALL
  -- Avaliada SO no regime REALIZADO: o PREVISTO usa o vencimento por construcao.
  SELECT 'rfn_financeiro__fluxo_caixa.data_caixa_nao_estimada', 'Refined',
         'rfn_financeiro__fluxo_caixa', 'Conta Azul', 'VALIDADE',
         'a data do caixa realizado vem da baixa, nao do vencimento', 'ALERTA', 0.99,
         COUNTIF(is_realizado), COUNTIF(is_realizado AND flag_data_caixa_estimada)
  FROM `vanguardamartech_refined`.`rfn_financeiro__fluxo_caixa`
),
r_fluxo_fk AS (
  SELECT 'rfn_financeiro__fluxo_caixa.movimento_existe'   AS id_regra,
         'Refined'                                        AS camada,
         'rfn_financeiro__fluxo_caixa'                    AS tabela,
         'Conta Azul'                                     AS sistema,
         'INTEGRIDADE'                                    AS dimensao,
         'todo id_movimento do fluxo existe na Trusted de movimento' AS regra,
         'BLOQUEANTE'                                     AS severidade,
         1.00                                             AS limiar,
         COUNT(*)                                         AS linhas_avaliadas,
         COUNTIF(m.id_movimento IS NULL)                  AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__fluxo_caixa` f
  LEFT JOIN (SELECT DISTINCT id_movimento FROM `vanguardamartech_trusted`.`trs_contazul__movimento`) m
    ON m.id_movimento = f.id_movimento
),
-- A UNICA REGRA DESTA LEVA QUE VERIFICA UMA IDENTIDADE CONTABIL.
-- O fluxo promete que a soma de cada regime reproduz o razao: REALIZADO = SUM(valor_pago)
-- e PREVISTO = SUM(valor_nao_pago) das parcelas vigentes. Ate aqui isso era afirmacao na
-- descricao, medida a mao uma vez. Grao: REGIME -- duas linhas avaliadas, nenhuma pode
-- sair de um centavo. Se ela falhar, TODO numero de caixa desta casa esta errado.
identidade AS (
  SELECT 'REALIZADO' AS regime,
         (SELECT SUM(valor_caixa) FROM `vanguardamartech_refined`.`rfn_financeiro__fluxo_caixa` WHERE is_realizado)
         - (SELECT SUM(valor_pago) FROM `vanguardamartech_trusted`.`trs_contazul__movimento` WHERE is_vigente)
                                                          AS diferenca
  UNION ALL
  SELECT 'PREVISTO',
         (SELECT SUM(valor_caixa) FROM `vanguardamartech_refined`.`rfn_financeiro__fluxo_caixa` WHERE NOT is_realizado)
         - (SELECT SUM(valor_nao_pago) FROM `vanguardamartech_trusted`.`trs_contazul__movimento` WHERE is_vigente)
),
r_identidade AS (
  SELECT 'rfn_financeiro__fluxo_caixa.caixa_reproduz_o_razao' AS id_regra,
         'Refined'                                        AS camada,
         'rfn_financeiro__fluxo_caixa'                     AS tabela,
         'Conta Azul'                                      AS sistema,
         'INTEGRIDADE'                                     AS dimensao,
         'a soma de cada regime reproduz o razao ao centavo (grao: REGIME)' AS regra,
         'BLOQUEANTE'                                      AS severidade,
         1.00                                              AS limiar,
         COUNT(*)                                          AS linhas_avaliadas,
         COUNTIF(ABS(COALESCE(diferenca, 1)) > 0.01)       AS linhas_falha
  FROM identidade
),
todas AS (
  SELECT * FROM r_entidade
  UNION ALL SELECT * FROM r_categoria
  UNION ALL SELECT * FROM r_vinculo
  UNION ALL SELECT * FROM r_movimento
  UNION ALL SELECT * FROM r_fluxo
  UNION ALL SELECT * FROM r_fluxo_fk
  UNION ALL SELECT * FROM r_identidade
),
avaliado AS (
  SELECT
    t.*,
    (t.linhas_avaliadas - t.linhas_falha)                       AS linhas_conformes,
    SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, NULLIF(t.linhas_avaliadas, 0))
                                                                AS taxa_conformidade,
    -- Regra sem linha para avaliar NAO passa: sai NULL, nunca TRUE.
    IF(t.linhas_avaliadas = 0, NULL,
       SAFE_DIVIDE(t.linhas_avaliadas - t.linhas_falha, t.linhas_avaliadas) >= t.limiar)
                                                                AS is_conforme,
    (t.linhas_avaliadas = 0)                                    AS flag_sem_linha_para_avaliar
  FROM todas t
)
SELECT
  a.*,
  CASE
    WHEN a.flag_sem_linha_para_avaliar          THEN 'SEM_DADO'
    WHEN a.is_conforme                          THEN 'CONFORME'
    WHEN a.severidade = 'BLOQUEANTE'            THEN 'FALHA_BLOQUEANTE'
    ELSE                                             'FALHA_ALERTA'
  END                                           AS resultado,
  'Conta Azul'                                  AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
