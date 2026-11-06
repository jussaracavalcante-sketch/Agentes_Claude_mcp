# Diagnóstico consolidado e plano de execução — regularização e evolução dos conectores Nekt

**Em resposta ao e-mail da Jéssica de 04/11 ("Plano de regularização e evolução dos conectores do Nekt").**
Data da medição: 06/11/2026. Somente leitura: nada foi alterado, disparado, arquivado ou excluído na Nekt para produzir este documento. **Responsáveis e prazos são proposta, não combinado.** Estado: **rascunho para aprovação — nada executado.**

---

## 0. Como ler

Cada item é classificado em **uma** destas categorias (as cinco pedidas no e-mail):

| Código | Categoria | Significado |
|---|---|---|
| **FT** | Falha técnica | A fonte devia funcionar e não funciona; a correção é da casa ou da plataforma |
| **CA** | Conta ausente | A conta existe no cliente/plataforma e não tem fonte (ou a fonte lê a conta errada) |
| **SB** | Stand-by | Existe, está parada de propósito ou aguardando decisão |
| **FE** | Fora de escopo | Ex-cliente, duplicata ou conta que não precisa ser mantida |
| **DA** | Dependência de acesso | Só se resolve com ação de quem é dono da conta, do plano ou da credencial |

Limites da medição (valem para todo o documento): o histórico lido traz as 3 últimas execuções por fonte (falhas seguidas é piso); `trigger_type` vem nulo (manual × agendado só por horário); sucesso de execução não prova dado; o VJOB só atualiza no warehouse aos domingos (tarefas novas aparecem a partir de 08/11).

## 1. Placar de hoje (varredura R-006 de 06/11)

372 fontes publicadas: **317 com sucesso, 55 com falha**. Das 55: **7 são dependência justificada** (YLIU + 6 Meta com 403) e **48 pedem credencial ou decisão fora do MCP**.

| Conector | Publicadas | Sucesso | Falha |
|---|---:|---:|---:|
| Google Ads | 43 | 0 | 43 |
| Meta Ads | 79 | 72 | 7 |
| RD Station | 53 | 52 | 1 |
| GA4 | 51 | 51 | 0 |
| Páginas do Facebook | 60 | 60 | 0 |
| Instagram | 58 | 57 | 1 |
| TikTok | 14 | 14 | 0 |
| LinkedIn (orgânico e Ads) | 2 | 2 | 0 |
| Internas e apoio (Supabase ×3, MySQL, Gmail ×2, Linear, GitHub, webhook, iClips ×2, Semrush) | 12 | 9 | 3 |

Qualidade: 42 suítes, 1.632 regras, 1.631 conformes, 1 alerta (carga desalinhada, fecha em 09/11). **Atenção:** as suítes principal e do iClips (carga de 19/10) e as sete de Google Ads/mídia (23/10) medem dado velho.

---

## 2. Frente 1 — Fontes com falha, rascunho, inativas ou paradas

### 2.1 Falhas ativas (55 fontes)

