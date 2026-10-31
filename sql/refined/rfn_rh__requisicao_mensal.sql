-- rfn_rh__requisicao_mensal  ·  Refined / rh (recrutamento, Quickin)  ·  L2 INTERNAL
-- Grao: mes de criacao x status x departamento da requisicao de vaga (pedido interno de contratacao).
-- Le: trs_quickin__requisicao (query-xP98, L3). Gatilho: evento em query-xP98. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 268 requisicoes = 268 · 120 linhas, 120 chaves · 278 posicoes ·
--   160 com remuneracao informada · 322 versoes · 432 seguidores · 90 analyzing + 178 archived · 14 departamentos · 2024-11 a 2026-10.
-- R1 A REMUNERACAO NAO ATRAVESSA: 95 das 120 linhas tem 1 ou 2 requisicoes, entao qualquer soma ou media por grupo revelaria a
--    faixa pedida de uma vaga especifica. Sai so qtd_com_remuneracao; o valor fica na Trusted (L3). Gestor contratante (nome) sai
--    so como contagem distinta.
-- R2 qtd_com_vaga_vinculada e ZERO em todas as linhas e e fato medido: o campo job e nulo nas 268 e nenhuma requisicao resolve
--    contra a vaga (ver Trusted). Nao e ausencia de dado da Refined, e ausencia de ponte na origem.
-- R3 status, departamento NULL virariam '(sem status)'/'(sem departamento)' (nao ha hoje).
-- LIMITACAO -- NAO CONTORNE: 'analyzing' (90) e o estado da ultima leitura, nao fila viva (o fluxo de aprovacao deixou de ser
--   usado). Titulo e descricao (texto livre) nao entram.
WITH r AS (SELECT * FROM `vanguardamartech_trusted`.`trs_quickin__requisicao`),
agg AS (
  SELECT
    DATE_TRUNC(DATE(criada_em), MONTH) AS mes_criacao,
    IFNULL(status, '(sem status)') AS status,
    IFNULL(departamento, '(sem departamento)') AS departamento,
    COUNT(*) AS qtd_requisicoes,
    SUM(qtd_posicoes) AS qtd_posicoes,
    COUNTIF(remuneracao IS NOT NULL) AS qtd_com_remuneracao,
    COUNTIF(remuneracao_max IS NOT NULL) AS qtd_com_remuneracao_max,
    COUNT(DISTINCT gestor_contratante) AS qtd_gestores_distintos,
    COUNT(DISTINCT id_responsavel) AS qtd_responsaveis_distintos,
    COUNT(DISTINCT tipo_contrato) AS qtd_tipos_contrato,
    COUNT(DISTINCT nivel_experiencia) AS qtd_niveis_experiencia,
    COUNT(DISTINCT categoria_posicao) AS qtd_categorias_posicao,
    COUNT(DISTINCT tipo_local_trabalho) AS qtd_locais_trabalho,
    COUNTIF(tem_vaga_vinculada) AS qtd_com_vaga_vinculada,
    SUM(qtd_seguidores) AS soma_seguidores,
    SUM(qtd_versoes) AS soma_versoes,
    MAX(atualizada_na_origem_em) AS ultima_atualizacao_na_origem_em,
    MAX(versao_lida_em) AS versao_lida_em
  FROM r
  GROUP BY 1, 2, 3
),
final AS (
  SELECT CONCAT(FORMAT_DATE('%Y-%m', mes_criacao), '|', status, '|', departamento) AS id_requisicao_mensal,
         a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
