const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  WidthType, ShadingType, BorderStyle, AlignmentType, HeadingLevel,
  VerticalAlign, LevelFormat, Footer, PageNumber, TabStopType, TabStopPosition,
} = require("docx");
const fs = require("fs");

// ---- medidas: A4 = 11906 DXA de largura; margens de 2 cm = 1134 DXA ----
const MARGEM = 1134;
const LARG = 11906 - 2 * MARGEM;   // 9638

// ---- paleta ----
const MARCA   = "0B3A5D";
const TINTA   = "12181F";
const TINTA2  = "3D4854";
const TINTA3  = "6B7684";
const REGUA   = "DFE3E8";
const CAB_BG  = "EAF1F7";
const OK      = "1C6B45";
const ALERTA  = "8A5A00";
const RISCO   = "93221F";

const S = 20;   // half-points por ponto: fonte 10pt = 20

// ---------- helpers de parágrafo ----------
const p = (texto, o = {}) => new Paragraph({
  spacing: { after: o.after ?? 100, before: o.before ?? 0, line: o.line ?? 260 },
  alignment: o.align,
  indent: o.indent,
  border: o.border,
  numbering: o.bullet ? { reference: "marcador", level: 0 } : undefined,
  children: Array.isArray(texto) ? texto : [new TextRun({
    text: texto, size: o.size ?? 10 * S, color: o.color ?? TINTA,
    bold: o.bold, italics: o.italico, font: "Calibri",
  })],
});

const r = (text, o = {}) => new TextRun({
  text, size: o.size ?? 10 * S, color: o.color ?? TINTA,
  bold: o.bold, italics: o.italico, font: "Calibri",
});

const h2 = (texto) => new Paragraph({
  spacing: { before: 320, after: 140 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: REGUA, space: 4 } },
  children: [r(texto.toUpperCase(), { size: 9 * S, bold: true, color: MARCA })],
});

const h3 = (texto) => new Paragraph({
  spacing: { before: 200, after: 90 },
  children: [r(texto, { size: 11 * S, bold: true, color: TINTA })],
});

// ---------- helpers de tabela ----------
const MARG_CEL = { top: 90, bottom: 90, left: 110, right: 110 };

const celCab = (texto, larg, o = {}) => new TableCell({
  width: { size: larg, type: WidthType.DXA },
  shading: { type: ShadingType.CLEAR, fill: CAB_BG, color: "auto" },
  margins: MARG_CEL,
  verticalAlign: VerticalAlign.BOTTOM,
  borders: {
    top:    { style: BorderStyle.NONE },
    left:   { style: BorderStyle.NONE },
    right:  { style: BorderStyle.NONE },
    bottom: { style: BorderStyle.SINGLE, size: 8, color: MARCA },
  },
  children: [new Paragraph({
    spacing: { after: 0, line: 220 },
    alignment: o.align,
    children: [r(texto.toUpperCase(), { size: 7.5 * S, bold: true, color: MARCA })],
  })],
});

const cel = (conteudo, larg, o = {}) => new TableCell({
  width: { size: larg, type: WidthType.DXA },
  margins: MARG_CEL,
  verticalAlign: VerticalAlign.TOP,
  shading: o.fundo ? { type: ShadingType.CLEAR, fill: o.fundo, color: "auto" } : undefined,
  borders: {
    top:    { style: BorderStyle.NONE },
    left:   { style: BorderStyle.NONE },
    right:  { style: BorderStyle.NONE },
    bottom: { style: BorderStyle.SINGLE, size: 4, color: REGUA },
  },
  children: Array.isArray(conteudo) && conteudo[0] instanceof Paragraph
    ? conteudo
    : [new Paragraph({
        spacing: { after: 0, line: 240 },
        alignment: o.align,
        children: Array.isArray(conteudo) ? conteudo
          : [r(conteudo, { size: 8.5 * S, bold: o.bold, color: o.color })],
      })],
});

