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

**Criar camada dá pelo MCP** — `create_layer`, em duas fases (`confirm=False` mostra o
preview, `confirm=True` cria). Verificado em 2026-09-04 criando a `Trusted Facebook Ads`.
De 2026-08-26 a 2026-09-03 esta regra dizia que criar camada era backoffice sem endpoint;
estava errado. A camada precisa existir antes de publicar a fonte.

**O nome da camada é irreversível.** Ele deriva o `slug` e o `database_name` físico que toda
query futura referencia. Camada não se renomeia e recurso não se move entre camadas — o
conserto é criar outra e reconstruir tudo que apontava para a primeira, perdendo o histórico
das tabelas e deixando a antiga como lixo que também não se exclui. Confirmar a grafia exata
com quem pediu, sempre.

**Nome de camada não é nome de dataset.** A camada `Nova_era_` é o dataset
`vanguardamartech_nova_era`, sem o underscore final. Descobrir o dataset pelo catálogo ou pela
mensagem de erro do `execute_sql`, que lista as camadas candidatas — nunca deduzir do nome.

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

### R-003 · Conta com nome igual não se unifica

**Contas cujo nome começa igual são unidades distintas e nunca são fundidas numa
única linha de cliente.** Registrado em 2026-09-01 a pedido.

Vale para todos os grupos da base: as 10 contas `BRAGA *`, as 3 `PMZ *`, as 4 do
conjunto Pneu Forte (`PNEU FORTE *`, `PNEU EXPRESS`, `SMILE PNEUS`), as 2 `CAA *`,
as 2 `DON WATCHES *`, as 2 `DR. CABRAL *` e as 3 `UNIPAR *`.

Na prática, na camada Trusted: a coluna `cliente` recebe o nome **da conta**, nunca
o do grupo. Nada de `CASE WHEN cliente LIKE 'BRAGA%' THEN 'GRUPO BRAGA'`. Quem
quiser o consolidado agrupa na leitura, por `id_conta` ou por prefixo de nome — a
Trusted não decide isso por ninguém.

Motivo: as contas têm verba, calendário e responsável próprios. Fundi-las na
ingestão destrói informação que não volta; separá-las na leitura é trivial.

**O que a regra NÃO proíbe:** várias contas dividirem a mesma tabela Trusted. O que
não pode é perderem identidade dentro dela. As linhas convivem desde que
`id_conta` e `cliente` continuem distintos por conta.

### R-004 · Achado que não afeta ingestão nem tratamento: documenta e segue

**Se o achado não muda o dado que entra nem o tratamento que ele recebe, vira documentação
— não vira pergunta, nem pedido de ajuste, nem tarefa para outro time.**
Registrado em 2026-09-01 a pedido.

**Afeta, e portanto escala:** fonte falhando, credencial inválida, stream faltando, coluna
ausente, tipo incompatível, grão errado, investimento perdido, chave duplicada, fuso ou
unidade trocados. Aqui parar e perguntar é certo.

**Não afeta, e portanto só documenta:** rótulo divergente do nome na plataforma, grafia,
acento, nomenclatura de camada, apelido desatualizado, conta sem entrega, nome duplicado
na origem, numeração interna, qualquer inconsistência cosmética.

Na prática: escolher o default sensato, registrar a escolha **e a alternativa que não foi
tomada**, seguir. Sem `AskUserQuestion` para esses casos, sem lista para outro time a menos
que peçam. O registro vai no doc do domínio e na descrição do recurso — quem precisar decidir
encontra lá, quando quiser.

### ADR-0009 · Medalhão

- `Raw` — cópia fiel das fontes, sem tratamento. Folder = sistema de origem.
- `Trusted` — dado validado e normalizado (fuso `America/Sao_Paulo`, tipos,
  unicidade). Folder = sistema de origem.
- `Refined` — regras de negócio e data products, camada oficial de consumo.
  Folder = domínio de negócio.

### Convenções operacionais

- **Fuso dos crons:** `America/Manaus` em todas as pipelines.
- **Nomenclatura Trusted:** `trs_<sistema>__<entidade>` (ex.: `trs_vjob__job`).
- **Nomenclatura Refined:** `rfn_<domínio>__<entidade>` (ex.: `rfn_midia__desempenho_diario`),
  folder = domínio de negócio. A descrição da transformação é parte da entrega: regras de
  negócio numeradas, bloco de limitações com "não contorne", e os números da validação com
  data. Inventário: `docs/nekt/refined-camada.md`.
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
  inteiro, então a união é exata — **verificado nas 39 contas em 2026-09-01**: dos 42.758
  pares (campanha, dia) de `campaign_performance`, 9.607 (22,5%) não têm nenhuma linha de
  anúncio e **zero** têm cobertura parcial; zero anúncios órfãos; o total reproduz
  `campaign_performance` ao micro (1.354.538.045.829 dos dois lados). Se um dia aparecer
  par parcial, a premissa cai e a query precisa de resíduo por diferença, não por presença.
- **`NOT EXISTS` correlacionado sobre CTE de união grande não roda no BigQuery.**
  Falhou em 2026-09-02 na `trs_google_ads__insight_diario` com *"Correlated subqueries that
  reference other tables are not supported unless they can be de-correlated"*. Com 5 fontes
  passava; com 39 o otimizador desistiu. **O tamanho da união muda o que o motor aceita —
  query que valida em piloto pequeno pode quebrar ao escalar.** A forma que funciona é
  anti-join: `LEFT JOIN <chaves distintas> ... WHERE <chave> IS NULL`. O `DISTINCT` no lado
  direito é obrigatório, senão o join multiplica a linha da esquerda.
