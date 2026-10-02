-- rfn_qualidade__regra_cadastro  ·  44 regras  ·  L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA de qualidade em uma execucao. Chave: id_regra
-- (a execucao se le em _extraido_at). Alerta ligado.
-- Gatilho: evento em query-65kE + query-NxG1 + query-hH5g, regra "all".
-- Cadencia DIARIA -- as tres disparam em query-8nEt (trs_iclips__projeto), que anda
--   com o notebook-Rbpo.
--
-- POR QUE UMA OITAVA SUITE. Mesmo motivo da do Gmail, da do iClips e da de Marketing: a
--   `rfn_qualidade__regra` esta com 57 KB e 84 regras e `update_transformation`
--   substitui o CODIGO INTEIRO -- somar regras la exigiria reescrever 57 mil caracteres
--   sem errar um, que e literalmente o caso de "query grande demais e query que nao se
--   conserta" ja registrado nesta casa. O CONTRATO DE COLUNAS E IDENTICO ao das outras
--   sete: um UNION ALL da o painel unico e `familia` diz de onde veio cada linha. Em
--   01/10/2026 a casa tem 380 regras em ONZE tabelas de qualidade, e nenhuma tabela
--   materializada fica sem regra.
--
-- O QUE FICAVA DE FORA: a familia CADASTRO inteira -- as tres dimensoes de identidade
--   da casa e a Gold de receita, 8.059 linhas materializadas sem UMA regra:
--     `rfn_cadastro__cliente`                         409   (query-65kE)
--     `rfn_cadastro__conta`                           190   (query-Y1Yt)
--     `rfn_cadastro__cliente_vbot`                      4   (query-NxG1)
--     `rfn_cadastro__cliente_vanguarda_comunicacao`     5   (query-hH5g)
--     `rfn_financeiro__receita_cliente_mensal`      7.451   (query-awMU)
--   A `rfn_cadastro__cliente_sk` NAO entra aqui: o grao dela ja e medido pela suite
--   principal (1.353/1.353).
--
-- POR QUE O GATILHO SO CITA TRES DAS CINCO, E POR QUE ISSO E O CERTO.
--   As cinco vem de TRES cadeias diferentes: `65kE`, `NxG1` e `hH5g` disparam as tres
--   em `query-8nEt` (iClips, diaria); `Y1Yt` dispara em `jHEX`+`HCcd` (dimensoes de
--   conta de midia); `awMU` dispara em `query-V3c3`, no fim da cadeia SEMANAL do VJOB.
--   Amarrar as cinco com "all" faria a suite esperar a passada semanal para medir o que
--   muda todo dia -- e uma falha em qualquer ramo impediria as 34 regras de rodar, que
--   e exatamente a armadilha declarada na suite do VJOB. O gatilho e "all" sobre os tres
--   irmaos que compartilham o MESMO upstream, entao eles estao garantidamente na mesma
--   passada; as outras duas sao medidas como estiverem materializadas.
--
-- E POR ISSO A REGRA DE FRESCOR TEM ESCOPO DE FONTE, NAO DE FAMILIA.
--   `cadastro.carga_do_mesmo_dia` compara `MAX(DATE(_extraido_at))` das TRES tabelas do
--   gatilho, e so delas. Incluir `conta` (outra cadeia) ou `receita` (semanal) faria a
--   regra falhar POR DESENHO, todo dia -- o mesmo erro que a suite do iClips ja evitou
--   ao deixar `peca_atributo` e `peca_categoria` de fora do frescor.
--
-- AS 34 PRIMEIRAS REGRAS, MEDIDAS EM 2026-09-29 SOBRE A TABELA MATERIALIZADA, ANTES DE
-- PUBLICAR. A primeira execucao, em 30/09, deu 34 CONFORMES. A segunda, em 01/10, deu
-- UMA FALHA BLOQUEANTE -- e a falha era da REGRA, nao do dado. Ver `futura_decompoe`.
--
-- +10 EM 01/10, SOBRE A `rfn_cliente__contexto` (410 linhas), QUE ESTAVA SEM REGRA
-- NENHUMA e que o CLAUDE.md nao registrava. Ver o bloco proprio, mais abaixo no codigo.
-- Medidas na tabela materializada e rodadas unidas a uma CTE antiga antes de publicar:
-- 11 regras, 11 ids distintos, CONFORME 11, ZERO falhas.
--
-- A REGRA QUE IMPORTA MAIS E A SEXTA IDENTIDADE DESTA CASA:
--   `rfn_financeiro__receita_cliente_mensal.honorario_mais_repasse_e_o_total`.
--   A R2 daquela tabela diz, em maiusculas, que HONORARIO E REPASSE NAO SE SOMAM COMO
--   RECEITA DA CASA -- parcela sem fornecedor e entrega da casa, parcela com fornecedor
--   tem um terceiro que recebe. As duas colunas existem justamente para nao serem
--   confundidas, e `valor_total` existe so para reconciliar com a Trusted. A identidade
--   testa que a decomposicao e EXAUSTIVA: se um dia aparecer parcela que nao cai em
--   nenhum dos dois lados, ela some da leitura de honorario E da de repasse, e
--   `valor_total` continua batendo com a Trusted -- nada na contagem denuncia.
--   Medido, linha a linha: 7.451 avaliadas, ZERO fora de um centavo.
--   R$ 19.757.217,94 + R$ 91.778.852,74 = R$ 111.536.070,68.
--   As cinco anteriores: `rateio_fecha_no_centavo` (custo), `caixa_reproduz_o_razao`
--   (Conta Azul), `itens_batem_com_a_auditoria` (VJOB), `custo_reproduz_hora_vezes_
--   valor_hora` (iClips) e `reproduz_a_trusted_linha_a_linha` (Marketing).
--
-- A SEGUNDA QUE IMPORTA E A QUE GUARDA A R-003 NA DIMENSAO DE CONTA:
--   `rfn_cadastro__conta.ambiguidade_nunca_vira_cnpj`. A Regra 2 daquela tabela declara
--   que nome do iClips apontando para mais de um CNPJ e DESCARTADO da ponte, e a conta
--   recebe `cnpj` NULL com `cnpj_ambiguo_na_origem = TRUE` -- "escolher um deles seria
--   inventar identidade juridica". Hoje e 1 conta bloqueada. Se um dia uma linha
--   ambigua sair COM CNPJ, a tabela estara atribuindo empresa a conta por desempate, que
--   e o que a R-003 proibe, e a contagem de linhas nao muda. BLOQUEANTE.
--
-- A TERCEIRA E O QUE DEFINE AS DUAS TABELAS INTRAGRUPO:
--   `..._vbot.cnpj_e_o_da_empresa` e `..._vanguarda_comunicacao.cnpj_e_o_da_empresa`.
--   Essas duas tabelas nao sao recorte de conveniencia: elas EXISTEM porque um CNPJ
--   define a empresa, e a propria descricao delas avisa que filtrar por NOME perde
--   R$ 47.544,32 e traz R$ 40.067,03 de outra empresa. Se um CNPJ diferente aparecer,
--   o filtro que da nome a tabela se soltou. BLOQUEANTE, com 4 e 5 linhas.
--
-- AS OUTRAS QUE GUARDAM PREMISSA DE VERDADE:
--   `cliente.chave_concorda_com_o_metodo` -- a R1 daquela tabela usa fallback: a chave e
--     `CNPJ:<14 digitos>` ou `ICLIPS:<id>`, e `chave_por` diz qual valeu. Chavear so por
--     CNPJ perderia 60 dos 409 clientes (14,7%). Se a chave deixar de concordar com o
--     metodo declarado, o mesmo cliente pode aparecer em duas linhas -- uma por CNPJ e
--     outra por id -- e o total continua parecendo certo.
--   `cliente.variacao_de_nome_decompoe` e `cliente.cadastro_duplicado_decompoe` -- as
--     duas flags da R3 e da R4 tem de ser exatamente `qtd > 1`. Sao os unicos sinais de
--     que a origem escreve o mesmo cliente de mais de um jeito.
--   `receita.cliente_sem_registro_nao_recebe_taxa` -- a R6 herda a doutrina da casa:
--     zero de conclusao e NULL, nunca zero. Se a taxa aparecer para quem nao tem uma
--     conclusao sequer, o indicador passa a somar denominador que ninguem marcou.
--   `receita.toda_linha_tem_um_lado` -- a R8 usa FULL OUTER e declara que 54% da receita
--     esta em cliente-mes SEM escopo. Linha sem nenhum dos dois lados seria linha que o
--     join inventou.
--   `receita.competencia_e_o_primeiro_dia` -- guarda a familia de defeito ja custosa
--     nesta base: `DATE(MAX(ano), MAX(mes), 1)` combina ano e mes maximos
--     INDEPENDENTEMENTE e inventou 9 meses de erro no CNPJ 26.123.250/0001-02.
--
-- UMA LINHA DE BASE, DE PROPOSITO:
--   `receita.cliente_catalogado`, limiar 0,70 contra 76,2% medido (1.772 de 7.451 com
--   `flag_cliente_nao_catalogado`). O buraco de cadastro do VJOB -- escopo e contrato
--   apontando para cliente que nao existe em `tbclientes` -- e DA ORIGEM e ja esta
--   medido nesta casa. Limiar apertado aqui so ensinaria a ignorar a suite; o que se
--   quer detectar e PIORA. Mesmo precedente do 0,70 do escopo e do 0,78 da origem do PI.
--
-- O QUE FICOU DE FORA, E A AUSENCIA E A DECISAO:
--   `rfn_cadastro__conta.fonte_nekt` preenchida. Medido: 141 das 190 contas (74%) NAO
--   tem fonte Nekt -- sao as contas que o MCC enxerga e a casa nao integrou, mais a
--   dimensao CONGELADA do Facebook (a fonte facebook-ads-mrJt foi excluida em 26/08 e a
--   tabela e uma foto). Uma regra de completude ali acusaria o que e legitimo.

