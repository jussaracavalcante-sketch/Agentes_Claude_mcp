/** Telas de catálogo do AI Studio: agentes, skills, ferramentas,
 *  integrações, conhecimento e modelos do LLM Gateway. */

import { useState } from 'react'
import { useApi } from '../../lib/useApi'
import type {
  Agent,
  IndexResponse,
  Integration,
  KnowledgeBase,
  LLMModelRow,
  RetrieveResponse,
  Skill,
  Tool,
} from '../../lib/types'
import { AUTONOMY_LABEL, formatNumber, formatUsd } from '../../lib/format'
import { api } from '../../lib/api'
import { describeError, useAuth } from '../../lib/auth'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  SearchInput,
} from '../../components/ui'
import {
  IconBook,
  IconGateway,
  IconPlug,
  IconRefresh,
  IconSearch,
  IconStudio,
  IconTool,
  IconUsers,
} from '../../components/Icons'

function useFiltered<T>(rows: T[] | null, query: string, match: (row: T, needle: string) => boolean) {
  const needle = query.trim().toLowerCase()
  if (!rows) return []
  if (!needle) return rows
  return rows.filter((row) => match(row, needle))
}

export function AgentsPage() {
  const [query, setQuery] = useState('')
  const { data, error, loading, reload } = useApi<Agent[]>('/agents')
  const rows = useFiltered(data, query, (row, needle) =>
    `${row.name} ${row.role} ${row.description}`.toLowerCase().includes(needle),
  )

  return (
    <div>
      <PageHeader
        icon={<IconUsers />}
        title="Agentes"
        subtitle="Agentes especializados com instruções, papéis e nível de autonomia."
        actions={<SearchInput value={query} onChange={setQuery} placeholder="Buscar agentes…" className="w-64" />}
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {rows.map((agent) => (
            <article key={agent.uid} className="card flex flex-col gap-3 p-4">
              <div className="flex items-start justify-between gap-2">
                <h3 className="text-sm font-medium text-ink-900">{agent.name}</h3>
                <Badge tone={agent.is_enabled ? 'success' : 'neutral'}>
                  {agent.is_enabled ? 'ativo' : 'inativo'}
                </Badge>
              </div>
              <p className="line-clamp-3 text-xs leading-relaxed text-ink-500">{agent.description}</p>
              <dl className="grid grid-cols-2 gap-2 border-t border-ink-100 pt-3 text-xs">
                <div>
                  <dt className="text-ink-400">Papel</dt>
                  <dd className="text-ink-700">{agent.role || '—'}</dd>
                </div>
                <div>
                  <dt className="text-ink-400">Modelo</dt>
                  <dd className="truncate text-ink-700">{agent.model_code ?? '—'}</dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-ink-400">Autonomia</dt>
                  <dd className="text-ink-700">{AUTONOMY_LABEL[agent.autonomy] ?? agent.autonomy}</dd>
                </div>
              </dl>
              <div className="flex flex-wrap gap-1.5">
                <Badge tone="info">{agent.tool_uids.length} ferramentas</Badge>
                <Badge tone="brand">{agent.skill_uids.length} skills</Badge>
                <Badge>temp {agent.temperature}</Badge>
              </div>
            </article>
          ))}
          {rows.length === 0 && (
            <div className="card md:col-span-2 xl:col-span-3">
              <EmptyState icon={<IconUsers className="h-6 w-6" />} title="Nenhum agente encontrado" />
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export function SkillsPage() {
  const [query, setQuery] = useState('')
  const { data, error, loading, reload } = useApi<Skill[]>('/skills')
  const rows = useFiltered(data, query, (row, needle) =>
    `${row.name} ${row.description}`.toLowerCase().includes(needle),
  )

  return (
    <div>
      <PageHeader
        icon={<IconStudio />}
        title="Skills"
        subtitle="Habilidades reutilizáveis pelos agentes."
        actions={<SearchInput value={query} onChange={setQuery} placeholder="Buscar skills…" className="w-64" />}
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="card">
          <DataTable
            rows={rows}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhuma skill cadastrada" />}
            columns={[
              { key: 'name', header: 'Skill', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'description', header: 'Descrição', render: (row) => row.description },
              {
                key: 'status',
                header: 'Status',
                render: (row) => (
                  <Badge tone={row.is_enabled ? 'success' : 'neutral'}>
                    {row.is_enabled ? 'ativa' : 'inativa'}
                  </Badge>
                ),
              },
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function ToolsPage() {
  const { data, error, loading, reload } = useApi<Tool[]>('/tools')

  return (
    <div>
      <PageHeader icon={<IconTool />} title="Ferramentas" subtitle="Chamadas que os agentes podem executar." />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="card">
          <DataTable
            rows={data ?? []}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhuma ferramenta cadastrada" />}
            columns={[
              { key: 'name', header: 'Ferramenta', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'kind', header: 'Tipo', render: (row) => <Badge tone="info">{row.kind}</Badge> },
              { key: 'description', header: 'Descrição', render: (row) => row.description },
              {
                key: 'approval',
                header: 'Aprovação humana',
                render: (row) =>
                  row.requires_approval ? <Badge tone="warning">exigida</Badge> : <span className="text-ink-400">—</span>,
              },
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function IntegrationsPage() {
  const { data, error, loading, reload } = useApi<Integration[]>('/integrations')

  return (
    <div>
      <PageHeader
        icon={<IconPlug />}
        title="Integrações"
        subtitle="Conectores com CRM, ERP, mídia, canais e sistemas legados."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="card">
          <DataTable
            rows={data ?? []}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhuma integração configurada" />}
            columns={[
              { key: 'name', header: 'Integração', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'system', header: 'Sistema', render: (row) => row.system },
              { key: 'kind', header: 'Tipo', render: (row) => <Badge tone="info">{row.kind}</Badge> },
              { key: 'auth', header: 'Autenticação', render: (row) => row.auth_type },
              { key: 'rate', header: 'Limite/min', render: (row) => formatNumber(row.rate_limit_per_min) },
              {
                key: 'status',
                header: 'Status',
                render: (row) => (
                  <span className="flex flex-col gap-1">
                    <Badge tone={row.status === 'connected' ? 'success' : 'warning'}>{row.status}</Badge>
                    {row.last_error && <span className="text-xs text-amber-700">{row.last_error}</span>}
                  </span>
                ),
              },
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function KnowledgePage() {
  const { can } = useAuth()
  const { data, error, loading, reload } = useApi<KnowledgeBase[]>('/knowledge')
  const [busy, setBusy] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  async function reindex(uid: string) {
    setBusy(uid)
    setNotice(null)
    setActionError(null)
    try {
      const result = await api.post<IndexResponse>(`/knowledge/${uid}/index`, {
        embedder: 'hashing',
      })
      setNotice(
        `${result.base_name}: ${result.documents} documento(s) e ${result.chunks} trecho(s) ` +
          `indexados com o embedder '${result.embedder}'.`,
      )
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    } finally {
      setBusy(null)
    }
  }

  return (
    <div className="space-y-5">
      <PageHeader
        icon={<IconBook />}
        title="Conhecimento"
        subtitle="Bases indexadas para recuperação semântica, com classificação de dado."
      />

      {notice && (
        <p className="rounded-lg bg-emerald-50 px-4 py-2.5 text-sm text-emerald-800">{notice}</p>
      )}
      {actionError && <ErrorBanner message={actionError} />}

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {(data ?? []).map((base) => (
            <article key={base.uid} className="card flex flex-col gap-3 p-4">
              <h3 className="text-sm font-medium text-ink-900">{base.name}</h3>
              <p className="text-xs leading-relaxed text-ink-500">{base.description}</p>
              <div className="flex flex-wrap gap-1.5 border-t border-ink-100 pt-3">
                <Badge tone="brand">{base.document_count} documentos</Badge>
                <Badge tone={base.data_classification === 'confidencial' ? 'danger' : 'neutral'}>
                  {base.data_classification}
                </Badge>
                <Badge>{base.embedding_model}</Badge>
              </div>
              {can('knowledge:index') && (
                <button
                  type="button"
                  className="btn-ghost mt-1 w-fit px-2.5 py-1.5 text-xs"
                  disabled={busy === base.uid}
                  onClick={() => void reindex(base.uid)}
                >
                  <IconRefresh className="h-3.5 w-3.5" />
                  {busy === base.uid ? 'Indexando…' : 'Reindexar'}
                </button>
              )}
            </article>
          ))}
        </div>
      )}

      <RetrievalTester />
    </div>
  )
}

function RetrievalTester() {
  const [query, setQuery] = useState('')
  const [result, setResult] = useState<RetrieveResponse | null>(null)
  const [busy, setBusy] = useState(false)
  const [testError, setTestError] = useState<string | null>(null)

  async function search(event: React.FormEvent) {
    event.preventDefault()
    if (!query.trim()) return
    setBusy(true)
    setTestError(null)
    try {
      setResult(await api.post<RetrieveResponse>('/knowledge/retrieve', { query, top_k: 5 }))
    } catch (caught) {
      setTestError(describeError(caught))
    } finally {
      setBusy(false)
    }
  }

  return (
    <section className="card p-5">
      <h2 className="text-base font-semibold text-ink-900">Testar recuperação</h2>
      <p className="mt-0.5 text-sm text-ink-500">
        A mesma busca que o agente executa quando aciona a ferramenta de conhecimento.
      </p>

      <form onSubmit={search} className="mt-4 flex flex-wrap items-center gap-2">
        <div className="relative min-w-[18rem] flex-1">
          <IconSearch className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-ink-400" />
          <input
            className="input pl-9"
            placeholder="Ex: qual o prazo de veiculação em Manaus?"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
        <button type="submit" className="btn-primary" disabled={busy || !query.trim()}>
          {busy ? 'Buscando…' : 'Buscar'}
        </button>
      </form>

      {testError && <div className="mt-4"><ErrorBanner message={testError} /></div>}

      {result && (
        <div className="mt-4">
          <p className="mb-3 text-xs text-ink-500">
            {result.hits} trecho(s) · embedder <code>{result.embedder}</code>
          </p>
          {result.hits === 0 ? (
            <EmptyState title="Nenhum trecho relevante" description="Reindexe a base ou reformule a pergunta." />
          ) : (
            <ol className="space-y-2">
              {result.chunks.map((chunk) => (
                <li key={chunk.chunk_uid} className="rounded-lg border border-ink-200 p-3">
                  <div className="mb-1.5 flex items-center gap-2">
                    <Badge tone={chunk.score >= 0.3 ? 'success' : 'neutral'}>
                      {chunk.score.toFixed(3)}
                    </Badge>
                    <span className="text-sm font-medium text-ink-800">
                      {chunk.document_title}
                    </span>
                  </div>
                  <p className="whitespace-pre-wrap text-xs leading-relaxed text-ink-600">
                    {chunk.content}
                  </p>
                </li>
              ))}
            </ol>
          )}
        </div>
      )}
    </section>
  )
}

export function LLMGatewayPage() {
  const { data, error, loading, reload } = useApi<LLMModelRow[]>('/llm/models')

  return (
    <div>
      <PageHeader
        icon={<IconGateway />}
        title="LLM Gateway"
        subtitle="Modelos disponíveis por provedor. A plataforma não depende de um único fornecedor."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="card">
          <DataTable
            rows={data ?? []}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhum modelo configurado" />}
            columns={[
              { key: 'provider', header: 'Provedor', render: (row) => <Badge tone="brand">{row.provider}</Badge> },
              { key: 'name', header: 'Modelo', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'code', header: 'Código', render: (row) => <code className="text-xs text-ink-500">{row.code}</code> },
              { key: 'window', header: 'Contexto', render: (row) => `${formatNumber(row.context_window)} tokens` },
              { key: 'in', header: 'Entrada / 1k', render: (row) => formatUsd(row.input_cost_per_1k) },
              { key: 'out', header: 'Saída / 1k', render: (row) => formatUsd(row.output_cost_per_1k) },
              {
                key: 'status',
                header: 'Status',
                render: (row) => (
                  <Badge tone={row.is_enabled ? 'success' : 'neutral'}>{row.is_enabled ? 'habilitado' : 'desabilitado'}</Badge>
                ),
              },
            ]}
          />
        </div>
      )}
    </div>
  )
}