const tabela = (colunas, linhas) => new Table({
  width: { size: LARG, type: WidthType.DXA },
  columnWidths: colunas,
  rows: linhas,
});

const legenda = (texto) => new Paragraph({
  spacing: { before: 80, after: 60, line: 220 },
  children: Array.isArray(texto) ? texto : [r(texto, { size: 7.5 * S, color: TINTA3, italics: true })],
});

// caixa de destaque: parágrafo com barra à esquerda e fundo
const caixa = (rotulo, corpo, cor = MARCA, fundo = CAB_BG) => new Table({
  width: { size: LARG, type: WidthType.DXA },
  columnWidths: [LARG],
  rows: [new TableRow({
    children: [new TableCell({
      width: { size: LARG, type: WidthType.DXA },
      shading: { type: ShadingType.CLEAR, fill: fundo, color: "auto" },
      margins: { top: 140, bottom: 140, left: 200, right: 180 },
      borders: {
        top:    { style: BorderStyle.NONE },
        right:  { style: BorderStyle.NONE },
        bottom: { style: BorderStyle.NONE },
        left:   { style: BorderStyle.SINGLE, size: 18, color: cor },
      },
      children: [
        new Paragraph({
          spacing: { after: 70, line: 220 },
          children: [r(rotulo.toUpperCase(), { size: 7.5 * S, bold: true, color: cor })],
        }),
        new Paragraph({ spacing: { after: 0, line: 250 }, children: corpo }),
      ],
    })],
  })],
});

// =====================================================================
const conteudo = [];

// ---------- cabeçalho ----------
conteudo.push(new Paragraph({
  spacing: { after: 80 },
  children: [r("VANGUARDA MARTECH · RELATÓRIO EXECUTIVO", { size: 8 * S, bold: true, color: MARCA })],
}));
conteudo.push(new Paragraph({
  spacing: { after: 140, line: 300 },
  children: [r("Arquitetura de dados Nekt: pilotos validados e camadas Trusted e Refined em produção",
    { size: 17 * S, bold: true, color: TINTA })],
}));
conteudo.push(new Paragraph({
  spacing: { after: 60, line: 240 },
  children: [
    r("Destinatário: ", { size: 8.5 * S, bold: true, color: TINTA2 }), r("Diretoria Executiva    ", { size: 8.5 * S, color: TINTA3 }),
    r("Emissor: ",      { size: 8.5 * S, bold: true, color: TINTA2 }), r("Head de Inteligência Artificial    ", { size: 8.5 * S, color: TINTA3 }),
  ],
}));
conteudo.push(new Paragraph({
  spacing: { after: 240, line: 240 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 16, color: MARCA, space: 8 } },
  children: [
    r("Data: ",   { size: 8.5 * S, bold: true, color: TINTA2 }), r("08/09/2026    ", { size: 8.5 * S, color: TINTA3 }),
    r("Escopo: ", { size: 8.5 * S, bold: true, color: TINTA2 }), r("mídia paga — Google Ads e Meta (Facebook Ads)", { size: 8.5 * S, color: TINTA3 }),
  ],
}));

// ---------- 1. resumo ----------
conteudo.push(h2("1. Resumo executivo"));
conteudo.push(p([
  r("A arquitetura de dados de mídia paga saiu da fase de extração e passou a operar em "),
  r("medalhão completo", { bold: true }),
  r(" — dado bruto, dado tratado e dado de consumo — para as duas plataformas que concentram a verba da casa. Os quatro pilotos abertos em 26/08 cumpriram sua função: cada um testou um caso-limite distinto e cada caso virou regra escrita que hoje governa as 46 fontes conectadas."),
], { size: 10.5 * S, line: 280, after: 180 }));

