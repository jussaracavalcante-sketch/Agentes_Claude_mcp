import { Link } from 'react-router-dom'
import { useApi } from '../lib/useApi'
import { useAuth } from '../lib/auth'
import type { HomeOverview } from '../lib/types'
import { formatLongDate, greeting } from '../lib/format'
import { ErrorBanner, LinkCard, Loading, StatCard } from '../components/ui'
import {
  IconAlert,
  IconBook,
  IconChat,
  IconEye,
  IconGateway,
  IconMonitor,
  IconPlug,
  IconSearch,
  IconStudio,
  IconTask,
  IconTool,
  IconTrace,
  IconUsers,
} from '../components/Icons'

export default function Home() {
  const { user } = useAuth()
  const { data, error, loading, reload } = useApi<HomeOverview>('/home/overview')

  if (loading) return <Loading />
  if (error) return <ErrorBanner message={error} onRetry={reload} />
  if (!data) return null

  const now = new Date(data.greeting_date)

  return (
    <div className="space-y-6">
      <section className="card overflow-hidden">
        <div className="flex flex-wrap items-start justify-between gap-4 p-6">
          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-ink-400">
              {formatLongDate(data.greeting_date)}
            </p>
            <h1 className="mt-1 text-3xl font-semibold tracking-tight text-ink-900">
              {greeting(now)}, {user?.name?.split(' ')[0]}
            </h1>
            <p className="mt-2 max-w-2xl text-sm text-ink-500">
              Aqui está o panorama da plataforma VKB. Acompanhe operações, performance e crie
              novos serviços com IA em poucos cliques.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Link to="/observabilidade" className="btn-primary">
              <IconMonitor className="h-4 w-4" />
              Monitoramento
            </Link>
            <Link to="/studio/servicos" className="btn-ghost">
              <IconStudio className="h-4 w-4" />
              Criar com IA
            </Link>
          </div>
        </div>
      </section>

      <div className="grid gap-4 md:grid-cols-3">
        <StatCard
          label="Serviços de IA Conversacional ativos"
          value={data.conversation_services}
          icon={<IconChat />}
          to="/studio/servicos?tipo=conversation"
        />
        <StatCard
          label="Serviços de Tarefas ativos"
          value={data.task_services}
          icon={<IconTask />}
          to="/studio/servicos?tipo=task"
        />
        <StatCard
          label="Serviços de Copilot ativos"
          value={data.copilot_services}
          icon={<IconStudio />}
          to="/studio/servicos?tipo=copilot"
        />
      </div>

      <div className="card flex items-center gap-3 px-4 py-3">
        <IconSearch className="h-4 w-4 text-ink-400" />
        <input
          className="w-full border-0 bg-transparent text-sm text-ink-700 placeholder:text-ink-400 focus:outline-none"
          placeholder="Buscar atalho… (ex: tasks, csat, deploy)"
          aria-label="Buscar atalho"
        />
      </div>

      <section className="card p-5">
        <div className="mb-4 flex items-start gap-3">
          <IconEye className="mt-0.5 text-brand-600" />
          <div>
            <h2 className="text-base font-semibold text-ink-900">Observabilidade</h2>
            <p className="text-sm text-ink-500">Acompanhe a operação em tempo real</p>
          </div>
        </div>
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          <LinkCard
            to="/observabilidade"
            title="Serviços"
            description="Visão geral consolidada com KPIs por período"
            icon={<IconMonitor />}
          />
          <LinkCard
            to="/conversas"
            title="Conversas"
            description="Histórico completo de conversas com filtros e busca"
            icon={<IconChat />}
          />
          <LinkCard
            to="/conversas?status=active"
            title="Conversas Ativas"
            description="Conversas em andamento, com tempo de espera ao vivo"
            icon={<IconChat />}
          />
          <LinkCard
            to="/tarefas"
            title="Tarefas"
            description="Pipeline de tarefas autônomas e seus stops"
            icon={<IconTask />}
          />
          <LinkCard
            to="/traces"
            title="Traces"
            description="Execuções, spans, tokens e custo por requisição"
            icon={<IconTrace />}
          />
          <LinkCard
            to="/analytics/consumo-llm"
            title="Consumo LLM"
            description="Tokens e custo por modelo, provedor e serviço"
            icon={<IconGateway />}
          />
        </div>
      </section>

      <section className="card p-5">
        <div className="mb-4 flex items-start gap-3">
          <IconStudio className="mt-0.5 text-brand-600" />
          <div>
            <h2 className="text-base font-semibold text-ink-900">AI Studio</h2>
            <p className="text-sm text-ink-500">Crie e gerencie serviços, agentes e integrações</p>
          </div>
        </div>
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          <LinkCard
            to="/studio/servicos"
            title="Serviços"
            description="Chat, Task e Copilot services do workspace"
            icon={<IconChat />}
          />
          <LinkCard
            to="/studio/agentes"
            title="Agentes"
            description="Agentes especializados com instruções e papéis"
            icon={<IconUsers />}
          />
          <LinkCard
            to="/studio/skills"
            title="Skills"
            description="Habilidades reutilizáveis para os agentes"
            icon={<IconStudio />}
          />
          <LinkCard
            to="/studio/conhecimento"
            title="Conhecimento"
            description="Bases indexadas para recuperação semântica"
            icon={<IconBook />}
          />
          <LinkCard
            to="/studio/ferramentas"
            title="Ferramentas"
            description="Chamadas HTTP, SQL, RPA e recuperação"
            icon={<IconTool />}
          />
          <LinkCard
            to="/studio/integracoes"
            title="Integrações"
            description="Conectores com CRM, ERP, mídia e canais"
            icon={<IconPlug />}
          />
        </div>
      </section>

      <div className="grid gap-4 md:grid-cols-3">
        <StatCard label="Conversas hoje" value={data.conversations_today} icon={<IconChat />} to="/conversas" />
        <StatCard label="Tarefas hoje" value={data.tasks_today} icon={<IconTask />} to="/tarefas" />
        <StatCard
          label="Execuções com falha"
          value={data.open_incidents}
          hint="Tarefas que exigem tratamento"
          icon={<IconAlert />}
          to="/tarefas?status=failed"
          accent={data.open_incidents > 0}
        />
      </div>
    </div>
  )
}
