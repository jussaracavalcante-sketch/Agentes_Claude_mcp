# Adendo à #1747 — situação das fontes de Google Ads em 05/11/2026

Resposta ao comentário da Jéssica (03/11, 14:15) no Job #1747. **Rascunho, não enviado.** Não refaz o relatório nem resolve as integrações: corrige a conclusão sobre o Google e documenta a pendência.

## 1. Texto para o comentário

> Jéssica, corrijo a conclusão sobre o Google. Nenhuma das 43 fontes de Google Ads teve a leitura retomada. A última execução válida de 42 delas foi em **22/10, entre 14:12 e 14:17** (a fonte `AMd2`, Santo Remédio, é de 22/09). Depois disso, todas as fontes ativas falharam: PmFB e x36N falharam de novo em 03/11 (PmFB às 08:16, com 4 falhas desde 22/10; x36N às 12:08, com 3), e as outras 37 ativas também falharam em 03/11. Três fontes da Unipar (`3eFc`, `mvUx`, `hBlk`) e a `AMd2` estão inativas. A causa lida no log de PmFB e x36N é a mesma: erro 401 `unauthorized_client` na renovação do token OAuth do Google. A reautorização de 28/10 não resolveu.
> O que isso muda no relatório: os 97,1% de cobertura de gasto do Google valem para o histórico de 13/09 a 12/10 e as leituras confirmadas valem até a execução de 22/10 (dado até 21/10). **A leitura corrente do Google é zero**: hoje o dado novo mais recente é de 21/10. A tabela por fonte e os encaminhamentos estão no adendo. Próxima passada agendada: terça 10/11.

## 2. O que muda nas conclusões do relatório (21/10) e do fechamento (29/10)

| Afirmação anterior | Situação em 05/11 |
|---|---|
| Google com 97,1% do gasto coberto (13/09 a 12/10) | Continua certo para essa janela, que é histórica. Não vale como leitura corrente. |
| 41 contas Google com leitura confirmada | Vale até a execução de 22/10. Nenhuma fonte teve sucesso depois. |
| Google: 43 publicadas, 42 com sucesso (posição de 21/10) | Hoje são **0 de 43** com a última execução em sucesso. |
| Dado do Google até 12/10 na comparação com o MCC | Dado novo chega até 21/10 e para aí; em 05/11 são 15 dias sem dado novo. |

Fora desse ponto, as medições de Meta, RD e demais sistemas não mudam com este adendo.

## 3. Situação por fonte (43 fontes)

**Leitura retomada: nenhuma.** Última execução válida: 22/10 (entre 14:12 e 14:17, horário de Brasília), exceto `AMd2` (22/09). "Dado na Trusted até" é a data mais recente com linha na tabela diária de insight, e em algumas contas ela é anterior por falta de veiculação, não por falha da extração. A tabela é lida de `trs_google_ads__insight_diario` (carga de 22/10).

