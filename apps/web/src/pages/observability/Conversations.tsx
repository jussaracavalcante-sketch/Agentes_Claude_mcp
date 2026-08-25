import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import type { Conversation, Page as PageType } from '../../lib/types'
import { CHANNEL_LABEL, CONVERSATION_STATUS_LABEL, formatDateTime } from '../../lib/format'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  Pagination,
  SearchInput,
  Tabs,
} from '../../components/ui'
import { IconChat, IconTrace } from '../../components/Icons'

const STATUS_TONE: Record<string, string> = {
  active: 'success',
  waiting: 'warning',
  handoff: 'info',
  closed: 'neutral',
  failed: 'danger',
}

export default function Conversations() {
  const [params, setParams] = useSearchParams()
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)

  const statusFilter = params.get('status') ?? ''
  const view = statusFilter === 'active' ? 'live' : 'history'

  const { data, error, loading, reload } = useApi<PageType<Conversation>>('/conversations', {
    q: query || undefined,
    status: statusFilter || undefined,
    page,
    page_size: 25,
  })

  return (
    <div>
      <PageHeader
        icon={<IconChat />}
        title="Histórico de Conversas"
        subtitle="Visualize e pesquise todas as conversas realizadas"
      />

      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <Tabs
          value={view}
          options={[
            { value: 'history', label: 'Histórico' },
            { value: 'live', label: 'Ao Vivo' },
          ]}
          onChange={(value) => {
            const next = new URLSearchParams(params)
            if (value === 'live') next.set('status', 'active')
            else next.delete('status')
            setParams(next, { replace: true })
            setPage(1)
          }}
        />
        <SearchInput
          value={query}
          onChange={(value) => {
            setQuery(value)
            setPage(1)
          }}
          placeholder="Buscar conversas…"
          className="w-full max-w-sm"
        />
      </div>

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="card">
          <DataTable
            rows={data.items}
            rowKey={(row) => row.uid}
            onRowClick={(row) => navigate(`/conversas/${row.uid}`)}
            empty={<EmptyState icon={<IconChat className="h-6 w-6" />} title="Nenhuma conversa encontrada" />}
            columns={[
              { key: 'id', header: 'ID', render: (row) => <span className="font-mono text-xs text-ink-500">#{row.public_id}</span> },
              { key: 'service', header: 'Serviço', render: (row) => <span className="font-medium text-ink-800">{row.service_name}</span> },
              { key: 'contact', header: 'Contato', render: (row) => row.contact ?? '—' },
              { key: 'channel', header: 'Canal', render: (row) => CHANNEL_LABEL[row.channel] ?? row.channel },
              { key: 'start', header: 'Início', render: (row) => formatDateTime(row.started_at) },
              {
                key: 'status',
                header: 'Fim',
                render: (row) => <Badge tone={STATUS_TONE[row.status]}>{CONVERSATION_STATUS_LABEL[row.status]}</Badge>,
              },
              {
                key: 'last',
                header: 'Última Msg',
                render: (row) => <span className="block max-w-[18rem] truncate">{row.last_message}</span>,
              },
              {
                key: 'handoff',
                header: 'Handoff',
                render: (row) => (row.handoff_at ? formatDateTime(row.handoff_at) : '—'),
              },
              {
                key: 'trace',
                header: 'Traces',
                render: (row) =>
                  row.trace_uid ? (
                    <Link
                      to={`/traces/${row.trace_uid}`}
                      onClick={(event) => event.stopPropagation()}
                      className="text-brand-600 hover:text-brand-800"
                      aria-label="Abrir trace"
                    >
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