| # | Fonte(s) | Sintoma | Categoria | Causa (medida ou inferida) | Ação proposta | Responsável (proposta) | Prazo (proposta) | Evidência de conclusão |
|---|---|---|---|---|---|---|---|---|
| 1 | **Google Ads ×43** | `401 unauthorized_client`, último sucesso de todas em 22/10; reautorização de 28/10 não valeu | **DA** | Renovação do token OAuth rejeitada (lido em 3 logs; as outras 40 só por padrão) | João reautoriza com o usuário Google do MCC; **testar UMA fonte, esperar sucesso, depois as demais**; nunca disparo em massa (cota do desenvolvedor estourou em 07/10 e 14/10) | João Araújo (já combinado: até **terça 10/11**, em tarefa VJOB) | 10/11 | ≥ 1 execução com sucesso **e linhas novas depois de 22/10**; só então as demais. Não vale o status da tarefa (a #2403 já constou como aprovada e não funcionou) |
| 2 | Google Ads `AMd2` (Santo Remédio, conta 281-904-4460) | 403 `CUSTOMER_NOT_ENABLED`, inativa | **FE** | A conta saiu do MCC | Arquivar na interface; a conta viva (513-801-6841) segue **SB** pelo e-mail do João de 30/09 | Jussara | 13/11 | Fonte arquivada |
| 3 | Google Ads Unipar `3eFc`, `mvUx`, `hBlk` | Inativas, `401` já em 25/10 | **DA** | Contas pendem do MCC do cliente (7749545148); a credencial precisa ter acesso a ele | Entram na reautorização do item 1, com a credencial que **a Nekt usa** | João | 10/11 | Sucesso + linhas novas |
| 4 | Meta `xDLw` (CA 02 Arena), `qy0W` (BA Elétrica 2026) | 403 `ads_read`, inativas | **DA** | Nem o token da agência lê: Termo de Transferência pendente | Admin do Business Manager atribui as contas ao Business da Vanguarda | João | 13/11 | Leitura pela Graph API e sucesso da fonte |
| 5 | Meta `geQA` (Santo Remédio Ecommerce) | 403, inativa | **DA** | A agência lê; falta acesso ao usuário que autorizou a Nekt | Atribuir ao usuário da conexão; confirmar se o e-mail de 30/09 vale também para Meta | João | 13/11 | Idem |
| 6 | Meta `f6h8` (Santo Remédio Reserva Nova) | 403, inativa | **SB** | Conta desabilitada na Meta (snapshot 09/10) | Confirmar com o cliente se segue em uso; senão, descartar | João | 13/11 | Decisão registrada |
| 7 | Meta `KUkx`, `OJi6` (Shizen) | 403, inativas | **DA** | Aprovação específica do cliente (e-mail do João, 15/10); **maior lacuna de gasto: R$ 8.400,59/7 dias** | Devolutiva do cliente Shizen | João | 13/11 | Sucesso + linhas |
| 8 | Instagram `wRZ1` (Braga Venda Direta) | `400` em `followers_count`, inativa | **FT** | Erro da API ao ler o perfil (4 falhas, 1 sucesso); causa no perfil/permissão não provada | Tarefa já aberta para a Gabriela; rascunho de e-mail no Gmail **não enviado** | Gabriela | 13/11 | Execução com sucesso e linha em `instagram_user_details` |
| 9 | RD `YLIU` (CDL) | 403 em `/platform/campaigns`, inativa | **DA** (**dependência justificada**) | O plano de RD do cliente não é compatível | **Nenhuma.** Só reabrir se a CDL mudar de plano | — | — | — |
| 10 | iClips: `rest-api-xk4P`, `rest-api-73hk`, `notebook-Rbpo` | `401 API Key inválida`; notebook sem execução desde 21/10 | **DA** | Chave do iClips recusada; Trusted do iClips e duas suítes congeladas em 19/10 | Chave nova entra pela interface (não pelo chat); **depois** reativar na ordem: fonte `xk4P`, `73hk`, notebook | Jussara (chave) | Aguardando a chave | Sucesso das três + `MAX(_extraido_at)` da `trs_iclips__projeto` ≥ data da retomada |
| 11 | `semrush-OnLY` | `WRONG KEY - ID PAIR`, nunca teve sucesso | **DA** | Par chave/ID rejeitado | Sem informação sobre quem tem o par correto; decidir **usar ou arquivar** | Jussara | 13/11 | Sucesso ou arquivamento |
| 12 | Meta `ckhA` | `TypeError` em `adsinsights` (03/11) | **FT** → resolvida | Não se repetiu | Sucesso em 06/11 09:58 | — | — | Já fechada |

### 2.2 Rodando sem entregar dado (sucesso ≠ dado)

| Fonte | Medido | Categoria | Ação proposta |
|---|---|---|---|
| `github-2Upt` | Sucesso, `github_institucionalrepositories` com **0 linhas** | **FT** | Conferir na interface a lista de repositórios e a data inicial do `connector_config` (o MCP redige os valores) |
| `webhook-v2-nZdJ` (Z-API) | Sucesso, 0 linhas | **DA** | Falta configurar a URL e o `x-api-key` na instância da Z-API; nada chega sem isso |
| `rd-station-socq` (AMZ Imports), Bajaj `jSLj` | Sucesso, sem tabela de contatos/eventos | **FT** ou **SB** | Confirmar se a conta RD tem base; se não tem, arquivar |
| `linkedin-ads-xiWu` | 1 conta lida ("Dislub Equador"), sem campanha nem analytics | **SB** | Confirmar com o criador (usuário 3615) qual cliente é; descrição já ajustada. Camada `grupo_pmz_linkedin` não muda (R-001) |

### 2.3 Rascunhos (a contagem deve ser reconferida; a de 06/11 foi 21 rascunhos de RD)

| Grupo | Quantidade | Categoria | Proposta |
|---|---:|---|---|
| RD copiando fonte ativa do mesmo cliente (`6VLn`, `Ril3`, `9t5P`, `whW9`, `7REI`, `BV7S`, `0KR1`, `jusk`, `8a7o`, `gdgN`, `KBtv`, `EyXL`, `ncty`, `JjsA`, `Osfw`, `yVc2`, `aiUh`) | 17 | **FE** (duplicata) | Arquivar na interface; ativar leria a conta duas vezes e gastaria crédito à toa |
| RD sem fonte ativa: `GhFV` (Braga Motos Yamaha Vendas), `TOPi` (Legacy) | 2 | **CA** | Autorizar com a conta RD do cliente (OAuth do analista de Inbound); camadas `braga_motos_yamaha_vendas_rd` e `legacy_pneus_rd` já criadas |
| RD sem rascunho útil: `vsNf` (Targo), `70tH` (Lovol) | 2 | **CA** | Camadas vazias existem; confirmar se os dois clientes têm conta RD |
| Meta Ads | a reconferir (1 em 29/10; 18 em 21/10) | **CA/DA** | Reler a listagem antes de agir |
| Facebook Pages, GA4 (`bLbp`) e outros | a reconferir | — | Idem |

### 2.4 Duplicatas rodando e gastando crédito

`facebook-pages-Xhmq` (mesma camada de `GyYt`, viola a R-001), `aikJ` (mesma página de `PPsY`), `nfih` (lê a Arena Tintas, não a Best Car) e `google-analytics-ga4-i5u3` (duplicata da `bLbp`). **FE.** Arquivar só pela interface; decisão adiada pela Jussara em 06/11. A página da Best Car **ficou sem fonte (CA)**.

### 2.5 Ex-clientes ainda publicados

Mari Mari (`gp7f`, `flYR`), Pátio Gourmet (`7vwE`, `XuHY`, `bhnp`) e Olá Casa Nova (`FKfU` Meta, `DzVL` Google): **FE**. As contas de Google Ads, Nova Era (5), Pátio Gourmet (2), Olá Casa Nova, UIARA, Hope Bay e Julia **continuam no MCC e gastando** (R$ 46.430,03 em 30 dias, medido em 16/10): pedir ao admin do MCC desvincular ou pausar.

---

## 3. Frente 2 — Matriz de cobertura por cliente, plataforma e rede social

Base já existente (não refeita do zero, como a Jéssica pediu em 03/11):

- Contas de mídia: `docs/nekt/inventario-contas-1743-2026-10-16.xlsx` (planilha oficial #1743).
- Redes sociais por cliente: `docs/nekt/base-perfis-sociais-1745-2026-11-05.xlsx`.
- Cobertura por gasto (medida em 15–16/10): Meta **65,4%** (7 dias) e Google **97,1%** (30 dias, já sem os ex-clientes e inativos no denominador; **o salto veio do denominador**).

**Proposta para a matriz final:** uma linha por cliente × plataforma, com as colunas `status` (CONECTADA / PENDENTE / BLOQUEADA / STAND-BY / FORA DE ESCOPO), `categoria` (FT/CA/SB/FE/DA), `fonte`, `última execução com sucesso`, `dado até`, `responsável`, `próximo passo`. As datas de "dado até" saem de `execute_sql` sobre as Trusted, não do status da fonte.

**Regra de leitura que a matriz precisa carregar:** em branco no checklist de redes ≠ "Não tem" ≠ inexistência de perfil (LinkedIn do AC Display está em branco e a Nekt lê a página; Via Marconi está "Não tem" e a Nekt lê a página Leapmotor). Pergunta à Gabriela pendente (rascunho no Gmail, não enviado).

**Lacunas conhecidas a classificar na matriz:** 11 contas Google sem fonte (R$ 23.198,90/30d, fora ex-clientes), as contas Meta que gastam e não têm fonte (reconferir contra o MCC da Meta), Best Car (Facebook), Braga Motos Consórcio (`instagram-A90g`, sem linha no checklist), TikTok pausado por senha (Best Car, KL, Move, Royal Enfield), e os 5 clientes de RD sem fonte ativa (Yamaha Vendas, Legacy, Targo, Lovol e conferência da Braga).

---

## 4. Frente 3 — Frequência de atualização (proposta, **nada alterado**)

Premissas: 1 crédito por execução bem-sucedida de fonte ou transformação; falha e carga inicial não cobram; limite de 9.000/mês; o consumo real só aparece em Billing (a tabela `nekt_runs` não é acessível ao token). **Os números abaixo são estimativas por contagem de execuções, não leitura de cobrança.**

| Família | Hoje | Proposta | Δ créditos/mês (est.) | Risco |
|---|---|---|---|---|
| Google Ads (43) | Semanal, terça (todas falhando) | **Manter semanal** até a reautorização valer; avaliar diária depois | Diária: ~+1.100 só nas fontes (43 × ~26 execuções extras), mais a cadeia de Trusted/Refined | Cota do desenvolvedor compartilhada (429 já ocorreu) |
| Meta Ads (~73 ativas) | Semanal, terça (escalonada) | Manter semanal; **diária só para as contas de maior gasto**, se a Diretoria pedir | Diária nas 73: ~+1.870 | A janela de insight é de 37 meses; diária só adianta o dado em até 6 dias |
| Instagram (~52) e Páginas (~54) | **Diária** (desde 21/10) | Manter ou voltar a semanal | Semanal economizaria ~2.800/mês | O dado social por execução é pequeno (0 a 9 posts por conta) |
| TikTok (14) | Semanal, terça 01:00 | Manter | Diária: ~+360 | — |
| GA4 (51) | Diária | Manter | — | — |
| RD Station (53) | Mista, diária e semanal | Padronizar por cliente conforme uso | — | Execuções longas em 02 e 03/11 (`f2o9` 189 min) sem causa |
| iClips (notebook) | Era a cada 4 h; **inativo** | **Decidir ao reativar**: 8 h ou 12 h | Voltar a 4 h custava ~3.300/mês; 8 h economiza ~1.650; 12 h ~2.200 | Com a social diária, **4 h estoura o limite** |
| `mysql-yIOn` (VJOB) | Domingo | Manter | — | Dado do VJOB é semanal por desenho |

**Antes de qualquer mudança:** (1) ler o consumo real em Billing; (2) o modelo de 15/10 supunha o notebook do iClips a cada 4 h e 60 fontes sociais semanais — hoje é o oposto (notebook parado, 108 fontes sociais diárias), então **o total atual não foi remedido**; (3) mudar cron de fonte publicada exige pedido explícito (R-002).

---

## 5. Frente 4 — Novas integrações

Conectores existentes na Nekt (verificado em 06/11) e fontes hoje (`list_resources`):

| Plataforma | Conector | Fontes hoje | Observação |
|---|---|---:|---|
| Google Search Console | `google-search-console` | 0 | Por propriedade; OAuth do dono do site |
| YouTube | `youtube` | 0 | OAuth do dono do canal |
| TikTok Ads | `tiktok-ads` | 0 | Contas de anúncio (3 no plano de 16/10); **Santo Remédio**: cuidado, conta bloqueada antes |
| LinkedIn Ads | `linkedin-ads` | 1 (`xiWu`, só a conta) | Identidade da conta a confirmar |
| Google Meu Negócio | `google-my-business` | 0 | Calendário da Gabriela: 26–29/10 (não cumprido como fonte) |
| Google Merchant Center | `google-merchant-center` | 0 | Só para clientes com Shopping/e-commerce |
| Google Sheets | `google-sheets` (origem e destino) | 0 | Útil para planilhas operacionais (checklists, squad) |
| Kwai, X, Threads, Snapchat | — | — | **Sem conector** (a Nekt prometeu avaliar o Kwai em 1 a 2 semanas a partir de 21/10, sem retorno por escrito) |

**Passos por integração** (a mesma esteira das fontes novas): rascunho com o que não é segredo → link de OAuth ao dono da conta → validar (lista de streams vazia = credencial sem acesso) → **confirmar o nome da camada com a Jussara (R-001, irreversível)** → publicar com cron e alerta de falha → aguardar a primeira execução agendada → `COUNT(*)` → Trusted, Refined e suíte própria. Cada fonte semanal custa ~4,35 créditos/mês.

**Falta levantar:** quais clientes têm Search Console, YouTube, Merchant Center e TikTok Ads; HubSpot, GA4 por propriedade e ActiveCampaign já têm levantamento próprio (`inventario-crm-analise-2026-10-15.xlsx`).

---

## 6. Cronograma proposto (para o Juarez), com marcos verificáveis

| Data (proposta) | Marco | Evidência |
|---|---|---|
| **Ter 10/11** | Google Ads: 1 fonte com sucesso e linhas novas; depois as demais, uma por vez | `list_pipeline_runs` + `MAX(_extraido_at)` de `trs_google_ads__insight_diario` > 22/10 |
| Qui 13/11 | Meta: 403 das 7 fontes com devolutiva do João (atribuir, aprovar ou descartar); `wRZ1` resolvida | Sucesso da fonte ou decisão registrada |
| Qui 13/11 | Arquivamento na interface: 17 rascunhos de RD duplicados, ex-clientes, `AMd2`, duplicatas `Xhmq`/`aikJ`/`nfih`/`i5u3` (**decisão da Jussara**) | Contagem de fontes na listagem |
| Seg 16/11 | Matriz de cobertura final entregue (Frente 2) com cobertura por gasto refeita | Planilha + cobertura Meta e Google |
| Qua 18/11 | Decisão de frequência (Frente 3) com o consumo real de Billing | Ata/tarefa |
| Ter 24/11 | Novas integrações (Frente 4): rascunhos criados e OAuth solicitados | Rascunhos na listagem |
| Dom 08/11 | Tarefas VJOB desta rodada visíveis no warehouse | `trs_vjob__job_tarefa` |

**Tarefas VJOB propostas (a criar por quem tem acesso; eu não escrevo no VJOB):**

1. Reautorizar as 43 fontes de Google Ads (João) — critério: sucesso **e** linhas novas.
2. Resolver os 403 da Meta: atribuições do Termo, Shizen e Santo Remédio (João).
3. `instagram-wRZ1` (Gabriela) — já aberta.
4. Arquivar rascunhos e duplicatas na interface da Nekt (Jussara, após aprovar a lista).
5. Chave nova do iClips e reativação em ordem (Jussara).
6. Matriz de cobertura final (Jussara).
7. Decisão de frequência com Billing (Jussara + Diretoria).
8. Levantamento de clientes para Search Console, YouTube, Merchant Center e TikTok Ads (analistas).

## 7. Decisões que dependem de quem manda

1. Aprovar a lista de arquivamento (rascunhos duplicados, duplicatas ativas, ex-clientes).
2. Cadência do notebook do iClips (4 h, 8 h ou 12 h) frente aos 9.000 créditos e à social diária.
3. Manter Instagram/Páginas diários ou voltar a semanal.
4. Prazo final a informar ao Juarez (as datas acima são proposta).
5. Pedir ao admin do MCC desvincular ou pausar as contas de ex-clientes que ainda gastam.

## 8. Segurança

Os logs de Google Ads, Páginas e Instagram trazem **token e client secret em claro na URL da exceção**: tratar como exposto, revisar quem acessa os logs e considerar rotação ao reautorizar. Nenhum desses valores foi copiado para este documento.