const painel = [
  ["R$ 3,66 mi", "verba de mídia sob governança, em BRL, nas duas plataformas"],
  ["11",         "tabelas na camada Trusted, sendo 5 publicadas hoje"],
  ["3 de 4",     "pilotos atravessando o medalhão inteiro"],
  ["zero",       "registros marcados como não confiáveis nos pilotos"],
];
const colPainel = [2410, 2410, 2409, 2409];
conteudo.push(new Table({
  width: { size: LARG, type: WidthType.DXA },
  columnWidths: colPainel,
  rows: [new TableRow({
    children: painel.map((c, i) => new TableCell({
      width: { size: colPainel[i], type: WidthType.DXA },
      margins: { top: 130, bottom: 130, left: 130, right: 130 },
      shading: { type: ShadingType.CLEAR, fill: "F7F9FB", color: "auto" },
      borders: {
        top:    { style: BorderStyle.SINGLE, size: 4, color: REGUA },
        bottom: { style: BorderStyle.SINGLE, size: 4, color: REGUA },
        left:   { style: BorderStyle.SINGLE, size: 4, color: REGUA },
        right:  { style: BorderStyle.SINGLE, size: 4, color: REGUA },
      },
      children: [
        new Paragraph({ spacing: { after: 50, line: 240 }, children: [r(c[0], { size: 15 * S, bold: true, color: MARCA })] }),
        new Paragraph({ spacing: { after: 0, line: 210 }, children: [r(c[1], { size: 7.5 * S, color: TINTA3 })] }),
      ],
    })),
  })],
}));
conteudo.push(legenda([
  r("Verba apurada em 08/09/2026: R$ 1.342.354,13 em Google Ads (35 contas em reais) e R$ 2.318.791,22 em Meta (7 contas). A conta Move Rental Cars fatura em dólar — US$ 19.600,06 — e por decisão de arquitetura ", { size: 7.5 * S, color: TINTA3 }),
  r("não é somada", { size: 7.5 * S, color: TINTA3, bold: true }),
  r(" às demais.", { size: 7.5 * S, color: TINTA3 }),
]));

// ---------- 2. pilotos ----------
conteudo.push(h2("2. Os quatro pilotos e o que cada um produziu"));
conteudo.push(p("Os pilotos não foram amostras aleatórias. Cada um foi escolhido para expor um problema específico antes de o problema aparecer em escala nas 39 contas de Google Ads.", { after: 140 }));

const cP = [1560, 2280, 2900, 1300, 1598];
conteudo.push(tabela(cP, [
  new TableRow({ tableHeader: true, children: [
    celCab("Piloto", cP[0]), celCab("Caso-limite testado", cP[1]),
    celCab("Regra ou ativo que gerou", cP[2]),
    celCab("Verba apurada", cP[3], { align: AlignmentType.RIGHT }),
    celCab("Medalhão", cP[4]),
  ]}),
  new TableRow({ children: [
    cel("Acesso Saúde", cP[0], { bold: true }),
    cel("Conta simples, nome do cadastro igual ao da plataforma — a linha de base.", cP[1]),
    cel([r("Tornou-se o ", { size: 8.5 * S }), r("marcador de fim de ciclo", { size: 8.5 * S, bold: true }),
         r(" de todo o parque: tem o horário de carga mais tardio das 39 contas, e hoje sete transformações são disparadas por ela.", { size: 8.5 * S })], cP[2]),
    cel("R$ 59.113,18", cP[3], { align: AlignmentType.RIGHT }),
    cel("Completo", cP[4], { bold: true, color: OK }),
  ]}),
  new TableRow({ children: [
    cel("Olá Casa Nova", cP[0], { bold: true }),
    cel("Divergência de nome: conhecida como Olá Casa Nova, cadastrada como “Ola Empreendimentos”.", cP[1]),
    cel([r("Regra de que ", { size: 8.5 * S }), r("identidade de conta se resolve por identificador, nunca por rótulo digitado", { size: 8.5 * S, bold: true }),
         r(". Evita relatório atribuído ao cliente errado.", { size: 8.5 * S })], cP[2]),
    cel("R$ 32.689,70", cP[3], { align: AlignmentType.RIGHT }),
    cel("Completo", cP[4], { bold: true, color: OK }),
  ]}),
  new TableRow({ children: [
    cel("Move Rental Cars", cP[0], { bold: true }),
    cel("Única das 42 contas que fatura em dólar.", cP[1]),
    cel([r("Regra de que ", { size: 8.5 * S }), r("verba não se soma entre moedas", { size: 8.5 * S, bold: true }),
         r(", declarada na camada de consumo. Foi também onde o problema de cobertura do Performance Max apareceu primeiro.", { size: 8.5 * S })], cP[2]),
    cel("US$ 19.600,06", cP[3], { align: AlignmentType.RIGHT }),
    cel("Completo", cP[4], { bold: true, color: OK }),
  ]}),
  new TableRow({ children: [
    cel("Don Watches conta 1", cP[0], { bold: true }),
    cel("Cliente com múltiplas contas ativas na mesma plataforma.", cP[1]),
    cel([r("Regra de que ", { size: 8.5 * S }), r("contas com o mesmo prefixo de nome nunca são unificadas", { size: 8.5 * S, bold: true }),
         r(" — cada uma tem verba, calendário e responsável próprios. Expôs também a pior inconsistência de nomenclatura da base.", { size: 8.5 * S })], cP[2]),
    cel("—", cP[3], { align: AlignmentType.RIGHT }),
    cel("Sem dado", cP[4], { bold: true, color: TINTA3 }),
  ]}),
]));
conteudo.push(legenda("Situação apurada em 08/09/2026 contra as tabelas em produção. “Medalhão” indica presença nas três camadas: Raw, Trusted e Refined."));

