# Regras de trabalho — Vanguarda MarTech

## Nekt · arquitetura de dados

### R-001 · Uma camada por fonte

**Política da empresa: cada fonte (source) da Nekt grava na sua própria camada.**
Nunca uma camada compartilhada entre fontes.

Nome da camada = cliente + conta + plataforma, quando o cliente tem mais de uma
conta na mesma plataforma. Ex.: `braga_veiculos_fb_ads`, `braga_acessorios_fb_ads`
— não uma `Braga_veiculos` para as duas.

Motivo: é o que mantém o permissionamento e a leitura da IA organizados conforme a
base cresce. Camada compartilhada obriga controle de acesso por tabela e faz a busca
semântica misturar contas e clientes.

**Criar camada é backoffice.** Não há endpoint — a API tem só `GET /layers/` e
`PATCH` de descrição. A camada precisa existir antes de publicar a fonte.

**Escopo:** vale para dado de cliente. Sistemas internos da Vanguarda (VJOB, iClips,
Conexa, Conta Azul, Qulture, Quickin, VBOT, GitHub, Linear) seguem o medalhão do
ADR-0009: camada `Raw`, folder = sistema de origem.

**Histórico:** de 2026-08-26 a 2026-08-31 esta regra dizia "a camada de saída é o
catálogo do cliente". Isso conflitava com uma camada por fonte sempre que o cliente
tinha várias contas. Corrigida em 2026-08-31 conforme a política da empresa.

**Desvios conhecidos, anteriores à regra — não corrigir sem decisão explícita:**

- As 33 fontes de RD Station gravam todas em `RD_marketing`.
- Facebook Ads da Braga: `facebook-ads-kQ2S` e `facebook-ads-GWZ2` compartilham
  `Braga_veiculos`.
- Google Ads: `google-ads-PsES` → `Braga_veiculos`, `google-ads-R4be` → `colmeia`,
  `google-ads-NP4k` → `PMZ_loja` (gravam no catálogo do cliente, não em camada
  própria).
- `facebook-ads-mrJt` ("Campanhas"), sem cliente definido.

### R-002 · Não mexer no que já está conectado

**Fonte já publicada e rodando não se altera** — nem cron, nem stream, nem camada de
destino — sem pedido explícito. Vale inclusive para correção que pareça óbvia.

O que é permitido sem pedido: leitura, diagnóstico, e escrever descrição
(`update_resource_description`), que é documentação e não muda comportamento.

Registrado em 2026-08-31.

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
- **Nomenclatura de camada por plataforma:** minúsculas, underscore, sem hífen,
  com sufixo da plataforma — `<cliente>_<conta>_g_ads` para Google Ads,
  `<cliente>_<conta>_fb_ads` para Facebook Ads. Uma por fonte, conforme a R-001.
  O bloco `<conta>` só entra quando o cliente tem mais de uma conta na plataforma.
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
  tabelas) porque a conta Don Watches 1 (`855-373-3895`) não tem atividade desde
  2023 — confirmado na API do Google Ads: R$ 0 de investimento, 0 impressões.
  A fonte `google-ads-vE2C` foi movida para execução semanal em 2026-08-31
  (era diária, consumindo ~30 créditos/mês para trazer zero linha).
- `list_layers` do MCP devolve lista incompleta (20 camadas, omite as `_g_ads`).
  Para inventário completo, paginar `list_tables` e agrupar por `layer_id`.
  `INFORMATION_SCHEMA` não é alternativa: o nível de projeto está sem
  permissão e o por-dataset falha porque a Nekt encapsula em `EXPORT DATA`.
- **Fontes Supabase espelham os schemas internos do Postgres/Supabase**
  (`auth`, `vault`, `storage`, `realtime`, `extensions`, `cron`,
  `information_schema`), e o padrão da Nekt é trazer tudo habilitado. Em
  2026-08-31 a `supabase-fEvu` tinha 109 streams habilitados e **apenas um** era
  dado de negócio (`public-app_meta`).
  Isso não é só ruído: o schema `auth` traz `refresh_tokens`, `sessions`,
  `mfa_factors` e `webauthn_credentials` — credenciais. Medido em 2026-08-31 na
  `supabase-x0tz`: 34 refresh tokens, 20 usuários e 9 sessões materializados no
  warehouse. Streams `auth` e `vault` desabilitados nas duas fontes nessa data;
  as tabelas já materializadas **continuam existindo** (desabilitar não apaga) e
  a exclusão é backoffice. Sobraram habilitados 82 streams de `information_schema`,
  `storage`, `realtime`, `extensions` e `cron` — ruído, sem risco.
  Ao conectar Supabase novo, desabilitar esses schemas antes do primeiro run.

### Antes de excluir qualquer coisa

- Camada só é excluível quando vazia (tabelas **e** volumes).
- Repontar a fonte **não move dados** — a Nekt re-extrai da API. Para preservar
  histórico, copiar de fato via transformação antes de excluir.
- API do Facebook Ads: janela de lookback de insights é de 37 meses. Histórico mais
  antigo que isso não é re-extraível.
