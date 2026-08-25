/** Curadoria, Evaluations, Privacidade (LGPD) e orçamentos FinOps. */

import { useState } from 'react'
import { useApi } from '../../lib/useApi'
import { api } from '../../lib/api'
import { describeError, useAuth } from '../../lib/auth'
import type { BudgetRow, CurationItem, EvaluationRow, PrivacyPolicyRow } from '../../lib/types'
import { formatDateTime, formatUsd } from '../../lib/format'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  Tabs,
} from '../../components/ui'
import { IconCheck, IconCuration, IconEval, IconPrivacy } from '../../components/Icons'

const DECISION_LABEL: Record<string, string> = {
  pending: 'Pendente',
  approved: 'Aprovada',
  rejected: 'Rejeitada',
  needs_revision: 'Requer revisão',
}

export function CurationPage() {
  const { can } = useAuth()
  const [decision, setDecision] = useState('pending')
  const [actionError, setActionError] = useState<string | null>(null)
  const { data, error, loading, reload } = useApi<CurationItem[]>('/curation', {
    decision: decision || undefined,
  })

  async function decide(uid: string, value: string) {
    setActionError(null)
    try {
      await api.post(`/curation/${uid}/decide`, { decision: value })
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    }
  }

  return (
    <div>
      <PageHeader
        icon={<IconCuration />}
        title="Curadoria"
        subtitle="Respostas amostradas para revisão humana antes de virarem padrão."
      />

      <div className="mb-4">
        <Tabs
          value={decision}
          onChange={setDecision}
          options={[
            { value: 'pending', label: 'Pendentes' },
            { value: 'approved', label: 'Aprovadas' },
            { value: '', label: 'Todas' },
          ]}
        />
      </div>

      {actionError && <div className="mb-4"><ErrorBanner message={actionError} /></div>}
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="space-y-3">
          {data.length === 0 && (
            <div className="card">
              <EmptyState icon={<IconCuration className="h-6 w-6" />} title="Nada na fila de curadoria" />
            </div>
          )}
          {data.map((item) => (
            <article key={item.uid} className="card p-5">
              <div className="mb-3 flex flex-wrap items-center gap-2">
                <span className="text-sm font-medium text-ink-900">{item.service_name}</span>
                <Badge tone="warning">{item.reason}</Badge>
                <Badge tone={item.decision === 'pending' ? 'neutral' : 'success'}>
                  {DECISION_LABEL[item.decision] ?? item.decision}
                </Badge>
                <span className="ml-auto text-xs text-ink-400">{formatDateTime(item.created_at)}</span>
              </div>
              <p className="text-sm text-ink-500">Pergunta</p>
              <p className="mb-3 text-sm text-ink-800">{item.question}</p>
              <p className="text-sm text-ink-500">Resposta do agente</p>
              <p className="rounded-lg bg-ink-50 p-3 text-sm text-ink-800">{item.answer}</p>

              {can('curation:write') && item.decision === 'pending' && (
                <div className="mt-4 flex flex-wrap gap-2">
                  <button type="button" className="btn-primary px-3 py-1.5 text-xs" onClick={() => void decide(item.uid, 'approved')}>
                    <IconCheck className="h-3.5 w-3.5" />
                    Aprovar
                  </button>
                  <button type="button" className="btn-ghost px-3 py-1.5 text-xs" onClick={() => void decide(item.uid, 'needs_revision')}>
                    Requer revisão
                  </button>
                  <button type="button" className="btn-ghost px-3 py-1.5 text-xs text-rose-600" onClick={() => void decide(item.uid, 'rejected')}>
                    Rejeitar
                  </button>
                </div>
              )}
            </article>
          ))}
        </div>
      )}
    </div>
  )
}

