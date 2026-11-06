-- rfn_qualidade__regra_vjob_cauda (query-Y7xG) · 25 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Gatilho: evento em query-c1x0 (ultimo elo da cadeia de job do VJOB). Alerta ligado. Cadencia SEMANAL (mysql-yIOn, domingo).
-- Cobre as 10 Trusted da cauda do mysql-yIOn publicadas em 02/10 e materializadas em 04/10 (carga 04:53): dominio, biblioteca_item, anexo_diverso, intranet_conteudo, intranet_leitura, compromisso, config_cliente, escopo_link_publico, escopo_data_extra, evento_sistema.
-- Medido em 04/10 sobre as tabelas materializadas: 23 regras com zero falha e DUAS linhas de base (leitura.usuario_catalogado 35 de 118, dominio.pai_catalogado 155 de 194).
-- Frescor com escopo de FONTE: as 10 vem da mesma fonte e disparam em paralelo em query-MZdN, entao a regra de carga_do_mesmo_dia garante que o gatilho fundo mediu a passada inteira.
WITH t_dom AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__dominio`),
t_bib AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__biblioteca_item`),
t_anx AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__anexo_diverso`),
t_con AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__intranet_conteudo`),
t_lei AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__intranet_leitura`),
t_cmp AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__compromisso`),
t_cfg AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__config_cliente`),
t_lnk AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__escopo_link_publico`),
t_dex AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__escopo_data_extra`),
t_evt AS (SELECT * FROM `vanguardamartech_trusted`.`trs_vjob__evento_sistema`),
cargas AS (
  SELECT 'dominio' AS tab, MAX(DATE(_extraido_at)) AS d FROM t_dom UNION ALL
  SELECT 'biblioteca_item', MAX(DATE(_extraido_at)) FROM t_bib UNION ALL
  SELECT 'anexo_diverso', MAX(DATE(_extraido_at)) FROM t_anx UNION ALL
  SELECT 'intranet_conteudo', MAX(DATE(_extraido_at)) FROM t_con UNION ALL
  SELECT 'intranet_leitura', MAX(DATE(_extraido_at)) FROM t_lei UNION ALL
  SELECT 'compromisso', MAX(DATE(_extraido_at)) FROM t_cmp UNION ALL
  SELECT 'config_cliente', MAX(DATE(_extraido_at)) FROM t_cfg UNION ALL
  SELECT 'escopo_link_publico', MAX(DATE(_extraido_at)) FROM t_lnk UNION ALL
  SELECT 'escopo_data_extra', MAX(DATE(_extraido_at)) FROM t_dex UNION ALL
  SELECT 'evento_sistema', MAX(DATE(_extraido_at)) FROM t_evt
),
r AS (
  -- UNICIDADE. Cada tabela-fonte tem a sua sequencia de id, entao a chave e composta (origem, id) e id cru nao basta.
  SELECT 'trs_vjob__dominio.chave_unica' AS id_regra, 'Trusted' AS camada, 'trs_vjob__dominio' AS tabela, 'VJOB' AS sistema, 'UNICIDADE' AS dimensao,
         '(tabela_origem, id_origem) e unica' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT CONCAT(tabela_origem, ':', CAST(id_origem AS STRING))) AS linhas_falha FROM t_dom
  UNION ALL SELECT 'trs_vjob__biblioteca_item.chave_unica', 'Trusted', 'trs_vjob__biblioteca_item', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_bib
  UNION ALL SELECT 'trs_vjob__anexo_diverso.chave_unica', 'Trusted', 'trs_vjob__anexo_diverso', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_anx
  UNION ALL SELECT 'trs_vjob__intranet_conteudo.chave_unica', 'Trusted', 'trs_vjob__intranet_conteudo', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_con
  UNION ALL SELECT 'trs_vjob__intranet_leitura.chave_unica', 'Trusted', 'trs_vjob__intranet_leitura', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_lei
  UNION ALL SELECT 'trs_vjob__compromisso.chave_unica', 'Trusted', 'trs_vjob__compromisso', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_cmp
  UNION ALL SELECT 'trs_vjob__config_cliente.chave_unica', 'Trusted', 'trs_vjob__config_cliente', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_cfg
  UNION ALL SELECT 'trs_vjob__escopo_link_publico.id_unico', 'Trusted', 'trs_vjob__escopo_link_publico', 'VJOB', 'UNICIDADE', 'id_link e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_link) FROM t_lnk
  UNION ALL SELECT 'trs_vjob__escopo_data_extra.id_unico', 'Trusted', 'trs_vjob__escopo_data_extra', 'VJOB', 'UNICIDADE', 'id_data_extra e unico', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT id_data_extra) FROM t_dex
  UNION ALL SELECT 'trs_vjob__evento_sistema.chave_unica', 'Trusted', 'trs_vjob__evento_sistema', 'VJOB', 'UNICIDADE', '(origem, id_origem) e unica', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNT(*) - COUNT(DISTINCT CONCAT(origem, ':', CAST(id_origem AS STRING))) FROM t_evt
  -- VALIDADE. Cada flag so vale se reproduz a coluna de que deriva; se soltar, o caso some da leitura sem a contagem mudar.
  UNION ALL SELECT 'trs_vjob__escopo_link_publico.sem_expiracao_concorda', 'Trusted', 'trs_vjob__escopo_link_publico', 'VJOB', 'VALIDADE',
         'flag_sem_expiracao e verdadeira exatamente quando expira_em e nulo (29 links sem expiracao na medicao de 02/10)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_expiracao <> (expira_em IS NULL)) FROM t_lnk
  UNION ALL SELECT 'trs_vjob__escopo_link_publico.vigente_nunca_expirado', 'Trusted', 'trs_vjob__escopo_link_publico', 'VJOB', 'VALIDADE',
         'link vigente na carga nunca esta expirado nem inativo (40 vigentes na medicao)', 'BLOQUEANTE', 1.00,
         COUNTIF(flag_vigente_na_carga), COUNTIF(flag_vigente_na_carga AND (flag_expirado_na_carga OR NOT ativo)) FROM t_lnk
  UNION ALL SELECT 'trs_vjob__evento_sistema.telefone_forma_concorda', 'Trusted', 'trs_vjob__evento_sistema', 'VJOB', 'VALIDADE',
         'flag_telefone_fora_de_forma e verdadeira exatamente quando o telefone existe e nao tem 12 ou 13 digitos', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_telefone_fora_de_forma <> (telefone_digitos IS NOT NULL AND LENGTH(telefone_digitos) NOT IN (12, 13))) FROM t_evt
  UNION ALL SELECT 'trs_vjob__compromisso.fim_antes_concorda', 'Trusted', 'trs_vjob__compromisso', 'VJOB', 'VALIDADE',
         'flag_fim_antes_do_inicio reproduz a comparacao entre fim e inicio, onde os dois existem', 'BLOQUEANTE', 1.00,
         COUNTIF(inicio IS NOT NULL AND fim IS NOT NULL), COUNTIF(inicio IS NOT NULL AND fim IS NOT NULL AND flag_fim_antes_do_inicio <> (fim < inicio)) FROM t_cmp
  UNION ALL SELECT 'trs_vjob__escopo_data_extra.links_iguais_concorda', 'Trusted', 'trs_vjob__escopo_data_extra', 'VJOB', 'VALIDADE',
         'flag_links_iguais reproduz a igualdade entre link_iclip e link_evidencia', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(IFNULL(flag_links_iguais, FALSE) <> IFNULL(link_iclip = link_evidencia, FALSE)) FROM t_dex
  UNION ALL SELECT 'trs_vjob__anexo_diverso.categoria_preenchida', 'Trusted', 'trs_vjob__anexo_diverso', 'VJOB', 'COMPLETUDE',
         'todo anexo tem categoria_arquivo (MIME, ou extensao quando o MIME e malformado ou generico)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(categoria_arquivo IS NULL) FROM t_anx
  UNION ALL SELECT 'trs_vjob__dominio.sem_nome_concorda', 'Trusted', 'trs_vjob__dominio', 'VJOB', 'VALIDADE',
         'flag_sem_nome e verdadeira exatamente quando nome e nulo', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_sem_nome <> (nome IS NULL)) FROM t_dom
  -- INTEGRIDADE. As zero-falha guardam o pai que hoje resolve; as duas LINHAS DE BASE existem para detectar PIORA.
  UNION ALL SELECT 'trs_vjob__config_cliente.conta_catalogada', 'Trusted', 'trs_vjob__config_cliente', 'VJOB', 'INTEGRIDADE',
         'toda configuracao aponta para conta de atendimento que existe (163 de 163 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada) FROM t_cfg
  UNION ALL SELECT 'trs_vjob__escopo_data_extra.escopo_catalogado', 'Trusted', 'trs_vjob__escopo_data_extra', 'VJOB', 'INTEGRIDADE',
         'toda data extra aponta para linha de escopo que existe (7 de 7 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_escopo_nao_catalogado) FROM t_dex
  UNION ALL SELECT 'trs_vjob__escopo_link_publico.conta_catalogada', 'Trusted', 'trs_vjob__escopo_link_publico', 'VJOB', 'INTEGRIDADE',
         'todo link publico aponta para conta de atendimento que existe (70 de 70 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(flag_conta_nao_catalogada) FROM t_lnk
  UNION ALL SELECT 'trs_vjob__compromisso.conta_catalogada', 'Trusted', 'trs_vjob__compromisso', 'VJOB', 'INTEGRIDADE',
         'compromisso com conta aponta para conta que existe (28 de 28 na medicao)', 'BLOQUEANTE', 1.00,
         COUNTIF(id_conta_atendimento IS NOT NULL), COUNTIF(flag_conta_nao_catalogada) FROM t_cmp
  UNION ALL SELECT 'trs_vjob__intranet_leitura.conteudo_catalogado', 'Trusted', 'trs_vjob__intranet_leitura', 'VJOB', 'INTEGRIDADE',
         'leitura com conteudo resolvido aponta para conteudo que existe (28 de 28 na medicao)', 'BLOQUEANTE', 1.00,
         COUNTIF(flag_conteudo_nao_catalogado IS NOT NULL), COUNTIF(flag_conteudo_nao_catalogado) FROM t_lei
  -- LINHA DE BASE. 83 das 118 leituras apontam para usuario fora do cadastro (leitura por nome cobre 30%); e da origem, a regra detecta piora.
  UNION ALL SELECT 'trs_vjob__intranet_leitura.usuario_catalogado', 'Trusted', 'trs_vjob__intranet_leitura', 'VJOB', 'INTEGRIDADE',
         'leitura aponta para usuario que existe no cadastro (35 de 118 na medicao)', 'ALERTA', 0.25,
         COUNT(*), COUNTIF(flag_usuario_nao_catalogado) FROM t_lei
  -- LINHA DE BASE. 39 dos 194 itens com pai apontam para pai fora do dominio (80% resolvem).
  UNION ALL SELECT 'trs_vjob__dominio.pai_catalogado', 'Trusted', 'trs_vjob__dominio', 'VJOB', 'INTEGRIDADE',
         'item de dominio com pai aponta para pai que existe (155 de 194 na medicao)', 'ALERTA', 0.75,
         COUNTIF(id_pai IS NOT NULL), COUNTIF(flag_pai_nao_catalogado) FROM t_dom
  -- FRESCOR com escopo de fonte: as 10 tabelas saem da mesma passada do mysql-yIOn; uma na carga anterior quer dizer que um ramo nao rodou.
  UNION ALL SELECT 'vjob_cauda.carga_do_mesmo_dia', 'Trusted', 'trs_vjob__* (10 da cauda)', 'VJOB', 'FRESCOR',
         'as 10 Trusted da cauda tem a mesma data de carga (todas 2026-10-04 na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(d < (SELECT MAX(d) FROM cargas)) FROM cargas
),
avaliado AS (
  SELECT r.*, (r.linhas_avaliadas - r.linhas_falha) AS linhas_conformes,
    SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, NULLIF(r.linhas_avaliadas, 0)) AS taxa_conformidade,
    IF(r.linhas_avaliadas = 0, NULL, SAFE_DIVIDE(r.linhas_avaliadas - r.linhas_falha, r.linhas_avaliadas) >= r.limiar) AS is_conforme,
    (r.linhas_avaliadas = 0) AS flag_sem_linha_para_avaliar
  FROM r
)
SELECT a.*,
  CASE WHEN a.flag_sem_linha_para_avaliar THEN 'SEM_DADO' WHEN a.is_conforme THEN 'CONFORME'
       WHEN a.severidade = 'BLOQUEANTE' THEN 'FALHA_BLOQUEANTE' ELSE 'FALHA_ALERTA' END AS resultado,
  'VJOB_CAUDA' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
