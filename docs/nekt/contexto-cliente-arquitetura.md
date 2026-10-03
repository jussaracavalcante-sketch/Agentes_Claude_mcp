# Contexto de cliente para aplicação conectada na Nekt — arquitetura

Levantado e iniciado em 2026-09-21. Objetivo: uma aplicação que se conecta à Nekt consegue
puxar, por cliente, o canônico, a identidade de marca (paleta, tipografia, bíblia da voz) e
todo o histórico.

---

## 1. Três superfícies de leitura, e elas NÃO são intercambiáveis

Um token MCP da Nekt é escopado em cinco eixos — `tables`, `volumes`, `secrets`,
`semantic_layer`, `live_connections`. Para leitura de contexto, três importam:

| Superfície | Ferramenta | Como recupera | Serve para |
|---|---|---|---|
| Warehouse | `execute_sql` | **lookup determinístico por chave** | fato estruturado: id, CNPJ, hex, contagem, data |
| Camada semântica | `get_semantic_context` | **busca vetorial**, devolve o documento inteiro | prosa: bíblia da voz, posicionamento, personas, proibições |
| Volumes | `read_file` | caminho do arquivo | binário: logo, manual de marca, fonte tipográfica |

**O erro a evitar:** pedir o hex exato da paleta à camada semântica. Busca vetorial devolve o
documento que *parece* relevante, não o registro certo — e devolve o documento **inteiro**
(medido: 4 a 7 mil caracteres por documento). Fato estruturado mora em tabela.

---

## 2. O bloqueio não é a marca — é a espinha

Medido em 2026-09-21:

| Medida | Valor |
|---|---:|
| Clientes no canônico (`rfn_cadastro__cliente`) | 407 |
| Contas de mídia (`rfn_cadastro__conta`) | 190 |
| Contas amarradas a cliente canônico **naquela tabela** | **2** |
| Contas com CNPJ | 43 |
| CNPJs distintos nessas contas | 34 |
| **Desses 34, quantos casam com cliente do canônico** | **34 — 100%** |

**A ponte não está errada, estava desligada.** A `rfn_cadastro__conta` foi publicada em
17/09 **antes** de a coluna `cnpj` materializar — a própria descrição dela registra isso como
segundo passo pendente. A `rfn_cliente__contexto` (`query-2k3p`) faz o join que faltava.

**Não usar `cliente_canonico_resolvido` como medida de cobertura:** ele diz 2; o real é 34.

**O que falta para os outros 373:** 147 das 190 contas não têm CNPJ na origem. Conserta-se no
cadastro do Google Ads / Meta, **não** em SQL. E **não** se resolve casando por nome — medido,
o nome diverge entre as bases em pelo menos 8 dos 38 casos conhecidos, e
`YAMAHA MOTOS MANAUS` aparece como `BRAGA MOTOS - YAMAHA`, o que faria uma regra por prefixo
fundir contas Braga (proibido pela R-003).

---

## 3. Não existe conteúdo de marca em nenhuma fonte conectada

Verificado em 2026-09-21, e é o fato que define o resto:

- `get_semantic_context` para *"paleta de cores, bíblia da voz, identidade de marca"* →
  **zero documentos**, `matched: false`.
- A camada semântica tem **5 documentos e ZERO pastas** — os quatro de setor (Mídia OFF,
  Mídia Paga, Social Media, Inbound) mais o de métricas, todos na raiz.
- O catálogo **não tem nenhuma coluna** de cor, logo, tipografia ou tom de voz. As únicas
  colunas de cor da base são `main_color` e `accent_color` **dentro do struct de anúncio
  responsivo do Google Ads** — configuração de criativo, não a paleta canônica do cliente.

**Isso é dado AUTORADO, não extraído.** Não há fonte para conectar. Tem custo de autoria por
cliente, e sem dono e caminho de manutenção apodrece.

