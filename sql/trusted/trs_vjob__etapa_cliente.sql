-- trs_vjob__etapa_cliente
-- Etapa de servico por cliente, do VJOB real (mysql-yIOn). Grao: uma etapa. Chave: id_etapa.
--
-- O SUFIXO "2" NAO SIGNIFICA DESCARTE AQUI. A origem e `tbetapasxclientes2`. Este
-- repositorio lista doze tabelas com sufixo `2`/`3` como duplicatas descartaveis --
-- `tbetapas2` e uma delas, **esta nao**. Medido em 2026-09-24: **7.782 linhas e marcacao
-- em 23/09/2026 12:45**, ontem. O sufixo nao prova descarte; **a data do ultimo evento
-- prova**. Conferir antes de descartar por nome.
--
-- MEDIDO EM 2026-09-24
--   7.782 linhas, 7.782 ids, **169 clientes, ZERO com `id_cliente = 0`**, 67 servicos,
--   3 areas (0, 1, 2). Datas de 25/04/2023 a **03/11/2026** -- ha etapa futura, entao
--   contagem sem recorte de janela soma mes que nao aconteceu.
--   Marcacao de 09/10/2025 a 23/09/2026, por 37 pessoas.
--
-- METADE DA TABELA NUNCA FOI ATIVADA, e e o achado principal. `ativo` e:
--   **NULL em 3.790 linhas (48,7%)** -- e **NENHUMA delas tem marcacao**, nem uma;
--   `1` em 3.987, dessas 1.446 marcadas;
--   `0` em 5, uma marcada.
--   Entao a taxa de marcacao muda de sentido conforme o denominador: **18,6% sobre a
--   tabela inteira e 36,3% sobre as etapas ativas**. `flag_nunca_ativada` existe para
--   que ninguem divida pelo denominador errado sem perceber.
--
-- 882 DAS 7.782 (11,3%) APONTAM PARA CLIENTE SEM CADASTRO em `tbclientes` -- o mesmo
--   buraco de origem ja medido no escopo (43.329 de 195.163), no cronograma (1.274 de
--   6.773) e na auditoria (1.372 de 3.025). O join e LEFT e a flag acende.
--
-- MARCADA SEM MARCADOR: 1.447 linhas tem `datamarcacao` e **1.423 tem `quemmarcou`**.
--   As 24 de diferenca foram marcadas sem que o sistema registrasse quem. Ficam
--   marcadas, nao corrigidas.
--
-- FUSO: NADA SE CONVERTE. `datamarcacao` vem TIMESTAMP direto do MySQL e ja e hora local
--   (America/Sao_Paulo), provado no nivel do conector em 2026-09-23.
--
-- CLASSIFICACAO: **L2 INTERNAL.** So ids, datas e flags. Nao ha nome, documento nem
--   texto livre.
--
-- LIMITACOES -- NAO CONTORNE
--   1. `area` tem **3 valores (0, 1, 2) e NENHUMA tabela de dominio** localizada. Sai
--      como numero. Agrupar funciona; nomear seria inventar.
--   2. `id_servico` tem 67 valores distintos. **NAO confundir com os 38 da
--      `trs_vjob__servico`** (escopo) nem com os 30 de `tbservicoscronograma`: sao
--      catalogos diferentes, e a casa ja registra que o do cronograma usa ids 22-159 e o
--      do escopo 1-44. Nao juntar sem provar a equivalencia primeiro.
--   3. `data` e **prazo/competencia da etapa, nao a data em que algo foi feito**. Quem
--      quiser datar a acao usa `marcado_em`, que existe em 1.447 das 7.782.
--   4. **Ha etapa ate 03/11/2026.** Toda serie precisa de recorte de janela explicito.
--
-- VALIDACAO 2026-09-24 (a query validada reproduziu todos estes numeros)
--   7.782 linhas · 7.782 ids · 882 sem cadastro de cliente · 3.790 nunca ativadas ·
--   1.447 marcadas · 24 marcadas sem marcador · 3 valores de area.
SELECT
  e.id                                                    AS id_etapa,
  e.id_cliente,
  c.nome                                                  AS cliente_nome,
  (c.id IS NULL)                                          AS flag_cliente_nao_catalogado,
  e.id_servico,
  e.area,
  e.data                                                  AS data_etapa,
  -- Tres estados, nao dois: ativa, desativada e NUNCA ATIVADA. O terceiro e metade da
  -- tabela e some se `ativo` virar um booleano de dois valores.
  (e.ativo = 1)                                           AS is_ativa,
  (e.ativo IS NULL)                                       AS flag_nunca_ativada,
  e.datamarcacao                                          AS marcado_em,
  (e.datamarcacao IS NOT NULL)                            AS is_marcada,
  NULLIF(e.quemmarcou, 0)                                 AS quem_marcou,
  -- 24 linhas foram marcadas sem que o sistema registrasse quem.
  (e.datamarcacao IS NOT NULL
     AND NULLIF(e.quemmarcou, 0) IS NULL)                 AS flag_marcada_sem_marcador,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'mysql-yIOn'                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(e)))                          AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbetapasxclientes2` e
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientes` c
  ON c.id = e.id_cliente
