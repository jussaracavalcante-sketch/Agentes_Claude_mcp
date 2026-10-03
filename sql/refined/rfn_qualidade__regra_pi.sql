-- rfn_qualidade__regra_pi (query-OUuy) · 9 regras · L2 INTERNAL
-- Refined / qualidade. Grao: uma REGRA em uma execucao. Gatilho: evento em query-iX2P (trs_pi__insercao). Alerta ligado. Cadencia DIARIA.
-- Paga a divida datada de 01/10: as colunas de projeto do iClips (troca de trs_projetos__projeto para trs_iclips__projeto) materializaram em 02/10.
-- Medido em 02/10 sobre a tabela materializada: 3.348 PIs, 967 com projeto, 966 com documento, 1 divergencia de nome e 1 de documento (PI 22889, R-003).
WITH t AS (SELECT * FROM `vanguardamartech_trusted`.`trs_pi__insercao`),
r AS (
  SELECT 'trs_pi__insercao.id_pi_unico' AS id_regra, 'Trusted' AS camada, 'trs_pi__insercao' AS tabela, 'PI' AS sistema, 'UNICIDADE' AS dimensao,
         'id_pi e unico e nunca nulo' AS regra, 'BLOQUEANTE' AS severidade, 1.00 AS limiar,
         COUNT(*) AS linhas_avaliadas, COUNT(*) - COUNT(DISTINCT id_pi) + COUNTIF(id_pi IS NULL) AS linhas_falha FROM t
  UNION ALL
  SELECT 'trs_pi__insercao.tem_projeto_concorda', 'Trusted', 'trs_pi__insercao', 'PI', 'VALIDADE',
         'tem_projeto_no_iclips concorda com a presenca do nome do projeto do iClips', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(tem_projeto_no_iclips <> (projeto_nome_iclips IS NOT NULL)) FROM t
  UNION ALL
  SELECT 'trs_pi__insercao.sem_projeto_nao_herda_coluna', 'Trusted', 'trs_pi__insercao', 'PI', 'VALIDADE',
         'PI sem projeto no iClips nao carrega documento, status nem flag de divergencia de projeto', 'BLOQUEANTE', 1.00,
         COUNTIF(NOT tem_projeto_no_iclips),
         COUNTIF(NOT tem_projeto_no_iclips AND (projeto_cliente_cnpj IS NOT NULL OR projeto_status IS NOT NULL OR flag_projeto_nome_diverge OR flag_documento_projeto_diverge)) FROM t
  UNION ALL
  SELECT 'trs_pi__insercao.projeto_documento_tem_forma', 'Trusted', 'trs_pi__insercao', 'PI', 'VALIDADE',
         'projeto_cliente_cnpj, quando existe, tem so digitos e 14 (CNPJ) ou 11 (CPF)', 'BLOQUEANTE', 1.00,
         COUNTIF(projeto_cliente_cnpj IS NOT NULL),
         COUNTIF(projeto_cliente_cnpj IS NOT NULL AND (NOT REGEXP_CONTAINS(projeto_cliente_cnpj, r'^\d+$') OR LENGTH(projeto_cliente_cnpj) NOT IN (11, 14))) FROM t
  UNION ALL
  SELECT 'trs_pi__insercao.projeto_is_pf_concorda', 'Trusted', 'trs_pi__insercao', 'PI', 'VALIDADE',
         'projeto_cliente_is_pf e verdadeiro exatamente quando o documento tem 11 digitos', 'BLOQUEANTE', 1.00,
         COUNTIF(projeto_cliente_cnpj IS NOT NULL),
         COUNTIF(projeto_cliente_cnpj IS NOT NULL AND projeto_cliente_is_pf <> (LENGTH(projeto_cliente_cnpj) = 11)) FROM t
  UNION ALL
  -- A flag so vale se reproduz a comparacao dos dois documentos; se soltar, a divergencia some sem a contagem mudar.
  SELECT 'trs_pi__insercao.documento_diverge_reproduz_a_comparacao', 'Trusted', 'trs_pi__insercao', 'PI', 'VALIDADE',
         'flag_documento_projeto_diverge reproduz a comparacao entre o documento do projeto e o do monitoramento', 'BLOQUEANTE', 1.00,
         COUNTIF(projeto_cliente_cnpj IS NOT NULL AND cliente_cnpj IS NOT NULL),
         COUNTIF(flag_documento_projeto_diverge <> (projeto_cliente_cnpj IS NOT NULL AND cliente_cnpj IS NOT NULL AND REGEXP_REPLACE(cliente_cnpj, r'\D', '') <> projeto_cliente_cnpj)) FROM t
  UNION ALL
  -- LINHA DE BASE. A divergencia e o caso R-003 (PI 22889, duas empresas CAA) e nao se desempata; a regra existe para detectar PIORA.
  SELECT 'trs_pi__insercao.documento_projeto_nao_diverge', 'Trusted', 'trs_pi__insercao', 'PI', 'INTEGRIDADE',
         'documento do projeto do iClips bate com o do monitoramento (855 de 856 na medicao)', 'ALERTA', 0.995,
         COUNTIF(projeto_cliente_cnpj IS NOT NULL AND cliente_cnpj IS NOT NULL), COUNTIF(flag_documento_projeto_diverge) FROM t
  UNION ALL
  SELECT 'trs_pi__insercao.nome_projeto_nao_diverge', 'Trusted', 'trs_pi__insercao', 'PI', 'INTEGRIDADE',
         'nome do projeto do iClips bate com o nome do PI (966 de 967 na medicao)', 'ALERTA', 0.995,
         COUNTIF(tem_projeto_no_iclips), COUNTIF(flag_projeto_nome_diverge) FROM t
  UNION ALL
  -- LINHA DE BASE DE COBERTURA. 139 dos 238 projetos citados nao existem na trs_iclips__projeto (causa nao verificada); a regra detecta queda, nao cobra o que a origem nao tem.
  SELECT 'trs_pi__insercao.projeto_resolvido_nos_vivos', 'Trusted', 'trs_pi__insercao', 'PI', 'INTEGRIDADE',
         'PIs nao cancelados com projeto resolvido no iClips (906 de 3.120 na medicao)', 'ALERTA', 0.25,
         COUNTIF(NOT is_cancelado), COUNTIF(NOT is_cancelado AND NOT tem_projeto_no_iclips) FROM t
  UNION ALL
  -- VINCULO DE PI NO CONTEXTO DE CLIENTE (divida datada de 02/10, paga em 03/10 depois da primeira carga com as colunas novas).
  -- Cada cliente declara por qual caminho cada PI entrou; se a soma nao fechar, algum PI foi contado sem caminho.
  SELECT 'rfn_cliente__contexto.pis_decompoem_por_caminho', 'Refined', 'rfn_cliente__contexto', 'PI', 'INTEGRIDADE',
         'qtd_pis = qtd_pis_por_documento + qtd_pis_por_rotulo em cada cliente (410 clientes, zero quebras na medicao)', 'BLOQUEANTE', 1.00,
         COUNT(*), COUNTIF(qtd_pis <> qtd_pis_por_documento + qtd_pis_por_rotulo) FROM `vanguardamartech_refined`.`rfn_cliente__contexto`
  UNION ALL
  -- Cada PI cai em no maximo um cliente: a soma de PIs vinculados nunca passa do total da Trusted. Se passar, o PI foi contado em dois clientes
  -- (o defeito de 25 PIs e R$ 308 mil corrigido em 02/10) e a contagem de linhas da Refined nao denuncia.
  SELECT 'rfn_cliente__contexto.pi_nunca_conta_duas_vezes', 'Refined', 'rfn_cliente__contexto', 'PI', 'INTEGRIDADE',
         'soma de qtd_pis nos clientes nao excede o total de PIs da Trusted (3.133 de 3.348 na medicao)', 'BLOQUEANTE', 1.00,
         1, IF((SELECT SUM(qtd_pis) FROM `vanguardamartech_refined`.`rfn_cliente__contexto`) > (SELECT COUNT(*) FROM t), 1, 0) FROM UNNEST([1])
  -- Sem LIMIT: no ultimo ramo de um UNION ALL ele vale para a uniao inteira e deixaria uma unica regra.
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
  'PI' AS familia, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'America/Sao_Paulo' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(a))) AS _payload_hash
FROM avaliado a