Por isso a `rfn_cliente__contexto` **não emite colunas de marca vazias**: schema que promete
dado inexistente é pior que schema incompleto. O contrato está na seção 5, para a aplicação
poder ser escrita contra ele antes de o dado existir.

---

## 4. O que já está construído

**`rfn_cliente__contexto` · `query-2k3p` · folder `cadastro`**

Grão: um cliente. Chave: `id_cliente` (`CNPJ:<14>` ou `ICLIPS:<id>`). Gatilho por evento em
`query-65kE`, `query-Y1Yt` e `query-iX2P`, regra any. Alerta de falha ligado.

Validado por execução antes do deploy: **407 linhas, 407 chaves distintas** — os dois LEFT JOIN
não multiplicaram linha. 34 com conta de mídia, 80 com PI (por rótulo), 3 INTRAGRUPO, 1 TESTE.

O que entrega hoje:

| Bloco | Colunas | Cobertura |
|---|---|---|
| Identidade canônica | `id_cliente`, `chave_por`, `cnpj`, `cliente_nome`, `nomes_conhecidos`, `ids_iclips`, `multiplos_cadastros_no_iclips` | 407 |
| Classe | `classe` = `TERCEIRO` / `INTRAGRUPO` / `TESTE` | 407 |
| Histórico iClips | `qtd_projetos`, `qtd_pecas`, `primeira_atividade`, `ultima_atividade`, `dias_sem_atividade` | 407 |
| Mídia paga | `tem_conta_de_midia`, `qtd_contas_midia`, `plataformas_midia`, `contas_midia`, `moedas_midia` | **34** |
| Mídia off / PI | `tem_pi`, `pi_vinculado_por`, `qtd_pis`, `valor_pi_vigente`, `qtd_tipos_midia_off` | **80, por rótulo** |
| Autodiagnóstico | `fontes_de_historico` (0 a 3) | 16 com 3 · 81 com 2 · 310 com 1 |

`fontes_de_historico` existe para a aplicação **saber o que não pedir** — em vez de perguntar
e receber zero sem saber se é ausência de dado ou ausência de vínculo.

**`classe`** é o filtro que uma aplicação de relatório de cliente precisa: `TERCEIRO` exclui as
3 empresas do grupo e o cadastro de teste. Declarada por **CNPJ**, nunca por nome — `VANGUARDA
INTERNACIONAL` e `PARA GUARDAR` são cliente real apesar do nome.

---

## 5. Contrato dos campos de marca — escrever a aplicação contra isto

Divisão pela superfície que serve cada tipo, não por conveniência de autoria.

### 5.1 Tabela (`execute_sql`) — o que precisa de valor exato

Tabela-alvo: `rfn_cliente__marca`, grão um cliente, chave `id_cliente`.

| Campo | Tipo | Exemplo | Por que em tabela |
|---|---|---|---|
| `id_cliente` | STRING | `CNPJ:07865616000174` | chave, junta com `rfn_cliente__contexto` |
| `cor_primaria_hex` | STRING | `#1B3A6F` | a aplicação precisa do valor, não da descrição |
| `cor_secundaria_hex` | STRING | `#E8A33D` | idem |
| `cores_apoio_hex` | ARRAY\<STRING\> | `['#F5F5F0','#2E2E2E']` | idem |
| `tipografia_titulo` | STRING | `Montserrat SemiBold` | nome exato da fonte |
| `tipografia_corpo` | STRING | `Inter Regular` | idem |
| `logo_versao_preferida` | STRING | `horizontal_positivo` | seleciona o arquivo no volume |
| `tem_manual_de_marca` | BOOL | `true` | a aplicação sabe se vale buscar o arquivo |
| `marca_atualizada_em` | DATE | `2026-09-21` | frescor — marca desatualizada engana |
| `marca_atualizada_por` | STRING | e-mail de quem autorou | rastreabilidade |
| `marca_status` | STRING | `VIGENTE` / `EM_REVISAO` / `AUSENTE` | **obrigatório**: ausência tem de ser explícita |

