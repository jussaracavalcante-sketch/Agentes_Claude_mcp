import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import type { Page as PageType, Span, Trace, TraceDetail } from '../../lib/types'
import { formatDateTime, formatDuration, formatNumber, formatUsd } from '../../lib/format'
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
import { IconChat, IconClose, IconTask, IconTrace } from '../../components/Icons'

const KIND_TONE: Record<Span['kind'], string> = {
  chain: 'neutral',
  model: 'brand',
  tool: 'info',
  skill: 'success',
  retrieval: 'info',
  guardrail: 'warning',
  handoff: 'warning',
}

function SpanRow({
  span,
  selected,
  onSelect,
}: {
  span: Span
  selected: boolean
  onSelect: (span: Span) => void
}) {
  return (
    <button
      type="button"
      onClick={() => onSelect(span)}
      style={{ paddingLeft: `${span.depth * 16 + 8}px` }}
      className={`flex w-full items-center gap-2 rounded-md py-1.5 pr-2 text-left text-xs transition-colors ${
        selected ? 'bg-brand-50' : 'hover:bg-ink-50'
      }`}
    >
      <Badge tone={KIND_TONE[span.kind]}>{span.kind}</Badge>
      <span className="min-w-0 flex-1 truncate font-medium text-ink-800">{span.name}</span>
      {span.tokens_in > 0 && (
        <span className="shrink-0 tabular-nums text-ink-400">
          {formatNumber(span.tokens_in)}→{formatNumber(span.tokens_out)}
        </span>
      )}
      <span className="w-16 shrink-0 text-right tabular-nums text-ink-500">
        {formatDuration(span.duration_ms)}
      </span>
      <span
        className={`shrink-0 rounded px-1.5 py-0.5 text-[10px] font-semibold ${
          span.status === 'success' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'
        }`}
      >
        {span.status === 'success' ? 'OK' : 'ERRO'}
      </span>
    </button>
  )
}

function SpanInspector({ span }: { span: Span }) {
  const [tab, setTab] = useState<'overview' | 'input' | 'output' | 'metadata'>('overview')

  return (
    <div className="flex h-full flex-col">
      <div className="mb-3 flex items-center gap-2">
        <Badge tone={KIND_TONE[span.kind]}>{span.kind}</Badge>
        <Badge tone={span.status === 'success' ? 'success' : 'danger'}>{span.status}</Badge>
        <span className="ml-auto text-xs tabular-nums text-ink-500">{formatDuration(span.duration_ms)}</span>
      </div>
      <h3 className="text-sm font-semibold text-ink-900">{span.name}</h3>
      <p className="mt-0.5 font-mono text-[11px] text-ink-400">{span.uid}</p>

      <div className="my-3">
        <Tabs
          value={tab}
          onChange={setTab}
          options={[
            { value: 'overview', label: 'Overview' },
            { value: 'input', label: 'Input' },
            { value: 'output', label: 'Output' },
            { value: 'metadata', label: 'Metadata' },
          ]}
        />
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto">
        {tab === 'overview' && (
          <dl className="space-y-2.5 text-sm">
            {[
              ['Tipo', span.kind],
              ['Nome', span.name],
              ['Início', formatDateTime(span.started_at)],
              ['Duração', formatDuration(span.duration_ms)],
              ['Status', span.status],
              ['Modelo', span.model ?? '—'],
              ['Tokens entrada', formatNumber(span.tokens_in)],
              ['Tokens saída', formatNumber(span.tokens_out)],
              ['Custo', formatUsd(span.cost_usd)],
            ].map(([label, value]) => (
              <div key={label} className="flex items-start justify-between gap-4 border-b border-ink-100 pb-2 last:border-0">
                <dt className="text-ink-500">{label}</dt>
                <dd className="text-right text-ink-800">{value}</dd>
              </div>
            ))}
            {span.error && <p className="rounded-lg bg-rose-50 p-3 text-xs text-rose-700">{span.error}</p>}
          </dl>
        )}
        {tab !== 'overview' && (
          <pre className="overflow-x-auto rounded-lg bg-ink-900 p-3 text-[11px] leading-relaxed text-ink-100">
            {JSON.stringify(
              tab === 'input' ? span.input_json : tab === 'output' ? span.output_json : span.metadata_json,
              null,
              2,
            )}
          </pre>
        )}
      </div>
    </div>
  )
}

