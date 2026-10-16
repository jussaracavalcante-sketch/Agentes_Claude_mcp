# -*- coding: utf-8 -*-
"""VAN-FOR-SGQ-001 - Formulario de Mapeamento de Processos por Setor.
A estrutura espelha as 16 secoes obrigatorias do POP (SGQ Vanguarda VAN-QUAL-001)."""
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.utils import get_column_letter

COD, VER, DATA = "VAN-FOR-SGQ-001", "1.0", "11/09/2026"
AZUL, AZUL2, CINZA, AMAREL, VERDE = "1F2D5C", "2E75B6", "F2F2F2", "FFF3CD", "E8F3EC"
BORDA = Border(*[Side(style="thin", color="BFBFBF")]*4)
F_TIT  = Font(name="Arial", size=14, bold=True, color=AZUL)
F_SUB  = Font(name="Arial", size=9,  color="595959")
F_HDR  = Font(name="Arial", size=9,  bold=True, color="FFFFFF")
F_TXT  = Font(name="Arial", size=10)
F_EX   = Font(name="Arial", size=9,  italic=True, color="7F6000")
F_CALC = Font(name="Arial", size=10, bold=True, color="1F4E2C")
F_B    = Font(name="Arial", size=10, bold=True)

SETORES = [
 ("Mídia Paga","Mídia Paga","MKT","MID",""),
 ("Inbound","Inbound","MKT","INB",""),
 ("Account","Account (Atendimento)","COM","ACC",""),
 ("Criação","Criação","MKT","CRI",""),
 ("Direção de Arte","Direção de Arte","MKT","ART",""),
 ("Dir. Operações","Diretoria de Operações","OPS","OPE",""),
 ("RH","Recursos Humanos","RH","RHU",""),
 ("Dir. Executiva","Diretoria Executiva","GOV*","DEX","codigo GOV proposto"),
 ("Social Media","Social Media","MKT","SOC",""),
 ("Financeiro","Financeiro / Controladoria","FIN","FIN",""),
 ("Planej. Estrat. e Inovação","Planejamento, Estratégia e Inovação","EST*","PEI","codigo EST proposto"),
]
COLS = [
 ("Código do Processo",16,1,"Cabeçalho"),("Nome do Processo",30,1,"Cabeçalho"),
 ("Objetivo (1 a 2 frases)",42,1,"§1 Objetivo"),("Escopo — o que o processo cobre",38,1,"§2 Escopo"),
 ("NÃO está no escopo",32,1,"§2 Escopo"),("Entidades aplicáveis",22,1,"§2 Escopo"),
 ("Gestor do Processo (cargo)",24,1,"Cabeçalho"),("Executor principal (cargo)",24,1,"§5 RACI"),
 ("Aprovador (cargo)",22,1,"§5 RACI"),("Fornecedores — de quem recebe",28,1,"§6 SIPOC"),
 ("Entradas — o que recebe",30,1,"§6 SIPOC"),("Saídas — o que entrega",30,1,"§6 SIPOC"),
 ("Clientes — quem recebe a saída",28,1,"§6 SIPOC"),("Sistemas e ferramentas",26,1,"§7 Recursos"),
 ("Documentos de referência",26,0,"§7 Recursos"),("Competências necessárias",28,0,"§8 Competências"),
 ("Treinamentos obrigatórios",26,0,"§8 Competências"),("Frequência de execução",20,1,"§9 Processo"),
 ("Volume médio mensal",16,0,"§10 KPIs"),("Registros e evidências gerados",30,1,"§14 Registros"),
 ("Local de armazenamento",24,1,"§14 Registros"),("Retenção",16,0,"§14 Registros"),
 ("Envolve pagamento ou compromisso financeiro?",20,1,"§5 RACI"),
 ("Prioridade para redação do POP",18,1,"Planejamento"),("Preenchido por",20,1,"Controle"),
 ("Data do preenchimento",16,1,"Controle"),("Status",16,1,"Controle"),
]
EXEMPLO = ["MKT.MID.01","Veiculação de campanha de mídia paga",
 "Padronizar o planejamento, a veiculação e a conferência de campanhas de mídia paga, garantindo rastreabilidade da verba e do resultado.",
 "Do briefing aprovado até o relatório de fechamento da campanha.",
 "Negociação comercial com o cliente; emissão de nota fiscal.","Vanguarda Martech",
 "Supervisor de Mídia Paga","Analista de Mídia Paga","Diretoria de Operações",
 "Account; Planejamento","Briefing aprovado; verba liberada; peças aprovadas",
 "Campanha veiculada; relatório de performance","Account; Cliente",
 "Google Ads; Meta Ads; Nekt; Power BI","VAN-POP-FIN-004 (Controle de Verbas de Impulsionamento)",
 "Gestão de campanhas; leitura de métricas; Excel intermediário","Google Ads Certification; LGPD",
 "Diária",45,"Print de veiculação; relatório mensal; PI assinado","Google Drive — SGQ/Mídia",
 "5 anos","Sim","Alta","(quem preencheu)","11/09/2026","Não iniciado"]
