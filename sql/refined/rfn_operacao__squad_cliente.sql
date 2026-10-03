-- rfn_operacao__squad_cliente  ·  query-ytQ7  ·  4.650 linhas  ·  L4 PERSONAL_DATA
-- Refined / operacao. Grao: um SLOT -- uma conta de atendimento em um papel de squad.
-- Origens: trs_vjob__cliente_atendimento (310) · trs_vjob__squad_alteracao (2.346) ·
--          trs_vjob__gestor_cliente (234) · trs_vjob__usuario (273).
-- Gatilho: evento em query-UDGW (ultimo elo do ramo de squad). Cadencia semanal.
--
-- O QUE ELA RESPONDE, e nenhuma tabela Gold desta casa respondia: **quem atende qual
--   cliente, em qual papel, desde quando, e quantas vezes esse posto ja trocou de
--   mao.** O estado vivia so na Trusted do cadastro e a historia so no log -- as duas
--   leituras nunca tinham sido postas lado a lado.
--
-- REGRA 1 - O GRAO E O SLOT, E O DENOMINADOR E EXPLICITO. 310 contas x 15 papeis =
--   **4.650 linhas, 4.650 chaves**, ocupadas ou nao. Emitir so o ocupado esconderia o
--   posto vago, que e exatamente o que se quer enxergar. `is_ocupado` separa:
--   **1.308 ocupados (28,1%)**, 526 deles em conta ativa.
--
-- REGRA 2 - O ESTADO DECIDE QUEM ATENDE HOJE; O LOG SO DATA. Medido: das 849 chaves
--   que tem log, **838 concordam com o cadastro e 11 divergem** -- e nenhuma linha do
--   log aponta para um slot que nao exista no cadastro, o que prova que o de-para
--   entre o nome fisico da coluna no log e a coluna do cadastro e exato nos 15 papeis.
--   **As 11 divergencias tem um padrao: 10 sao "o log poe alguem e o cadastro esta
--   vazio"** -- o posto foi esvaziado sem gerar linha de log -- **e 9 das 11 estao em
--   conta ja desativada**. A unica no sentido inverso (ALIMENTA COMERCIO) e uma
--   atribuicao que nunca foi logada. Portanto **o log nao e trilha de auditoria
--   completa**, e quem ler o log como estado erra em 11 contas. `flag_estado_diverge_do_log`
--   acende e `ocupacao_desde` sai NULL nesses casos -- nunca se escolhe o log.
--
-- REGRA 3 - `ocupacao_desde` E O INICIO DA OCUPACAO ATUAL, nao a primeira alteracao do
--   slot. Calculado assim: acha-se a ultima alteracao que colocou OUTRA pessoa (ou
--   ninguem) e toma-se a primeira linha posterior a ela que ja aponta para o ocupante
--   de hoje. Sem isso, um posto que passou por A -> B -> A dataria de quando A chegou
--   na primeira vez.
--
-- REGRA 4 - COBERTURA DE DATA E 59,3%, E ELA VAI JUNTO COM O NUMERO. Dos 1.308 slots
--   ocupados, **776 tem data e 532 nao** -- o log comeca em **06/11/2024** e as contas
--   sao anteriores. `flag_ocupacao_sem_data` marca. **Ausencia de data NUNCA vira data
--   antiga por default**: seria inventar antiguidade.
--   **CONSEQUENCIA QUE MUDA A LEITURA:** qualquer taxa de rotatividade tirada daqui e
--   **piso, nunca taxa**. O conjunto datavel e, por construcao, o que mudou depois de
--   11/2024 -- ele super-representa o recente. Em conta ativa: 526 slots ocupados, 433
--   com data (82,3%), **278 (52,9% do total ocupado) trocaram de mao nos ultimos 90
--   dias**, mediana de **61 dias** de ocupacao e maximo de 665. Os outros 248 mudaram
--   antes ou nunca foram logados -- a tabela nao distingue os dois.
--
-- REGRA 5 - FAMILIA E POSICAO. Os sufixos 2 e 3 (`criacao2`, `redacao3`) sao POSICOES
--   do mesmo papel, nao papeis diferentes -- declarado na origem, que nao tem tabela de
--   dominio. Somar por `papel` conta CARGA (um posto e um posto); somar por
--   `papel_familia` conta FUNCAO. Contar pessoa por `papel` a duplica quando ela ocupa
--   duas posicoes da mesma familia na mesma conta.
--
-- REGRA 6 - A ARITMETICA DO LOG FECHA: `SUM(qtd_alteracoes)` = **2.346**, exatamente o
--   total da Trusted. Nenhuma linha do log se perde e nenhuma e contada duas vezes --
--   cada uma cai em um unico slot. Esta e a identidade que guarda o de-para.
--
-- SETE PAPEIS SUSTENTAM A OPERACAO E OITO ESTAO PRATICAMENTE VAZIOS. Em conta ativa:
--   customersuccess 101 · assistente 89 · analistasocial 69 · analistamktmeta 66 ·
--   analistamktgoogle 63 · analistamkt 60 · analistaseo 57 -- e depois cai um
--   precipicio: sac 16 (uma pessoa so), criacao 2, storymaker 1, criacao2 1, redacao2 1,
--   criacao3/redacao/redacao3 **zero**. A mesma forma aparece no log (385 a 279
--   alteracoes nos sete, 1 a 16 nos demais): **nao e lacuna de registro, e o uso real**.
--   Redacao e criacao acontecem, mas nao sao geridas por este quadro.
--
-- O ESPECIALISTA RODA, O DONO DA CONTA FICA. Alteracoes por slot ocupado em conta
--   ativa: analistaseo **4,37** · analistamkt 4,08 · analistamktmeta 3,08 ·
--   analistamktgoogle 3,06 · analistasocial 2,59 · assistente 2,18 ·
--   customersuccess **1,64**. O posto de relacionamento troca 2,7x menos que o de SEO.
--
-- 153 SLOTS APONTAM PARA PESSOA QUE NAO EXISTE NO CADASTRO DE USUARIO -- 36 pessoas,
--   11,7% dos slots ocupados e 25% das pessoas. Gente que saiu e cujo cadastro nao
--   esta mais la. `flag_responsavel_nao_catalogado` acende e `responsavel_nome` sai
--   NULL. Leitura por nome cobre 88,3% dos slots ocupados.
--
-- O GESTOR E 1:1 COM A CONTA E A ARITMETICA ESTA DECLARADA: `trs_vjob__gestor_cliente`
--   tem 234 linhas para 234 contas distintas, **zero duplicidade** -- mas **39 apontam
--   para conta que nao existe** no cadastro de atendimento (conta apagada). Entao
--   234 - 39 = **195 contas com gestor** e 115 sem (`flag_conta_sem_gestor`, 1.725
--   slots). As 39 linhas nao aparecem nesta tabela, de proposito: o grao aqui e o slot
--   da conta viva.
--
-- LIMITACOES - nao contorne:
--   1. **Isto nao mede trabalho, mede atribuicao.** Quem esta no posto nao e quem
--      entregou -- entrega esta em `rfn_operacao__job` e `rfn_operacao__escopo_mensal`.
--   2. **Nao ha serie historica de estado.** A tabela e reconstruida inteira a cada
--      execucao e mostra o estado da carga. Para "quem atendia em marco", so o log --
--      e ele cobre 59,3% dos postos.
--   3. **`dias_na_ocupacao_atual` e relativo a data da CARGA**, nao a uma data fixa.
--      Para corte historico estavel, comparar `ocupacao_desde` contra a data escolhida.
--   4. **4 contas ativas nao tem nenhum papel preenchido** (`flag_conta_sem_squad`).
--      Nao quer dizer que ninguem atende -- quer dizer que o quadro nao foi preenchido.
--   5. **Carga por pessoa se calcula aqui, margem nao.** Nao ha custo nem hora ligada
--      ao slot; `rfn_operacao__custo_peca` rateia por peca, nao por atendimento.
--
-- FUSO: relogio local da intranet, herdado das Trusted. NAO CONVERTER.
--
-- MEDIDO EM 2026-09-28 sobre as tabelas materializadas: 4.650 linhas · 4.650 chaves ·
--   310 contas · 15 papeis · 1.308 ocupados · 526 em conta ativa · 144 pessoas (57 em
--   conta ativa, maximo de 22 contas, media 7,2) · 776 com data · 849 slots com log ·
--   11 divergencias · 153 sem cadastro · 195 contas com gestor · soma de alteracoes
--   2.346 = total da Trusted.
WITH conta AS (
  SELECT
    id_atendimento, nome_conta, grupo_na_origem, classe, id_cliente, cnpj_digitos,
    nome_no_cadastro_juridico, is_ativo, desativado_em, cadastrado_em, contrato_em,
    qtd_papeis_preenchidos,
    [STRUCT('customersuccess' AS papel, id_customer_success AS id_responsavel),
     ('analistamkt', id_analista_mkt), ('analistamktgoogle', id_analista_mkt_google),
     ('analistamktmeta', id_analista_mkt_meta), ('analistaseo', id_analista_seo),
     ('analistasocial', id_analista_social), ('storymaker', id_storymaker),
     ('sac', id_sac), ('assistente', id_assistente),
     ('criacao', id_criacao), ('criacao2', id_criacao_2), ('criacao3', id_criacao_3),
     ('redacao', id_redacao), ('redacao2', id_redacao_2), ('redacao3', id_redacao_3)] AS slots
  FROM `vanguardamartech_trusted`.`trs_vjob__cliente_atendimento`
),
-- REGRA 1 - o grao e o SLOT: 310 contas x 15 papeis = 4.650 linhas, ocupadas ou nao.
estado AS (
  SELECT c.* EXCEPT (slots), s.papel, s.id_responsavel
  FROM conta c, UNNEST(c.slots) s
),
log AS (
  SELECT id_alteracao, id_atendimento, papel, id_responsavel_anterior, id_responsavel_novo,
         tipo_evento, alterado_em, id_alterado_por
  FROM `vanguardamartech_trusted`.`trs_vjob__squad_alteracao`
),
-- REGRA 6 - cada linha do log cai em um unico slot: SUM(qtd_alteracoes) = 2.346.
hist AS (
  SELECT
    id_atendimento, papel,
    COUNT(*)                                            AS qtd_alteracoes,
    COUNTIF(tipo_evento = 'ATRIBUICAO')                 AS qtd_atribuicoes,
    COUNTIF(tipo_evento = 'TROCA')                      AS qtd_trocas,
    COUNTIF(tipo_evento = 'REMOCAO')                    AS qtd_remocoes,
    MIN(alterado_em)                                    AS primeira_alteracao_em,
    MAX(alterado_em)                                    AS ultima_alteracao_em,
    COUNT(DISTINCT id_responsavel_novo)                 AS qtd_pessoas_no_historico,
    COUNT(DISTINCT id_alterado_por)                     AS qtd_autores_no_historico
  FROM log GROUP BY 1, 2
),
-- REGRA 3 - inicio da OCUPACAO ATUAL. Ultima alteracao que colocou outra pessoa (ou
--   ninguem) -> a ocupacao corrente comeca na primeira linha posterior a ela.
fim_da_anterior AS (
  SELECT l.id_atendimento, l.papel, MAX(l.alterado_em) AS t
  FROM log l
  JOIN estado e ON e.id_atendimento = l.id_atendimento AND e.papel = l.papel
  WHERE l.id_responsavel_novo IS DISTINCT FROM e.id_responsavel
  GROUP BY 1, 2
),
inicio AS (
  SELECT l.id_atendimento, l.papel, MIN(l.alterado_em) AS desde
  FROM log l
  JOIN estado e ON e.id_atendimento = l.id_atendimento AND e.papel = l.papel
  LEFT JOIN fim_da_anterior f ON f.id_atendimento = l.id_atendimento AND f.papel = l.papel
  WHERE e.id_responsavel IS NOT NULL
    AND l.id_responsavel_novo IS NOT DISTINCT FROM e.id_responsavel
    AND (f.t IS NULL OR l.alterado_em > f.t)
  GROUP BY 1, 2
),
ult AS (
  SELECT id_atendimento, papel, id_responsavel_novo AS responsavel_no_log
  FROM (SELECT l.*, ROW_NUMBER() OVER (
          PARTITION BY l.id_atendimento, l.papel
          ORDER BY l.alterado_em DESC, l.id_alteracao DESC) AS rn
        FROM log l)
  WHERE rn = 1
),
usr AS (SELECT DISTINCT id_usuario, nome, ativo FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
ges AS (
  SELECT id_atendimento, id_gestor, gestor_nome, universo_do_gestor,
         flag_gestor_ja_e_papel_na_conta
  FROM `vanguardamartech_trusted`.`trs_vjob__gestor_cliente`
),
montado AS (
  SELECT
    CONCAT(CAST(e.id_atendimento AS STRING), ':', e.papel)      AS id_slot,
    e.id_atendimento,
    e.nome_conta,
    e.grupo_na_origem,
    e.classe,
    e.id_cliente                                                AS id_cliente_juridico,
    e.cnpj_digitos,
    e.nome_no_cadastro_juridico,
    e.is_ativo                                                  AS is_conta_ativa,
    e.desativado_em                                             AS conta_desativada_em,
    e.cadastrado_em                                             AS conta_cadastrada_em,
    e.contrato_em                                               AS conta_contrato_em,
    e.qtd_papeis_preenchidos                                    AS qtd_papeis_da_conta,
    (e.qtd_papeis_preenchidos = 0)                              AS flag_conta_sem_squad,

    -- REGRA 5 - familia agrupa posicao; `papel` conta carga, `papel_familia` conta funcao.
    e.papel,
    CASE
      WHEN e.papel LIKE 'criacao%' THEN 'CRIACAO'
      WHEN e.papel LIKE 'redacao%' THEN 'REDACAO'
      ELSE UPPER(e.papel)
    END                                                         AS papel_familia,
    CASE
      WHEN ENDS_WITH(e.papel, '3') THEN 3
      WHEN ENDS_WITH(e.papel, '2') THEN 2
      ELSE 1
    END                                                         AS papel_posicao,

    e.id_responsavel,
    u.nome                                                      AS responsavel_nome,
    u.ativo                                                     AS responsavel_ativo_no_cadastro,
    (e.id_responsavel IS NOT NULL)                              AS is_ocupado,
    (e.id_responsavel IS NOT NULL AND u.id_usuario IS NULL)     AS flag_responsavel_nao_catalogado,

    -- REGRA 4 - sem log, sem data. Nunca uma data antiga por default.
    i.desde                                                     AS ocupacao_desde,
    IF(i.desde IS NULL, NULL, DATE_DIFF(CURRENT_DATE(), DATE(i.desde), DAY))
                                                                AS dias_na_ocupacao_atual,
    (e.id_responsavel IS NOT NULL AND i.desde IS NULL)           AS flag_ocupacao_sem_data,

    IFNULL(h.qtd_alteracoes, 0)                                 AS qtd_alteracoes,
    IFNULL(h.qtd_atribuicoes, 0)                                AS qtd_atribuicoes,
    IFNULL(h.qtd_trocas, 0)                                     AS qtd_trocas,
    IFNULL(h.qtd_remocoes, 0)                                   AS qtd_remocoes,
    h.primeira_alteracao_em,
    h.ultima_alteracao_em,
    h.qtd_pessoas_no_historico,
    h.qtd_autores_no_historico,
    (h.id_atendimento IS NULL)                                  AS flag_slot_sem_historico,

    -- REGRA 2 - o estado decide; quando o log discorda, a flag acende e a data cai.
    (h.id_atendimento IS NOT NULL
       AND ul.responsavel_no_log IS DISTINCT FROM e.id_responsavel)
                                                                AS flag_estado_diverge_do_log,
    ul.responsavel_no_log,

    g.id_gestor,
    g.gestor_nome,
    g.universo_do_gestor,
    g.flag_gestor_ja_e_papel_na_conta,
    (g.id_atendimento IS NULL)                                  AS flag_conta_sem_gestor
  FROM estado e
  LEFT JOIN usr    u  ON u.id_usuario     = e.id_responsavel
  LEFT JOIN hist   h  ON h.id_atendimento = e.id_atendimento AND h.papel = e.papel
  LEFT JOIN ult    ul ON ul.id_atendimento = e.id_atendimento AND ul.papel = e.papel
  LEFT JOIN inicio i  ON i.id_atendimento = e.id_atendimento AND i.papel = e.papel
  LEFT JOIN ges    g  ON g.id_atendimento = e.id_atendimento
)
SELECT
  m.*,
  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(m)))                                AS _payload_hash
FROM montado m
