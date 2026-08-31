# Regras de trabalho — Vanguarda MarTech

## Nekt · arquitetura de dados

### R-001 · Fonte nova aponta para o catálogo do cliente

**Ao criar uma fonte (source) nova na Nekt, a camada de saída é sempre o catálogo
do cliente a que o dado pertence.** Nunca uma camada genérica compartilhada.

Motivo: é o que mantém o permissionamento e a leitura da IA organizados conforme a
base cresce. Camada compartilhada obriga controle de acesso por tabela e faz a busca
semântica misturar clientes.

Camadas de cliente existentes: `Acesso_saude`, `Braga_veiculos`, `Best_car`,
`Colmeia`, `Constroi_incorporadora`, `Nova_era_`, `Nova_era_boa_vista`,
`Nova_era_pvh`, `Patio_gourmet`, `PMZ_loja`, `Prestex`.

Se o cliente ainda não tem catálogo, criar o catálogo primeiro — não usar outro
como provisório.

**Escopo:** vale para dado de cliente. Sistemas internos da Vanguarda (VJOB, iClips,
Conexa, Conta Azul, Qulture, Quickin, VBOT, GitHub, Linear) seguem o medalhão do
ADR-0009: camada `Raw`, folder = sistema de origem.

**Aplicado desde:** 2026-08-26. Fontes anteriores a esta data podem não seguir a
regra — `facebook-ads-mrJt` ("Campanhas") é o caso conhecido, sem cliente definido.

### ADR-0009 · Medalhão

- `Raw` — cópia fiel das fontes, sem tratamento. Folder = sistema de origem.
- `Trusted` — dado validado e normalizado (fuso `America/Sao_Paulo`, tipos,
  unicidade). Folder = sistema de origem.
- `Refined` — regras de negócio e data products, camada oficial de consumo.
  Folder = domínio de negócio.

### Convenções operacionais

- **Fuso dos crons:** `America/Manaus` em todas as pipelines.
- **Nomenclatura Trusted:** `trs_<sistema>__<entidade>` (ex.: `trs_vjob__job`).
- **Metadados de linhagem na Trusted:** `_extraido_at`, `_fonte`, `_payload_hash`.
- **Fuso na origem:** VJOB grava hora local (`America/Sao_Paulo`); iClips devolve
  UTC. Tratar cada um conforme a origem, não assumir um padrão único.
- **Nomenclatura de camada Google Ads:** `<cliente>_g_ads` — minúsculas,
  underscore, sem hífen. Só para conta cujo cliente ainda não tem catálogo;
  se já tem, vale a R-001 e o destino é o catálogo do cliente.
  Inventário e renomeações pendentes: `docs/nekt/camadas-google-ads.md`.

### Armadilhas conhecidas

- `supabase_bronze_vjob__tbjobs.projeto` **não** é FK de cliente. A tabela-pai de
  projetos do VJOB não existe em nenhum stream. Cliente só via
  `tbcronograma.cliente` ou `tbclientexservico.id_cliente`.
- `tbjobsgeral.id_setor` é constante `1` e não resolve contra `tbsetor`
  (que começa no id 11). Campo morto — não modelar como dimensão.
- **Nome de camada e prefixo de tabela não identificam a conta Google Ads.**
  Casos confirmados de nome trocado: `don_watches_conta_1_g_ads` guarda a
  conta 2 e vice-versa; `braga_yamaha_consorcios` guarda a Braga Yamaha/Motos;
  `caa` guarda só a CAA Tintas. Sempre resolver a conta pelo `customer_id`
  extraído de `resource_name` (`customers/<id>/...`).
- `vanguardamartech_don_watches_conta_2` está vazia (0 linhas em todas as
  tabelas) apesar de a fonte `google-ads-vE2C` rodar com sucesso diariamente —
  e cada run bem-sucedido com zero linha consome 1 crédito.
- `list_layers` do MCP devolve lista incompleta (20 camadas, omite as `_g_ads`).
  Para inventário completo, paginar `list_tables` e agrupar por `layer_id`.
  `INFORMATION_SCHEMA` não é alternativa: o nível de projeto está sem
  permissão e o por-dataset falha porque a Nekt encapsula em `EXPORT DATA`.
- Fontes Supabase espelham schemas internos (`auth`, `storage`, `realtime`,
  `vault`, `information_schema`). Desabilitar esses streams: não são dado de
  negócio e `vault_decrypted_secrets` expõe segredos no warehouse.

### Antes de excluir qualquer coisa

- Camada só é excluível quando vazia (tabelas **e** volumes).
- Repontar a fonte **não move dados** — a Nekt re-extrai da API. Para preservar
  histórico, copiar de fato via transformação antes de excluir.
- API do Facebook Ads: janela de lookback de insights é de 37 meses. Histórico mais
  antigo que isso não é re-extraível.