- **Tabela no catálogo não é tabela existente.** A Nekt cria a entrada no catálogo quando a
  fonte é configurada; a tabela só nasce na primeira execução que **escreve dado**. Uma
  referência a tabela catalogada mas não materializada derruba a query inteira, não só aquele
  ramo. Confirmado em 2026-09-02 com a `rd-station-socq`. Conferir materialização com um
  `COUNT(*)` antes de somar fonte nova a qualquer união.
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
  de executar depois de três falhas seguidas. O efeito no `active` é inconsistente:
  em 2026-08-31 as 3 fontes da Unipar estavam paradas há dois dias e ainda
  apareciam com `active: true`; em 2026-09-01, depois de mais uma falha, viraram
  `active: false` / `status: inactive`. Não dá para confiar no campo em nenhuma das
  direções. Medido em 2026-08-31: 12 das 93 fontes
  ativas nunca tiveram uma execução bem-sucedida, 7 delas criadas nos dois dias
  anteriores. **Fonte publicada não é fonte integrada — conferir a primeira
  execução antes de considerar pronta.**
- **`validate_source_connector_config`: o sinal confiável é a lista de streams, não o
  status.** Medido em 2026-09-01 na `semrush-OnLY`, cuja chave de API é rejeitada com
  `403 ERROR 120 :: WRONG KEY - ID PAIR` em toda extração: a validação retornou
  `status: "success"` e `streams: []`. **Validação boa traz os streams do conector;
  lista vazia significa que a credencial não funcionou.** O comportamento varia por
  conector — em 2026-09-03, com a senha do Postgres rejeitada, a `supabase-x0tz`
  devolveu `status: "failed"` corretamente (com `parsed_error: "Unknown Python
  exception."`, que não diz nada; o motivo real só aparece em
  `get_pipeline_run_logs`). Então: `failed` é conclusivo, `success` não é — nesse caso
  confira os streams. Vale como teste de credencial em fonte já publicada, ao
  contrário do `get_setup_link`.
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

- **RD Station: a origem de tráfego vem em cinco formatos no mesmo campo.**
  `fonte_trafego_bruta` mistura, medido em 2026-09-03 sobre 17.602 conversões:
  `encoded_<base64>` (4.995, um JSON com a sessão de origem dentro), query string
  `utm_source=...` (1.400), texto livre (~4.200, ~990 grafias — `FACEBOOK` e `Facebook`
  convivem), URL ou `android-app://<pacote>` (~660) e vazio (8.354). Dentro do blob base64 a
  origem está em `first_session.value` e ainda vem em três dialetos: UTM, o cookie `__utmz`
  legado do Analytics (`utmcsr=`/`utmcmd=`/`utmccn=`, separado por `|`) e URL crua.
  **Ler só `utm_source` dá 1.400 linhas com um único valor distinto** e a falsa impressão de
  que não há origem. Tratado na `rfn_marketing__conversao`. Decodificar percent-encoding
  trocando `%XX` por caractere um a um corrompe acento — o jeito certo é montar a cadeia de
  bytes em hexadecimal e converter para texto uma vez no fim.
- **`gad_campaignid` é a chave de funil, e é a única honesta.** O auto-tagging do Google Ads
  deixa `gad_source` e `gad_campaignid` na origem de tráfego do RD, e `gad_campaignid` **é** o
  `id_campanha` do Google Ads — junção exata por id, que resolve o cliente de graça
  (campanha → `id_conta` → `cliente`). Medido em 2026-09-03: 1.083 conversões carregam o
  parâmetro, 38 das 57 campanhas casam na Trusted, cobrindo 908 conversões (5,2%).
  **Cobertura baixa é o número certo.** Casar por nome de cliente não é alternativa: dos 39
  rótulos do Google Ads e 29 do RD, só 8 batem exatamente, e os quase-pares incluem os casos
  3-para-1 do PMZ e 2-para-1 da Don Watches, que a R-003 proíbe fundir.

- **Pooler do Supabase: o usuário precisa carregar o identificador do projeto.** No
  host compartilhado `aws-<n>-<região>.pooler.supabase.com` o Supavisor não descobre
  qual projeto é o alvo pelo hostname, então o usuário tem de ser
  `postgres.<project_ref>`, não `postgres`. Usuário sem o sufixo dá
  `FATAL: (ENOIDENTIFIER) no tenant identifier provided (external_id or sni_hostname
  required)` — que é erro de **roteamento**, não de senha. Confusão fácil porque o
  Supavisor reporta o erro de senha também como `user "postgres"`, sem o sufixo:
  `password authentication failed for user "postgres"` significa que o tenant FOI
  resolvido e a senha é que foi rejeitada. Distinguir os dois evita trocar a senha
  quando o problema é o usuário, e vice-versa. Visto em 2026-09-03 na `supabase-x0tz`.

### Antes de excluir qualquer coisa

- Camada só é excluível quando vazia (tabelas **e** volumes).
- Repontar a fonte **não move dados** — a Nekt re-extrai da API. Para preservar
  histórico, copiar de fato via transformação antes de excluir.
- API do Facebook Ads: janela de lookback de insights é de 37 meses. Histórico mais
  antigo que isso não é re-extraível.
