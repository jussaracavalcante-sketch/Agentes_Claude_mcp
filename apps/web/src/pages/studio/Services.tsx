import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import { useAuth } from '../../lib/auth'
import { api } from '../../lib/api'
import { describeError } from '../../lib/auth'
import type { Service, ServiceType } from '../../lib/types'
import { SERVICE_STATUS_LABEL, SERVICE_TYPE_LABEL } from '../../lib/format'
import {
  Badge,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  SearchInput,
  Tabs,
} from '../../components/ui'
import { IconChat, IconMore, IconPlus, IconStudio, IconTask } from '../../components/Icons'

type Filter = 'all' | ServiceType

const TABS: { value: Filter; label: string }[] = [
  { value: 'all', label: 'Todos' },
  { value: 'conversation', label: 'Conversação' },
  { value: 'task', label: 'Tarefas' },
  { value: 'copilot', label: 'Copilot' },
]

const TYPE_ICON: Record<ServiceType, JSX.Element> = {
  conversation: <IconChat className="h-3.5 w-3.5" />,
  task: <IconTask className="h-3.5 w-3.5" />,
  copilot: <IconStudio className="h-3.5 w-3.5" />,
}

const TYPE_TONE: Record<ServiceType, string> = {
  conversation: 'info',
  task: 'warning',
  copilot: 'brand',
}

const STATUS_TONE: Record<string, string> = {
  active: 'success',
  draft: 'neutral',
  inactive: 'neutral',
  archived: 'neutral',
}

function ServiceCard({ service }: { service: Service }) {
  return (
    <Link
      to={`/studio/servicos/${service.uid}`}
      className="card flex flex-col gap-3 p-4 transition-shadow hover:shadow-pop"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 items-start gap-2">
          <span className="mt-0.5 shrink-0 text-ink-400">{TYPE_ICON[service.type]}</span>
          <h3 className="truncate text-sm font-medium text-ink-900">{service.name}</h3>
        </div>
        <IconMore className="h-4 w-4 shrink-0 text-ink-400" />
      </div>

      <p className="line-clamp-3 min-h-[3.5rem] text-xs leading-relaxed text-ink-500">
        {service.description || 'Sem descrição.'}
      </p>

      <div className="flex flex-wrap items-center gap-2">
        <Badge tone={TYPE_TONE[service.type]} icon={TYPE_ICON[service.type]}>
          {SERVICE_TYPE_LABEL[service.type]}
        </Badge>
        <Badge tone={STATUS_TONE[service.status]}>{SERVICE_STATUS_LABEL[service.status]}</Badge>
        {service.active_version && <Badge tone="neutral">{service.active_version}</Badge>}
        {service.has_draft && <Badge tone="warning">rascunho</Badge>}
      </div>
    </Link>
  )
}

export default function Services() {
  const [params, setParams] = useSearchParams()
  const { can } = useAuth()
  const [query, setQuery] = useState('')
  const [creating, setCreating] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const filter = (params.get('tipo') as Filter) ?? 'all'
  const { data, error, loading, reload } = useApi<Service[]>('/services')

  const visible = useMemo(() => {
    const rows = data ?? []
    const byType = filter === 'all' ? rows : rows.filter((row) => row.type === filter)
    const needle = query.trim().toLowerCase()
    if (!needle) return byType
    return byType.filter(
      (row) =>
        row.name.toLowerCase().includes(needle) || row.description.toLowerCase().includes(needle),
    )
  }, [data, filter, query])

  async function createService(name: string, type: ServiceType) {
    setFormError(null)
    try {
      await api.post('/services', { name, type, description: '' })
      setCreating(false)
      await reload()
    } catch (caught) {
      setFormError(describeError(caught))
    }
  }

  return (
    <div>
      <PageHeader
        icon={<IconStudio />}
        title="Serviços"
        subtitle="Gerencie os serviços de IA — conversação, tarefas e copilot — em um só lugar."
      />

      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <Tabs
          value={filter}
          options={TABS}
          onChange={(value) => {
            const next = new URLSearchParams(params)
            if (value === 'all') next.delete('tipo')
            else next.set('tipo', value)
            setParams(next, { replace: true })
          }}
        />
        <div className="flex flex-1 flex-wrap items-center justify-end gap-2">
          <SearchInput
            value={query}
            onChange={setQuery}
            placeholder="Buscar serviços…"
            className="w-full max-w-xs"
          />
          {can('services:write') && (
            <button type="button" className="btn-primary" onClick={() => setCreating(true)}>
              <IconPlus className="h-4 w-4" />
              Criar Serviço
            </button>
          )}
        </div>
      </div>

      {creating && (
        <form
          className="card mb-5 flex flex-wrap items-end gap-3 p-4"
          onSubmit={(event) => {
            event.preventDefault()
            const form = new FormData(event.currentTarget)
            void createService(String(form.get('name')), form.get('type') as ServiceType)
          }}
        >
          <div className="min-w-[16rem] flex-1">
            <label htmlFor="new-name" className="mb-1.5 block text-sm font-medium text-ink-700">
              Nome do serviço
            </label>
            <input id="new-name" name="name" required className="input" placeholder="Ex: Atendimento Comercial" />
          </div>
          <div>
            <label htmlFor="new-type" className="mb-1.5 block text-sm font-medium text-ink-700">
              Tipo
            </label>
            <select id="new-type" name="type" className="input" defaultValue="conversation">
              <option value="conversation">Conversação</option>
              <option value="task">Tarefa</option>
              <option value="copilot">Copiloto</option>
            </select>
          </div>
          <button type="submit" className="btn-primary">
            Criar
          </button>
          <button type="button" className="btn-ghost" onClick={() => setCreating(false)}>
            Cancelar
          </button>
          {formError && <p className="w-full text-sm text-rose-600">{formError}</p>}
        </form>
      )}

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {!loading && !error && visible.length === 0 && (
        <div className="card">
          <EmptyState
            icon={<IconStudio className="h-6 w-6" />}
            title={`Nenhum serviço de ${filter === 'all' ? 'IA' : SERVICE_TYPE_LABEL[filter]} ainda`}
            description="Um serviço é a aplicação de IA que atende seus clientes ou executa tarefas. Descreva o que você precisa e monte o serviço em minutos."
            action={
              can('services:write') && (
                <button type="button" className="btn-primary" onClick={() => setCreating(true)}>
                  <IconPlus className="h-4 w-4" />
                  Criar manualmente
                </button>
              )
            }
          />
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {visible.map((service) => (
          <ServiceCard key={service.uid} service={service} />
        ))}
      </div>
    </div>
  )
}