LISTAS = {
 "Entidades":["Vanguarda Martech","VPromo","VBOT","Vanguarda Martech e VPromo","Todas"],
 "Frequencia":["Sob demanda","Diária","Semanal","Quinzenal","Mensal","Trimestral","Semestral","Anual"],
 "Retencao":["2 anos","3 anos","5 anos","Permanente"],"SimNao":["Sim","Não"],
 "Prioridade":["Alta","Média","Baixa"],
 "Status":["Não iniciado","Em preenchimento","Preenchido","Validado pela Qualidade"],
 "SLA":["Imediato","15 min","1 hora","D+1","D+2","Semanal","Mensal"],"RACI":["R","A","C","I"],
 "COSO":["Estratégico","Operacional","Financeiro","Compliance","Governance"],
 "Escala13":[1,2,3],"Eficacia":["Alta","Média","Baixa"],"Setores":[s[1] for s in SETORES],
}
HDR_ROW, DATA_ROW, NLIN, NDET = 7, 8, 60, 200
wb = Workbook(); wb.remove(wb.active)

def cabecalho(ws, titulo, sub, ncols, legenda=None):
    n = min(ncols, 12)
    for r,(v,f) in enumerate([(titulo,F_TIT),
        (f"{COD}  |  Versão {VER}  |  Emissão {DATA}  |  SGQ Vanguarda (VAN-QUAL-001)  |  CONFIDENCIAL",F_SUB),
        (sub,F_SUB)], start=1):
        ws.merge_cells(start_row=r,start_column=1,end_row=r,end_column=n)
        ws.cell(row=r,column=1,value=v).font=f
    ws.merge_cells(start_row=5,start_column=1,end_row=5,end_column=n)
    lg = ws.cell(row=5,column=1, value=legenda or
        "COMO PREENCHER: escreva a partir da linha 9. A linha 8, em amarelo, é EXEMPLO — apague-a ou sobrescreva-a. "
        "Colunas com (*) são obrigatórias. Células em verde são calculadas automaticamente: não digite nelas.")
    lg.font=Font(name="Arial",size=9,bold=True,color="1F4E2C")
    lg.fill=PatternFill("solid",fgColor=VERDE); lg.alignment=Alignment(wrap_text=True,vertical="center")
    ws.row_dimensions[5].height=30

def headers(ws, cols):
    for i,(nome,larg,obr,sec) in enumerate(cols,start=1):
        c=ws.cell(row=HDR_ROW,column=i,value=(nome+" *") if obr else nome)
        c.font=F_HDR; c.fill=PatternFill("solid",fgColor=AZUL); c.border=BORDA
        c.alignment=Alignment(wrap_text=True,vertical="center",horizontal="center")
        ws.column_dimensions[get_column_letter(i)].width=larg
        if sec:
            s=ws.cell(row=HDR_ROW-1,column=i,value=sec)
            s.font=Font(name="Arial",size=7,italic=True,color="7F7F7F")
            s.alignment=Alignment(horizontal="center")
    ws.row_dimensions[HDR_ROW].height=42
    ws.freeze_panes=ws.cell(row=DATA_ROW,column=3)

def grade(ws,ncols,nlin,calc_cols=()):
    for r in range(DATA_ROW,DATA_ROW+nlin):
        for c in range(1,ncols+1):
            cel=ws.cell(row=r,column=c); cel.border=BORDA
            cel.alignment=Alignment(wrap_text=True,vertical="top")
            if c in calc_cols:
                cel.fill=PatternFill("solid",fgColor=VERDE); cel.font=F_CALC
                cel.alignment=Alignment(horizontal="center",vertical="center")
            elif r==DATA_ROW:
                cel.fill=PatternFill("solid",fgColor=AMAREL); cel.font=F_EX
            else:
                cel.font=F_TXT
                if (r-DATA_ROW)%2==1: cel.fill=PatternFill("solid",fgColor=CINZA)
        ws.row_dimensions[r].height=30