| Cliente | Conta na plataforma | Fonte | Última execução com sucesso | Falhas desde então | Última falha | Dado na Trusted até | Situação |
|---|---|---|---|---:|---|---|---|
| ACESSO SAÚDE | ACESSO SAÚDE | `google-ads-cwt3` | 22/10 14:13 a 14:17 | 3 | 03/11 13:45 | 21/10/2026 | Ativa e falhando |
| AMAZONCOPY | Amazoncopy | `google-ads-fwxw` | 22/10 14:12 a 14:17 | 2 | 03/11 11:52 | 26/11/2025 | Ativa e falhando |
| AMZ GERADORES | AMZ Geradores | `google-ads-ZcMG` | 22/10 14:12 a 14:17 | 2 | 03/11 10:55 | 21/10/2026 | Ativa e falhando |
| ARENA TINTAS | Arena Tintas | `google-ads-x36N` | 22/10 14:12 a 14:17 | 3 | 03/11 12:08 | 21/10/2026 | Ativa e falhando |
| BA ELÉTRICA | CA - BA Elétrica | `google-ads-WxA8` | 22/10 14:12 a 14:17 | 2 | 03/11 12:15 | 21/10/2026 | Ativa e falhando |
| BIGAZINE | Bigazine | `google-ads-dMx7` | 22/10 14:12 a 14:17 | 2 | 03/11 12:01 | 21/10/2026 | Ativa e falhando |
| BRAGA ACESSÓRIOS | Braga Acessórios | `google-ads-6Z2v` | 22/10 14:12 a 14:17 | 2 | 03/11 08:47 | 21/10/2026 | Ativa e falhando |
| BRAGA MINI | BRAGA MOTORS - MINI | `google-ads-RCRU` | 22/10 14:12 a 14:16 | 2 | 03/11 09:05 | 21/10/2026 | Ativa e falhando |
| BRAGA MOTORRAD | MOTO BMW | BRAGA MOTORS - MOTORRAD | `google-ads-VozJ` | 22/10 14:12 a 14:17 | 2 | 03/11 09:12 | 21/10/2026 | Ativa e falhando |
| BRAGA MOTORS BMW | BRAGA VEICULOS LTDA | `google-ads-cFrH` | 22/10 14:12 a 14:17 | 2 | 03/11 09:21 | 21/10/2026 | Ativa e falhando |
| BRAGA PÓS VENDAS | BRAGA VEÍCULOS PÓS VENDAS | `google-ads-PsES` | 22/10 14:12 a 14:16 | 2 | 03/11 08:55 | 23/07/2026 | Ativa e falhando |
| BRAGA VAREJO | Braga Motomarcas | `google-ads-PmFB` | 22/10 14:12 a 14:17 | 4 | 03/11 08:16 | 30/08/2025 | Ativa e falhando |
| BRAGA YAMAHA | Braga Motos | `google-ads-Pk69` | 22/10 14:12 a 14:17 | 2 | 03/11 08:31 | 21/10/2026 | Ativa e falhando |
| BRAGA YAMAHA CONSÓRCIOS | Braga Consórcio | `google-ads-5J1y` | 22/10 14:12 a 14:17 | 2 | 03/11 08:24 | 21/10/2026 | Ativa e falhando |
| CAA ALUMÍNIO | CAA - ALUMINIO | `google-ads-A1kM` | 22/10 14:12 a 14:17 | 2 | 03/11 09:43 | 21/10/2026 | Ativa e falhando |
| CAA TINTAS | CAA Tintas | `google-ads-mEnk` | 22/10 14:12 a 14:17 | 2 | 03/11 09:36 | 21/10/2026 | Ativa e falhando |
| COLMEIA | CONSTRUTORA COLMEIA S/A | `google-ads-R4be` | 22/10 14:12 a 14:17 | 2 | 03/11 11:44 | 21/10/2026 | Ativa e falhando |
| CONSTRÓI INCORPORADORA | Constrói Construtora | `google-ads-jT4J` | 22/10 14:12 a 14:17 | 2 | 03/11 11:28 | 21/10/2026 | Ativa e falhando |
| DEB TRANSPORTADORA | DEB Transportes | `google-ads-C4Aq` | 22/10 14:12 a 14:17 | 2 | 03/11 10:01 | 01/10/2026 | Ativa e falhando |
| DMELLO (TEMPO DAS TINTAS) | Dmello Tempo das Tintas | `google-ads-URNQ` | 22/10 14:12 a 14:17 | 2 | 03/11 09:27 | 24/08/2026 | Ativa e falhando |
| DOCTOR MAIS | Doctor Mais | `google-ads-ABUl` | 22/10 14:12 a 14:17 | 2 | 03/11 11:36 | 21/10/2026 | Ativa e falhando |
| DON WATCHES (conta 1) | Don Watches - Ativa | `google-ads-vE2C` | 22/10 14:13 a 14:16 | 2 | 03/11 13:19 | tabela semanal (Prestex) | Ativa e falhando |
| DON WATCHES (conta 2) | Don Watches - Ativa Validada | `google-ads-QuKh` | 22/10 14:12 a 14:17 | 2 | 03/11 13:12 | 22/08/2026 | Ativa e falhando |
| DR. CABRAL (conta 1) | Dr. Cabral | `google-ads-wypN` | 22/10 14:12 a 14:16 | 2 | 03/11 11:05 | tabela semanal (Prestex) | Ativa e falhando |
| HOSPITAL SANTA JÚLIA | HOSPITAL SANTA JULIA | `google-ads-rSav` | 22/10 14:12 a 14:17 | 2 | 03/11 11:19 | 21/10/2026 | Ativa e falhando |
| MILLENIUM | Millennium Shopping | `google-ads-GZ55` | 22/10 14:12 a 14:17 | 2 | 03/11 10:24 | 21/10/2026 | Ativa e falhando |
| MOVE RENTAL CARS | Move Rental Cars | `google-ads-vfUV` | 22/10 14:12 a 14:17 | 2 | 03/11 13:28 | 21/10/2026 | Ativa e falhando |
| OLÁ CASA NOVA | Olá Empreendimentos | `google-ads-DzVL` | 22/10 14:13 a 14:17 | 3 | 03/11 13:36 | 21/10/2026 | Ativa e falhando |
| PMZ ESCOLA DE MECÂNICOS | Escola PMZ | `google-ads-PdSr` | 22/10 14:12 a 14:17 | 2 | 03/11 12:41 | 21/10/2026 | Ativa e falhando |
| PMZ GRUPO ECOMM | PMZ ECOMM | `google-ads-Llsu` | 22/10 14:12 a 14:17 | 2 | 03/11 12:24 | 21/10/2026 | Ativa e falhando |
| PMZ GRUPO LOJA | PMZ | `google-ads-NP4k` | 22/10 14:12 a 14:17 | 2 | 03/11 12:32 | 21/10/2026 | Ativa e falhando |
| PNEU EXPRESS | Pneu Forte l Pneu Express | `google-ads-802k` | 22/10 14:12 a 14:17 | 2 | 03/11 10:32 | 21/10/2026 | Ativa e falhando |
| PNEU FORTE DISTRIBUIDORA | Pneu Forte | Distribuidora | `google-ads-0B2k` | 22/10 14:12 a 14:17 | 2 | 03/11 10:16 | 21/10/2026 | Ativa e falhando |
| PRESTEX | Prestex | `google-ads-OzfZ` | 22/10 14:12 a 14:17 | 2 | 03/11 02:02 | tabela semanal (Prestex) | Ativa e falhando |
| REI DAS MANGUEIRAS | Rei das Mangueiras | `google-ads-PnyV` | 22/10 14:12 a 14:17 | 2 | 03/11 10:08 | 21/10/2026 | Ativa e falhando |
| RODRIX | RODRIX MOTOS | `google-ads-rYKp` | 22/10 14:12 a 14:17 | 2 | 03/11 09:53 | 21/10/2026 | Ativa e falhando |
| ROYAL ENFIELD | ROYAL ENFIELD | `google-ads-SyTu` | 22/10 14:12 a 14:16 | 2 | 03/11 08:40 | 21/10/2026 | Ativa e falhando |
| SANTO REMÉDIO | SANTO REMÉDIO VNG | `google-ads-AMd2` | 22/09 11:11 a 11:15 | 2 | 29/09 11:26 | 16/07/2025 | Inativa; conta saiu do MCC (stand-by) |
| SMILE PNEUS | Pneu Forte l Smile Pneus | `google-ads-Jl1R` | 22/10 14:12 a 14:17 | 2 | 03/11 10:39 | 21/10/2026 | Ativa e falhando |
| STEEL PORT | Steel Port Am | `google-ads-x20o` | 22/10 14:12 a 14:17 | 2 | 03/11 10:48 | 27/03/2026 | Ativa e falhando |
| UNIPAR | Boa Vista | `google-ads-3eFc` | 22/10 14:12 a 14:17 | 3 | 25/10 12:48 | 21/10/2026 | Inativa (Nekt desativou por falhas seguidas) |
| UNIPAR | Parque das Torres | `google-ads-hBlk` | 22/10 14:12 a 14:16 | 3 | 25/10 13:05 | 21/10/2026 | Inativa (Nekt desativou por falhas seguidas) |
| UNIPAR | Neo Vila | `google-ads-mvUx` | 22/10 14:12 a 14:17 | 3 | 25/10 12:56 | 21/10/2026 | Inativa (Nekt desativou por falhas seguidas) |