export function EvaluationsPage() {
  const { data, error, loading, reload } = useApi<EvaluationRow[]>('/evaluations')

  return (
    <div>
      <PageHeader
        icon={<IconEval />}
        title="Evaluations"
        subtitle="Suites de regressão executadas antes de publicar em produção."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={<EmptyState icon={<IconEval className="h-6 w-6" />} title="Nenhuma avaliação configurada" />}
            columns={[
              { key: 'name', header: 'Avaliação', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'service', header: 'Serviço', render: (row) => row.service_name },
              { key: 'metric', header: 'Métrica', render: (row) => <Badge tone="info">{row.metric}</Badge> },
              { key: 'cases', header: 'Casos', render: (row) => row.case_count },
              { key: 'threshold', header: 'Limiar', render: (row) => `${(row.threshold * 100).toFixed(0)}%` },
              {
                key: 'score',
                header: 'Última execução',
                render: (row) =>
                  row.last_score === null ? (
                    '—'
                  ) : (
                    <span className="flex items-center gap-2">
                      <span className="tabular-nums">{(row.last_score * 100).toFixed(1)}%</span>
                      <Badge tone={row.last_passed ? 'success' : 'danger'}>
                        {row.last_passed ? 'aprovada' : 'reprovada'}
                      </Badge>
                    </span>
                  ),
              },
              { key: 'gate', header: 'Gate', render: (row) => (row.is_gate ? <Badge tone="brand">bloqueia deploy</Badge> : '—') },
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function PrivacyPage() {
  const policies = useApi<PrivacyPolicyRow[]>('/privacy/policies')
  const budgets = useApi<BudgetRow[]>('/finops/budgets')

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconPrivacy />}
        title="Privacidade e FinOps"
        subtitle="Políticas de retenção de dado pessoal (LGPD) e limites de consumo por escopo."
      />

      {policies.loading && <Loading />}
      {policies.error && <ErrorBanner message={policies.error} onRetry={policies.reload} />}

      {policies.data && (
        <section className="card">
          <div className="border-b border-ink-100 px-5 py-4">
            <h2 className="text-base font-semibold text-ink-900">Políticas de dados</h2>
            <p className="mt-0.5 text-sm text-ink-500">
              Base legal, retenção e uso pelo provedor de IA — por categoria de dado.
            </p>
          </div>
          <DataTable
            rows={policies.data}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhuma política definida" />}
            columns={[
              { key: 'name', header: 'Política', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'category', header: 'Categoria', render: (row) => <Badge tone={row.data_category === 'dado_pessoal' ? 'warning' : 'neutral'}>{row.data_category}</Badge> },
              { key: 'basis', header: 'Base legal', render: (row) => row.legal_basis },
              { key: 'retention', header: 'Retenção', render: (row) => `${row.retention_days} dias` },
              { key: 'redact', header: 'Mascarar PII', render: (row) => (row.redact_pii ? <Badge tone="success">sim</Badge> : <Badge tone="danger">não</Badge>) },
              {
                key: 'training',
                header: 'Treino do provedor',
                render: (row) => (row.allow_provider_training ? <Badge tone="danger">permitido</Badge> : <Badge tone="success">vedado</Badge>),
              },
              { key: 'region', header: 'Região', render: (row) => row.storage_region },
            ]}
          />
        </section>
      )}

      {budgets.data && (
        <section className="card">
          <div className="border-b border-ink-100 px-5 py-4">
            <h2 className="text-base font-semibold text-ink-900">Orçamentos FinOps</h2>
            <p className="mt-0.5 text-sm text-ink-500">
              Consumo do mês corrente contra o limite definido por serviço ou unidade.
            </p>
          </div>
          <DataTable
            rows={budgets.data}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhum limite configurado" />}
            columns={[
              { key: 'scope', header: 'Escopo', render: (row) => <Badge tone="info">{row.scope}</Badge> },
              { key: 'label', header: 'Alvo', render: (row) => <span className="font-medium text-ink-900">{row.scope_label}</span> },
              { key: 'limit', header: 'Limite', render: (row) => formatUsd(row.limit_usd) },
              {
                key: 'consumed',
                header: 'Consumido',
                render: (row) => {
                  const ratio = row.limit_usd > 0 ? row.consumed_usd / row.limit_usd : 0
                  const tone = ratio >= 1 ? 'danger' : ratio * 100 >= row.alert_at_percent ? 'warning' : 'success'
                  return (
                    <span className="flex items-center gap-2">
                      <span className="tabular-nums">{formatUsd(row.consumed_usd)}</span>
                      <Badge tone={tone}>{(ratio * 100).toFixed(0)}%</Badge>
                    </span>
                  )
                },
              },
              { key: 'alert', header: 'Alerta em', render: (row) => `${row.alert_at_percent}%` },
              { key: 'stop', header: 'Bloqueio duro', render: (row) => (row.hard_stop ? <Badge tone="danger">sim</Badge> : '—') },
            ]}
          />
        </section>
      )}
    </div>
  )
}