conteudo.push(caixa("Leitura correta do quarto piloto", [
  r("A conta Don Watches 1 aparece com zero registros porque "),
  r("não tem atividade desde 2023", { bold: true }),
  r(" — investimento zero e nenhuma impressão, confirmado contra a API do Google Ads. O vazio é o resultado correto, não falha de integração. Em 31/08 a extração dessa conta foi reduzida de diária para semanal: consumia crédito de plataforma todos os dias para trazer nenhuma linha."),
]));

// ---------- 3. camadas ----------
conteudo.push(h2("3. O que foi construído nas camadas"));
conteudo.push(p([
  r("O modelo em três estágios foi aplicado como "),
  r("estágio de tratamento e não como pasta", { bold: true }),
  r(": toda fonte atravessa os três, e o estágio se identifica pelo prefixo da tabela. Isso vale para dado de sistema interno e para dado de cliente, sem exceção."),
], { after: 140 }));

const cC = [1300, 4300, 4038];
conteudo.push(tabela(cC, [
  new TableRow({ tableHeader: true, children: [
    celCab("Camada", cC[0]), celCab("O que existe", cC[1]), celCab("Para que serve na decisão", cC[2]),
  ]}),
  new TableRow({ children: [
    cel("Raw", cC[0], { bold: true }),
    cel("Cópia fiel das 46 fontes de mídia — 39 contas de Google Ads e 7 de Meta. Nada é corrigido aqui, por definição.", cC[1]),
    cel("Rastreabilidade e auditoria. Permite reconstruir qualquer número até a origem.", cC[2]),
  ]}),
  new TableRow({ children: [
    cel("Trusted", cC[0], { bold: true }),
    cel([
      new Paragraph({ spacing: { after: 60, line: 240 }, children: [
        r("Google Ads (8 tabelas): ", { size: 8.5 * S, bold: true }),
        r("desempenho diário, dimensão de campanha, dimensão de conta e cinco recortes — faixa etária, gênero, geográfico, localização do usuário e termo de busca.", { size: 8.5 * S }),
      ]}),
      new Paragraph({ spacing: { after: 0, line: 240 }, children: [
        r("Meta (3 tabelas): ", { size: 8.5 * S, bold: true }),
        r("desempenho diário, dimensão de campanha e dimensão de conta.", { size: 8.5 * S }),
      ]}),
    ], cC[1]),
    cel("Número fiel à plataforma com forma corrigida: tipos, fuso, unicidade provada e linhagem. É a base sobre a qual qualquer análise pode ser refeita.", cC[2]),
  ]}),
  new TableRow({ children: [
    cel("Refined", cC[0], { bold: true }),
    cel([r("Um produto de dados de mídia cobrindo ", { size: 8.5 * S }),
         r("as duas plataformas na mesma tabela", { size: 8.5 * S, bold: true }),
         r(", no grão de campanha por dia, com as regras de negócio declaradas e numeradas.", { size: 8.5 * S })], cC[1]),
    cel("Camada oficial de consumo. É onde a verba se soma e onde os indicadores derivados (CPC, CPA, ROAS) são calculados a partir de totais — nunca por média de médias.", cC[2]),
  ]}),
]));
conteudo.push(legenda("Inventário em 08/09/2026. Os cinco recortes de segmentação foram publicados hoje; a primeira materialização deles ocorre no ciclo de carga desta terça-feira."));

