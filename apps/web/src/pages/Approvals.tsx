/** Fila de aprovações: ações que o agente retém por política de autonomia. */

import { useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../lib/api'
import { describeError, useAuth } from '../lib/auth'
import { useApi } from '../lib/useApi'
import type { PendingAction } from '../lib/types'
import { formatDateTime } from '../lib/format'
import {
  Badge,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  Tabs,
} from '../components/ui'
import { IconCheck, IconClose, IconCuration, IconTrace } from '../components/Icons'

const STATUS_LABEL: Record<string, string> = {
  pending: 'Pendente',
  approved: 'Aprovada (falhou ao executar)',
  rejected: 'Rejeitada',
  executed: 'Executada',
  expired: 'Expirada',
}

const STATUS_TONE: Record<string, string> = {
  pending: 'warning',
  approved: 'info',
  rejected: 'neutral',
  executed: 'success',
  expired: 'neutral',
}

export default function Approvals() {
  const { can } = useAuth()
  const [filter, setFilter] = useState('pending')
  const [busy, setBusy] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const { data, error, loading, reload } = useApi<PendingAction[]>('/approvals', {
    status: filter || undefined,
  })

  async function decide(uid: string, approve: boolean) {
    setBusy(uid)
    setActionError(null)
    try {
      await api.post(`/approvals/${uid}/decide`, { approve })
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    } finally {
      setBusy(null)
    }
  }

  return (
    <div>
      <PageHeader
        icon={<IconCuration />}
        title="Aprovações"
        subtitle="Ações retidas pelo nível de autonomia do agente ou pela marca da ferramenta."
      />

      <div className="mb-4">
        <Tabs
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'pending', label: 'Pendentes' },
            { value: 'executed', label: 'Executadas' },
            { value: 'rejected', label: 'Rejeitadas' },
            { value: '', label: 'Todas' },
          ]}
        />
      </div>

      {actionError && <div className="mb-4"><ErrorBanner message={actionError} /></div>}
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && data.length === 0 && (
        <div className="card">
          <EmptyState
            icon={<IconCuration className="h-6 w-6" />}
            title="Nada na fila"
            description="Quando um agente pedir uma ferramenta que exige autorização, ela aparece aqui."
          />
        </div>
      )}

      <div className="space-y-3">
        {(data ?? []).map((action) => (
          <article key={action.uid} className="card p-5">
            <div className="mb-3 flex flex-wrap items-center gap-2">
              <span className="text-sm font-medium text-ink-900">{action.tool_name}</span>
              <Badge tone={STATUS_TONE[action.status]}>
                {STATUS_LABEL[action.status] ?? action.status}
              </Badge>
              <span className="text-sm text-ink-500">· {action.service_name}</span>
              <span className="ml-auto text-xs text-ink-400">
                {formatDateTime(action.created_at)}
              </span>
            </div>

            <p className="mb-3 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-900">
              {action.reason}
            </p>

            <p className="mb-1 text-xs font-medium uppercase tracking-wide text-ink-400">
              Argumentos
            </p>
            <pre className="overflow-x-auto rounded-lg bg-ink-900 p-3 text-[11px] text-ink-100">
              {JSON.stringify(action.arguments_json, null, 2)}
            </pre>

            {action.error && (
              <p className="mt-3 rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-800">
                {action.error}
              </p>
            )}

            {action.status === 'executed' && (
              <>
                <p className="mb-1 mt-3 text-xs font-medium uppercase tracking-wide text-ink-400">
                  Resultado
                </p>
                <pre className="max-h-40 overflow-auto rounded-lg bg-ink-50 p-3 text-[11px] text-ink-700">
                  {JSON.stringify(action.result_json, null, 2)}
                </pre>
              </>
            )}

            <div className="mt-4 flex flex-wrap items-center gap-2">
              {action.status === 'pending' && can('runtime:approve') && (
                <>
                  <button
                    type="button"
                    className="btn-primary px-3 py-1.5 text-xs"
                    disabled={busy === action.uid}
                    onClick={() => void decide(action.uid, true)}
                  >
                    <IconCheck className="h-3.5 w-3.5" />
                    Aprovar e executar
                  </button>
                  <button
                    type="button"
                    className="btn-ghost px-3 py-1.5 text-xs text-rose-600"
                    disabled={busy === action.uid}
                    onClick={() => void decide(action.uid, false)}
                  >
                    <IconClose className="h-3.5 w-3.5" />
                    Rejeitar
                  </button>
                </>
              )}
              {action.decided_by && (
                <span className="text-xs text-ink-500">
                  decidido por {action.decided_by} em {formatDateTime(action.decided_at)}
                </span>
              )}
              {action.trace_uid && (
                <Link
                  to={`/traces/${action.trace_uid}`}
                  className="ml-auto inline-flex items-center gap-1 text-xs font-medium text-brand-700 hover:underline"
                >
                  <IconTrace className="h-3 w-3" />
                  trace da execução
                </Link>
              )}
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}
