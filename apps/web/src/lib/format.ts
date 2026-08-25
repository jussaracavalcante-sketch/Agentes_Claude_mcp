/** Formatação pt-BR compartilhada pelas telas. */

const DATE_TIME = new Intl.DateTimeFormat('pt-BR', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
})

const DATE_ONLY = new Intl.DateTimeFormat('pt-BR', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
})

const LONG_DATE = new Intl.DateTimeFormat('pt-BR', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
})

const TIME = new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' })

const NUMBER = new Intl.NumberFormat('pt-BR')

export const formatDateTime = (value?: string | null) => (value ? DATE_TIME.format(new Date(value)) : '—')
export const formatDate = (value?: string | null) => (value ? DATE_ONLY.format(new Date(value)) : '—')
export const formatTime = (value?: string | null) => (value ? TIME.format(new Date(value)) : '—')
export const formatLongDate = (value: string) => LONG_DATE.format(new Date(value)).toUpperCase()
export const formatNumber = (value: number) => NUMBER.format(value)

export function formatUsd(value: number): string {
  // Custos por execução são frequentemente da ordem de centavos.
  const digits = value > 0 && value < 0.01 ? 4 : 2
  return `US$ ${value.toFixed(digits)}`
}

export function formatBrl(value: number): string {
  return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

export function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms} ms`
  if (ms < 60_000) return `${(ms / 1000).toFixed(2)} s`
  const minutes = Math.floor(ms / 60_000)
  const seconds = Math.round((ms % 60_000) / 1000)
  return `${minutes} min ${seconds}s`
}

export function relativeTime(value: string): string {
  const diff = Date.now() - new Date(value).getTime()
  const minutes = Math.round(diff / 60_000)
  if (minutes < 1) return 'agora'
  if (minutes < 60) return `há ${minutes} min`
  const hours = Math.round(minutes / 60)
  if (hours < 24) return `há ${hours} h`
  return `há ${Math.round(hours / 24)} d`
}

export const greeting = (date: Date) => {
  const hour = date.getHours()
  if (hour < 12) return 'Bom dia'
  if (hour < 18) return 'Boa tarde'
  return 'Boa noite'
}

export const SERVICE_TYPE_LABEL: Record<string, string> = {
  conversation: 'Conversação',
  task: 'Tarefa',
  copilot: 'Copiloto',
}

export const SERVICE_STATUS_LABEL: Record<string, string> = {
  draft: 'Rascunho',
  active: 'Ativo',
  inactive: 'Inativo',
  archived: 'Arquivado',
}

export const CONVERSATION_STATUS_LABEL: Record<string, string> = {
  active: 'Ativo',
  waiting: 'Aguardando',
  handoff: 'Transbordo',
  closed: 'Encerrado',
  failed: 'Falhou',
}

export const TASK_STATUS_LABEL: Record<string, string> = {
  queued: 'Na fila',
  running: 'Executando',
  succeeded: 'Concluída',
  failed: 'Falhou',
  awaiting_approval: 'Aguardando aprovação',
  cancelled: 'Cancelada',
}

export const AUTONOMY_LABEL: Record<string, string> = {
  n0_sugere: 'N0 · Sugere',
  n1_executa_com_aprovacao: 'N1 · Executa com aprovação',
  n2_executa_reversivel: 'N2 · Executa (reversível)',
  n3_executa_irreversivel: 'N3 · Executa (irreversível)',
}

export const CHANNEL_LABEL: Record<string, string> = {
  webchat: 'webchat',
  whatsapp: 'WhatsApp',
  voice: 'Voz',
  email: 'E-mail',
  api: 'API',
  portal: 'Portal',
}
