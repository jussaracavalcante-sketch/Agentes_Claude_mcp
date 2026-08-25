import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import type { Page as PageType, TaskRun } from '../../lib/types'
import { TASK_STATUS_LABEL, formatDateTime, formatDuration, formatUsd } from '../../lib/format'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  Pagination,
  Tabs,
} from '../../components/ui'
import { IconTask, IconTrace } from '../../components/Icons'

const STATUS_TONE: Record<string, string> = {
  succeeded: 'success',
  failed: 'danger',
  running: 'info',
  queued: 'neutral',
  awaiting_approval: 'warning',
  cancelled: 'neutral',
}

const FILTERS = [
  { value: '', label: 'Todas' },
  { value: 'succeeded', label: 'Concluídas' },
  { value: 'failed', label: 'Falhas' },
  { value: 'awaiting_approval', label: 'Aguardando aprovação' },
]

export default function Tasks() {
  const [params, setParams] = useSearchParams()
  const [page, setPage] = useState(1)
  const status = params.get('status') ?? ''
  const serviceUid = params.get('service_uid') ?? ''

  const { data, error, loading, reload } = useApi<PageType<TaskRun>>('/tasks', {
    status: status || undefined,
    service_uid: serviceUid || undefined,
    page,
    page_size: 25,
  })

  return (
    <div>
      <PageHeader
        icon={<IconTask />}
        title="Tarefas"
        subtitle="Pipeline de tarefas autônomas e seus stops"
      />

      <div className="mb-4">
        <Tabs
          value={status}
          options={FILTERS}
          onChange={(value) => {
            const next = new URLSearchParams(params)
            if (value) next.set('status', value)
            else next.delete('status')
            setParams(next, { replace: true })
            setPage(1)
          }}
        />
      </div>

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="card">
          <DataTable
            rows={data.items}
            rowKey={(row) => row.uid}
            empty={<EmptyState icon={<IconTask className="h-6 w-6" />} title="Nenhuma tarefa no período" />}
            columns={[
              { key: 'id', header: 'ID', render: (row) => <span className="font-mono text-xs text-ink-500">#{row.public_id}</span> },
              { key: 'service', header: 'Serviço', render: (row) => <span className="font-medium text-ink-800">{row.service_name}</span> },
              { key: 'trigger', header: 'Gatilho', render: (row) => <Badge tone="info">{row.trigger}</Badge> },
              {
                key: 'status',
                header: 'Status',
                render: (row) => <Badge tone={STATUS_TONE[row.status]}>{TASK_STATUS_LABEL[row.status]}</Badge>,
              },
              { key: 'start', header: 'Início', render: (row) => formatDateTime(row.started_at) },
              { key: 'duration', header: 'Duração', render: (row) => formatDuration(row.duration_ms) },
              {
                key: 'steps',
                header: 'Passos',
                render: (row) => (
                  <span className="tabular-nums">
                    {row.steps_done}/{row.steps_total}
                  </span>
                ),
              },
              { key: 'cost', header: 'Custo', render: (row) => formatUsd(row.cost_usd) },
              {
                key: 'trace',
                header: 'Trace',
                render: (row) =>
                  row.trace_uid ? (
                    <Link to={`/traces/${row.trace_uid}`} className="text-brand-600 hover:text-brand-800" aria-label="Abrir trace">
                      <IconTrace />
                    </Link>
                  ) : (
                    '—'
                  ),
              },
            ]}
          />
          <Pagination page={data.page} pageSize={data.page_size} total={data.total} onChange={setPage} />
        </div>
      )}
    </div>
  )
}
