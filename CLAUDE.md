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

**Não existe "catálogo do cliente" nesta base.** As camadas sem sufixo de
plataforma (`Acesso_saude`, `Braga_veiculos`, `colmeia`, `Best_car`, `PMZ_loja`,
`Patio_gourmet`, `Constroi_incorporadora`, `Nova_era_`, `Nova_era_pvh`,
`Nova_era_boa_vista`) **são as camadas do Facebook Ads** — ficaram sem sufixo
porque o Meta foi integrado antes de existir a convenção. Verificado em
2026-08-31: `Acesso_saude` tem 33 campanhas de Facebook e o Google Ads da mesma
conta está em `Acesso_saude_google_ADS`, com 36.

**Desvios conhecidos, anteriores à regra — não corrigir sem decisão explícita:**

- As 33 fontes de RD Station gravam todas em `RD_marketing`.
- **Camadas com duas plataformas misturadas:** `colmeia` (Facebook 122 campanhas +
  Google Ads 12), `Braga_veiculos` (2 fontes de Facebook + 1 de Google Ads) e
  `PMZ_loja` (1 de cada). Fontes envolvidas: `google-ads-R4be`, `google-ads-PsES`,
  `google-ads-NP4k`, `facebook-ads-kQ2S`, `facebook-ads-GWZ2`, `facebook-ads-ln1a`,
  `facebook-ads-x4yO`.
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
- **Google Ads: `ad_performance` não fecha com `campaign_performance`.** O Google
  não publica desempenho por anúncio em campanha `PERFORMANCE_MAX`. Trusted lida
  só sobre `ad_performance` perde esse investimento em silêncio — medido em
  2026-08-31: Move Rental Cars perdia US$ 1.347,11 de US$ 19.372,45 (7%, 18.072
  cliques) e Olá Casa Nova R$ 126,35. A Acesso Saúde não perdia nada, o que faz o
  erro passar despercebido em conta sem PMax. Solução aplicada na
  `trs_google_ads__insight_diario`: grão misto com coluna `grao` — linhas
  `ANUNCIO` de `ad_performance` mais linhas `CAMPANHA` de `campaign_performance`
  só para os pares (campanha, dia) ausentes. A ausência é sempre por campanha-dia
  inteiro, verificado em 3 contas, então a união é exata.
- **O prefixo de tabela também não segue o nome da camada.** A camada
  `move_rental_cars_g_ads` guarda tabelas com prefixo `google_ads_move_rental`,
  sem o `_cars`. Pior caso confirmado, a Don Watches: a camada
  `don_watches_conta_1_g_ads` guarda a conta **2** (945-172-6644, fonte
  `google-ads-QuKh`) com prefixo `google_ads_don_watches_2`, e a camada
  `don_watches_conta_2` guarda a conta **1** (855-373-3895, fonte
  `google-ads-vE2C`) com prefixo `google_ads_watches_2` — os dois prefixos dizem
  "2". Descobrir o prefixo pelo catálogo e a conta pelo `resource_name`, nunca
  deduzir do nome.
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
- **Trocar credencial de fonte já publicada não passa pelo MCP.** O
  `get_setup_link` só aceita fonte em rascunho: *"Setup links can only be
  generated for draft sources."* Em fonte viva, credencial e `connector_config`
  se editam apenas na interface web da Nekt. Verificado em 2026-08-31 tentando
  gerar link para `semrush-OnLY`.
- `list_layers` do MCP devolve lista incompleta (20 camadas, omite as `_g_ads`).
  Para inventário completo, paginar `list_tables` e agrupar por `layer_id`.
  `INFORMATION_SCHEMA` não é alternativa: o nível de projeto está sem
  permissão e o por-dataset falha porque a Nekt encapsula em `EXPORT DATA`.
- **`status: idle` + `active: true` NÃO significam que a fonte funciona — no MCP.**
  Esses campos da API descrevem o deploy, não a execução: pelo MCP, uma fonte que
  falhou em 100% das tentativas é indistinguível de uma saudável. Só o histórico
  (`list_pipeline_runs` por slug) revela. **A interface web da Nekt, ao contrário,
  mostra um selo "Failed" por fonte** — ali a falha é visível, é a API que não a
  expõe. Ao diagnosticar via MCP, nunca concluir saúde por `status`/`active`.
  Complicando: `settings_max_consecutive_failures` (3 por padrão) faz a Nekt parar
  de executar depois de três falhas seguidas **sem mudar o `active`** — a fonte
  fica parada e continua listada como ativa. Medido em 2026-08-31: 12 das 93 fontes
  ativas nunca tiveram uma execução bem-sucedida, 7 delas criadas nos dois dias
  anteriores. **Fonte publicada não é fonte integrada — conferir a primeira
  execução antes de considerar pronta.**
- **`validate_source_connector_config` devolve `success` com credencial inválida.**
  Medido em 2026-09-01 na `semrush-OnLY`, cuja chave de API é rejeitada com
  `403 ERROR 120 :: WRONG KEY - ID PAIR` em toda extração: a validação retornou
  `status: "success"` e `streams: []`. **O sinal útil é a lista de streams, não o
  status** — validação boa traz os streams do conector; lista vazia significa que a
  credencial não funcionou. Vale como teste rápido de credencial (funciona também em
  fonte já publicada, ao contrário do `get_setup_link`), desde que se leia os streams.
- **Validar a conta contra a API não valida a credencial da Nekt.** As 3 fontes do
  Grupo Unipar (`google-ads-3eFc`, `mvUx`, `hBlk`) foram validadas contra a API do
  Google Ads na integração e mesmo assim dão `USER_PERMISSION_DENIED` na extração:
  as contas pendem do MCC do cliente (7749545148), não do MCC da Vanguarda
  (1704439246), e a conta Google do OAuth da Nekt não tem acesso a ele. A validação
  na integração usou outra credencial. Ao integrar conta de MCC de terceiro,
  confirmar o acesso **com a credencial que a Nekt usa**, não com outra.
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
