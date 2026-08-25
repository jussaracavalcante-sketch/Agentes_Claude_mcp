import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import type { MonitoringOverview } from '../../lib/types'
import { CONVERSATION_STATUS_LABEL, TASK_STATUS_LABEL, formatUsd, relativeTime } from '../../lib/format'
import { BarRanking } from '../../components/charts'
import {
  Badge,
  ErrorBanner,
  Loading,
  PageHeader,
  PeriodPicker,
  Section,
  StatCard,
} from '../../components/ui'
import type { Period } from '../../components/ui'
import { IconChat, IconMonitor, IconTask, IconTrace } from '../../components/Icons'

const STATUS_TONE: Record<string, string> = {
  active: 'success',
  waiting: 'warning',
  handoff: 'info',
  closed: 'neutral',
  failed: 'danger',
  succeeded: 'success',
  running: 'info',
  awaiting_approval: 'warning',
  cancelled: 'neutral',
}

export default function Monitoring() {
  const [period, setPeriod] = useState<Period>('1D')
  const { data, error, loading, reload } = useApi<MonitoringOverview>('/monitoring', { period })

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconMonitor />}
        title="Monitoramento"
        subtitle="Visão geral de chats, tasks e traces do workspace"
        actions={<PeriodPicker value={period} onChange={setPeriod} />}
      />

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Conversas" value={data.conversations} hint="Chats iniciados no período" icon={<IconChat />} to="/conversas" />
            <StatCard label="Live Chats" value={data.live_chats} hint="Conversas em andamento" icon={<IconChat />} to="/conversas?status=active" />
            <StatCard label="Tasks" value={data.tasks} hint="Tarefas iniciadas no período" icon={<IconTask />} to="/tarefas" />
            <StatCard label="Traces" value={data.traces} hint="Execuções, spans, tokens e custo" icon={<IconTrace />} to="/traces" />
          </div>

          <Section title="Conversas por serviço" description="Distribuição de chats no período">
            <BarRanking data={data.conversations_by_service} />
          </Section>

          <div className="grid gap-4 lg:grid-cols-2">
            <Section title="Conversas recentes" description="Últimos chats iniciados">
              {data.recent_conversations.length === 0 ? (
                <p className="py-8 text-center text-sm text-ink-400">Nenhuma conversa no período.</p>
              ) : (
                <ul className="divide-y divide-ink-100">
                  {data.recent_conversations.map((conversation) => (
                    <li key={conversation.uid} className="flex items-start justify-between gap-4 py-3">
                      <Link to={`/conversas/${conversation.uid}`} className="min-w-0 flex-1">
                        <span className="flex items-center gap-2">
                          <span className="truncate text-sm font-medium text-ink-800">
                            {conversation.service_name}
                          </span>
                          <Badge tone={STATUS_TONE[conversation.status]}>
                            {CONVERSATION_STATUS_LABEL[conversation.status]}
                          </Badge>
                        </span>
                        <span className="mt-0.5 block truncate text-xs text-ink-500">
                          {conversation.last_message}
                        </span>
                      </Link>
                      <span className="shrink-0 text-xs text-ink-400">
                        {relativeTime(conversation.started_at)}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
              <Link to="/conversas" className="mt-4 inline-block text-sm font-medium text-brand-700 hover:underline">
                Ver dashboard conversacional →
              </Link>
            </Section>

            <Section title="Tasks recentes" description="Últimas execuções autônomas">
              {data.recent_tasks.length === 0 ? (
                <p className="py-8 text-center text-sm text-ink-400">Nenhuma task no período.</p>
              ) : (
                <ul className="divide-y divide-ink-100">
                  {data.recent_tasks.map((task) => (
                    <li key={task.uid} className="flex items-start justify-between gap-4 py-3">
                      <Link to={`/tarefas?service_uid=${task.service_uid}`} className="min-w-0 flex-1">
                        <span className="flex items-center gap-2">
                          <span className="truncate text-sm font-medium text-ink-800">{task.service_name}</span>
                          <Badge tone={STATUS_TONE[task.status]}>{TASK_STATUS_LABEL[task.status]}</Badge>
                        </span>
                        <span className="mt-0.5 block text-xs text-ink-500">
                          #{task.public_id} · {task.steps_done}/{task.steps_total} passos ·{' '}
                          {formatUsd(task.cost_usd)}
                        </span>
                      </Link>
                      <span className="shrink-0 text-xs text-ink-400">{relativeTime(task.started_at)}</span>
                    </li>
                  ))}
                </ul>
              )}
              <Link to="/tarefas" className="mt-4 inline-block text-sm font-medium text-brand-700 hover:underline">
                Ver pipeline completo →
              </Link>
            </Section>
          </div>
        </>
      )}
    </div>
  )
}