WITH

-- ─────────────────────────────── rfn_cadastro__cliente (8) ───────────────────────────
r_cliente AS (
  SELECT 'rfn_cadastro__cliente.id_cliente_unico' AS id_regra, 'Refined' AS camada,
         'rfn_cadastro__cliente' AS tabela, 'iClips' AS sistema, 'UNICIDADE' AS dimensao,
         'id_cliente e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_cliente) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  -- A R1 daquela tabela: chave com fallback declarado. Ver o bloco no cabecalho.
  SELECT 'rfn_cadastro__cliente.chave_concorda_com_o_metodo', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'INTEGRIDADE',
         'a chave e montada pelo metodo que chave_por declara', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((chave_por = 'CNPJ'
                  AND id_cliente <> CONCAT('CNPJ:', REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', '')))
              OR (chave_por = 'ID_ICLIPS' AND NOT STARTS_WITH(id_cliente, 'ICLIPS:')))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  SELECT 'rfn_cadastro__cliente.chave_por_conhecido', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'VALIDADE',
         'chave_por e CNPJ ou ID_ICLIPS', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(chave_por IS NULL OR chave_por NOT IN ('CNPJ', 'ID_ICLIPS'))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  SELECT 'rfn_cadastro__cliente.nome_preenchido', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'COMPLETUDE',
         'cliente_nome esta preenchido', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(cliente_nome IS NULL OR TRIM(cliente_nome) = '')
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  -- So e documento o que tem 14 digitos (CNPJ) ou 11 (CPF). Denominador = quem TEM.
  SELECT 'rfn_cadastro__cliente.documento_tem_forma', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'VALIDADE',
         'o documento que existe tem 14 ou 11 digitos', 'BLOQUEANTE', 1.00,
         COUNTIF(NULLIF(TRIM(cnpj), '') IS NOT NULL),
         COUNTIF(NULLIF(TRIM(cnpj), '') IS NOT NULL
                 AND LENGTH(REGEXP_REPLACE(cnpj, r'[^0-9]', '')) NOT IN (14, 11))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  SELECT 'rfn_cadastro__cliente.variacao_de_nome_decompoe', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'VALIDADE',
         'nome_tem_variacao e exatamente qtd_nomes_conhecidos maior que um',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(nome_tem_variacao <> (qtd_nomes_conhecidos > 1))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  SELECT 'rfn_cadastro__cliente.cadastro_duplicado_decompoe', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'VALIDADE',
         'multiplos_cadastros_no_iclips e exatamente qtd_ids_iclips maior que um',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(multiplos_cadastros_no_iclips <> (qtd_ids_iclips > 1))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`

  UNION ALL
  SELECT 'rfn_cadastro__cliente.janela_nao_inverte', 'Refined',
         'rfn_cadastro__cliente', 'iClips', 'VALIDADE',
         'a ultima atividade nunca e anterior a primeira', 'BLOQUEANTE', 1.00,
         COUNTIF(primeira_atividade_em IS NOT NULL AND ultima_atividade_em IS NOT NULL),
         COUNTIF(ultima_atividade_em < primeira_atividade_em)
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`
),

-- ─────────────────────────────── rfn_cadastro__conta (7) ─────────────────────────────
r_conta AS (
  SELECT 'rfn_cadastro__conta.id_conta_unico' AS id_regra, 'Refined' AS camada,
         'rfn_cadastro__conta' AS tabela, 'Midia' AS sistema, 'UNICIDADE' AS dimensao,
         'id_conta e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_conta) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`

  UNION ALL
  SELECT 'rfn_cadastro__conta.chave_e_plataforma_mais_id', 'Refined',
         'rfn_cadastro__conta', 'Midia', 'INTEGRIDADE',
         'id_conta e plataforma mais o id da conta na plataforma', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(id_conta <> CONCAT(plataforma, ':', id_conta_plataforma)
                 OR NULLIF(TRIM(id_conta_plataforma), '') IS NULL)
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`

  UNION ALL
  SELECT 'rfn_cadastro__conta.plataforma_conhecida', 'Refined',
         'rfn_cadastro__conta', 'Midia', 'VALIDADE',
         'plataforma e GOOGLE_ADS ou FACEBOOK_ADS', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(plataforma IS NULL OR plataforma NOT IN ('GOOGLE_ADS', 'FACEBOOK_ADS'))
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`

  UNION ALL
  -- A REGRA QUE GUARDA A R-003 AQUI. Ver o bloco no cabecalho.
  SELECT 'rfn_cadastro__conta.ambiguidade_nunca_vira_cnpj', 'Refined',
         'rfn_cadastro__conta', 'Midia', 'INTEGRIDADE',
         'conta com nome ambiguo na origem nunca recebe CNPJ', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(cnpj_ambiguo_na_origem AND NULLIF(TRIM(cnpj), '') IS NOT NULL)
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`

  UNION ALL
  SELECT 'rfn_cadastro__conta.cnpj_tem_14_digitos', 'Refined',
         'rfn_cadastro__conta', 'Midia', 'VALIDADE',
         'o CNPJ que existe tem 14 digitos', 'BLOQUEANTE', 1.00,
         COUNTIF(NULLIF(TRIM(cnpj), '') IS NOT NULL),
         COUNTIF(NULLIF(TRIM(cnpj), '') IS NOT NULL
                 AND LENGTH(REGEXP_REPLACE(cnpj, r'[^0-9]', '')) <> 14)
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`

  UNION ALL
  SELECT 'rfn_cadastro__conta.resolvido_por_concorda_com_o_cnpj', 'Refined',
         'rfn_cadastro__conta', 'Midia', 'VALIDADE',
         'cnpj_resolvido_por existe exatamente onde ha CNPJ, e so RAZAO_SOCIAL ou ROTULO_DA_CONTA',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF((NULLIF(TRIM(cnpj_resolvido_por), '') IS NOT NULL)
                   <> (NULLIF(TRIM(cnpj), '') IS NOT NULL)
              OR (NULLIF(TRIM(cnpj_resolvido_por), '') IS NOT NULL
                  AND cnpj_resolvido_por NOT IN ('RAZAO_SOCIAL', 'ROTULO_DA_CONTA')))
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`

  UNION ALL
  SELECT 'rfn_cadastro__conta.identidade_decompoe', 'Refined',
         'rfn_cadastro__conta', 'Midia', 'VALIDADE',
         'identidade_juridica_resolvida e exatamente ter CNPJ', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(identidade_juridica_resolvida <> (NULLIF(TRIM(cnpj), '') IS NOT NULL))
  FROM `vanguardamartech_refined`.`rfn_cadastro__conta`
),

-- ───────────────────────── as duas tabelas intragrupo (6) ────────────────────────────
r_intragrupo AS (
  SELECT 'rfn_cadastro__cliente_vbot.id_cadastro_unico' AS id_regra, 'Refined' AS camada,
         'rfn_cadastro__cliente_vbot' AS tabela, 'Intragrupo' AS sistema,
         'UNICIDADE' AS dimensao, 'id_cadastro e unico' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_cadastro) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vbot`

  UNION ALL
  -- O QUE DEFINE A TABELA. Ver o bloco no cabecalho.
  SELECT 'rfn_cadastro__cliente_vbot.cnpj_e_o_da_empresa', 'Refined',
         'rfn_cadastro__cliente_vbot', 'Intragrupo', 'INTEGRIDADE',
         'todo cadastro carrega o CNPJ 61.077.352/0001-30', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', '') <> '61077352000130')
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vbot`

  UNION ALL
  SELECT 'rfn_cadastro__cliente_vbot.chave_declara_o_sistema', 'Refined',
         'rfn_cadastro__cliente_vbot', 'Intragrupo', 'INTEGRIDADE',
         'id_cadastro comeca pelo sistema da linha', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NOT STARTS_WITH(id_cadastro, CONCAT(sistema, ':')))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vbot`

  UNION ALL
  SELECT 'rfn_cadastro__cliente_vanguarda_comunicacao.id_cadastro_unico', 'Refined',
         'rfn_cadastro__cliente_vanguarda_comunicacao', 'Intragrupo', 'UNICIDADE',
         'id_cadastro e unico', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT id_cadastro)
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vanguarda_comunicacao`

  UNION ALL
  SELECT 'rfn_cadastro__cliente_vanguarda_comunicacao.cnpj_e_o_da_empresa', 'Refined',
         'rfn_cadastro__cliente_vanguarda_comunicacao', 'Intragrupo', 'INTEGRIDADE',
         'todo cadastro carrega o CNPJ 07.865.616/0001-74', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(REGEXP_REPLACE(IFNULL(cnpj, ''), r'[^0-9]', '') <> '07865616000174')
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vanguarda_comunicacao`

  UNION ALL
  SELECT 'rfn_cadastro__cliente_vanguarda_comunicacao.chave_declara_o_sistema', 'Refined',
         'rfn_cadastro__cliente_vanguarda_comunicacao', 'Intragrupo', 'INTEGRIDADE',
         'id_cadastro comeca pelo sistema da linha', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NOT STARTS_WITH(id_cadastro, CONCAT(sistema, ':')))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vanguarda_comunicacao`
),

-- ───────────────── rfn_financeiro__receita_cliente_mensal (12) ───────────────────────
r_receita AS (
  SELECT 'rfn_financeiro__receita_cliente_mensal.id_receita_mensal_unico' AS id_regra,
         'Refined' AS camada, 'rfn_financeiro__receita_cliente_mensal' AS tabela,
         'VJOB' AS sistema, 'UNICIDADE' AS dimensao,
         'id_receita_mensal e unico' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_receita_mensal) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.grao_cliente_competencia', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'UNICIDADE',
         'o par cliente e competencia e unico', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNT(*) - COUNT(DISTINCT CONCAT(CAST(id_cliente AS STRING), '|',
                                          CAST(competencia AS STRING)))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  -- A SEXTA IDENTIDADE DESTA CASA. Ver o bloco no cabecalho.
  SELECT 'rfn_financeiro__receita_cliente_mensal.honorario_mais_repasse_e_o_total', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'honorario mais repasse reproduz o valor total dentro de um centavo',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(ABS(IFNULL(valor_honorario, 0) + IFNULL(valor_repasse, 0)
                     - IFNULL(valor_total, 0)) > 0.01)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.cliente_sem_registro_nao_recebe_taxa', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'cliente sem nenhuma conclusao tem taxa NULL, nunca zero', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(is_cliente_sem_registro AND taxa_conclusao IS NOT NULL)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.toda_linha_tem_um_lado', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'INTEGRIDADE',
         'toda linha tem receita ou escopo -- o FULL OUTER nao inventa linha',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(NOT tem_receita AND NOT tem_escopo)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.concluido_nunca_excede_planejado', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'o escopo concluido nunca passa do planejado', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_escopo_concluido > qtd_escopo_planejado)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.carimbo_nunca_excede_concluido', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'o escopo com carimbo nunca passa do concluido', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_escopo_com_carimbo > qtd_escopo_concluido)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.nfse_nunca_excede_parcela', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'a parcela com NFSe nunca passa do total de parcelas', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_parcelas_com_nfse > qtd_parcelas)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  -- Guarda a familia DATE(MAX(ano), MAX(mes), 1). Ver o bloco no cabecalho.
  SELECT 'rfn_financeiro__receita_cliente_mensal.competencia_e_o_primeiro_dia', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'competencia e exatamente o primeiro dia do proprio ano e mes',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(competencia <> DATE(ano, mes, 1))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  -- O REFERENCIAL E A DATA DA CARGA, NAO O RELOGIO -- e isso foi corrigido em 01/10/2026,
  -- no dia em que a regra falhou. Escrita com `CURRENT_DATE`, ela acusou 224 de 7.451 em
  -- 01/10: sao exatamente as 224 linhas de competencia 2026-10, marcadas como futuras
  -- quando a tabela foi escrita (27/09) e deixando de ser futuras quando o mes virou. O
  -- DADO ESTAVA CERTO E A REGRA ESTAVA ERRADA -- contra `DATE(_extraido_at)` sao ZERO
  -- falhas. A tabela e SEMANAL (cadeia do VJOB, domingo), entao entre uma carga e a
  -- seguinte o relogio anda e a flag nao: comparar as duas coisas fabrica falha toda
  -- virada de mes.
  --   A DISTINCAO QUE IMPORTA, e ela separa esta regra das outras sete desta casa que
  --   citam o relogio: regra que afirma que o DADO nunca e futuro (`data > CURRENT_DATE`)
  --   e SEGURA, porque o tempo passando so a faz passar mais. Regra que compara uma FLAG
  --   GRAVADA contra o relogio nao e, porque a flag congela na carga e o relogio nao para.
  --   Era o mesmo motivo pelo qual `flag_mes_futuro`, `flag_inicio_futuro` e
  --   `flag_ocorrencia_futura` ficaram DE FORA das suites de VBOT, iClips e recorrencia --
  --   o criterio ja existia e esta regra, de 29/09, e anterior a ele.
  SELECT 'rfn_financeiro__receita_cliente_mensal.futura_decompoe', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'is_competencia_futura e exatamente competencia depois do mes DA CARGA',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(is_competencia_futura
                 <> (competencia > DATE_TRUNC(DATE(_extraido_at), MONTH)))
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  SELECT 'rfn_financeiro__receita_cliente_mensal.valor_nao_negativo', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'VALIDADE',
         'nenhum valor e negativo', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(valor_total < 0 OR valor_honorario < 0 OR valor_repasse < 0
                 OR valor_com_nfse < 0)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`

  UNION ALL
  -- LINHA DE BASE, limiar 0,70 contra 76,2%. Ver o bloco no cabecalho.
  SELECT 'rfn_financeiro__receita_cliente_mensal.cliente_catalogado', 'Refined',
         'rfn_financeiro__receita_cliente_mensal', 'VJOB', 'INTEGRIDADE',
         'o cliente da linha existe no cadastro do VJOB', 'ALERTA', 0.70,
         COUNT(*),
         COUNTIF(flag_cliente_nao_catalogado)
  FROM `vanguardamartech_refined`.`rfn_financeiro__receita_cliente_mensal`
),

