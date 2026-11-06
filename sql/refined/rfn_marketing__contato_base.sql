-- rfn_marketing__contato_base  (query-NdTU)
-- Refined / marketing, L2, gatilho de evento em query-9dz7 (trs_rd_station__contato). Grao: um cliente (conta RD), fotografia da carga.
-- A Trusted tem dois graos: completo (tem_detalhe) e minimo; telefone, localizacao e consentimento so existem no completo,
-- entao as taxas dividem por qtd_com_detalhe. AUTORIZADO = granted e nenhum declined (LGPD).
-- Medido em 06/10/2026: 30 clientes, 110.105 contatos, 98.298 com detalhe = 97.760 autorizados + 282 recusaram + 256 sem registro; 22 clientes so tem grao minimo.
-- Atualizada em 16/10/2026: 48 fontes/clientes (18 novas de 14/10), colunas de duplicidade entre fontes. TOTAL DA CASA = SUM(qtd_contatos_canonicos).
SELECT
  cliente,
  COUNT(*) AS qtd_contatos,
  COUNTIF(tem_detalhe) AS qtd_com_detalhe,
  COUNTIF(NOT tem_detalhe) AS qtd_grao_minimo,
  COUNTIF(tem_detalhe AND REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'granted')
          AND NOT REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'declined')) AS qtd_autorizados,
  COUNTIF(tem_detalhe AND REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'declined')) AS qtd_recusaram,
  COUNTIF(tem_detalhe AND NOT REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'granted|declined')) AS qtd_sem_registro,
  SAFE_DIVIDE(COUNTIF(tem_detalhe AND REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'granted')
              AND NOT REGEXP_CONTAINS(IFNULL(bases_legais_json, ''), r'declined')), COUNTIF(tem_detalhe)) AS taxa_autorizados,
  COUNTIF(tem_telefone) AS qtd_com_telefone,
  SAFE_DIVIDE(COUNTIF(tem_telefone), COUNTIF(tem_detalhe)) AS taxa_com_telefone,
  COUNTIF(tem_localizacao) AS qtd_com_localizacao,
  SAFE_DIVIDE(COUNTIF(tem_localizacao), COUNTIF(tem_detalhe)) AS taxa_com_localizacao,
  COUNT(DISTINCT dominio_email) AS qtd_dominios_email,
  MIN(DATE(criado_em)) AS primeiro_contato_criado_em,
  MAX(atualizado_data) AS ultima_atualizacao_em,
  (COUNTIF(tem_detalhe) = 0) AS flag_so_grao_minimo,
  -- duplicidade entre fontes (16/10/2026): o mesmo uuid lido por mais de uma conexao. Cada cliente continua
  -- com TODOS os seus contatos; para o TOTAL DA CASA somar qtd_contatos_canonicos, nunca qtd_contatos.
  COUNTIF(flag_contato_em_mais_de_uma_fonte) AS qtd_contatos_em_mais_de_uma_fonte,
  COUNTIF(NOT flag_contato_em_mais_de_uma_fonte) AS qtd_contatos_exclusivos,
  COUNTIF(_rn = 1) AS qtd_contatos_canonicos,
  COUNTIF(campos_customizados_json IS NOT NULL) AS qtd_com_campos_customizados,
  CURRENT_TIMESTAMP() AS _extraido_at,
  MAX(_extraido_at) AS _extraido_trusted
FROM (
  SELECT t.*,
    -- linha canonica do contato (mesmo uuid em mais de uma _fonte): prefere grao completo, depois a atualizacao mais recente
    ROW_NUMBER() OVER (PARTITION BY t.uuid_contato ORDER BY t.tem_detalhe DESC, t.atualizado_em DESC, t._fonte) AS _rn
  FROM `vanguardamartech_trusted`.`trs_rd_station__contato` t
)
GROUP BY cliente