### 5.2 Documento semântico — o que é prosa

Um documento por cliente, nomeado `Cliente — <nome canônico>`, contendo:

- posicionamento e promessa
- bíblia da voz: como fala, como **não** fala, vocabulário proibido
- personas e público
- restrições de compliance ou jurídicas do setor
- histórico de relacionamento em prosa (o que já foi tentado, o que não funcionou)

**Cada documento abre com o `id_cliente`** para poder ser cruzado com a tabela.

### 5.3 Volume — o binário

Volume por cliente, caminho `marca/<id_cliente>/`:
`logo_horizontal_positivo.svg` · `logo_vertical_negativo.svg` · `manual_de_marca.pdf` ·
`fontes/` · `templates/`

---

## 6. O que falta decidir, e por que não decidi sozinho

**Onde o time autora o conteúdo de marca.** Não é escolha técnica — é de dono e de ferramenta,
e eu não consigo executar nenhuma das opções sozinho: o MCP do Supabase desta sessão está
autenticado numa organização diferente dos 10 projetos da Vanguarda (medido em 18/09,
interseção zero).

| Opção | Como funciona | A favor | Contra |
|---|---|---|---|
| **A · Tabela de entrada no Supabase** | o time preenche uma tabela `meta_marca_cliente`; a Nekt extrai e a Refined consome | **é o padrão que esta base já usa** — `supabase_meta_depara_custo_conta` tem `atualizado_por` e `atualizado_em` e é preenchida pelo time | precisa de alguém com acesso ao Supabase para criar a tabela e de uma interface mínima |
| **B · Planilha, como a VAN-SEM-001** | mesma mecânica do preenchimento dos 4 setores, que já funcionou | time já conhece o fluxo; zero setup | planilha não versiona e não valida hex |
| **C · Documentos semânticos direto** | eu autoro por MCP | rápido para poucos clientes | 407 clientes por MCP é inviável, não há pastas na camada semântica, e o time não consegue editar |

**Minha recomendação: A**, com B como ponte para os primeiros clientes. É o padrão da própria
base, versiona, carrega quem autorou e quando, e deixa a Nekt como consumidora — não como
lugar de digitação.

**Segunda decisão, menor:** por quais clientes começar. Sugestão dos **16 com as três fontes de
histórico amarradas** — são os que dão retorno imediato para qualquer aplicação, porque já têm
canônico, mídia paga e mídia off ligados.

---

## 7. Passos seguintes, na ordem

1. **Ligar a espinha** — pedir CNPJ nas 147 contas de mídia sem documento. É o que mais aumenta
   cobertura e não depende de autoria nenhuma. Ação no cadastro do Google Ads / Meta.
2. **Decidir o local de autoria** (seção 6) e criar a tabela de entrada.
3. **`rfn_cliente__marca`** — construir quando a entrada existir, contra o contrato da 5.1.
4. **Documento semântico de entrada** — um único documento que ensina a aplicação conectada a
   navegar as três superfícies. Só faz sentido depois de 2 e 3, senão aponta para o vazio.
5. **Trocar a lista de CNPJ da `classe`** por join no par `query-NxG1` / `query-hH5g` quando
   essas duas materializarem.

## 8. O que NÃO foi feito, e por quê

- **Nenhuma coluna de marca emitida vazia** — contrato documentado em vez de schema falso.
- **Nenhum documento semântico criado** — a camada não tem pastas e a raiz é o único destino;
  criar 407 documentos por MCP não é caminho.
- **Nenhuma pipeline rodada à mão.** A `rfn_cliente__contexto` materializa no próximo evento.
- **Nada tocado na `rfn_cadastro__conta`** — ela é de outro autor e está viva; o join que
  faltava foi feito na tabela nova, não alterando a dela.
