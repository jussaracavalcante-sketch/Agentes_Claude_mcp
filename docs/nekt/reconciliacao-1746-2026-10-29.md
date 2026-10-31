# Tarefa #1746 — referência reconciliada com o relatório de 25/10 (posição de 29/10/2026)

Base de comparação: `relatorio-conferencia-integracoes-2026-10-25.pdf` (Drive). Verificação de 29/10 por histórico de execução (`list_pipeline_runs`) e `COUNT(*)` nas tabelas. Nada foi disparado, alterado, arquivado ou excluído.

## 1. Status: 25/10 contra 29/10

| plataforma | 25/10 | 29/10 | mudou |
|---|---|---|---|
| Meta Ads | 63 ativas, 54 lendo, 6 sem linha, 3 falhando (+2 fora do Termo) | 81 publicadas: 73 sucesso, 8 falha (`xDLw`, `qy0W`, `geQA` ativas; `XuHY`, `bhnp`, `OJi6`, `KUkx`, `f6h8` inativas) | `tWIP` e `bU6W` recuperaram em 27/10 e entraram nas Trusted (66 contas). `flYR`, `gp7f`, `7vwE` (ex-clientes) foram arquivadas. As ativas com 3+ falhas seguidas continuam ativas |
| Google Ads | 37 lendo (até 22/10), reautorização vencida | **0 de 43 com sucesso.** `401 unauthorized_client` desde 27/10; a reautorização de 28/10 não valeu em 2 testes (`PmFB`, `x36N`) | **piorou.** Trusted e Refined só têm histórico até 21–22/10 |
| Instagram | 55 lendo | 58 contas na Trusted, 56 fontes com sucesso (`wRZ1` inativa, 400) | sem perda |
| Páginas do Facebook | 56 lendo | 57 páginas na Trusted, 54 com sucesso e 6 falhas em 28/10 (`400 (#12) genre field is deprecated`) | 5 a 6 falhas novas |
| TikTok | 5, manual | 14 fontes, agendadas (terça 01:00), 1.379 vídeos, suíte 19/19 | **melhorou** |
| RD Station | 52, 49 lendo | 52 de 53 com sucesso (`YLIU` inativa); **sem a CDL (`YLIU`) e as cópias da Vanguarda (`1eaJ`, `bjQx`): 50 fontes, 50 com sucesso** | igual |
| GA4 | 51, 45 lendo | 51 com sucesso, 45 com dado | igual. Defeito de duplicação de dia corrigido em 29/10 (suíte 40/40) |
| iClips (apoio) | não citado | chave inválida, notebook e 2 fontes inativos desde 19–22/10 | **novo bloqueio** |
| Qualidade | 607/610 (23/10) | 42 suítes, 1.631 de 1.631 conformes (29/10). Principal e iClips com carga de 19/10; mídia/Google com carga de 23/10 | todas as falhas de 25–28/10 fechadas |

## 2. Contas validadas com leitura de dados

Lista conta a conta: aba Contas de `inventario-fontes-1747-2026-10-21.xlsx`, sem a CDL e sem as duas contas próprias da Vanguarda (Meta `AJ09`, Google 750-265-3880): **204 contas aplicáveis, 157 com leitura confirmada** (eram 209 e 159). Verificação contra a plataforma:

- **Meta:** relida em 21/10, 66 contas em reais, 48 com gasto, todas dentro de 1% (R$ 70.298,30 na Nekt contra R$ 70.319,03 na Meta, maior diferença R$ 6,06). Cobertura por gasto 64,0% em 13–19/10.
- **Google:** conferido contra o MCC em 16/10, 34 contas, todas dentro de 1% (R$ 90.422,37 contra R$ 90.423,09; nenhuma das duas contas retiradas fazia parte dessa comparação). **A leitura parou em 22/10; a validação vale até essa data.**
- **RD:** sem referência independente; vale "dado presente" (277.001 contatos em 29/10; a CDL e as cópias da Vanguarda saem da conta).
- **TikTok:** 14 perfis conferidos pelo `username`; 13 com vídeos.

## 3. Exceções, motivo, responsável e próximo passo

| exceção | motivo | responsável (proposta) | próximo passo |
|---|---|---|---|
| 43 fontes Google Ads | `401 unauthorized_client` na renovação do OAuth; reautorização de 28/10 não valeu | admin do MCC Google (a designar; João Araújo é ADMIN desde 02/07) | reabrir os links, reautorizar e testar uma fonte por vez (cota do desenvolvedor) |
| Meta `xDLw`, `qy0W` | 403 `ads_read`; contas fora do Business da agência | João Araújo | atribuir as contas ao Business da agência |
| Meta `geQA` | 403; a agência lê a conta, o usuário da Nekt não | João Araújo | atribuir ao usuário que autorizou a Nekt; confirmar se o e-mail de 30/09 do Santo Remédio vale para Meta |
| Meta `KUkx`, `OJi6` (Shizen) | 403; depende de aprovação do cliente | João Araújo | aguardar o cliente; maior lacuna de gasto (R$ 32.461,07 em 30 dias, lido em 21/10) |
| Meta `f6h8` (Santo Remédio Reserva Nova) | 403, conta desabilitada na Meta | João Araújo | decidir se segue no escopo |
| Meta 7 fontes com 0 linhas | conta sem veiculação ou limite esgotado (medido em 15/10) | João e analistas | confirmar veiculação; aceitar zero ou arquivar |
| Páginas 6 falhas (`genre` deprecated) | API v24 | Jussara / Gabriela | corrigir stream; depende de decisão sobre mexer em fonte publicada (R-002) |
| iClips | API key inválida | Jussara (troca na interface da Nekt) | renovar a chave; reativar notebook |
| GA4 5 propriedades vazias, RD `socq`, BAJAJ | tag ou conta sem dado | Bruna Lima e analistas Inbound | confirmar com o cliente |
| GitHub, Z-API | rodam, 0 linhas | Jussara | credencial e repositórios (GitHub); URL e `x-api-key` na instância (Z-API) |

## 4. Lista de clientes aplicáveis com a Bruna e HubSpot

- **Lista de clientes aplicáveis: já está no Drive.** Aba "RD e GA4" de `consolidado-contas-plataformas-2026-10-23.xlsx` (Drive), cruzada com a planilha "DIVISÃO DE CLIENTE POR SQUAD" (60 clientes na aba vigente): cada fonte de RD traz o analista Inbound do squad. Posição de 23/10, **sem a CDL e sem as cópias da Vanguarda**: RD 50 fontes, 50 conectadas, nenhuma pendente (saíram `YLIU`, `1eaJ` e `bjQx`, que eram as 3 pendentes); GA4 51 fontes, 45 conectadas, 5 pendentes (propriedades sem dado: `Sg96`, `Yi7s`, `eTRF`, `lBA2`, `rT4R`) e 1 não manter (`i5u3`, duplicata de `bLbp`). O GA4 não tem coluna de analista. O que continua com a Bruna no item SOL-07 do cronograma: validar e publicar o rascunho `O2oe` (Braga Motos Yamaha) e confirmar as 5 propriedades GA4.
- **HubSpot: nenhuma conta no escopo.** Zero fontes `hubspot` na Nekt (conferido em 29/10), nenhuma menção a HubSpot no consolidado de 23/10, no checklist de redes sociais nem na planilha de squad. **Conclusão a registrar:** sem contas HubSpot no escopo. Reabre se a Bruna indicar algum cliente.
