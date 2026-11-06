-- trs_vjob__acesso  ·  query-OwrE  ·  49.206 linhas  ·  L4 PERSONAL_DATA
-- Trusted / VJOB. Grao: um acesso a intranet. Chave: id_acesso = (origem, id).
-- Origem: acessos2 (47.857) + acessos (1.349). Gatilho: evento em query-MZdN.
--
-- L4 e NAO L5: as duas origens tem tres colunas (id, idusuario, datahora) e nenhuma
--   credencial. E log de EVENTO, nao de segredo. O inventario dos 199 streams
--   classificava as duas como L5; isso esta corrigido aqui.
-- DUAS ORIGENS INDEPENDENTES: ZERO pares (idusuario, datahora) em comum, janelas que se
--   sobrepoem. Somar nao duplica. Chave composta por prevencao: as faixas de id sao
--   disjuntas hoje (1-1.349 e 8.748-56.605) mas sao duas sequencias, nao uma.
-- (usuario, data-hora) NAO E CHAVE: 400 pares repetidos em acessos2.
-- 2.508 linhas (5,1%) com usuario fora do cadastro. Janela 2019-05-23 a 2026-09-24.
WITH u AS (SELECT DISTINCT id_usuario FROM `vanguardamartech_trusted`.`trs_vjob__usuario`),
base AS (
  SELECT 'ACESSOS2' AS origem, id, idusuario, datahora
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_acessos2`
  UNION ALL
  SELECT 'ACESSOS', id, idusuario, datahora
  FROM `vanguardamartech_vjob_real_mysql`.`mysql_vjobvjob_2024_acessos`
),
prep AS (
  SELECT
    CONCAT(b.origem, ':', CAST(b.id AS STRING)) AS id_acesso,
    b.origem,
    b.id                                        AS id_acesso_bruto,
    NULLIF(b.idusuario, 0)                      AS id_usuario,
    b.datahora                                  AS acessado_em,
    DATE(b.datahora)                            AS dt_acesso,
    (b.origem = 'ACESSOS2')                     AS is_log_vigente
  FROM base b
),
tratado AS (
  SELECT
    p.*,
    (p.id_usuario IS NULL)                                   AS flag_usuario_ausente,
    (p.id_usuario IS NOT NULL AND u.id_usuario IS NULL)      AS flag_usuario_nao_catalogado
  FROM prep p
  LEFT JOIN u ON u.id_usuario = p.id_usuario
)
SELECT t.*, CURRENT_TIMESTAMP() AS _extraido_at, 'mysql-yIOn' AS _fonte,
  'America/Sao_Paulo' AS _fuso, TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
