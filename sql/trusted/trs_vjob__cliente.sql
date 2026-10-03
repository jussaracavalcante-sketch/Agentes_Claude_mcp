-- trs_vjob__cliente
-- Trusted do VJOB REAL (MySQL): um cliente por linha. Chave id_cliente.
-- Fonte: mysql-yIOn, stream `vjob_2024_tbclientes`, tabela
-- `vanguardamartech_vjob_real_mysql.mysql_vjobvjob_2024_tbclientes`.
--
-- ESTA E A TABELA-PAI QUE O DERIVADO NAO TINHA. Ate 21/09/2026 a casa registrava
-- que o cliente do VJOB era "numero sem nome, sem CNPJ e sem ponte para lugar
-- nenhum". Era verdade sobre as fontes Supabase e falso sobre o sistema.
--
-- PREFIXO DE TABELA: `mysql_vjob` colado ao nome do stream, que ja inclui o banco
-- -- `mysql_vjobvjob_2024_tbclientes`. Terceiro caso da armadilha de prefixo na
-- base (Google Ads, Linear, MySQL). Nunca deduzir; achar pelo catalogo.
--
-- VOLUME -- medido em 2026-09-23
--   317 clientes. 166 com CNPJ VALIDO (52%), em 140 CNPJs distintos, e 2 com
--   fragmento de mascara (ver o bloco DOCUMENTO). 21 com CPF.
--   Cadastro de 03/10/2023 a 21/09/2026.
--
-- FUSO -- O VJOB GRAVA HORA LOCAL. Verificado em 2026-09-23 por DOIS caminhos:
--   (a) o mesmo registro no MySQL e no payload bronze do Supabase carrega o
--       relogio identico (tbjobs 1461: 2026-08-24 11:15:59 nos dois);
--   (b) a distribuicao horaria das marcacoes de escopo tem pico as 12h, queda as
--       13-14h e retomada as 15-19h -- almoco. Em UTC o "almoco" cairia as 10-11h,
--       que nao e almoco de ninguem.
--   Portanto `DATETIME(ts)` SEM argumento de fuso, que devolve o relogio de parede
--   original. Aplicar 'America/Sao_Paulo' aqui SUBTRAIRIA 3 horas de um dado que
--   ja e local.
--
-- DOCUMENTO -- `tem_cnpj` PASSOU A SIGNIFICAR VALIDO, nao preenchido (2026-09-23).
--   Dois cadastros -- `MOVE RENTAL CARS` 335 e 336 -- trazem `87.176.853/4___-__`,
--   que e a mascara do formulario preenchida pela metade: 9 digitos. A versao
--   anterior desta tabela acendia `tem_cnpj` neles e entregava o fragmento em
--   `cnpj_digitos`, que e a chave de juncao. Nove digitos nao sao um CNPJ; sao um
--   prefixo, e juntar por prefixo e o mesmo erro de juntar por rotulo.
--   Agora `cnpj_digitos` so existe com 14 digitos, `flag_cnpj_invalido` acende nos
--   dois casos e `cnpj_digitos_origem` preserva o que veio -- marcar, nunca apagar.
--   A `rfn_cadastro__cliente_sk` foi corrigida na mesma sessao e trata os dois como
--   ISOLADO, com o fragmento visivel em `candidato_sk_por_documento_parcial`.
--
-- DADO PESSOAL FICA FORA. A origem traz `cpf` (21 linhas), `responsavel`,
-- `telefone`, `email`, `emailfinanceiro` e `endereco` -- contato de pessoa fisica.
-- A Trusted emite apenas flags de presenca, para que a completude do cadastro
-- possa ser medida sem o dado sair. Mesmo criterio do e-mail no Linear e no GitHub,
-- e o precedente do `Gestao de Projetos do iClips` (cpf e valorHora descartados).
--
-- LIMITACOES -- NAO CONTORNE
--   1. **A ponte por documento cobre METADE.** 166 de 317 cadastros tem CNPJ VALIDO
--      (168 tinham o campo preenchido; 2 sao fragmento de mascara -- ver o bloco
--      DOCUMENTO no topo). Para os 151 sem documento, ligar a iClips ou ao
--      financeiro e casamento POR NOME -- hipotese declarada, nunca prova. Vale o
--      que a armadilha do `silver_vjob_escopo` ja dizia.
--   2. **140 CNPJs distintos para 166 validos**: ha CNPJ repetido entre
--      cadastros. Cadastro nao e empresa. Agrupar por `cnpj_digitos` funde
--      cadastros que a R-003 manda manter separados se forem contas distintas --
--      conferir antes.
--   3. `nicho` e **vazio nas 317 linhas**. Campo morto, fica fora.
--   4. `cidade` e INT64 na origem (id de cidade), sem tabela de dominio localizada
--      nesta passagem. Sai como id, nao como nome.
--   5. **96 clientes com escopo NAO tem cadastro aqui** -- ver a limitacao 1 da
--      trs_vjob__escopo. Este cadastro nao cobre tudo que o escopo referencia.
--   6. As 14 colunas de papel (`customersuccess`, `analistamkt`, `analistasocial`,
--      `criacao2`, `redacao3`...) sao ids de usuario da intranet, nao nomes.
--      Resolvem contra `tbusuariointranet` -- que carrega CPF, RG e salario, entao
--      quem for montar essa dimensao trata disso antes.
SELECT
  c.id                                            AS id_cliente,
  TRIM(c.nome)                                    AS cliente,
  NULLIF(TRIM(IFNULL(c.razao,'')), '')            AS razao_social,

  -- CNPJ em tres formas. Ver o bloco DOCUMENTO no topo.
  --   cnpj_digitos ......... a CHAVE DE JUNCAO. So existe quando tem 14 digitos.
  --   cnpj_digitos_origem .. os digitos como vieram, sempre.
  --   cnpj_origem .......... o texto cru, com mascara.
  IF(LENGTH(REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]','')) = 14,
     REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]',''), NULL)    AS cnpj_digitos,
  NULLIF(REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]', ''), '') AS cnpj_digitos_origem,
  NULLIF(TRIM(IFNULL(c.cnpj,'')), '')             AS cnpj_origem,
  (LENGTH(REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]','')) = 14)           AS tem_cnpj,
  (NULLIF(REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]',''),'') IS NOT NULL
   AND LENGTH(REGEXP_REPLACE(IFNULL(c.cnpj,''), r'[^0-9]','')) <> 14)      AS flag_cnpj_invalido,

  NULLIF(TRIM(IFNULL(c.modelo,'')), '')           AS modelo,
  c.status                                        AS status_codigo,
  (c.status = 1)                                  AS is_ativo,
  c.tipofaturamento                               AS tipo_faturamento_codigo,
  c.cidade                                        AS id_cidade,
  NULLIF(TRIM(IFNULL(c.estado,'')), '')           AS uf,

  -- Completude do cadastro sem expor o dado. Ver o bloco DADO PESSOAL no topo.
  (NULLIF(TRIM(IFNULL(c.responsavel,'')),'') IS NOT NULL)    AS tem_responsavel,
  (NULLIF(TRIM(IFNULL(c.cpf,'')),'') IS NOT NULL)            AS tem_cpf,
  (NULLIF(TRIM(IFNULL(c.telefone,'')),'') IS NOT NULL)       AS tem_telefone,
  (NULLIF(TRIM(IFNULL(c.email,'')),'') IS NOT NULL)          AS tem_email,
  (NULLIF(TRIM(IFNULL(c.emailfinanceiro,'')),'') IS NOT NULL) AS tem_email_financeiro,
  (NULLIF(TRIM(IFNULL(c.endereco,'')),'') IS NOT NULL)       AS tem_endereco,

  -- Equipe alocada: ids de usuario da intranet. Ver limitacao 6.
  c.customersuccess                               AS id_customer_success,
  c.analistamkt                                   AS id_analista_mkt,
  c.analistamktgoogle                             AS id_analista_google,
  c.analistamktmeta                               AS id_analista_meta,
  c.analistasocial                                AS id_analista_social,
  c.analistaseo                                   AS id_analista_seo,
  c.storymaker                                    AS id_storymaker,
  c.sac                                           AS id_sac,
  c.assistente                                    AS id_assistente,
  c.criacao                                       AS id_criacao,
  c.redacao                                       AS id_redacao,
  (IF(c.customersuccess > 0,1,0) + IF(c.analistamkt > 0,1,0) + IF(c.analistamktgoogle > 0,1,0)
   + IF(c.analistamktmeta > 0,1,0) + IF(c.analistasocial > 0,1,0) + IF(c.analistaseo > 0,1,0)
   + IF(c.storymaker > 0,1,0) + IF(c.sac > 0,1,0) + IF(c.assistente > 0,1,0)
   + IF(c.criacao > 0,1,0) + IF(c.redacao > 0,1,0))        AS qtd_papeis_alocados,

  c.escopo                                        AS flag_escopo_codigo,
  c.setup                                         AS flag_setup_codigo,

  -- SEM argumento de fuso, de proposito. Ver o bloco FUSO no topo.
  DATETIME(c.datacadastro)                        AS cadastrado_em,
  DATE(DATETIME(c.datacadastro))                  AS dt_cadastro,
  c.datacontrato                                  AS dt_contrato,

  CURRENT_TIMESTAMP()                             AS _extraido_at,
  'mysql-yIOn'                                    AS _fonte,
  'America/Sao_Paulo'                             AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(c)))                  AS _payload_hash
FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_tbclientes` c
