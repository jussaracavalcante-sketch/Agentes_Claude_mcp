-- trs_rh__pessoa_house
-- Trusted / RH. Grao: um VINCULO de pessoa (ou PJ da folha) a um SETOR de housing -- o centro de custo de cliente a que a pessoa esta alocada.
-- Chave: id_house = pessoa_norm | id_setor. Origem: vanguardamartech_raw.supabase_meta_pessoa_house (fonte supabase-x0tz, diaria).
-- Medido em 2026-10-19: 68 linhas, 68 pessoa_norm distintos (ninguem em dois setores), 18 setores; origem 'folha' 67 e 'generica' 1.
-- O SETOR RESOLVE 18 DE 18 em supabase_meta_param_no (eixo centro_custo, nivel 4, tipo setor): sao os centros de custo de CLIENTE -- Nova Era,
-- Fabrica de Eventos, Braga, Ciesa, CAA, Santo Remedio, SKN, Colmeia, Pneu Forte, Prestex, Santa Julia, Via Marconi, Amazon Copy, Shizen, PMZ,
-- Unipar Construtora, Murano, Castelinho. "House" aqui e a pessoa alocada ao cliente (housing), nao um departamento interno.
-- NEM TUDO E PESSOA: 9 das 68 linhas sao razao social de PJ (Radio TV do Amazonas Ltda., Fabrica de Eventos Ltda., Braga Veiculos Ltda., IPOG...),
-- marcadas por heuristica de texto em flag_parece_pj (ltda, s.a, eireli, me, epp, comercio, servicos, associacao, coordenacao) -- e heuristica,
-- nao cadastro. 51 das 68 existem em meta_pessoa (pessoa canonica); as 17 restantes sao as 9 PJ e 8 nomes fora da semente.
-- Nivel: L4 PERSONAL_DATA -- nome de pessoa e a que cliente ela esta alocada. A Refined (rfn_rh__pessoa_canonica_resumo) so conta por setor.
-- Fuso: `atualizado_em` e instante UTC do Supabase, sem conversao.
WITH h AS (
  SELECT pessoa_norm, setor_id, pessoa_exibe, origem, obs, atualizado_em, atualizado_por
  FROM `vanguardamartech_raw`.`supabase_meta_pessoa_house`
),
tratado AS (
  SELECT
    CONCAT(h.pessoa_norm, '|', CAST(h.setor_id AS STRING))                          AS id_house,
    h.pessoa_norm,
    NULLIF(TRIM(h.pessoa_exibe), '')                                                AS pessoa_exibe,
    h.setor_id                                                                      AS id_setor,
    NULLIF(TRIM(s.nome), '')                                                        AS setor_nome,
    s.eixo                                                                          AS setor_eixo,
    s.tipo                                                                          AS setor_tipo,
    (s.id IS NULL)                                                                  AS flag_setor_nao_catalogado,
    CAST(pc.pessoa_id AS STRING)                                                    AS id_pessoa_canonica,
    (pc.pessoa_id IS NOT NULL)                                                      AS flag_na_pessoa_canonica,
    REGEXP_CONTAINS(h.pessoa_norm, r'ltda|s\.a|eireli|\bme\b|epp|coordenacao|comercio|servicos|associa') AS flag_parece_pj,
    h.origem                                                                        AS origem_do_vinculo,
    NULLIF(TRIM(h.obs), '')                                                         AS obs,
    h.atualizado_em,
    h.atualizado_por
  FROM h
  LEFT JOIN `vanguardamartech_raw`.`supabase_meta_param_no` s ON s.id = h.setor_id
  LEFT JOIN `vanguardamartech_raw`.`supabase_meta_pessoa` pc ON pc.pessoa_norm = h.pessoa_norm
)
SELECT t.*, 'L4_PERSONAL_DATA' AS classificacao_dado, CURRENT_TIMESTAMP() AS _extraido_at, 'supabase-x0tz' AS _fonte, 'UTC' AS _fuso,
  TO_HEX(MD5(TO_JSON_STRING(t))) AS _payload_hash
FROM tratado t
