-- trs_vjob__escopo
-- Trusted do VJOB REAL (MySQL): um escopo planejado por linha. Chave id_escopo.
-- Fonte: mysql-yIOn, stream `vjob_2024_tbescopofinal`, tabela
-- `vanguardamartech_vjob_real_mysql.mysql_vjobvjob_2024_tbescopofinal`.
--
-- ESTA TABELA CARIMBA A CONCLUSAO, E O DERIVADO NAO CARIMBAVA. `datahoramarcado`
-- existe aqui e NAO existe em `supabase_silver_vjob_escopo`. Ate 21/09/2026 a casa
-- registrava que "a tabela de escopo nao carimba quando a conclusao foi marcada" --
-- verdade sobre o derivado, falso sobre o sistema. O derivado perdeu a coluna no
-- caminho, e com ela a unica forma de datar a acao.
--
-- VOLUME E UNICIDADE -- medido em 2026-09-23
--   195.163 linhas, 195.163 `id` distintos. Grao = escopo planejado.
--   251 clientes, 38 servicos, anos de 2023 a 2027 (ha escopo futuro).
--   O derivado Supabase tem 183.455 -- **11.708 linhas a menos**.
--
-- CONCLUSAO: 68.016 com `status = 1` (34,9%). Dessas, **57.090 tem carimbo** e
--   **10.926 (16%) nao datam a acao**. Mais 73 linhas tem carimbo e status = 0 --
--   marcado e desmarcado. Qualquer serie temporal de conclusao cobre 84% das
--   conclusoes; a cobertura tem de vir junto com o numero.
--
-- FUSO -- O VJOB GRAVA HORA LOCAL. Verificado em 2026-09-23 por DOIS caminhos:
--   (a) o mesmo registro no MySQL e no payload bronze do Supabase carrega o
--       relogio identico (tbjobs 1461: 2026-08-24 11:15:59 nos dois);
--   (b) a distribuicao horaria das 57.163 marcacoes tem pico as 12h (9.566), queda
--       as 13-14h (1.982 e 1.711) e retomada as 15-19h -- o almoco da casa. Em UTC
--       esse "almoco" cairia as 10-11h, que nao e almoco de ninguem.
--   Portanto `DATETIME(ts)` SEM argumento de fuso. Aplicar 'America/Sao_Paulo'
--   SUBTRAIRIA 3 horas de um dado que ja e local.
--
-- LIMITACOES -- NAO CONTORNE
--   1. **96 DOS 251 CLIENTES DO ESCOPO (38%) NAO TEM CADASTRO EM `tbclientes`**,
--      e eles carregam **44.356 escopos (23%), dos quais 19.416 concluidos**.
--      Nao e falha de extracao -- as duas tabelas vieram da mesma carga. E a origem
--      que tem escopo apontando para cadastro que nao existe mais.
--      O join E o certo: verificado em 2026-09-23 contra os nomes ja resolvidos no
--      derivado, `tbclientes` bate em **155 de 156** e `tbclientesatedimentos` bate
--      em **ZERO**. A hipotese de que o id apontava para a tabela de atendimentos
--      foi testada e descartada.
--      `flag_cliente_nao_catalogado` acende nessas linhas. O LEFT JOIN e proposital:
--      com INNER, um quarto da base sumiria sem sinal.
--   2. **16% das conclusoes nao datam.** Ver acima. `flag_concluido_sem_carimbo`
--      existe para que a serie declare a propria cobertura.
--   3. **Contar conclusao pelo mes de CADASTRO inverte o sinal.** Foi o que
--      aconteceu em 21/09/2026, quando so havia o derivado: relatou-se queda de 83
--      para 65 clientes com conclusao entre junho e setembro. Medido pelo mes da
--      MARCACAO, setembro e o maior mes da serie (4.632 marcacoes, 91 clientes,
--      56 pessoas, contra 2.696 de agosto). Use `marcado_em`, nunca `cadastrado_em`,
--      para datar conclusao.
--   4. **A base tem escopo FUTURO** -- ano vai ate 2027. Contagem sem recorte de
--      janela soma mes que ainda nao aconteceu.
--   5. Campos mortos, fora da tabela: `setor` (valor 0 nas 195.163 linhas),
--      `servicoextra` (0 em todas), `id_canal_publicacao` (um unico valor distinto,
--      232 nao-zero), `google_event_id` (1 linha), `google_calendar_email`,
--      `google_sync_status`, `google_last_payload`.
--      `status2` a `status7` sao quase vazios (90, 33, 238, 3, 4 e 76 linhas) e
--      nao explicam nada -- ficam fora, e a contagem esta aqui para quem duvidar.
--   6. **`id_servico` sai como ID, sem nome.** A tabela de dominio de servicos nao
--      foi localizada no catalogo nesta passagem. O derivado resolve 34 dos 38 e
--      deixa 4 como "(outro)" (ids 10, 17, 19 e 27, somando 7.980 escopos), entao
--      herdar dele tambem nao fecharia. Resolver o nome e trabalho da Refined,
--      depois de achar a tabela.
--      Os maiores por volume: 3 CARDS 71.195 - 4 REELS 15.398 - 39 STORIES 13.370 -
--      8 E-MAIL MKT 11.512 - 7 BLOGS 9.575.
--   7. O derivado marca 82 linhas como concluidas que o sistema marca `status = 0`,
--      e essas 82 tem status2..status7 TODOS nulos -- ou seja, a divergencia nao se
--      explica por nenhuma coluna de status. O sistema e a fonte de verdade; as 82
--      contam como NAO concluidas aqui.
--   8. `nome_quemmarcou` e o nome desnormalizado na origem, preenchido em 66.422 de
--      57.163 marcacoes -- ou seja, sobra nome sem carimbo. Identidade se resolve
--      por `id_quemmarcou` (156 pessoas distintas), nunca pelo rotulo.
SELECT
  e.id                                            AS id_escopo,
  e.id_cliente,
  c.cliente,
  c.is_ativo                                      AS cliente_ativo,
  c.cnpj_digitos                                  AS cliente_cnpj,
  (c.id_cliente IS NULL)                          AS flag_cliente_nao_catalogado,

  e.id_servico,
  e.mes,
  e.ano,
  DATE(e.ano, e.mes, 1)                           AS competencia,
  e.periodicidade,

  -- CONCLUSAO. status = 1 e o unico criterio do sistema; ver limitacao 6.
  e.status                                        AS status_codigo,
  (e.status = 1)                                  AS is_concluido,
  (e.status = 1 AND e.datahoramarcado IS NULL)    AS flag_concluido_sem_carimbo,
  (e.status = 0 AND e.datahoramarcado IS NOT NULL) AS flag_carimbo_sem_conclusao,

  e.id_quemmarcou                                 AS id_marcado_por,
  NULLIF(TRIM(IFNULL(e.nome_quemmarcou,'')), '')  AS marcado_por_nome,
  e.queminseriu                                   AS id_inserido_por,

  -- SEM argumento de fuso, de proposito. Ver o bloco FUSO no topo.
  DATETIME(e.datahoramarcado)                     AS marcado_em,
  DATE(DATETIME(e.datahoramarcado))               AS dt_marcacao,
  DATETIME(e.datacadastro)                        AS cadastrado_em,
  DATE(DATETIME(e.datacadastro))                  AS dt_cadastro,
  e.datafinal                                     AS dt_prazo,
  DATETIME(e.datafinal_alterada_em)               AS prazo_alterado_em,
  (e.datafinal_alterada_em IS NOT NULL)           AS flag_prazo_alterado,

  -- Atraso em dias corridos: so faz sentido onde HA carimbo e HA prazo.
  IF(e.datahoramarcado IS NULL OR e.datafinal IS NULL, NULL,
     DATE_DIFF(DATE(DATETIME(e.datahoramarcado)), e.datafinal, DAY)) AS dias_prazo_vs_marcacao,

  NULLIF(TRIM(IFNULL(e.id_insercao,'')), '')      AS id_insercao,
  NULLIF(TRIM(IFNULL(e.linkpostado,'')), '')      AS link_postado,
  NULLIF(TRIM(IFNULL(e.linkiclips,'')), '')       AS link_iclips,
  (NULLIF(TRIM(IFNULL(e.fotovisita,'')),'') IS NOT NULL OR
   NULLIF(TRIM(IFNULL(e.linkvisita,'')),'') IS NOT NULL) AS tem_registro_visita,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'mysql-yIOn'                                    AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(e)))                  AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbescopofinal` e
-- LEFT e proposital: escopo de cliente que saiu do cadastro nao pode sumir.
LEFT JOIN `vanguardamartech_trusted`.`trs_vjob__cliente` c
  ON c.id_cliente = e.id_cliente