# ---------- LISTAS ----------
wsL=wb.create_sheet("Listas")
wsL.cell(row=1,column=1,value="Listas de validação — VAN-FOR-SGQ-001").font=F_TIT
wsL.cell(row=2,column=1,value="Não editar sem avisar a Gestão da Qualidade: estas colunas alimentam os menus suspensos de todas as abas.").font=F_SUB
COLL={}
for i,(nome,vals) in enumerate(LISTAS.items(),start=1):
    L=get_column_letter(i); COLL[nome]=(L,len(vals))
    h=wsL.cell(row=4,column=i,value=nome); h.font=F_HDR
    h.fill=PatternFill("solid",fgColor=AZUL2); h.border=BORDA
    wsL.column_dimensions[L].width=26
    for j,v in enumerate(vals,start=5):
        c=wsL.cell(row=j,column=i,value=v); c.font=F_TXT; c.border=BORDA

def dv(ws,lista,col,nlin):
    L,n=COLL[lista]
    d=DataValidation(type="list",formula1=f"=Listas!${L}$5:${L}${4+n}",allow_blank=True)
    ws.add_data_validation(d); d.add(f"{col}{DATA_ROW}:{col}{DATA_ROW+nlin-1}")

# ---------- ABAS DE SETOR ----------
NC=len(COLS)
for aba,nome,area,pref,obs in SETORES:
    ws=wb.create_sheet(aba)
    sub=f"Setor: {nome}   |   Código de área SGQ: {area}   |   Prefixo dos processos: {pref}.NN"
    if obs: sub += f"   |   ATENÇÃO: {obs}, pendente de validação da Qualidade"
    cabecalho(ws,f"Mapeamento de Processos — {nome}",sub,NC)
    headers(ws,COLS); grade(ws,NC,NLIN)
    for i,v in enumerate(EXEMPLO,start=1):
        ws.cell(row=DATA_ROW,column=i,value=v)
    ws.cell(row=DATA_ROW,column=1,value=f"{pref}.01")
    for lista,col in [("Entidades","F"),("Frequencia","R"),("Retencao","V"),
                      ("SimNao","W"),("Prioridade","X"),("Status","AA")]:
        dv(ws,lista,col,NLIN)

# ---------- ETAPAS (§9.1) ----------
ETP=[("Setor",26,1,""),("Código do Processo",16,1,""),("Trilho / Sistema",18,0,"iClips, Conexa, etc."),
 ("Nº da etapa",10,1,""),("Descrição da etapa",46,1,"o que é feito"),("Responsável (cargo)",24,1,""),
 ("Ferramenta / Sistema",22,1,""),("Evidência gerada",26,1,""),("SLA",14,1,""),
 ("É ponto de decisão?",14,1,"vira gateway no BPMN"),("Condição da decisão",28,0,"se sim")]
ws=wb.create_sheet("Etapas")
cabecalho(ws,"Etapas dos Processos (§9.1 e fluxo BPMN)",
 "Uma linha por etapa. As etapas viram a descrição detalhada do POP e os elementos do diagrama BPMN — ordem e responsável definem as raias.",len(ETP))
headers(ws,ETP); grade(ws,len(ETP),NDET)
for i,v in enumerate(["Mídia Paga","MID.01","Google Ads",1,"Receber briefing aprovado e conferir verba liberada",
 "Analista de Mídia Paga","Nekt / Google Ads","Briefing assinado","D+1","Não",""],start=1):
    ws.cell(row=DATA_ROW,column=i,value=v)
for lista,col in [("Setores","A"),("SLA","I"),("SimNao","J")]: dv(ws,lista,col,NDET)

# ---------- RACI (§5) ----------
RAC=[("Setor",26,1,""),("Código do Processo",16,1,""),("Atividade",44,1,""),
 ("Papel / Cargo",26,1,""),("Classificação",14,1,"R, A, C ou I"),("Observação",30,0,"")]
