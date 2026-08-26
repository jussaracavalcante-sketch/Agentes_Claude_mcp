/** Área de Segurança: visão geral, usuários, papéis, unidades, chaves,
 *  funcionalidades e trilha de auditoria. */

import { useState } from 'react'
import { useApi } from '../../lib/useApi'
import { api } from '../../lib/api'
import { describeError, useAuth } from '../../lib/auth'
import type {
  ApiKeyRow,
  AuditLogRow,
  FeatureFlagRow,
  Page as PageType,
  RoleRow,
  SecurityOverview as SecurityOverviewType,
  UnitRow,
  UserRow,
} from '../../lib/types'
import { formatBrl, formatDateTime } from '../../lib/format'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  Pagination,
  SearchInput,
  StatCard,
} from '../../components/ui'
import { IconKey, IconLock, IconPlus, IconUsers } from '../../components/Icons'

export function SecurityOverviewPage() {
  const { data, error, loading, reload } = useApi<SecurityOverviewType>('/security/overview')

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconLock />}
        title="Visão Geral de Segurança"
        subtitle="Acompanhe identidades e papéis ativos no tenant."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <StatCard label="Usuários" value={data.users_total} hint="Total de usuários cadastrados no tenant" icon={<IconUsers />} to="/seguranca/usuarios" />
          <StatCard label="Papéis & Permissões" value={data.roles_total} hint="Total de papéis cadastrados no tenant" icon={<IconLock />} to="/seguranca/papeis" />
          <StatCard label="Usuários ativos" value={data.users_active} hint="Com acesso liberado ao console" icon={<IconUsers />} />
          <StatCard label="Chaves de API ativas" value={data.api_keys_active} hint="Credenciais de integração vigentes" icon={<IconKey />} to="/seguranca/chaves" />
          <StatCard label="Unidades" value={data.units_total} hint="Centros de custo cadastrados" icon={<IconLock />} to="/seguranca/unidades" />
          <StatCard label="Eventos de auditoria (30d)" value={data.audit_events_30d} hint="Registros na trilha do período" icon={<IconLock />} to="/seguranca/auditoria" />
        </div>
      )}
    </div>
  )
}

export function UsersPage() {
  const { can } = useAuth()
  const [query, setQuery] = useState('')
  const { data, error, loading, reload } = useApi<UserRow[]>('/security/users', {
    q: query || undefined,
  })

  return (
    <div>
      <PageHeader
        icon={<IconUsers />}
        title="Usuários"
        subtitle="Identidades do tenant, com papéis e unidade organizacional."
        actions={<SearchInput value={query} onChange={setQuery} placeholder="Buscar usuários…" className="w-64" />}
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhum usuário encontrado" />}
            columns={[
              {
                key: 'name',
                header: 'Usuário',
                render: (row) => (
                  <span>
                    <span className="block font-medium text-ink-900">{row.name}</span>
                    <span className="block text-xs text-ink-500">{row.email}</span>
                  </span>
                ),
              },
              { key: 'unit', header: 'Unidade', render: (row) => row.unit?.name ?? '—' },
              {
                key: 'roles',
                header: 'Papéis',
                render: (row) => (
                  <span className="flex flex-wrap gap-1">
                    {row.roles.length === 0 && '—'}
                    {row.roles.map((role) => (
                      <Badge key={role} tone={role === 'admin' ? 'brand' : 'neutral'}>
                        {role}
                      </Badge>
                    ))}
                  </span>
                ),
              },
              { key: 'last', header: 'Último acesso', render: (row) => formatDateTime(row.last_login_at) },
              {
                key: 'status',
                header: 'Status',
                render: (row) => (
                  <span className="flex flex-wrap gap-1">
                    <Badge tone={row.is_active ? 'success' : 'danger'}>{row.is_active ? 'ativo' : 'inativo'}</Badge>
                    {row.must_change_password && <Badge tone="warning">trocar senha</Badge>}
                  </span>
                ),
              },
              ...(can('security:write')
                ? [
                    {
                      key: 'actions',
                      header: 'Ações',
                      render: (row: UserRow) => <ResetPasswordButton uid={row.uid} />,
                    },
                  ]
                : []),
            ]}
          />
        </div>
      )}
    </div>
  )
}