conteudo.push(h3("Entregas de hoje, 08/09/2026"));
conteudo.push(p([r("Cinco recortes de segmentação do Google Ads", { bold: true }),
  r(" publicados na camada Trusted, consolidando as 39 contas em cada um. Abrem análise de público, geografia e termo de busca que antes não existia na base.")], { bullet: true, after: 60 }));
conteudo.push(p([r("Produto de mídia da Refined passou a cobrir Meta além de Google Ads.", { bold: true }),
  r(" Até hoje representava apenas o Google — cerca de 37% da verba. Passa a representar as duas plataformas.")], { bullet: true, after: 60 }));
conteudo.push(p([r("Correção de um alarme falso iminente:", { bold: true }),
  r(" o indicador de defasagem de fonte foi recalibrado de 2 para 9 dias, porque a carga passou de diária para semanal em 04/09. Sem o ajuste, todas as contas seriam marcadas como defasadas a partir de quinta-feira, e o indicador perderia utilidade.")], { bullet: true, after: 140 }));

// ---------- 4. evidência ----------
conteudo.push(h2("4. Evidência de qualidade"));
conteudo.push(p("Nenhuma camada foi considerada pronta sem prova numérica. As verificações abaixo foram executadas contra as tabelas em produção em 08/09/2026.", { after: 140 }));

const cE = [3100, 2900, 3638];
conteudo.push(tabela(cE, [
  new TableRow({ tableHeader: true, children: [
    celCab("Verificação", cE[0]), celCab("Resultado", cE[1]), celCab("O que isso garante", cE[2]),
  ]}),
  new TableRow({ children: [
    cel("Unicidade do grão no fato de Meta", cE[0]),
    cel("137.744 registros = 137.744 chaves = 137.744 assinaturas de conteúdo", cE[1], { bold: true }),
    cel("Nenhuma linha duplicada e nenhuma perdida na consolidação de 7 contas.", cE[2]),
  ]}),
  new TableRow({ children: [
    cel("Consolidação de Meta contra o modelo anterior", cE[0]),
    cel("reproduz o total ao centavo", cE[1], { bold: true }),
    cel("A troca de dez tabelas por cliente por uma tabela única não alterou nenhum número.", cE[2]),
  ]}),
  new TableRow({ children: [
    cel("Integridade entre camadas nos pilotos", cE[0]),
    cel("zero registros não confiáveis", cE[1], { bold: true }),
    cel("Nenhuma campanha órfã, nenhuma conta fora do catálogo, nenhuma moeda divergente.", cE[2]),
  ]}),
  new TableRow({ children: [
    cel("Verba preservada no cruzamento com campanha", cE[0]),
    cel("R$ 94.646,41 preservados", cE[1], { bold: true }),
    cel("São 18 campanhas já excluídas no Meta que ainda carregam investimento histórico — 4,1% da verba da plataforma. O desenho do cruzamento as mantém visíveis em vez de descartá-las em silêncio.", cE[2]),
  ]}),
]));

