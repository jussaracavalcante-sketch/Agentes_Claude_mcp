/** Ciclo de vida: versões, implantações e portabilidade. */

import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import { api } from '../../lib/api'
import { describeError, useAuth } from '../../lib/auth'
import type { Deployment, PortabilityJobRow, Version } from '../../lib/types'
import { formatDateTime } from '../../lib/format'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  SearchInput,
  Tabs,
} from '../../components/ui'
import { IconCheck, IconExport, IconLifecycle, IconRefresh } from '../../components/Icons'

const VERSION_TONE: Record<string, string> = {
  draft: 'neutral',
  review: 'info',
  approved: 'info',
  published: 'success',
  rolled_back: 'warning',
  terminated: 'danger',
}

const VERSION_LABEL: Record<string, string> = {
  draft: 'Rascunho',
  review: 'Em revisão',
  approved: 'Aprovada',
  published: 'Publicada',
  rolled_back: 'Revertida',
  terminated: 'Encerrada',
}

const ENVIRONMENT_LABEL: Record<string, string> = {
  development: 'Desenvolvimento',
  staging: 'Homologação',
  production: 'Produção',
}

export function VersionsPage() {
  const [params] = useSearchParams()
  const { can } = useAuth()
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('')
  const [busy, setBusy] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)

  const serviceUid = params.get('service') ?? ''
  const { data, error, loading, reload } = useApi<Version[]>('/versions', {
    service_uid: serviceUid || undefined,
    status: status || undefined,
    q: query || undefined,
  })

  async function run(action: 'approve' | 'deploy' | 'rollback', version: Version) {
    setBusy(version.uid)
    setActionError(null)
    setNotice(null)
    try {
      if (action === 'approve') {
        await api.post(`/versions/${version.uid}/approve`)
        setNotice(`Versão ${version.version} aprovada.`)
      } else if (action === 'deploy') {
        await api.post(`/versions/${version.uid}/deploy`, { environment: 'production' })
        setNotice(`Versão ${version.version} publicada em produção.`)
      } else {
        await api.post(`/versions/${version.uid}/rollback`)
        setNotice(`Serviço revertido para ${version.version}.`)
      }
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
        icon={<IconLifecycle />}
        title="Versões"
        subtitle="Gerenciamento de versões de serviços — aprovação, publicação e rollback."
      />

      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <Tabs
          value={status}
          onChange={setStatus}
          options={[
            { value: '', label: 'Todos os status' },
            { value: 'draft', label: 'Rascunho' },
            { value: 'approved', label: 'Aprovadas' },
            { value: 'published', label: 'Publicadas' },
            { value: 'rolled_back', label: 'Revertidas' },
          ]}
        />
        <SearchInput value={query} onChange={setQuery} placeholder="Buscar versões…" className="w-full max-w-sm" />
      </div>

      {notice && <p className="mb-4 rounded-lg bg-emerald-50 px-4 py-2.5 text-sm text-emerald-800">{notice}</p>}
      {actionError && <div className="mb-4"><ErrorBanner message={actionError} /></div>}

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={<EmptyState icon={<IconLifecycle className="h-6 w-6" />} title="Nenhuma versão encontrada" />}
            columns={[
              { key: 'service', header: 'Serviço', render: (row) => <span className="font-medium text-ink-800">{row.service_name}</span> },
              { key: 'version', header: 'Versão', render: (row) => <code className="rounded bg-ink-100 px-1.5 py-0.5 text-xs">{row.version}</code> },
              { key: 'status', header: 'Status', render: (row) => <Badge tone={VERSION_TONE[row.status]}>{VERSION_LABEL[row.status] ?? row.status}</Badge> },
              { key: 'active', header: 'Ativa', render: (row) => (row.is_active ? <Badge tone="success">em produção</Badge> : '—') },
              {
                key: 'tags',
                header: 'Tags',
                render: (row) =>
                  row.tags_json.length === 0 ? '—' : (
                    <span className="flex gap-1">{row.tags_json.map((tag) => <Badge key={tag}>{tag}</Badge>)}</span>
                  ),
              },
              { key: 'created', header: 'Criado em', render: (row) => formatDateTime(row.created_at) },
              {
                key: 'actions',
                header: 'Ações',
                render: (row) => (
                  <span className="flex items-center gap-1.5">
                    {can('lifecycle:approve') && row.status === 'draft' && (
                      <button type="button" className="btn-ghost px-2 py-1 text-xs" disabled={busy === row.uid} onClick={() => void run('approve', row)}>
                        <IconCheck className="h-3.5 w-3.5" />
                        Aprovar
                      </button>
                    )}
                    {can('lifecycle:deploy') && row.status === 'approved' && (
                      <button type="button" className="btn-primary px-2 py-1 text-xs" disabled={busy === row.uid} onClick={() => void run('deploy', row)}>
                        Publicar
                      </button>
                    )}
                    {can('lifecycle:deploy') && !row.is_active && row.status !== 'draft' && (
                      <button type="button" className="btn-ghost px-2 py-1 text-xs" disabled={busy === row.uid} onClick={() => void run('rollback', row)}>
                        <IconRefresh className="h-3.5 w-3.5" />
                        Reverter
                      </button>
                    )}
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

export function DeploymentsPage() {
  const [environment, setEnvironment] = useState('')
  const { data, error, loading, reload } = useApi<Deployment[]>('/deployments', {
    environment: environment || undefined,
  })

  return (
    <div>
      <PageHeader
        icon={<IconLifecycle />}
        title="Implantações"
        subtitle="Publicações por ambiente, com quem solicitou e quem aprovou."
      />

      <div className="mb-4">
        <Tabs
          value={environment}
          onChange={setEnvironment}
          options={[
            { value: '', label: 'Todos os ambientes' },
            { value: 'development', label: 'Desenvolvimento' },
            { value: 'staging', label: 'Homologação' },
            { value: 'production', label: 'Produção' },
          ]}
        />
      </div>

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhuma implantação registrada" />}
            columns={[
              {
                key: 'env',
                header: 'Ambiente',
                render: (row) => (
                  <Badge tone={row.environment === 'production' ? 'brand' : 'neutral'}>
                    {ENVIRONMENT_LABEL[row.environment] ?? row.environment}
                  </Badge>
                ),
              },
              {
                key: 'status',
                header: 'Status',
                render: (row) => (
                  <Badge tone={row.status === 'succeeded' ? 'success' : row.status === 'failed' ? 'danger' : 'warning'}>
                    {row.status}
                  </Badge>
                ),
              },
              { key: 'requested', header: 'Solicitado por', render: (row) => row.requested_by ?? '—' },
              { key: 'approved', header: 'Aprovado por', render: (row) => row.approved_by ?? '—' },
              { key: 'finished', header: 'Concluído em', render: (row) => formatDateTime(row.finished_at) },
              { key: 'notes', header: 'Observação', render: (row) => row.notes || '—' },
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function PortabilityPage() {
  const { can } = useAuth()
  const [busy, setBusy] = useState(false)
  const [result, setResult] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const { data, error, loading, reload } = useApi<PortabilityJobRow[]>('/portability')

  async function exportAssets() {
    setBusy(true)
    setActionError(null)
    setResult(null)
    try {
      const response = await api.post<{ item_count: number; checksum: string; bundle: unknown }>(
        '/portability/export',
        { scope: ['services', 'agents', 'skills', 'tools'] },
      )
      // Entrega o pacote ao operador: portabilidade só vale se sair da plataforma.
      const blob = new Blob([JSON.stringify(response.bundle, null, 2)], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const anchor = document.createElement('a')
      anchor.href = url
      anchor.download = `vkb-export-${response.checksum.slice(0, 8)}.json`
      anchor.click()
      URL.revokeObjectURL(url)
      setResult(`${response.item_count} ativos exportados · checksum ${response.checksum.slice(0, 16)}…`)
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div>
      <PageHeader
        icon={<IconExport />}
        title="Importar / Exportar"
        subtitle="Portabilidade dos ativos: serviços, agentes, skills e ferramentas em JSON aberto."
        actions={
          can('lifecycle:export') && (
            <button type="button" className="btn-primary" onClick={() => void exportAssets()} disabled={busy}>
              <IconExport className="h-4 w-4" />
              {busy ? 'Exportando…' : 'Exportar ativos'}
            </button>
          )
        }
      />

      {result && <p className="mb-4 rounded-lg bg-emerald-50 px-4 py-2.5 text-sm text-emerald-800">{result}</p>}
      {actionError && <div className="mb-4"><ErrorBanner message={actionError} /></div>}

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={
              <EmptyState
                icon={<IconExport className="h-6 w-6" />}
                title="Nenhuma exportação registrada"
                description="A exportação gera um pacote JSON aberto — nenhum ativo fica preso a formato proprietário."
              />
            }
            columns={[
              { key: 'direction', header: 'Operação', render: (row) => <Badge tone="brand">{row.direction}</Badge> },
              { key: 'scope', header: 'Escopo', render: (row) => row.scope_json.join(', ') },
              { key: 'items', header: 'Itens', render: (row) => row.item_count },
              { key: 'checksum', header: 'Checksum', render: (row) => <code className="text-xs text-ink-500">{row.checksum?.slice(0, 16) ?? '—'}</code> },
              { key: 'created', header: 'Data', render: (row) => formatDateTime(row.created_at) },
              { key: 'by', header: 'Solicitado por', render: (row) => row.created_by ?? '—' },
            ]}
          />
        </div>
      )}
    </div>
  )
}