function ResetPasswordButton({ uid }: { uid: string }) {
  const [state, setState] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function reset() {
    setBusy(true)
    try {
      const response = await api.post<{ detail: string }>(`/security/users/${uid}/reset-password`)
      setState(response.detail)
    } catch (caught) {
      setState(describeError(caught))
    } finally {
      setBusy(false)
    }
  }

  if (state) return <span className="text-xs text-emerald-700">{state}</span>

  return (
    <button type="button" className="btn-ghost px-2 py-1 text-xs" onClick={() => void reset()} disabled={busy}>
      Redefinir senha
    </button>
  )
}

export function RolesPage() {
  const { data, error, loading, reload } = useApi<RoleRow[]>('/security/roles')

  return (
    <div>
      <PageHeader
        icon={<IconLock />}
        title="Papéis & Permissões"
        subtitle="Controle de acesso por função. Papéis de sistema não são editáveis."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="grid gap-4 md:grid-cols-2">
          {data.map((role) => (
            <article key={role.uid} className="card p-5">
              <div className="mb-2 flex items-start justify-between gap-3">
                <div>
                  <h3 className="text-sm font-semibold text-ink-900">{role.name}</h3>
                  <code className="text-xs text-ink-500">{role.code}</code>
                </div>
                {role.is_system && <Badge tone="brand">sistema</Badge>}
              </div>
              <p className="mb-3 text-sm text-ink-600">{role.description}</p>
              <div className="flex flex-wrap gap-1">
                {role.permissions.map((permission) => (
                  <span key={permission} className="rounded bg-ink-100 px-1.5 py-0.5 font-mono text-[11px] text-ink-600">
                    {permission}
                  </span>
                ))}
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  )
}

export function UnitsPage() {
  const { data, error, loading, reload } = useApi<UnitRow[]>('/security/units')

  return (
    <div>
      <PageHeader
        icon={<IconLock />}
        title="Unidades"
        subtitle="Unidades organizacionais e centros de custo para rateio do consumo."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhuma unidade cadastrada" />}
            columns={[
              { key: 'code', header: 'Código', render: (row) => <code className="text-xs">{row.code}</code> },
              { key: 'name', header: 'Unidade', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'cc', header: 'Centro de custo', render: (row) => row.cost_center ?? '—' },
              { key: 'budget', header: 'Orçamento mensal', render: (row) => formatBrl(row.monthly_budget_brl) },
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function ApiKeysPage() {
  const { can } = useAuth()
  const [secret, setSecret] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const { data, error, loading, reload } = useApi<ApiKeyRow[]>('/security/api-keys')

  async function createKey(name: string) {
    setActionError(null)
    try {
      const created = await api.post<{ secret: string }>('/security/api-keys', { name, scopes: [] })
      setSecret(created.secret)
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    }
  }

  async function revoke(uid: string) {
    try {
      await api.delete(`/security/api-keys/${uid}`)
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    }
  }

  return (
    <div>
      <PageHeader
        icon={<IconKey />}
        title="Chaves de API"
        subtitle="Credenciais de integração. O segredo é exibido uma única vez, na criação."
      />

      {can('security:write') && (
        <form
          className="card mb-4 flex flex-wrap items-end gap-3 p-4"
          onSubmit={(event) => {
            event.preventDefault()
            const form = new FormData(event.currentTarget)
            void createKey(String(form.get('name')))
            event.currentTarget.reset()
          }}
        >
          <div className="min-w-[16rem] flex-1">
            <label htmlFor="key-name" className="mb-1.5 block text-sm font-medium text-ink-700">
              Nome da chave
            </label>
            <input id="key-name" name="name" required className="input" placeholder="Ex: Integração portal interno" />
          </div>
          <button type="submit" className="btn-primary">
            <IconPlus className="h-4 w-4" />
            Emitir chave
          </button>
        </form>
      )}

      {secret && (
        <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 p-4">
          <p className="text-sm font-medium text-amber-900">Guarde este segredo agora — ele não será exibido novamente.</p>
          <code className="mt-2 block break-all rounded bg-white px-3 py-2 font-mono text-xs text-ink-800">{secret}</code>
        </div>
      )}
      {actionError && <div className="mb-4"><ErrorBanner message={actionError} /></div>}

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <div className="card">
          <DataTable
            rows={data}
            rowKey={(row) => row.uid}
            empty={<EmptyState icon={<IconKey className="h-6 w-6" />} title="Nenhuma chave emitida" />}
            columns={[
              { key: 'name', header: 'Nome', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
              { key: 'prefix', header: 'Prefixo', render: (row) => <code className="text-xs">{row.prefix}…</code> },
              { key: 'created', header: 'Criada em', render: (row) => formatDateTime(row.created_at) },
              { key: 'used', header: 'Último uso', render: (row) => formatDateTime(row.last_used_at) },
              {
                key: 'status',
                header: 'Status',
                render: (row) => <Badge tone={row.is_active ? 'success' : 'neutral'}>{row.is_active ? 'ativa' : 'revogada'}</Badge>,
              },
              ...(can('security:write')
                ? [
                    {
                      key: 'actions',
                      header: 'Ações',
                      render: (row: ApiKeyRow) =>
                        row.is_active ? (
                          <button type="button" className="btn-ghost px-2 py-1 text-xs text-rose-600" onClick={() => void revoke(row.uid)}>
                            Revogar
                          </button>
                        ) : (
                          '—'
                        ),
                    },
                  ]
                : []),
            ]}
          />
        </div>
      )}
    </div>
  )
}

export function FeatureFlagsPage() {
  const { can } = useAuth()
  const { data, error, loading, reload } = useApi<FeatureFlagRow[]>('/security/feature-flags')

  async function toggle(uid: string, enabled: boolean) {
    await api.patch(`/security/feature-flags/${uid}`, undefined, { enabled })
    await reload()
  }

  return (
    <div>
      <PageHeader
        icon={<IconLock />}
        title="Funcionalidades"
        subtitle="Recursos habilitados para este tenant."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="grid gap-3 md:grid-cols-2">
          {data.map((flag) => (
            <article key={flag.uid} className="card flex items-start justify-between gap-4 p-4">
              <div>
                <h3 className="text-sm font-medium text-ink-900">{flag.name}</h3>
                <p className="mt-0.5 text-xs text-ink-500">{flag.description}</p>
                <code className="mt-1.5 block text-[11px] text-ink-400">{flag.code}</code>
              </div>
              <button
                type="button"
                disabled={!can('security:write')}
                onClick={() => void toggle(flag.uid, !flag.enabled)}
                aria-pressed={flag.enabled}
                className={`relative h-6 w-11 shrink-0 rounded-full transition-colors disabled:opacity-50 ${
                  flag.enabled ? 'bg-brand-600' : 'bg-ink-300'
                }`}
              >
                <span
                  className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                    flag.enabled ? 'translate-x-[22px]' : 'translate-x-0.5'
                  }`}
                />
              </button>
            </article>
          ))}
        </div>
      )}
    </div>
  )
}

export function AuditLogsPage() {
  const [page, setPage] = useState(1)
  const [actor, setActor] = useState('')
  const { data, error, loading, reload } = useApi<PageType<AuditLogRow>>('/security/audit-logs', {
    actor: actor || undefined,
    page,
    page_size: 50,
  })

  return (
    <div>
      <PageHeader
        icon={<IconLock />}
        title="Logs de Auditoria"
        subtitle="Trilha append-only de quem fez o quê, quando e de onde."
        actions={
          <SearchInput
            value={actor}
            onChange={(value) => {
              setActor(value)
              setPage(1)
            }}
            placeholder="Filtrar por autor…"
            className="w-64"
          />
        }
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {data && (
        <div className="card">
          <DataTable
            rows={data.items}
            rowKey={(row) => row.uid}
            empty={<EmptyState title="Nenhum evento registrado" />}
            columns={[
              { key: 'when', header: 'Data', render: (row) => formatDateTime(row.created_at) },
              { key: 'actor', header: 'Autor', render: (row) => row.actor_email ?? 'sistema' },
              { key: 'action', header: 'Ação', render: (row) => <Badge tone="info">{row.action}</Badge> },
              { key: 'resource', header: 'Recurso', render: (row) => row.resource_type },
              { key: 'summary', header: 'Resumo', render: (row) => row.summary },
              { key: 'ip', header: 'Origem', render: (row) => <code className="text-xs text-ink-500">{row.ip_address ?? '—'}</code> },
            ]}
          />
          <Pagination page={data.page} pageSize={data.page_size} total={data.total} onChange={setPage} />
        </div>
      )}
    </div>
  )
}