ws=wb.create_sheet("RACI")
cabecalho(ws,"Matriz de Responsabilidades — RACI (§5)",
 "Uma linha por par atividade × papel. R = Responsável (executa) | A = Aprovador | C = Consultado | I = Informado. "
 "REGRA DE OURO DO SGQ: atividade que envolve pagamento ou compromisso financeiro tem obrigatoriamente o CEO como A.",len(RAC))
headers(ws,RAC); grade(ws,len(RAC),NDET)
for i,v in enumerate(["Mídia Paga","MID.01","Aprovar verba da campanha","CEO — Breno Maciel","A",
 "Obrigatório: a atividade envolve compromisso financeiro"],start=1):
    ws.cell(row=DATA_ROW,column=i,value=v)
for lista,col in [("Setores","A"),("RACI","E")]: dv(ws,lista,col,NDET)

# ---------- KPIs (§10) ----------
KPI=[("Setor",26,1,""),("Código do Processo",16,1,""),("Indicador",30,1,""),
 ("Fórmula / Métrica",38,1,"como se calcula"),("Meta numérica",14,1,""),("Unidade",12,1,"%, R$, dias, un."),
 ("Frequência",16,1,""),("Responsável",24,1,""),("Ritual de acompanhamento",28,1,"onde é revisado")]
ws=wb.create_sheet("KPIs")
cabecalho(ws,"Indicadores de Desempenho (§10)",
 "Mínimo de 5 indicadores por processo, conforme o SGQ. Meta precisa ser número, não adjetivo: '95%' serve, 'alta' não.",len(KPI))
headers(ws,KPI); grade(ws,len(KPI),NDET)
for i,v in enumerate(["Mídia Paga","MID.01","Aderência da verba veiculada",
 "(verba veiculada ÷ verba aprovada) × 100",95,"%","Mensal","Supervisor de Mídia Paga",
 "Reunião mensal de operações"],start=1):
    ws.cell(row=DATA_ROW,column=i,value=v)
for lista,col in [("Setores","A"),("Frequencia","G")]: dv(ws,lista,col,NDET)

# ---------- RISCOS (§11 COSO ERM) ----------
RIS=[("Setor",26,1,""),("Código do Processo",16,1,""),("Nº",8,1,""),("Risco",40,1,""),
 ("Categoria COSO",18,1,""),("Probabilidade (1-3)",12,1,""),("Impacto (1-3)",12,1,""),
 ("NR (P×I)",10,0,"calculado"),("Classificação",18,0,"calculado"),
 ("Controle existente",32,1,""),("Eficácia",12,1,"Alta/Média/Baixa"),("Plano de ação",34,1,"")]
ws=wb.create_sheet("Riscos")
cabecalho(ws,"Riscos do Processo — COSO ERM (§11)",
 "Mínimo de 5 riscos por processo. NR e Classificação são calculados: NR ≥ 6 exige ação imediata, 4 a 5 monitoramento, até 3 aceitável.",len(RIS))
headers(ws,RIS); grade(ws,len(RIS),NDET,calc_cols=(8,9))
for i,v in enumerate(["Mídia Paga","MID.01",1,"Verba veiculada acima do aprovado sem aditivo",
 "Financeiro",2,3,None,None,"Conferência semanal do painel de verba","Média",
 "Automatizar alerta de estouro na Nekt"],start=1):
    if v is not None: ws.cell(row=DATA_ROW,column=i,value=v)
for r in range(DATA_ROW,DATA_ROW+NDET):
    ws.cell(row=r,column=8,value=f'=IF(OR($F{r}="",$G{r}=""),"",$F{r}*$G{r})')
    ws.cell(row=r,column=9,value=f'=IF($H{r}="","",IF($H{r}>=6,"Ação imediata",IF($H{r}>=4,"Monitoramento","Aceitável")))')
for lista,col in [("Setores","A"),("COSO","E"),("Escala13","F"),("Escala13","G"),("Eficacia","K")]:
    dv(ws,lista,col,NDET)

# ---------- CONSOLIDADO ----------
CON=[("Setor",30,0,""),("Aba",26,0,""),("Código de área",14,0,""),("Processos mapeados",14,0,"calculado"),
 ("Etapas",10,0,"calculado"),("Linhas RACI",12,0,"calculado"),("KPIs",10,0,"calculado"),
 ("Riscos",10,0,"calculado"),("Riscos NR ≥ 6",12,0,"calculado"),("Pronto para POP?",18,0,"calculado")]