Resumo: 39 ativas e falhando (todas com a última falha em 03/11), 4 inativas (Unipar ×3 desde 25/10 e `AMd2`). Contas sem dado recente por falta de veiculação, não por extração: `PmFB` (Braga Varejo, dado até 30/08/2025), `fwxw` (26/11/2025), `x20o` (27/03/2026), `PsES` (23/07/2026), `QuKh` (22/08/2026), `URNQ` (24/08/2026) e `C4Aq` (01/10/2026).

## 4. Encaminhamentos atualizados (proposta; nenhum enviado)

| # | Ação | Responsável | Observação |
|---|---|---|---|
| 1 | Refazer a autorização com o usuário Google que administra o MCC Vanguarda, informando qual usuário e qual aplicativo OAuth foram usados em 28/10 | Administrador do MCC Google (nome a confirmar; João Araújo é ADMIN) | A reautorização de 28/10 zerou o aviso do conector, mas não resolveu: o 401 persiste |
| 2 | Testar em **uma** fonte (piloto: `PmFB`) antes de reautorizar as demais | Head de IA, depois da ação 1 | Disparo manual em massa estoura a cota do desenvolvedor (07/10 e 14/10) |
| 3 | Unipar (`3eFc`, `mvUx`, `hBlk`): reautorizar com usuário com acesso ao MCC do Grupo Unipar (7749545148) e reativar a fonte | Administrador do MCC do cliente | A Nekt não executa fonte desativada |
| 4 | Santo Remédio (`AMd2`, conta 281-904-4460): sem ação; stand-by. A conta viva (513-801-6841) só se o João confirmar | João Araújo | E-mail do João de 30/09 |
| 5 | Prestex (`OzfZ`): entra na mesma reautorização; granularidade semanal | Administrador do MCC Google | |
| 6 | Abrir chamado no suporte da Nekt: os logs de erro expõem token e segredo em texto claro | Head de IA | Reconexões com credenciais novas |
| 7 | Conferir a passada de terça (10/11) e reabrir o indicador de cobertura quando houver o primeiro sucesso | Head de IA | Antes disso o indicador corrente do Google fica em zero |

## 5. Limites

- O histórico de execução lido traz as 10 últimas de cada fonte; o último sucesso de todas está dentro delas.
- A causa (401 `unauthorized_client`) foi lida no log de duas fontes (PmFB e x36N, 03/11); as outras 41 seguem o mesmo padrão por inferência, e o log de 3 fontes já havia sido lido em 27/10.
- O gasto Google do MCC não foi refeito; as coberturas em reais do relatório continuam sendo as medidas até 21/10.
- Nomes de responsáveis e ações são proposta; o administrador do MCC Google segue sem nome.
