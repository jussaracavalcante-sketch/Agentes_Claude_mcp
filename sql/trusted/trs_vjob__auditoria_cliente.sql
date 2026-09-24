-- trs_vjob__auditoria_cliente
-- Item de auditoria de servico por cliente, do VJOB real (mysql-yIOn).
-- Grao: um item auditado. Chave: id_auditoria_item.
--
-- MODULO VIVO. Medido em 2026-09-24: 3.025 itens, ultimo cadastro **21/09/2026 16:56**
-- e ultima marcacao **22/09/2026 19:48**. Janela de cadastro: 02/07/2025 em diante.
-- 46 clientes, 56 auditorias, 5 setores, 27 categorias, 4 subcategorias.
--
-- AQUI A CONCLUSAO SEMPRE DATA A ACAO -- ao contrario do escopo. Medido:
--   `status = 1` (feito) sao **1.544** e `datahoramarcacao` preenchida sao **1.544**, e
--   a coincidencia e EXATA: **zero marcados sem data e zero com data sem marcacao**.
--   Isso contrasta com `tbescopofinal`, onde 16% das conclusoes nao datam a acao. Serie
--   temporal de auditoria cobre **100%** das conclusoes; a de escopo cobre 84%.
--   `status = 0` sao 1.481. Nao ha terceiro valor.
--
-- 1.372 DOS 3.025 ITENS (45,4%) APONTAM PARA CLIENTE SEM CADASTRO em `tbclientes`.
--   E o mesmo buraco de origem ja medido no escopo (43.329 de 195.163) e no cronograma
--   (1.274 de 6.773) -- nao e falha de extracao, as tabelas vieram da mesma carga. O join
--   e LEFT e `flag_cliente_nao_catalogado` acende: **com INNER, 45% da tabela sumiria sem
--   sinal**.
--
-- O SETOR RESOLVE PELA METADE, e isso esta medido: dos 5 valores de `id_setor` presentes
--   (3, 4, 6, 7, 8), **apenas 3 existem em `tbsetor`** -- 6 Inbound Marketing,
--   7 Social Media e 8 Account Manager. Os ids 3 e 4 nao existem no dominio.
--   `flag_setor_nao_resolvido` marca **584 linhas**; 2.441 resolvem. `id_setor` continua
--   visivel nas duas situacoes.
--   (Nota de catalogo: `tbsetor` tem 17 linhas e comeca no **id 5**, nao no 11 como este
--   repositorio registrava. O que continua verdadeiro e que `tbjobsgeral.id_setor = 1`
--   nao resolve contra ele.)
--
-- `id_servico` AQUI NAO E DIMENSAO DE SERVICO. Sao **1.339 valores distintos em 3.025
--   linhas**, faixa 2 a 1.393 -- comportamento de id de instancia, nao de catalogo. NAO
--   juntar com `trs_vjob__servico` (38 servicos) nem com `tbservicoscronograma` (30): sao
--   universos diferentes, e o numero de valores distintos e a prova.
--
-- FUSO: NADA SE CONVERTE. Os TIMESTAMP vem direto do MySQL e ja sao hora local
--   (America/Sao_Paulo), provado no nivel do conector em 2026-09-23.
--
-- CLASSIFICACAO: **L2 INTERNAL.** So ids, datas, status e uma URL de evidencia (295 de
--   3.025). Nao ha nome, documento nem texto livre de pessoa.
--
-- LIMITACOES -- NAO CONTORNE
--   1. `id_auditoria`, `id_categoria` e `id_sub` **nao tem tabela de dominio localizada**
--      no catalogo. Saem como id, sem rotulo. Agrupar por eles funciona; nomea-los nao.
--   2. `datafinal` (prazo) esta em 3.016 das 3.025. Os 9 sem prazo entram nas contagens.
--   3. **46 clientes nao e a base de clientes da casa.** Esta auditoria cobre um recorte;
--      nao inferir cobertura de processo a partir daqui.
--   4. `url` e link de evidencia no servidor do VJOB. **O arquivo nao esta nesta base.**
--
-- VALIDACAO 2026-09-24 (a query validada reproduziu todos estes numeros)
--   3.025 linhas · 3.025 ids · 3.025 `_payload_hash` distintos · 1.372 sem cadastro de
--   cliente · 584 com setor nao resolvido e 2.441 resolvido · 1.544 feitos ·
--   **ZERO com `flag_status_sem_carimbo`** · 295 com evidencia · 9 sem prazo.
SELECT
  a.id                                                    AS id_auditoria_item,
  a.id_auditoria,
  a.id_cliente,
  c.nome                                                  AS cliente_nome,
  (c.id IS NULL)                                          AS flag_cliente_nao_catalogado,
  a.id_servico,
  a.id_setor,
  s.setor                                                 AS setor,
  -- 2 dos 5 ids de setor nao existem no dominio. Marcar, nunca apagar.
  (a.id_setor IS NOT NULL AND s.id IS NULL)               AS flag_setor_nao_resolvido,
  a.id_categoria,
  a.id_sub,
  a.datafinal                                             AS prazo,
  (a.status = 1)                                          AS is_feito,
  (a.ativo = 1)                                           AS is_ativo,
  a.datahoramarcacao                                      AS marcado_em,
  NULLIF(a.quemmarcou, 0)                                 AS quem_marcou,
  NULLIF(a.queminseriu, 0)                                AS quem_inseriu,
  a.datadecadastro                                        AS cadastrado_em,
  NULLIF(TRIM(a.url), '')                                 AS url_evidencia,
  (NULLIF(TRIM(a.url), '') IS NOT NULL)                   AS flag_tem_evidencia,
  -- A invariante da tabela, emitida como coluna para que uma quebra futura seja visivel
  -- sem ninguem precisar lembrar de conferir. Hoje e FALSE em 3.025 de 3.025.
  ((a.status = 1) <> (a.datahoramarcacao IS NOT NULL))    AS flag_status_sem_carimbo,
  CURRENT_TIMESTAMP()                                     AS _extraido_at,
  'mysql-yIOn'                                            AS _fonte,
  TO_HEX(MD5(TO_JSON_STRING(a)))                          AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbauditoriaclientes` a
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientes` c
  ON c.id = a.id_cliente
LEFT JOIN `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbsetor` s
  ON s.id = a.id_setor
