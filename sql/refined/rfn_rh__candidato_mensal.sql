-- rfn_rh__candidato_mensal  ·  Refined / rh (recrutamento, Quickin)  ·  L2 INTERNAL
-- Grao: mes de criacao do candidato x status de consentimento LGPD.
-- Le: trs_quickin__candidato (query-IUvF, L4). Gatilho: evento em query-IUvF. Cadencia diaria (supabase-x0tz).
-- Identidade (19/10/2026, contra a Trusted materializada): 3.207 candidatos = 3.207 · 28 linhas, 28 chaves · 245 com e-mail
--   repetido · 18 nascimento implausivel · 44 com nota · 3.370 telefones · 390 tags · 2024-11 a 2026-10.
-- R1 NADA PESSOAL ATRAVESSA: nome, e-mail, data de nascimento, cidade, bairro e UF ficam na Trusted. Aqui so contagem; UF e cidade
--    saem como numero de valores distintos (qtd_ufs_distintas, qtd_cidades_distintas), nunca o rotulo.
-- R2 O ACHADO QUE MANDA: consentimento 'needs' em 3.203 de 3.207 (99,9%); consented 1, declined 2, expired 1. A base guarda dado
--    pessoal de 3.207 candidatos e UM tem consentimento registrado. Nao filtrar por status para "limpar" a base sem decisao do RH.
-- R3 media_nota_avaliacao e NULL quando nenhum candidato do grupo tem nota (23 das 28 linhas): zero seria uma nota.
-- R4 consentimento_status NULL viraria '(sem registro)' (nao ha hoje). O mes e o de CRIACAO na plataforma (criado_em, UTC real
--    convertido para America/Sao_Paulo na Trusted).
-- LIMITACAO -- NAO CONTORNE: a mesma pessoa pode ter mais de um id (245 marcados por e-mail repetido): qtd_candidatos conta ids,
--   nao pessoas. Nao ha CPF, logo nao ha ponte com colaborador. Avaliacoes cobrem 1,4% (44 de 3.207).
WITH c AS (SELECT * FROM `vanguardamartech_trusted`.`trs_quickin__candidato`),
agg AS (
  SELECT
    DATE_TRUNC(DATE(criado_em), MONTH) AS mes_criacao,
    IFNULL(consentimento_status, '(sem registro)') AS consentimento_status,
    COUNT(*) AS qtd_candidatos,
    COUNTIF(flag_email_repetido) AS qtd_email_repetido,
    COUNTIF(email IS NULL) AS qtd_sem_email,
    COUNTIF(data_nascimento IS NULL) AS qtd_sem_nascimento,
    COUNTIF(flag_nascimento_implausivel) AS qtd_nascimento_implausivel,
    COUNTIF(tem_headline) AS qtd_com_headline,
    COUNTIF(tem_resumo) AS qtd_com_resumo,
    COUNTIF(nota_media_avaliacao IS NOT NULL) AS qtd_com_nota,
    AVG(nota_media_avaliacao) AS media_nota_avaliacao,
    COUNTIF(qtd_telefones > 0) AS qtd_com_telefone,
    SUM(qtd_telefones) AS soma_telefones,
    SUM(qtd_tags) AS soma_tags,
    COUNTIF(uf IS NOT NULL) AS qtd_com_uf,
    COUNT(DISTINCT uf) AS qtd_ufs_distintas,
    COUNT(DISTINCT cidade) AS qtd_cidades_distintas,
    COUNTIF(consentimento_atualizado_em IS NOT NULL) AS qtd_consentimento_datado,
    MAX(atualizado_na_origem_em) AS ultima_atualizacao_na_origem_em
  FROM c
  GROUP BY 1, 2
),
final AS (
  SELECT CONCAT(FORMAT_DATE('%Y-%m', mes_criacao), '|', consentimento_status) AS id_candidato_mensal,
         a.*, 'L2_INTERNAL' AS classificacao_dado
  FROM agg a
)
SELECT f.*, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(f))) AS _payload_hash
FROM final f