export function TraceDrawer({ uid, onClose }: { uid: string; onClose: () => void }) {
  const { data, error, loading } = useApi<TraceDetail>(`/traces/${uid}`)
  const [selected, setSelected] = useState<Span | null>(null)

  useEffect(() => {
    if (data && data.spans.length > 0) setSelected(data.spans[0])
  }, [data])

  useEffect(() => {
    const handler = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  return (
    <div className="fixed inset-0 z-40 flex">
      <button type="button" aria-label="Fechar" className="flex-1 bg-ink-900/40" onClick={onClose} />
      <div className="flex w-full max-w-5xl flex-col bg-white shadow-pop">
        <header className="flex items-start justify-between gap-4 border-b border-ink-200 p-5">
          <div>
            <h2 className="text-lg font-semibold text-ink-900">
              Detalhe do Trace {data ? `— ${data.reference_label}` : ''}
            </h2>
            <p className="mt-0.5 text-sm text-ink-500">
              Árvore de execução, inputs/outputs e tokens por span.
            </p>
          </div>
          <button type="button" onClick={onClose} className="rounded-md p-1.5 text-ink-500 hover:bg-ink-100" aria-label="Fechar">
            <IconClose />
          </button>
        </header>

        {loading && <Loading />}
        {error && <div className="p-5"><ErrorBanner message={error} /></div>}

        {data && (
          <>
            <div className="border-b border-ink-200 p-5">
              <div className="mb-3 flex flex-wrap items-center gap-2">
                <Badge tone={data.origin === 'chat' ? 'info' : 'warning'} icon={data.origin === 'chat' ? <IconChat className="h-3 w-3" /> : <IconTask className="h-3 w-3" />}>
                  {data.origin === 'chat' ? 'Chat' : 'Task'}
                </Badge>
                <Badge tone={data.status === 'ok' ? 'success' : 'danger'}>{data.status.toUpperCase()}</Badge>
                <Badge tone="brand">{data.model ?? '—'}</Badge>
                <code className="ml-auto font-mono text-[11px] text-ink-400">{data.uid}</code>
              </div>
              <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
                {[
                  ['INICIADO', formatDateTime(data.started_at)],
                  ['DURAÇÃO', formatDuration(data.duration_ms)],
                  ['TOKENS ENTRADA', formatNumber(data.tokens_in)],
                  ['TOKENS SAÍDA', formatNumber(data.tokens_out)],
                  ['TOKENS RACIOCÍNIO', formatNumber(data.tokens_reasoning)],
                  ['CUSTO', formatUsd(data.cost_usd)],
                ].map(([label, value]) => (
                  <div key={label}>
                    <dt className="text-[10px] font-semibold uppercase tracking-wide text-ink-400">{label}</dt>
                    <dd className="mt-0.5 text-sm text-ink-800">{value}</dd>
                  </div>
                ))}
              </dl>
              <p className="mt-3 text-xs text-ink-500">
                {data.reference_label} · {data.service_name}
              </p>
            </div>

            <div className="grid min-h-0 flex-1 gap-4 overflow-hidden p-5 lg:grid-cols-2">
              <div className="flex min-h-0 flex-col rounded-lg border border-ink-200">
                <div className="flex items-center justify-between border-b border-ink-100 px-3 py-2">
                  <span className="text-xs font-medium text-ink-600">{data.spans.length} span(s)</span>
                </div>
                <div className="min-h-0 flex-1 overflow-y-auto p-1.5">
                  {data.spans.map((span) => (
                    <SpanRow
                      key={span.uid}
                      span={span}
                      selected={selected?.uid === span.uid}
                      onSelect={setSelected}
                    />
                  ))}
                </div>
              </div>

              <div className="min-h-0 overflow-hidden rounded-lg border border-ink-200 p-4">
                {selected ? <SpanInspector span={selected} /> : <p className="text-sm text-ink-400">Selecione um span.</p>}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}

export default function Traces() {
  const { uid } = useParams()
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [origin, setOrigin] = useState('')
  const [page, setPage] = useState(1)

  const { data, error, loading, reload } = useApi<PageType<Trace>>('/traces', {
    q: query || undefined,
    origin: origin || undefined,
    page,
    page_size: 25,
  })

  const columns = useMemo(
    () => [
      {
        key: 'origin',
        header: 'Origem',
        render: (row: Trace) => (
          <Badge tone={row.origin === 'chat' ? 'info' : 'warning'}>
            {row.origin === 'chat' ? 'Chat' : 'Task'}
          </Badge>
        ),
      },
      { key: 'start', header: 'Início', render: (row: Trace) => formatDateTime(row.started_at) },
      { key: 'service', header: 'Serviço', render: (row: Trace) => <span className="font-medium text-ink-800">{row.service_name}</span> },
      { key: 'ref', header: 'Referência', render: (row: Trace) => row.reference_label },
      { key: 'model', header: 'Modelo', render: (row: Trace) => <code className="text-xs text-ink-500">{row.model}</code> },
      { key: 'spans', header: 'Spans', render: (row: Trace) => row.span_count },
      { key: 'duration', header: 'Duração', render: (row: Trace) => formatDuration(row.duration_ms) },
      {
        key: 'tokens',
        header: 'Tokens',
        render: (row: Trace) => (
          <span className="tabular-nums">
            {formatNumber(row.tokens_in)} → {formatNumber(row.tokens_out)}
          </span>
        ),
      },
      { key: 'cost', header: 'Custo', render: (row: Trace) => formatUsd(row.cost_usd) },
      {
        key: 'status',
        header: 'Status',
        render: (row: Trace) => (
          <Badge tone={row.status === 'ok' ? 'success' : 'danger'}>{row.status.toUpperCase()}</Badge>
        ),
      },
    ],
    [],
  )

  return (
    <div>
      <PageHeader
        icon={<IconTrace />}
        title="Traces"
        subtitle="Execuções de IA (chat e task), com spans, tokens e custo por requisição"
      />

      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <Tabs
          value={origin}
          options={[
            { value: '', label: 'Todos' },
            { value: 'chat', label: 'Chat' },
            { value: 'task', label: 'Task' },
          ]}
          onChange={(value) => {
            setOrigin(value)
            setPage(1)
          }}
        />
        <SearchInput
          value={query}
          onChange={(value) => {
            setQuery(value)
            setPage(1)
          }}
          placeholder="Trace UID, Chat ID ou Task ID"
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
            onRowClick={(row) => navigate(`/traces/${row.uid}`)}
            columns={columns}
            empty={<EmptyState icon={<IconTrace className="h-6 w-6" />} title="Nenhum trace encontrado" />}
          />
          <Pagination page={data.page} pageSize={data.page_size} total={data.total} onChange={setPage} />
        </div>
      )}

      {uid && <TraceDrawer uid={uid} onClose={() => navigate('/traces')} />}
    </div>
  )
}
