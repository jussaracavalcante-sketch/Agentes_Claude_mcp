-- trs_vjob__ia_geracao
-- A execucao da IA para uma solicitacao, no modulo `ia_*` do VJOB real (mysql-yIOn).
-- Grao: uma geracao. Chave: id_geracao.
--
-- ESTA TABELA CORRIGE UMA AFIRMACAO MINHA, publicada horas antes na descricao da
-- `trs_vjob__ia_solicitacao`: eu escrevi que "a peca gerada NAO esta aqui, nao ha coluna
-- com o que a IA devolveu". **Ha.** `ia_geracoes` existe, tem 86 linhas e carrega
-- `resultado` -- o texto entregue -- alem de `modelo`, `uso_json` e `custo_estimado_usd`.
-- Eu tinha visto `ia_geracao_arquivos` e concluido que a tabela-pai nao estava no
-- catalogo, sem contar as linhas dela. Estava.
--
-- MEDIDO EM 2026-09-24
--   86 geracoes, 86 ids, **86 solicitacoes distintas -- 1:1 exato** com a
--   `trs_vjob__ia_solicitacao`. Janela 23/06 a 17/09/2026.
--   Status, mesmo vocabulario da solicitacao: concluido 75 · erro 6 ·
--   aguardando_configuracao 3 · erro_imagem 1 · aguardando_montagem_imagem 1.
--   `resultado` preenchido nas **86**, 4.314 caracteres em media.
--   **UM unico modelo (`gpt-5.4`) e UM unico provedor** em toda a base.
--
-- O CUSTO DA OPERACAO DE IA E MEDIDO E E PEQUENO: **US$ 14,04 em tres meses**
--   (US$ 14,043281 na soma validada: 14,018770 nos concluidos + 0,018243 + 0,006268).
--   A maior geracao custou
--   US$ 0,528973. **75 das 86 tem custo; 11 nao tem** -- os 6 `erro`, os 3
--   `aguardando_configuracao` e **2 CONCLUIDAS**. As nove primeiras nunca chamaram o
--   provedor; as duas concluidas sem custo nao tem explicacao na base, e ficam marcadas
--   em vez de arredondadas. Nos onze casos `custo_estimado_usd` sai NULL e
--   `flag_sem_custo` acende. **NULL, nunca zero**: zero e um numero e seria
--   somado como se a chamada tivesse sido gratuita. Mesma doutrina do "zero de conclusao
--   nao e zero, e NULL" da `rfn_operacao__escopo_mensal`.
--
-- `resposta_bruta` NAO E EMITIDA -- so `chars_resposta_bruta` e a flag. E o envelope cru
--   do provedor (77 das 86, 4.184 caracteres em media), e duplicar ~350 KB de payload que
--   ja esta na Raw nao acrescenta nada que `resultado` nao diga. Quem precisar do envelope
--   le a Raw. **Nao afirmo que sao identicos** -- nao medi isso; afirmo que nao vale o
--   peso na Trusted.
--
-- FUSO: NADA SE CONVERTE. `criado_em` vem TIMESTAMP direto do MySQL e ja e hora local.
--
-- CLASSIFICACAO: **L3 CONFIDENTIAL**. `resultado` e peca de comunicacao de cliente de
--   terceiro, antes de publicar. Medido em 2026-09-24: ZERO CPF, CNPJ, telefone ou
--   e-mail nos campos livres do modulo. Texto livre gerado a partir de briefing humano,
--   entao a medicao e um retrato -- remedir se o modulo crescer.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **86 linhas e 3 clientes nao sustentam indicador.** Custo medio por peca daqui
--      nao projeta nada; e a media de um piloto.
--   2. O 1:1 com a solicitacao **e o estado de hoje, nao uma garantia do esquema**. Uma
--      nova tentativa sobre a mesma solicitacao criaria a segunda geracao. Por isso a
--      tabela existe separada e a chave e `id_geracao`, nao `id_solicitacao`.
--   3. `id_provedor` nao tem tabela de dominio localizada; sai como id, sem rotulo.
--   4. `uso_json` sai como TEXTO CRU (75 das 86). Tokens de entrada e saida estao ali
--      dentro e **nao sao desaninhados aqui** -- o formato nao foi medido, e desaninhar
--      sem medir e adivinhar.
--   5. `custo_estimado_usd` e ESTIMATIVA do proprio sistema, em dolar, e **nao ha taxa de
--      cambio nesta base**. Nao converter para real sem uma fonte de cambio declarada.
WITH ger AS (
  SELECT
    g.id                                                  AS id_geracao,
    g.solicitacao_id                                      AS id_solicitacao,
    NULLIF(CAST(g.provedor_id AS STRING), '')             AS id_provedor,
    NULLIF(TRIM(g.modelo), '')                            AS modelo,
    NULLIF(TRIM(g.status), '')                            AS status,
    NULLIF(g.resultado, '')                               AS resultado,
    NULLIF(g.erro, '')                                    AS erro,
    NULLIF(g.uso_json, '')                                AS uso_json,
    -- O valor chega como texto na origem. SAFE_CAST: o que nao for numero vira NULL em
    -- vez de derrubar a query, e a flag abaixo denuncia quantos foram.
    SAFE_CAST(NULLIF(CAST(g.custo_estimado_usd AS STRING), '') AS FLOAT64) AS custo_estimado_usd,
    LENGTH(COALESCE(g.resposta_bruta, ''))                AS chars_resposta_bruta,
    g.criado_em
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_ia_geracoes` g
)
SELECT
  ger.id_geracao,
  ger.id_solicitacao,
  ger.id_provedor,
  ger.modelo,
  ger.status,
  (ger.status = 'concluido')                              AS is_concluido,
  (ger.status IN ('erro', 'erro_imagem'))                 AS is_erro,
  ger.resultado,
  LENGTH(COALESCE(ger.resultado, ''))                     AS chars_resultado,
  ger.erro,
  ger.uso_json,
  ger.custo_estimado_usd,
  -- Chamada que nunca aconteceu nao custou zero: nao custou NADA que se saiba.
  (ger.custo_estimado_usd IS NULL)                        AS flag_sem_custo,
  ger.chars_resposta_bruta,
  (ger.chars_resposta_bruta > 0)                          AS flag_tem_resposta_bruta,
  ger.criado_em,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'mysql-yIOn'                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(ger)))                        AS _payload_hash
FROM ger