// ---------- 5. limites ----------
conteudo.push(h2("5. Limites declarados da plataforma"));
conteudo.push(p([
  r("Estes limites são de origem — impostos pelo Google e pelo Meta — e "),
  r("não são corrigíveis por engenharia", { bold: true }),
  r(". Estão escritos na documentação de cada tabela para que nenhum relatório futuro os trate como erro nem os ignore."),
], { after: 140 }));

const cL = [3100, 1400, 5138];
conteudo.push(tabela(cL, [
  new TableRow({ tableHeader: true, children: [
    celCab("Limite", cL[0]),
    celCab("Cobertura", cL[1], { align: AlignmentType.RIGHT }),
    celCab("Consequência para a leitura", cL[2]),
  ]}),
  new TableRow({ children: [
    cel("Campanhas Performance Max não publicam recorte demográfico", cL[0]),
    cel("80,0%", cL[1], { bold: true, align: AlignmentType.RIGHT }),
    cel("R$ 270.088,20 de verba — 20,1% do total — não tem faixa etária nem gênero disponível. A relação é exata: a cobertura é sempre 100% menos a fatia em Performance Max.", cL[2]),
  ]}),
  new TableRow({ children: [
    cel("Localização física do usuário não sempre resolvida", cL[0]),
    cel("93,5%", cL[1], { bold: true, align: AlignmentType.RIGHT }),
    cel("Para relatório de verba por região existe um recorte alternativo que fecha em 100%, porque usa o alvo configurado na campanha e não a observação.", cL[2]),
  ]}),
  new TableRow({ children: [
    cel("Limiar de privacidade em termos de busca", cL[0]),
    cel("61,2%", cL[1], { bold: true, align: AlignmentType.RIGHT }),
    cel("Termo com volume baixo não é publicado. A cobertura varia de 15,7% a 86,8% por conta, conforme o perfil de volume. Serve para negativação de termo, não para totalizar verba.", cL[2]),
  ]}),
]));
conteudo.push(legenda("Percentuais medidos em 08/09/2026 sobre as 36 contas de Google Ads com dado, em reais."));

conteudo.push(caixa("Regra de leitura consolidada", [
  r("Verba de mídia se soma na camada de consumo. Recorte serve para dividir, nunca para totalizar.", { bold: true }),
  r(" Um único dos cinco recortes reconcilia com o investimento total; os outros quatro cobrem parcelas conhecidas e declaradas. Somar verba a partir de um recorte produz número menor que o real, com aparência de correto."),
]));

