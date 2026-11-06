-- rfn_rh__organograma_resumo  ·  Refined / rh  ·  L2 INTERNAL
-- Grao: diretoria x area do organograma da empresa, com os cargos mapeados a cada setor.
-- Le: trs_qulture__organograma (query-pvTG, L2): origem ORGANOGRAMA (50 setores) e origem CARGO_SETOR (37 cargos), unidas pelo
--   setor em maiusculas. Gatilho: evento em query-pvTG. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 50 setores = 50 (50 nomes distintos em maiusculas, join 1:1) · 37 cargos
--   mapeados = 37 · 5 linhas, 5 chaves · 18 departamentos · zero cargo com setor fora do organograma.
-- R1 FULL OUTER JOIN: cargo cujo setor nao exista no organograma cairia na linha '(setor fora do organograma)' em vez de sumir
--    (hoje nenhum). qtd_cargos_mapeados e NULL quando nenhum setor do grupo tem cargo (nao ha hoje).
-- R2 Nenhuma pessoa entra: e estrutura (setor, departamento, diretoria, area, cargo). Nome de setor/cargo nao atravessa.
-- R3 A area 'Operação' aparece sob duas diretorias ('Operação' e 'Técnica'): a chave e diretoria|area, nao area.
-- LIMITACAO -- NAO CONTORNE: cadastro mantido a mao pelo RH, parado em 16/06/2026; cargo novo depois disso nao esta no mapa.
--   O mapa cobre 67% dos cargos da planilha de RH (135 de 202). Vinculo cargo -> setor e o cadastrado, nao onde a pessoa esta hoje.
WITH o AS (SELECT * FROM `vanguardamartech_trusted`.`trs_qulture__organograma` WHERE origem = 'ORGANOGRAMA'),
c AS (SELECT * FROM `vanguardamartech_trusted`.`trs_qulture__organograma` WHERE origem = 'CARGO_SETOR'),
cs AS (SELECT UPPER(TRIM(setor)) AS setor_chave, COUNT(*) AS qtd_cargos, COUNTIF(flag_setor_fora_do_organograma) AS qtd_fora FROM c GROUP BY 1),
base AS (
  SELECT o.id_chave, o.setor, o.departamento, o.diretoria, o.area, o.atualizado_em, cs.qtd_cargos, cs.qtd_fora
  FROM o FULL OUTER JOIN cs ON cs.setor_chave = UPPER(TRIM(o.setor))
),
agg AS (
  SELECT
    CASE WHEN id_chave IS NULL THEN '(setor fora do organograma)' ELSE IFNULL(diretoria, '(sem diretoria)') END AS diretoria,
    CASE WHEN id_chave IS NULL THEN '(setor fora do organograma)' ELSE IFNULL(area, '(sem área)') END AS area,
    COUNT(id_chave) AS qtd_setores,
    COUNT(DISTINCT departamento) AS qtd_departamentos,
    COUNTIF(id_chave IS NOT NULL AND qtd_cargos IS NOT NULL) AS qtd_setores_com_cargo_mapeado,
    COUNTIF(id_chave IS NOT NULL AND qtd_cargos IS NULL) AS qtd_setores_sem_cargo_mapeado,
    IF(COUNTIF(qtd_cargos IS NOT NULL) = 0, NULL, SUM(qtd_cargos)) AS qtd_cargos_mapeados,
    IF(COUNTIF(qtd_fora IS NOT NULL) = 0, NULL, SUM(qtd_fora)) AS qtd_cargos_fora_do_organograma,
    MAX(atualizado_em) AS atualizado_em
  FROM base
  GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(diretoria, '|', area) AS id_organograma_resumo, a.*, 'L2_INTERNAL' AS classificacao_dado FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
