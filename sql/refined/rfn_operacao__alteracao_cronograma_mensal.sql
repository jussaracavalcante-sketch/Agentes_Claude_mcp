-- rfn_operacao__alteracao_cronograma_mensal  ·  query-CHK9  ·  1.003 linhas  ·  L4
-- Refined / operacao. Grao: um MES, uma COLUNA ALTERADA, uma PESSOA.
-- Chave: id_alteracao_mensal = <mes>:<coluna>:<id_usuario ou SEM_USUARIO>.
-- Origens: trs_vjob__cronograma_alteracao (18.955) · trs_vjob__usuario (273).
-- Gatilho: evento em query-v4r2. Cadencia semanal, herdada da mysql-yIOn.
--
-- O QUE ELA RESPONDE: **o que muda nos contratos da casa, quando, quanto e por quem.**
--   `tbmudancas` e o unico log de alteracao de dinheiro de contrato que esta base tem, e
--   ate hoje nada na camada de consumo o lia.
--
-- ============================================================================
-- REGRA 1 - ELA NAO JUNTA COM CONTRATO NEM COM PARCELA, E ISSO E DELIBERADO.
-- ============================================================================
--   A Trusted declara que `id_alvo` aponta ora para o CONTRATO ora para a PARCELA e que
--   em **8.786 linhas (46,4%) e indecidivel** -- as duas sequencias de id se sobrepoem em
--   4.121 valores. Um join direto duplica essas linhas entre as duas pontas sem que a
--   contagem denuncie. **Esta Refined resolve o problema nao o tendo**: o grao e o
--   EVENTO agregado por mes, coluna e pessoa, e nenhum join de alvo acontece. O
--   `alvo_resolvido` viaja como CONTAGEM em cada linha (`qtd_alvo_contrato`,
--   `qtd_alvo_parcela`, `qtd_alvo_ambiguo`, `qtd_alvo_nao_catalogado`), para que a
--   ambiguidade fique visivel sem multiplicar o grao.
--
-- ============================================================================
-- REGRA 2 - O LOTE DE 22/09/2026 E O ACHADO QUE MUDA A LEITURA DE SETEMBRO.
-- ============================================================================
--   **1.367 alteracoes em 11 minutos e 28 segundos**, todas na coluna `servico`, sobre
--   **1.367 alvos DISTINTOS**, com 19 valores de usuario diferentes. Isso nao e gente
--   trabalhando -- e script. O conteudo confirma: o servico **56 "Veiculacao de Midia"**
--   virou **157 "VEICULACAO DE MIDIA OFF" (1.002 vezes)** e **158 "VEICULACAO DE MIDIA
--   ON" (365)**, e os dois ids foram criados em `tbservicoscronograma` em **18/08/2026
--   22:54**. E uma RECODIFICACAO DE CATALOGO, nao operacao.
--   Sem separar, 2026-09 e o maior mes da serie (1.577) depois de meses de 228 a 382 --
--   e nao e.
--
--   **O CRITERIO E FISICO, NAO UM LIMIAR ESCOLHIDO.** Um par (dia, coluna) e lote quando
--   tem **>= 100 eventos E >= 1 evento por segundo sustentado**. Ninguem edita um
--   contrato a cada meio segundo. A medicao mostra que o criterio nao esta numa zona
--   cinzenta: o lote de 22/09 roda a **1,99/s** e o segundo mais denso da base inteira
--   (2024-07-22, `mesanoreferencia`, 889 eventos) roda a **0,09/s** -- **22x mais lento**.
--   `qtd_em_lote` e `qtd_fora_de_lote` convivem em toda linha; **serie de operacao humana
--   se le em `qtd_fora_de_lote`**.
--
-- REGRA 3 - `usuario` E ID E RESOLVE -- corrigido na Trusted em 2026-09-28. A versao
--   anterior dela afirmava que era texto livre e que casar a pessoa seria "hipotese, nao
--   prova". Os 42 valores sao todos numericos e **40 existem em `trs_vjob__usuario`**:
--   **17.296 de 18.955 linhas (91,2%) tem pessoa**. Os 2 ids que nao resolvem (282 e
--   347, 706 linhas) so aparecem em 2024 -- gente que saiu, o mesmo mecanismo ja medido
--   no squad e no gestor. Mais 953 linhas sem usuario nenhum.
--   **Sem pessoa NAO vira uma pessoa "desconhecida":** `id_usuario` sai NULL e a linha
--   se distingue por `flag_sem_usuario` (nao havia usuario) ou
--   `flag_usuario_nao_catalogado` (havia, e o cadastro sumiu). Fundir os dois num balde
--   so esconderia qual dos dois problemas e.
--
-- REGRA 4 - DINHEIRO SO ONDE HA DINHEIRO. `delta_valor`, `valor_antigo_total`,
--   `valor_novo_total`, `qtd_aumento` e `qtd_reducao` saem **NULL** fora de `valor` e
--   `comissao` -- nunca zero. Zero seria somado; NULL obriga a decidir. Nas 444 linhas
--   monetarias **100% dos dois lados sao numericos**, entao nao ha perda de parse.
--
--   **`delta_valor` NAO E "o contrato cresceu".** O campo alterado pertence ora ao
--   contrato ora a parcela -- e a casa ja mediu que `tbcronograma.valor` e o valor de UMA
--   parcela, nao do contrato. Entao o delta e o **movimento liquido do campo logado**,
--   misturando dois graos de "valor", e serve para ver direcao e intensidade, nunca para
--   afirmar tamanho de carteira. Medido: `valor` **+R$ 160.468,78** em 355 alteracoes
--   (192 para cima, 163 para baixo) e `comissao` **-R$ 311,27** em 89 (25 e 64).
--
-- REGRA 5 - O DELTA TELESCOPA E POR ISSO SOMA. Alteracoes sucessivas do mesmo campo
--   (a->b, b->c) somam para a->c, entao somar `delta_valor` entre meses e legitimo. O
--   que nao e legitimo e somar entre COLUNAS -- `valor` e `comissao` sao grandezas
--   diferentes, e por isso a coluna esta no grao.
--
-- LIMITACOES - nao contorne:
--   1. **Isto mede EDICAO, nao negocio.** Um contrato cujo valor nunca foi editado nao
--      aparece aqui, e isso nao quer dizer que ele nao existe ou nao mudou por outro
--      caminho -- quer dizer que ninguem editou aquele campo naquela tela.
--   2. **Nao ha cliente.** O alvo e indecidivel em 46,4%, entao nao se chega ao cliente
--      sem inventar. Para dinheiro por cliente, `rfn_financeiro__rentabilidade_cliente`.
--   3. **8 eventos nao alteraram nada** (`qtd_sem_mudanca`). Contam em `qtd_alteracoes`
--      porque foram gravados; quem mede mudanca de fato subtrai.
--   4. **`os` (2) e `qtdparcelas` (1)** tem volume proximo de zero. Nao tirar tendencia.
--   5. **A serie comeca em 2024-04.** O modulo de cronograma e mais antigo que o log.
--
-- FUSO: relogio local da intranet, herdado da Trusted. NAO CONVERTER.
--
-- MEDIDO EM 2026-09-28 sobre a tabela materializada: 18.955 eventos · 1.003 linhas ·
--   1.003 chaves · 30 meses (2024-04 a 2026-09) · 18 colunas · 1.367 em lote e 17.588
--   fora · 17.296 com pessoa, 706 com usuario sem cadastro, 953 sem usuario ·
--   444 linhas monetarias.
WITH a AS (
  SELECT
    id_alteracao, id_alvo, alvo_resolvido, coluna_afetada,
    valor_antigo, valor_novo, flag_sem_mudanca, usuario, flag_sem_usuario, alterado_em,
    DATE(alterado_em)                        AS dia,
    DATE_TRUNC(DATE(alterado_em), MONTH)     AS mes_referencia,
    SAFE_CAST(usuario AS INT64)              AS id_usuario
  FROM `vanguardamartech_trusted`.`trs_vjob__cronograma_alteracao`
),
-- REGRA 2 - densidade por (dia, coluna). O criterio e fisico: >= 100 eventos E
--   >= 1 por segundo sustentado. Hoje isola exatamente um lote, com 22x de folga
--   para o segundo mais denso da base.
densidade AS (
  SELECT dia, coluna_afetada,
    COUNT(*)                                                   AS n,
    TIMESTAMP_DIFF(MAX(alterado_em), MIN(alterado_em), SECOND) AS span_seg
  FROM a GROUP BY 1, 2
),
lote AS (
  SELECT dia, coluna_afetada
  FROM densidade
  WHERE n >= 100 AND SAFE_DIVIDE(n, NULLIF(span_seg, 0)) >= 1
),
marcado AS (
  SELECT a.*, (l.dia IS NOT NULL) AS is_lote
  FROM a
  -- ANTI-JOIN sobre CTE pequena; o correlacionado nao roda no BigQuery ao escalar.
  LEFT JOIN lote l ON l.dia = a.dia AND l.coluna_afetada = a.coluna_afetada
),
usr AS (SELECT DISTINCT id_usuario, nome FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
agregado AS (
  SELECT
    m.mes_referencia,
    m.coluna_afetada,
    m.id_usuario,
    -- REGRA 3 - sem pessoa nao vira pessoa desconhecida; os dois motivos se distinguem.
    LOGICAL_OR(m.flag_sem_usuario)                              AS flag_sem_usuario,
    LOGICAL_OR(m.id_usuario IS NOT NULL AND u.id_usuario IS NULL)
                                                                AS flag_usuario_nao_catalogado,
    MAX(u.nome)                                                 AS usuario_nome,

    COUNT(*)                                                    AS qtd_alteracoes,
    COUNT(DISTINCT m.id_alvo)                                   AS qtd_alvos_distintos,
    COUNT(DISTINCT m.dia)                                       AS qtd_dias_com_alteracao,
    COUNTIF(m.flag_sem_mudanca)                                 AS qtd_sem_mudanca,

    -- REGRA 1 - a ambiguidade viaja como contagem, nunca como join.
    COUNTIF(m.alvo_resolvido = 'CONTRATO')                      AS qtd_alvo_contrato,
    COUNTIF(m.alvo_resolvido = 'PARCELA')                       AS qtd_alvo_parcela,
    COUNTIF(m.alvo_resolvido = 'AMBIGUO')                       AS qtd_alvo_ambiguo,
    COUNTIF(m.alvo_resolvido = 'NAO_CATALOGADO')                AS qtd_alvo_nao_catalogado,

    -- REGRA 2 - operacao humana se le no `fora_de_lote`.
    COUNTIF(m.is_lote)                                          AS qtd_em_lote,
    COUNTIF(NOT m.is_lote)                                      AS qtd_fora_de_lote,

    MIN(m.alterado_em)                                          AS primeira_alteracao_em,
    MAX(m.alterado_em)                                          AS ultima_alteracao_em,

    -- REGRA 4 - dinheiro so onde ha dinheiro; fora disso os agregados saem NULL.
    SUM(IF(m.coluna_afetada IN ('valor', 'comissao'),
           SAFE_CAST(m.valor_antigo AS FLOAT64), NULL))         AS soma_antigo,
    SUM(IF(m.coluna_afetada IN ('valor', 'comissao'),
           SAFE_CAST(m.valor_novo AS FLOAT64), NULL))           AS soma_novo,
    COUNTIF(m.coluna_afetada IN ('valor', 'comissao')
            AND SAFE_CAST(m.valor_novo AS FLOAT64)
              > SAFE_CAST(m.valor_antigo AS FLOAT64))           AS qtd_aumento_bruta,
    COUNTIF(m.coluna_afetada IN ('valor', 'comissao')
            AND SAFE_CAST(m.valor_novo AS FLOAT64)
              < SAFE_CAST(m.valor_antigo AS FLOAT64))           AS qtd_reducao_bruta
  FROM marcado m
  LEFT JOIN usr u ON u.id_usuario = m.id_usuario
  GROUP BY 1, 2, 3
)
SELECT
  CONCAT(CAST(g.mes_referencia AS STRING), ':', g.coluna_afetada, ':',
         IFNULL(CAST(g.id_usuario AS STRING), 'SEM_USUARIO'))   AS id_alteracao_mensal,
  g.mes_referencia,
  g.coluna_afetada,
  (g.coluna_afetada IN ('valor', 'comissao'))                   AS is_coluna_monetaria,

  g.id_usuario,
  g.usuario_nome,
  g.flag_sem_usuario,
  g.flag_usuario_nao_catalogado,

  g.qtd_alteracoes,
  g.qtd_alvos_distintos,
  g.qtd_dias_com_alteracao,
  g.qtd_sem_mudanca,

  g.qtd_alvo_contrato,
  g.qtd_alvo_parcela,
  g.qtd_alvo_ambiguo,
  g.qtd_alvo_nao_catalogado,

  g.qtd_em_lote,
  g.qtd_fora_de_lote,
  (g.qtd_em_lote > 0)                                           AS flag_tem_lote,

  -- REGRA 4 - NULL, nunca zero, fora das colunas de dinheiro.
  IF(g.coluna_afetada IN ('valor', 'comissao'),
     ROUND(g.soma_novo - g.soma_antigo, 2), NULL)               AS delta_valor,
  IF(g.coluna_afetada IN ('valor', 'comissao'),
     ROUND(g.soma_antigo, 2), NULL)                             AS valor_antigo_total,
  IF(g.coluna_afetada IN ('valor', 'comissao'),
     ROUND(g.soma_novo, 2), NULL)                               AS valor_novo_total,
  IF(g.coluna_afetada IN ('valor', 'comissao'),
     g.qtd_aumento_bruta, NULL)                                 AS qtd_aumento,
  IF(g.coluna_afetada IN ('valor', 'comissao'),
     g.qtd_reducao_bruta, NULL)                                 AS qtd_reducao,

  g.primeira_alteracao_em,
  g.ultima_alteracao_em,

  CURRENT_TIMESTAMP()                                           AS _extraido_at,
  'mysql-yIOn'                                                  AS _fonte,
  'America/Sao_Paulo'                                           AS _fuso
FROM agregado g