// ---------- 6. riscos ----------
conteudo.push(h2("6. Riscos e valor bloqueado"));
const cR = [900, 3500, 2100, 3138];
conteudo.push(tabela(cR, [
  new TableRow({ tableHeader: true, children: [
    celCab("Grau", cR[0]), celCab("Risco", cR[1]), celCab("Exposição", cR[2]), celCab("Onde se resolve", cR[3]),
  ]}),
  new TableRow({ children: [
    cel("Alto", cR[0], { bold: true, color: RISCO }),
    cel([r("Nove contas de Meta do Grupo Braga não integradas.", { size: 8.5 * S, bold: true }),
         r(" Dependem de estrutura de destino que só o backoffice da plataforma cria.", { size: 8.5 * S })], cR[1]),
    cel("R$ 1,89 milhão de verba fora da governança", cR[2], { bold: true }),
    cel("Backoffice da Nekt, seguido de nove autorizações de acesso.", cR[3]),
  ]}),
  new TableRow({ children: [
    cel("Alto", cR[0], { bold: true, color: RISCO }),
    cel([r("Três contas do Grupo Unipar nunca extraíram.", { size: 8.5 * S, bold: true }),
         r(" A credencial usada pela plataforma não tem acesso à central de contas do cliente.", { size: 8.5 * S })], cR[1]),
    cel("cerca de R$ 4 mil por mês sem visibilidade", cR[2], { bold: true }),
    cel("Refazer a autorização com a identidade correta, na interface da plataforma. Credencial não transita por este canal.", cR[3]),
  ]}),
  new TableRow({ children: [
    cel("Médio", cR[0], { bold: true, color: ALERTA }),
    cel([r("Janela de reprocessamento incompatível com a nova cadência.", { size: 8.5 * S, bold: true }),
         r(" A plataforma reprocessa 7 dias, mas a carga passou a ser semanal.", { size: 8.5 * S })], cR[1]),
    cel("correção tardia de conversão pode não ser capturada", cR[2]),
    cel("Elevar a janela para 14 dias na interface da plataforma.", cR[3]),
  ]}),
  new TableRow({ children: [
    cel("Médio", cR[0], { bold: true, color: ALERTA }),
    cel([r("Saldo de créditos da plataforma.", { size: 8.5 * S, bold: true }),
         r(" Em 04/09 o saldo esgotou e cinco pipelines falharam por 24 horas.", { size: 8.5 * S })], cR[1]),
    cel("parada de carga de um dia, já recuperada", cR[2]),
    cel("Previsibilidade de recarga junto à área responsável por licenças e pagamentos de plataforma.", cR[3]),
  ]}),
  new TableRow({ children: [
    cel("Médio", cR[0], { bold: true, color: ALERTA }),
    cel([r("Termo de busca contém texto digitado por pessoa.", { size: 8.5 * S, bold: true }),
         r(" Pode conter nome, telefone ou condição de saúde — dado sensível para os seis clientes do setor de saúde.", { size: 8.5 * S })], cR[1]),
    cel("exposição sob Art. 11 da LGPD", cR[2]),
    cel("Decisão de tratamento antes de qualquer exposição em painel, relatório ou exportação.", cR[3]),
  ]}),
]));
conteudo.push(legenda("Os valores de exposição das duas primeiras linhas vêm do inventário de pendências consolidado em 31/08/2026, não de medição desta data."));

// ---------- 7. plano ----------
conteudo.push(h2("7. Plano de ação"));
const cA = [4200, 2500, 1400, 1538];
const acoes = [
  ["Conferir a materialização dos cinco recortes publicados hoje e registrar o resultado", "Head de IA", "08/09/2026", "Agendado", ALERTA],
  ["Elevar a janela de reprocessamento para 14 dias", "Head de IA, na interface da plataforma", "até 15/09/2026", "A fazer", TINTA3],
  ["Criar as nove estruturas de destino do Grupo Braga e conduzir as autorizações de acesso", "Head de IA com o fornecedor da plataforma; acessos com a supervisão de Mídia Paga", "a definir", "Bloqueado", RISCO],
  ["Refazer a autorização das três contas do Grupo Unipar com a identidade que tem acesso", "Head de IA com a supervisão de Mídia Paga", "a definir", "Bloqueado", RISCO],
  ["Definir previsibilidade de recarga de créditos da plataforma", "Área de licenças e pagamentos de plataforma", "a definir", "A decidir", TINTA3],
  ["Definir o tratamento de termo de busca para os clientes de saúde", "Jurídico, com a Head de IA", "antes da 1ª exposição", "A decidir", TINTA3],
];
conteudo.push(tabela(cA, [
  new TableRow({ tableHeader: true, children: [
    celCab("Ação", cA[0]), celCab("Dono proposto", cA[1]), celCab("Prazo", cA[2]), celCab("Situação", cA[3]),
  ]}),
  ...acoes.map(a => new TableRow({ children: [
    cel(a[0], cA[0]), cel(a[1], cA[1]), cel(a[2], cA[2]),
    cel(a[3], cA[3], { bold: true, color: a[4] }),
  ]})),
]));
conteudo.push(legenda([
  r("Os donos acima são ", { size: 7.5 * S, color: TINTA3, italics: true }),
  r("proposta", { size: 7.5 * S, color: TINTA3, italics: true, bold: true }),
  r(", com base no papel de cada área — não há designação formal registrada para estes itens. Confirmar antes de comunicar como compromisso.", { size: 7.5 * S, color: TINTA3, italics: true }),
]));

