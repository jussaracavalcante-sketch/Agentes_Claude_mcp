-- rfn_rh__recrutamento_mensal (query-eZXu)
-- Refined / rh. Grao: um mes x departamento da vaga. Chave: (mes_referencia, departamento).
-- Nivel: L2 INTERNAL (so contagem; candidato, remuneracao e gestor NAO atravessam).
--
-- LE: trs_quickin__vaga (217 vagas, query-6XFL) e trs_quickin__aplicacao (4.013 aplicacoes, query-hcpP).
-- VALIDACAO (18/10/2026, reproduzindo as duas Trusted sobre a Raw, que ainda nao materializaram): 138 linhas, 138 chaves;
-- soma de qtd_vagas_abertas 217 = total de vagas; qtd_posicoes 242; qtd_aplicacoes_das_vagas 4.013 = total de aplicacoes;
-- qtd_contratacoes 150 = total de aplicacoes contratadas (zero contratada sem data); meses 2024-11 a 2026-10;
-- vagas 212 arquivadas e 5 abertas.
--
-- REGRAS: (R1) vaga entra no mes de ABERTURA (date_open em America/Sao_Paulo); contratacao entra no mes da CONTRATACAO
-- (hired_date) e no departamento da vaga: as duas medidas sao coortes diferentes e NAO se dividem na mesma linha
-- (a contratacao de um mes pode ser de vaga aberta meses antes). (R2) FULL OUTER JOIN: mes com contratacao e sem vaga
-- aberta, ou o contrario, continua existindo. (R3) departamento sem nome vira '(sem departamento)', nunca descartado.
-- LIMITACAO -- NAO CONTORNE: date_close da vaga e data PLANEJADA (vai ate 2040 e existe nas 5 abertas): nao mede
-- tempo de fechamento, por isso nao entra aqui. So 5 vagas abertas hoje e a base nao tem tempo de contratacao nem
-- custo por vaga; a taxa de conversao do funil nao e calculada aqui.
WITH v AS (
  SELECT DATE_TRUNC(CAST(aberta_em AS DATE), MONTH) AS mes,
         IFNULL(departamento, '(sem departamento)') AS departamento,
         COUNT(*)                                   AS qtd_vagas_abertas,
         SUM(IFNULL(qtd_posicoes, 0))               AS qtd_posicoes,
         COUNTIF(status = 'archived')               AS qtd_vagas_arquivadas,
         COUNTIF(status = 'open')                   AS qtd_vagas_em_aberto,
         SUM(qtd_aplicacoes_na_base)                AS qtd_aplicacoes_das_vagas
  FROM `vanguardamartech_trusted`.`trs_quickin__vaga`
  WHERE aberta_em IS NOT NULL
  GROUP BY 1, 2
),
c AS (
  SELECT DATE_TRUNC(CAST(a.contratado_em AS DATE), MONTH) AS mes,
         IFNULL(vg.departamento, '(sem departamento)')     AS departamento,
         COUNT(*)                                          AS qtd_contratacoes
  FROM `vanguardamartech_trusted`.`trs_quickin__aplicacao` a
  LEFT JOIN `vanguardamartech_trusted`.`trs_quickin__vaga` vg ON vg.id_vaga = a.id_vaga
  WHERE a.is_contratado AND a.contratado_em IS NOT NULL
  GROUP BY 1, 2
)
SELECT
  COALESCE(v.mes, c.mes)                                AS mes_referencia,
  COALESCE(v.departamento, c.departamento)              AS departamento,
  IFNULL(v.qtd_vagas_abertas, 0)                        AS qtd_vagas_abertas,
  IFNULL(v.qtd_posicoes, 0)                             AS qtd_posicoes,
  IFNULL(v.qtd_vagas_arquivadas, 0)                     AS qtd_vagas_arquivadas,
  IFNULL(v.qtd_vagas_em_aberto, 0)                      AS qtd_vagas_em_aberto,
  IFNULL(v.qtd_aplicacoes_das_vagas, 0)                 AS qtd_aplicacoes_das_vagas,
  IFNULL(c.qtd_contratacoes, 0)                         AS qtd_contratacoes,
  CURRENT_TIMESTAMP()                                   AS _extraido_at,
  'supabase-x0tz'                                       AS _fonte,
  'America/Sao_Paulo'                                   AS _fuso,
  TO_HEX(MD5(CONCAT(CAST(COALESCE(v.mes, c.mes) AS STRING), COALESCE(v.departamento, c.departamento)))) AS _payload_hash
FROM v
FULL OUTER JOIN c ON v.mes = c.mes AND v.departamento = c.departamento
