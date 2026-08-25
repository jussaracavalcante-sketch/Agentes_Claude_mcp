import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import { api } from '../../lib/api'
import { describeError, useAuth } from '../../lib/auth'
import type { ServiceDetail as ServiceDetailType, Version } from '../../lib/types'
import {
  CHANNEL_LABEL,
  SERVICE_STATUS_LABEL,
  SERVICE_TYPE_LABEL,
  formatDateTime,
} from '../../lib/format'
import { Badge, EmptyState, ErrorBanner, Loading, Tabs } from '../../components/ui'
import {
  IconArrowLeft,
  IconEdit,
  IconLifecycle,
  IconMore,
  IconPlay,
  IconPlus,
  IconSave,
} from '../../components/Icons'

type Pane = 'principal' | 'agentes' | 'estagios' | 'avancado'

const PANES: { value: Pane; label: string }[] = [
  { value: 'principal', label: 'Principal' },
  { value: 'agentes', label: 'Agentes' },
  { value: 'estagios', label: 'Estágios' },
  { value: 'avancado', label: 'Avançado' },
]

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="text-xs font-medium uppercase tracking-wide text-ink-400">{label}</dt>
      <dd className="mt-1 text-sm text-ink-800">{children}</dd>
    </div>
  )
}

export default function ServiceDetail() {
  const { uid = '' } = useParams()
  const { can } = useAuth()
  const [pane, setPane] = useState<Pane>('principal')
  const [busy, setBusy] = useState(false)
  const [notice, setNotice] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [editing, setEditing] = useState(false)

  const { data, error, loading, reload } = useApi<ServiceDetailType>(uid ? `/services/${uid}` : null)
  const versions = useApi<Version[]>(uid ? '/versions' : null, { service_uid: uid })

  if (loading) return <Loading />
  if (error) return <ErrorBanner message={error} onRetry={reload} />
  if (!data) return null

  async function saveVersion() {
    setBusy(true)
    setActionError(null)
    setNotice(null)
    try {
      const created = await api.post<Version>(`/services/${uid}/versions`, {
        changelog: 'Versão salva pelo console.',
      })
      setNotice(`Versão ${created.version} salva.`)
      await Promise.all([reload(), versions.reload()])
    } catch (caught) {
      setActionError(describeError(caught))
    } finally {
      setBusy(false)
    }
  }

  async function saveInstruction(form: FormData) {
    setBusy(true)
    setActionError(null)
    try {
      await api.patch(`/services/${uid}`, {
        name: String(form.get('name')),
        description: String(form.get('description')),
        instruction: String(form.get('instruction')),
        objectives: String(form.get('objectives'))
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean),
      })
      setEditing(false)
      setNotice('Alterações salvas no rascunho.')
      await reload()
    } catch (caught) {
      setActionError(describeError(caught))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div>
      <Link to="/studio/servicos" className="mb-4 inline-flex items-center gap-1.5 text-sm text-ink-500 hover:text-ink-800">
        <IconArrowLeft className="h-4 w-4" />
        Voltar para serviços
      </Link>

      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap items-center gap-2.5">
            <h1 className="text-2xl font-semibold tracking-tight text-ink-900">{data.name}</h1>
            <Badge tone={data.type === 'task' ? 'warning' : data.type === 'copilot' ? 'brand' : 'info'}>
              {SERVICE_TYPE_LABEL[data.type]}
            </Badge>
            <Badge tone={data.status === 'active' ? 'success' : 'neutral'}>
              {SERVICE_STATUS_LABEL[data.status]}
            </Badge>
          </div>
          <p className="mt-1.5 text-xs text-ink-500">
            Criado por {data.created_by ?? '—'} em {formatDateTime(data.created_at)} · Última
            alteração por {data.updated_by ?? '—'} em {formatDateTime(data.updated_at)}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {can('lifecycle:write') && (
            <button type="button" className="btn-primary" onClick={() => void saveVersion()} disabled={busy}>
              <IconSave className="h-4 w-4" />
              Salvar versão
              {data.has_draft && (
                <span className="rounded bg-white/20 px-1.5 py-0.5 text-[10px] font-semibold">rascunho</span>
              )}
            </button>
          )}
          <Link to={`/ciclo-de-vida/versoes?service=${data.uid}`} className="btn-ghost">
            <IconLifecycle className="h-4 w-4" />
            Versões
          </Link>
          <button type="button" className="btn-ghost">
            <IconPlay className="h-4 w-4" />
            Executar
          </button>
          <button type="button" className="btn-ghost px-2.5">
            <IconMore className="h-4 w-4" />
          </button>
          {can('services:write') && (
            <button type="button" className="btn-primary" onClick={() => setEditing((value) => !value)}>
              <IconEdit className="h-4 w-4" />
              {editing ? 'Cancelar' : 'Editar'}
            </button>
          )}
        </div>
      </div>

      {notice && (
        <p className="mb-4 rounded-lg bg-emerald-50 px-4 py-2.5 text-sm text-emerald-800">{notice}</p>
      )}
      {actionError && <div className="mb-4"><ErrorBanner message={actionError} /></div>}

      <div className="grid gap-6 lg:grid-cols-[13rem_1fr]">
        <aside>
          <p className="mb-2 px-1 text-[11px] font-semibold uppercase tracking-wide text-ink-400">
            Essenciais
          </p>
          <div className="space-y-0.5">
            {PANES.map((option) => (
              <button
                key={option.value}
                type="button"
                onClick={() => setPane(option.value)}
                className={`w-full rounded-lg px-3 py-2 text-left text-sm transition-colors ${
                  pane === option.value
                    ? 'bg-brand-50 font-medium text-brand-700'
                    : 'text-ink-600 hover:bg-ink-100'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </aside>

        <div className="space-y-4">
          {pane === 'principal' && (
            <>
              <section className="card p-5">
                <h2 className="mb-4 text-base font-semibold text-ink-900">Informações Gerais</h2>
                {editing ? (
                  <form
                    className="space-y-4"
                    onSubmit={(event) => {
                      event.preventDefault()
                      void saveInstruction(new FormData(event.currentTarget))
                    }}
                  >
                    <div>
                      <label htmlFor="name" className="mb-1.5 block text-sm font-medium text-ink-700">Nome</label>
                      <input id="name" name="name" className="input" defaultValue={data.name} required />
                    </div>
                    <div>
                      <label htmlFor="description" className="mb-1.5 block text-sm font-medium text-ink-700">Descrição</label>
                      <textarea id="description" name="description" className="input min-h-[5rem]" defaultValue={data.description} />
                    </div>
                    <div>
                      <label htmlFor="instruction" className="mb-1.5 block text-sm font-medium text-ink-700">Instrução</label>
                      <textarea id="instruction" name="instruction" className="input min-h-[9rem] font-mono text-xs" defaultValue={data.instruction} />
                    </div>
                    <div>
                      <label htmlFor="objectives" className="mb-1.5 block text-sm font-medium text-ink-700">
                        Objetivos <span className="font-normal text-ink-400">(um por linha)</span>
                      </label>
                      <textarea
                        id="objectives"
                        name="objectives"
                        className="input min-h-[5rem]"
                        defaultValue={data.objectives_json.join('\n')}
                      />
                    </div>
                    <button type="submit" className="btn-primary" disabled={busy}>
                      Salvar alterações
                    </button>
                  </form>
                ) : (
                  <dl className="grid gap-5 sm:grid-cols-2">
                    <Field label="Nome">{data.name}</Field>
                    <Field label="UID">
                      <code className="rounded bg-ink-100 px-1.5 py-0.5 text-xs">{data.uid}</code>
                    </Field>
                    <Field label="Descrição">{data.description || '—'}</Field>
                    <Field label="Canais">
                      <span className="flex flex-wrap gap-1.5">
                        {data.channels_json.length === 0 && '—'}
                        {data.channels_json.map((channel) => (
                          <Badge key={channel}>{CHANNEL_LABEL[channel] ?? channel}</Badge>
                        ))}
                      </span>
                    </Field>
                    <Field label="Criado em">{formatDateTime(data.created_at)}</Field>
                    <Field label="Criado por">{data.created_by ?? '—'}</Field>
                    <Field label="Última alteração">{formatDateTime(data.updated_at)}</Field>
                    <Field label="Alterado por">{data.updated_by ?? '—'}</Field>
                    <Field label="Versão ativa">{data.active_version ?? 'Nenhuma publicada'}</Field>
                    <Field label="Classificação do dado">{data.data_classification}</Field>
                  </dl>
                )}
              </section>

              <section className="card p-5">
                <div className="mb-3 flex items-center justify-between">
                  <h2 className="text-base font-semibold text-ink-900">Instrução</h2>
                </div>
                {data.instruction ? (
                  <pre className="whitespace-pre-wrap rounded-lg bg-ink-50 p-4 text-xs leading-relaxed text-ink-700">
                    {data.instruction}
                  </pre>
                ) : (
                  <p className="py-10 text-center text-sm text-ink-400">Nenhuma instrução configurada</p>
                )}
              </section>

              <section className="card p-5">
                <div className="mb-3 flex items-center justify-between">
                  <h2 className="text-base font-semibold text-ink-900">Objetivos</h2>
                  {can('services:write') && (
                    <button type="button" className="btn-ghost px-2.5 py-1.5 text-xs" onClick={() => setEditing(true)}>
                      <IconPlus className="h-3.5 w-3.5" />
                      Adicionar
                    </button>
                  )}
                </div>
                {data.objectives_json.length > 0 ? (
                  <ul className="space-y-2">
                    {data.objectives_json.map((objective) => (
                      <li key={objective} className="flex items-start gap-2 text-sm text-ink-700">
                        <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-brand-500" />
                        {objective}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="py-10 text-center text-sm text-ink-400">Nenhum objetivo configurado</p>
                )}
              </section>
            </>
          )}

          {pane === 'agentes' && (
            <section className="card p-5">
              <h2 className="mb-4 text-base font-semibold text-ink-900">Agentes do serviço</h2>
              {data.agents.length === 0 ? (
                <EmptyState title="Nenhum agente vinculado" description="Vincule ao menos um agente supervisor para orquestrar a jornada." />
              ) : (
                <ul className="divide-y divide-ink-100">
                  {data.agents.map((link) => (
                    <li key={link.uid} className="flex items-center justify-between gap-4 py-3">
                      <div>
                        <p className="text-sm font-medium text-ink-900">{link.agent_name}</p>
                        <p className="text-xs text-ink-500">{link.agent_role || 'sem papel definido'}</p>
                      </div>
                      {link.is_supervisor && <Badge tone="brand">Supervisor</Badge>}
                    </li>
                  ))}
                </ul>
              )}
            </section>
          )}

          {pane === 'estagios' && (
            <section className="card p-5">
              <h2 className="mb-4 text-base font-semibold text-ink-900">Estágios da jornada</h2>
              {data.stages.length === 0 ? (
                <EmptyState title="Nenhum estágio configurado" description="Serviços de tarefa e copiloto normalmente não usam estágios." />
              ) : (
                <ol className="space-y-3">
                  {data.stages.map((stage) => (
                    <li key={stage.uid} className="rounded-lg border border-ink-200 p-4">
                      <div className="flex items-center gap-2">
                        <code className="rounded bg-brand-50 px-2 py-0.5 text-xs font-semibold text-brand-700">
                          {stage.code}
                        </code>
                        <span className="text-sm font-medium text-ink-900">{stage.name}</span>
                      </div>
                      <p className="mt-2 text-sm text-ink-600">{stage.instruction}</p>
                      <p className="mt-1.5 text-xs text-ink-400">Saída: {stage.exit_condition}</p>
                    </li>
                  ))}
                </ol>
              )}
            </section>
          )}

          {pane === 'avancado' && (
            <section className="card p-5">
              <h2 className="mb-4 text-base font-semibold text-ink-900">Avançado</h2>
              <dl className="grid gap-5 sm:grid-cols-2">
                <Field label="Transbordo humano">{data.handoff_enabled ? 'Habilitado' : 'Desabilitado'}</Field>
                <Field label="Unidade responsável">{data.unit_uid ?? '—'}</Field>
                <Field label="Responsável">{data.owner_email ?? '—'}</Field>
                <Field label="Rascunho pendente">{data.has_draft ? 'Sim' : 'Não'}</Field>
              </dl>
              <div className="mt-5">
                <p className="mb-2 text-xs font-medium uppercase tracking-wide text-ink-400">Histórico de versões</p>
                {versions.data && versions.data.length > 0 ? (
                  <ul className="divide-y divide-ink-100">
                    {versions.data.map((version) => (
                      <li key={version.uid} className="flex items-center justify-between py-2.5 text-sm">
                        <span className="flex items-center gap-2">
                          <code className="rounded bg-ink-100 px-1.5 py-0.5 text-xs">{version.version}</code>
                          <span className="text-ink-600">{version.changelog}</span>
                        </span>
                        {version.is_active && <Badge tone="success">ativa</Badge>}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-ink-400">Nenhuma versão salva.</p>
                )}
              </div>
            </section>
          )}
        </div>
      </div>

      <div className="mt-6 lg:hidden">
        <Tabs value={pane} options={PANES} onChange={setPane} />
      </div>
    </div>
  )
}