ws=wb.create_sheet("Consolidado")
cabecalho(ws,"Consolidado do Levantamento",
 "Atualiza sozinho conforme os setores preenchem. 'Pronto para POP' exige ao menos 1 processo, 3 etapas, 5 KPIs e 5 riscos — os mínimos do SGQ.",
 len(CON),legenda="ESTA ABA É TODA CALCULADA. Não digite nada aqui — os números vêm das abas dos setores.")
headers(ws,CON); grade(ws,len(CON),len(SETORES)+1,calc_cols=(4,5,6,7,8,9,10))
for k,(aba,nome,area,pref,obs) in enumerate(SETORES):
    r=DATA_ROW+k
    ws.cell(row=r,column=1,value=nome).font=F_B
    ws.cell(row=r,column=1).fill=PatternFill("solid",fgColor="FFFFFF")
    ws.cell(row=r,column=1).alignment=Alignment(vertical="center")
    for col,val in [(2,aba),(3,area)]:
        c=ws.cell(row=r,column=col,value=val); c.font=F_TXT
        c.fill=PatternFill("solid",fgColor="FFFFFF"); c.alignment=Alignment(vertical="center")
    q=f"'{aba}'"
    ws.cell(row=r,column=4,value=f'=COUNTIF({q}!$B${DATA_ROW+1}:$B${DATA_ROW+NLIN-1},"?*")')
    for col,sheet in [(5,"Etapas"),(6,"RACI"),(7,"KPIs"),(8,"Riscos")]:
        ws.cell(row=r,column=col,
            value=f'=COUNTIFS({sheet}!$A${DATA_ROW+1}:$A${DATA_ROW+NDET-1},$A{r})')
    ws.cell(row=r,column=9,
        value=f'=COUNTIFS(Riscos!$A${DATA_ROW+1}:$A${DATA_ROW+NDET-1},$A{r},Riscos!$H${DATA_ROW+1}:$H${DATA_ROW+NDET-1},">=6")')
    ws.cell(row=r,column=10,
        value=f'=IF(AND($D{r}>=1,$E{r}>=3,$G{r}>=5,$H{r}>=5),"Sim","Faltam itens")')
rt=DATA_ROW+len(SETORES)
ws.cell(row=rt,column=1,value="TOTAL").font=F_B
ws.cell(row=rt,column=1).fill=PatternFill("solid",fgColor=CINZA)
for col in range(2,4):
    ws.cell(row=rt,column=col).fill=PatternFill("solid",fgColor=CINZA)
for col in range(4,10):
    L=get_column_letter(col)
    ws.cell(row=rt,column=col,value=f'=SUM({L}{DATA_ROW}:{L}{rt-1})').font=F_B
ws.cell(row=rt,column=10,value=f'=COUNTIF($J${DATA_ROW}:$J{rt-1},"Sim")&" de {len(SETORES)} setores"').font=F_B