-- ───────────────────────────── rfn_cliente__contexto (10) ───────────────────────────
-- ACRESCENTADA EM 01/10/2026, E ELA DESMENTE UMA AFIRMACAO MINHA DE 30/09.
--   Em 30/09 eu escrevi que "nao sobra tabela materializada sem regra nesta base". ERA
--   FALSO. Um inventario cruzando as 152 transformacoes ativas da Nekt contra o
--   repositorio achou DUAS Refined materializadas com ZERO regra: a
--   `rfn_midia__termo_busca_mensal` (1.368.269 linhas, a MAIOR Refined da casa, agora na
--   suite query-XAmt) e esta, `rfn_cliente__contexto` (410 linhas, de 25/09). As duas
--   existem no deploy E no repositorio; o que faltava era o REGISTRO, e com ele a
--   cobertura. Cobertura se confere cruzando a plataforma contra o repositorio, nunca
--   pela memoria do que foi escrito.
--
-- ELA ESTA NESTA SUITE PORQUE E O MESMO DOMINIO -- a tabela le `rfn_cadastro__cliente` e
--   `rfn_cadastro__conta`, as duas ja medidas aqui. Como `conta` e `receita`, ela NAO
--   esta no gatilho e e medida COMO ESTIVER MATERIALIZADA; na pratica roda um minuto
--   antes (01/10: contexto 07:08:30, suite 07:09). As regras abaixo sao todas
--   invariantes no tempo -- a unica que depende de data usa `DATE(_extraido_at)`.
--
-- O QUE E ESTA TABELA: o PONTO DE ENTRADA deterministico de contexto de cliente para
--   aplicacao conectada na Nekt. A camada semantica e busca vetorial e devolve o
--   documento que PARECE relevante; esta tabela devolve o REGISTRO certo por chave.
r_contexto AS (
  SELECT 'rfn_cliente__contexto.id_cliente_unico' AS id_regra, 'Refined' AS camada,
         'rfn_cliente__contexto' AS tabela, 'iClips' AS sistema, 'UNICIDADE' AS dimensao,
         'id_cliente e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade,
         1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNT(*) - COUNT(DISTINCT id_cliente) + COUNTIF(id_cliente IS NULL) AS linhas_falha
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  -- Mesma chave com fallback da `rfn_cadastro__cliente`, de onde esta tabela herda a
  -- identidade: `CNPJ:<digitos>` ou `ICLIPS:<id>`, com `chave_por` declarando qual valeu.
  -- Se a chave deixar de concordar com o metodo, o mesmo cliente pode aparecer em duas
  -- linhas -- uma por CNPJ e outra por id -- e o lookup deterministico devolve a errada.
  SELECT 'rfn_cliente__contexto.chave_concorda_com_o_metodo', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'INTEGRIDADE',
         'a chave e CNPJ mais digitos ou ICLIPS mais id, conforme chave_por declara',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(chave_por IS NULL OR chave_por NOT IN ('CNPJ', 'ID_ICLIPS')
              OR (chave_por = 'CNPJ' AND id_cliente <> CONCAT('CNPJ:', IFNULL(cnpj, '')))
              OR (chave_por = 'ID_ICLIPS' AND NOT STARTS_WITH(id_cliente, 'ICLIPS:')))
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  -- A REGRA 3 daquela tabela: `classe` separa terceiro de casa propria SEM apagar nenhum
  -- dos dois, e a aplicacao que faz relatorio de cliente filtra TERCEIRO. Classe nova
  -- cairia fora de TODO filtro existente sem a contagem de linhas mudar.
  SELECT 'rfn_cliente__contexto.classe_conhecida', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'classe e TERCEIRO, INTRAGRUPO ou TESTE', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(classe IS NULL OR classe NOT IN ('TERCEIRO', 'INTRAGRUPO', 'TESTE'))
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  SELECT 'rfn_cliente__contexto.documento_tem_forma', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'o documento que existe tem 14 digitos (CNPJ) ou 11 (CPF), sem pontuacao',
         'BLOQUEANTE', 1.00,
         COUNTIF(cnpj IS NOT NULL),
         COUNTIF(cnpj IS NOT NULL
                 AND (LENGTH(cnpj) NOT IN (14, 11) OR REGEXP_CONTAINS(cnpj, r'[^0-9]')))
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  SELECT 'rfn_cliente__contexto.flags_de_cadastro_decompoem', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'identidade, variacao de nome e cadastro duplicado concordam com as contagens, e o nome nunca falta',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(identidade_juridica_resolvida <> (cnpj IS NOT NULL)
              OR nome_tem_variacao <> (qtd_nomes_conhecidos > 1)
              OR multiplos_cadastros_no_iclips <> (qtd_ids_iclips > 1)
              OR NULLIF(TRIM(cliente_nome), '') IS NULL)
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  SELECT 'rfn_cliente__contexto.midia_decompoe', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'tem_conta_de_midia e exatamente ter conta, e a plataforma nunca passa da conta',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tem_conta_de_midia <> (qtd_contas_midia > 0)
              OR qtd_plataformas_midia > qtd_contas_midia)
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  -- A LIMITACAO 2 daquela tabela vira teste. Ate 02/10/2026 o historico de PI entrava so por
  -- ROTULO e a regra exigia `pi_vinculado_por = 'ROTULO'`. A tabela foi reescrita em
  -- 02/10 (query-2k3p): o PI entra por DOCUMENTO e, so sem documento, por ROTULO unico, e o
  -- vinculo declarado passa a ser DOCUMENTO, ROTULO ou DOCUMENTO+ROTULO. A regra aceita os
  -- tres e continua exigindo que a ressalva esteja visivel na linha: `pi_vinculado_por`
  -- existe para que ninguem leia a contagem como prova. Aceita tambem o valor antigo, de
  -- proposito -- a tabela e a suite rodam em ordem nao garantida e nenhuma das duas deve
  -- quebrar a outra. DIVIDA DATADA: depois da primeira carga nova, acrescentar a regra
  -- `qtd_pis = qtd_pis_por_documento + qtd_pis_por_rotulo`; as colunas ainda nao existem
  -- na tabela materializada e referencia-las agora derrubaria a suite inteira.
  SELECT 'rfn_cliente__contexto.pi_decompoe_e_o_vinculo_e_declarado', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'tem_pi e exatamente ter PI, o vigente nunca passa do total, e o vinculo declarado e DOCUMENTO, ROTULO ou DOCUMENTO+ROTULO',
         'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(tem_pi <> (qtd_pis > 0)
              OR qtd_pis_vigentes > qtd_pis
              OR (NULLIF(pi_vinculado_por, '') IS NOT NULL) <> tem_pi
              OR (tem_pi AND pi_vinculado_por NOT IN ('DOCUMENTO', 'ROTULO', 'DOCUMENTO+ROTULO')))
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  -- O REFERENCIAL E A DATA DA CARGA, NAO O RELOGIO -- escrita hoje ja com o criterio que
  -- a `futura_decompoe` custou para formular, nesta mesma suite e nesta mesma manha.
  -- `dias_sem_atividade` e calculado na carga e congela ali; o relogio nao para. Contra
  -- `CURRENT_DATE` esta regra falharia em toda linha no dia seguinte a cada carga.
  SELECT 'rfn_cliente__contexto.dias_sem_atividade_conta_da_carga', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'dias_sem_atividade e a distancia da ultima atividade ate a DATA DA CARGA',
         'BLOQUEANTE', 1.00,
         COUNTIF(ultima_atividade IS NOT NULL),
         COUNTIF(ultima_atividade IS NOT NULL
                 AND IFNULL(dias_sem_atividade, -1)
                     <> DATE_DIFF(DATE(_extraido_at), ultima_atividade, DAY))
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  SELECT 'rfn_cliente__contexto.janela_nao_inverte', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'a ultima atividade nunca e anterior a primeira', 'BLOQUEANTE', 1.00,
         COUNTIF(primeira_atividade IS NOT NULL AND ultima_atividade IS NOT NULL),
         COUNTIF(ultima_atividade < primeira_atividade)
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`

  UNION ALL
  SELECT 'rfn_cliente__contexto.metrica_nao_negativa', 'Refined',
         'rfn_cliente__contexto', 'iClips', 'VALIDADE',
         'projeto, peca, PI, conta e valor nunca sao negativos', 'BLOQUEANTE', 1.00,
         COUNT(*),
         COUNTIF(qtd_projetos < 0 OR qtd_pecas < 0 OR qtd_pis < 0 OR qtd_pis_vigentes < 0
              OR qtd_contas_midia < 0 OR qtd_nomes_conhecidos < 1 OR qtd_ids_iclips < 0
              OR valor_pi_vigente < 0 OR qtd_tipos_midia_off < 0)
  FROM `vanguardamartech_refined`.`rfn_cliente__contexto`
),

-- ─────────────────── frescor com escopo de FONTE, nao de familia (1) ─────────────────
carga AS (
  SELECT 'cliente' AS t, MAX(DATE(_extraido_at)) AS d
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente`
  UNION ALL SELECT 'vbot', MAX(DATE(_extraido_at))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vbot`
  UNION ALL SELECT 'vanguarda_comunicacao', MAX(DATE(_extraido_at))
  FROM `vanguardamartech_refined`.`rfn_cadastro__cliente_vanguarda_comunicacao`
),
r_frescor AS (
  SELECT 'cadastro.carga_do_mesmo_dia' AS id_regra, 'Refined' AS camada,
         '(as 3 tabelas do gatilho)' AS tabela, 'iClips' AS sistema,
         'VALIDADE' AS dimensao,
         'as 3 tabelas que disparam a suite foram escritas na mesma passada' AS regra,
         'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas,
         COUNTIF(d <> (SELECT MAX(d) FROM carga)) AS linhas_falha
  FROM carga
),

todas AS (
  SELECT * FROM r_cliente
  UNION ALL SELECT * FROM r_conta
  UNION ALL SELECT * FROM r_intragrupo
  UNION ALL SELECT * FROM r_receita
  UNION ALL SELECT * FROM r_contexto
  UNION ALL SELECT * FROM r_frescor
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
  'Cadastro'                                    AS familia,
  CURRENT_TIMESTAMP()                           AS _extraido_at,
  'multiplas'                                   AS _fonte,
  'America/Sao_Paulo'                           AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a)))                AS _payload_hash
FROM avaliado a