// ---------- 8. ressalvas ----------
conteudo.push(h2("8. Ressalvas"));
const ressalvas = [
  [["Os cinco recortes publicados hoje ainda não materializaram.", true], [" Estavam com zero execuções às 12:39 (Manaus) e a primeira carga ocorre no ciclo das 12:43 desta terça. A conferência dos números está agendada para hoje.", false]],
  [["A cobertura de Meta na camada de consumo entra no mesmo ciclo.", true], [" O código foi publicado hoje às 10:13 e a tabela ainda continha apenas Google Ads no momento desta emissão.", false]],
  [["Os valores de exposição do Grupo Braga e do Grupo Unipar", true], [" vêm do inventário de pendências de 31/08/2026 e não foram remedidos hoje.", false]],
  [["A dimensão de conta de Meta é uma fotografia congelada", true], [" de 26/08/2026, tirada de uma fonte que foi excluída. Nome de conta, moeda e fuso do lado Meta não se atualizam sozinhos, e isso está declarado na própria tabela.", false]],
  [["Sete contas de Meta estão em quatro fusos horários diferentes.", true], [" “Dia” não significa exatamente a mesma coisa entre elas. Não é corrigível com a extração atual; a coluna de fuso declara qual se aplica a cada linha.", false]],
  [["Uma inconsistência de medição foi encontrada e corrigida nesta data:", true], [" totais de verba publicados hoje mais cedo somavam reais e dólares na mesma cifra. Os percentuais praticamente não se alteraram — a cobertura demográfica passou de 80,2% para 80,0% — mas os valores absolutos foram refeitos por moeda e a documentação corrigida, com registro do que a versão anterior afirmava.", false]],
];
ressalvas.forEach(rs => conteudo.push(p(rs.map(x => r(x[0], { bold: x[1] })), { bullet: true, after: 70 })));

// ---------- rodapé de conteúdo ----------
conteudo.push(new Paragraph({
  spacing: { before: 300, after: 0, line: 230 },
  border: { top: { style: BorderStyle.SINGLE, size: 6, color: REGUA, space: 8 } },
  children: [r("Documento gerado em 08/09/2026 a partir de consulta direta às tabelas em produção da plataforma Nekt e ao inventário de pendências versionado no repositório do projeto. Todos os valores desta página são resultado de medição registrada, não de estimativa. Detalhamento técnico, consultas de verificação e histórico de correções em docs/nekt/, repositório Agentes_Claude_mcp, ramo claude/reconectar-nekt-osv23g.",
    { size: 7.5 * S, color: TINTA3 })],
}));

// =====================================================================
const doc = new Document({
  creator: "Head de Inteligência Artificial — Vanguarda MarTech",
  title: "Arquitetura de dados Nekt: pilotos validados e camadas Trusted e Refined em produção",
  description: "Relatório executivo para a Diretoria Executiva — 08/09/2026",
  numbering: {
    config: [{
      reference: "marcador",
      levels: [{
        level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 300, hanging: 200 } } },
      }],
    }],
  },
  sections: [{
    properties: { page: { margin: { top: MARGEM, right: MARGEM, bottom: MARGEM, left: MARGEM } } },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          tabStops: [{ type: TabStopType.RIGHT, position: LARG }],
          children: [
            r("Vanguarda MarTech · Relatório executivo · 08/09/2026", { size: 7.5 * S, color: TINTA3 }),
            r("\t", { size: 7.5 * S }),
            new TextRun({ children: ["Página ", PageNumber.CURRENT, " de ", PageNumber.TOTAL_PAGES],
              size: 7.5 * S, color: TINTA3, font: "Calibri" }),
          ],
        })],
      }),
    },
    children: conteudo,
  }],
});

Packer.toBuffer(doc).then(b => {
  const saida = process.argv[2];
  fs.writeFileSync(saida, b);
  console.log(`gravado: ${saida} (${b.length.toLocaleString("pt-BR")} bytes)`);
});