# ---------- INSTRUÇÕES ----------
ws=wb.create_sheet("Instruções",0)
ws.column_dimensions["A"].width=4; ws.column_dimensions["B"].width=34; ws.column_dimensions["C"].width=96
ws.cell(row=1,column=2,value="Mapeamento de Processos por Setor").font=Font(name="Arial",size=16,bold=True,color=AZUL)
ws.cell(row=2,column=2,value=f"{COD}  |  Versão {VER}  |  Emissão {DATA}  |  CONFIDENCIAL").font=F_SUB
ws.cell(row=3,column=2,value="Sistema de Gestão da Qualidade — Vanguarda Martech | VPromo | VBOT").font=F_SUB
BLOCOS=[
 ("Para que serve","Este formulário coleta, de cada setor, a matéria-prima dos Procedimentos Operacionais Padrão (POP). "
  "As colunas não são genéricas: cada uma alimenta uma seção obrigatória do POP conforme o SGQ VAN-QUAL-001. "
  "O que não for preenchido aqui não pode ser inventado depois — vira lacuna no procedimento."),
 ("O que este documento NÃO é","Não é um POP. É o formulário que antecede o POP. Os POPs são redigidos a partir daqui, "
  "recebem código VAN-POP-[ÁREA]-[SEQ] e seguem para aprovação do CEO."),
 ("Quem preenche","Cada setor preenche a SUA aba. O gestor da área é responsável pelo conteúdo; a Gestão da Qualidade valida."),
 ("Como preencher","1) Abra a aba do seu setor.\n"
  "2) A linha 8, em amarelo, é um EXEMPLO preenchido — use como referência e apague ou sobrescreva.\n"
  "3) Escreva um processo por linha, a partir da linha 9.\n"
  "4) Colunas com (*) no título são obrigatórias.\n"
  "5) Depois volte às abas Etapas, RACI, KPIs e Riscos e detalhe cada processo que você listou."),
 ("Ordem sugerida","Aba do setor → Etapas → RACI → KPIs → Riscos. Comece pelos processos de prioridade Alta: "
  "não é preciso mapear tudo de uma vez."),
 ("Como os códigos funcionam","O código do processo tem o formato PREFIXO.NN — por exemplo MID.01 para o primeiro processo "
  "de Mídia Paga. O prefixo de cada setor está no topo da respectiva aba. Esse código é a chave que liga a linha do "
  "processo às abas de Etapas, RACI, KPIs e Riscos: escreva-o igual nas quatro."),
 ("Mínimos exigidos pelo SGQ","Por processo: no mínimo 3 etapas, 5 indicadores e 5 riscos. A aba Consolidado mostra "
  "quem já atingiu o mínimo e quem ainda não."),
 ("Regra de ouro do RACI","Toda atividade que envolve pagamento ou compromisso financeiro tem o CEO como Aprovador (A). "
  "Não há exceção."),
 ("Escala de risco","Probabilidade e Impacto vão de 1 a 3. O Nível de Risco (NR) é o produto dos dois e é calculado "
  "automaticamente: NR ≥ 6 exige ação imediata, 4 a 5 pede monitoramento, até 3 é aceitável."),
 ("Cores da planilha","Amarelo = linha de exemplo, para apagar. Verde = célula calculada, não digite. "
  "Cinza alternado = apenas leitura de linha. Azul escuro = cabeçalho."),
 ("Prazo e devolução","Devolver à Gestão da Qualidade. A planilha volta inteira, com todas as abas — não separe."),
 ("Dois códigos de área pendentes","A tabela oficial do SGQ tem sete áreas: FIN, MKT, COM, OPS, RH, TEC e VBOT. "
  "Diretoria Executiva e Planejamento/Estratégia e Inovação não se encaixam em nenhuma delas; as abas trazem GOV e EST "
  "como PROPOSTA, marcados com asterisco, aguardando decisão da Qualidade. Observe também que cinco setores "
  "(Mídia Paga, Inbound, Criação, Direção de Arte e Social Media) caem todos em MKT — por isso o código do processo "
  "usa prefixo próprio por setor, senão MKT sozinho não diria de quem é o processo."),
]
r=5
for tit,txt in BLOCOS:
    c=ws.cell(row=r,column=2,value=tit); c.font=F_HDR
    c.fill=PatternFill("solid",fgColor=AZUL); c.border=BORDA
    c.alignment=Alignment(vertical="center",wrap_text=True)
    t=ws.cell(row=r,column=3,value=txt); t.font=F_TXT
    t.alignment=Alignment(wrap_text=True,vertical="top"); t.border=BORDA
    ws.row_dimensions[r].height=max(32, 15*(txt.count("\n")+1) + 13*(len(txt)//95))
    r+=1
ws.cell(row=r+1,column=2,value="Referenciais").font=F_B
ws.cell(row=r+1,column=3,value="ISO 9001:2015 · ABPMP CBOK v3.0 · PMBOK 7ª Ed. · COSO ERM · Lean · "
    "Planejamento Estratégico Vanguarda 2030 · SGQ Vanguarda VAN-QUAL-001").font=F_TXT
ws.cell(row=r+1,column=3).alignment=Alignment(wrap_text=True)
ws.sheet_view.showGridLines=False

ORD=["Instruções"]+[s[0] for s in SETORES]+["Etapas","RACI","KPIs","Riscos","Consolidado","Listas"]
wb._sheets=sorted(wb._sheets,key=lambda s:ORD.index(s.title))
out="/home/user/Agentes_Claude_mcp/docs/sgq/VAN-FOR-SGQ-001_Mapeamento_de_Processos_por_Setor.xlsx"
import os; os.makedirs(os.path.dirname(out),exist_ok=True)
wb.save(out)
print("abas:",len(wb.sheetnames)); print(wb.sheetnames); print("salvo:",out)
