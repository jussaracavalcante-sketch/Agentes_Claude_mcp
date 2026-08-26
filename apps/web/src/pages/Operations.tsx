/** Fluxos de Trabalho, Operações e Portal do Desenvolvedor. */

import { useApi } from '../lib/useApi'
import { useAuth } from '../lib/auth'
import type { MonitoringOverview, Service, ServiceDetail } from '../lib/types'
import { SERVICE_TYPE_LABEL, formatNumber } from '../lib/format'
import {
  Badge,
  DataTable,
  EmptyState,
  ErrorBanner,
  Loading,
  PageHeader,
  Section,
  StatCard,
} from '../components/ui'
import { IconChat, IconDev, IconFlow, IconOps, IconTask, IconTrace } from '../components/Icons'

export function WorkflowsPage() {
  const { data, error, loading, reload } = useApi<Service[]>('/services')
  const conversational = (data ?? []).filter((service) => service.type === 'conversation')

  return (
    <div>
      <PageHeader
        icon={<IconFlow />}
        title="Fluxos de Trabalho"
        subtitle="Jornadas conversacionais e seus estágios, do primeiro contato ao transbordo humano."
      />
      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}
      {!loading && !error && (
        <div className="space-y-4">
          {conversational.length === 0 && (
            <div className="card">
              <EmptyState icon={<IconFlow className="h-6 w-6" />} title="Nenhum fluxo configurado" />
            </div>
          )}
          {conversational.map((service) => (
            <WorkflowCard key={service.uid} uid={service.uid} />
          ))}
        </div>
      )}
    </div>
  )
}

function WorkflowCard({ uid }: { uid: string }) {
  const { data } = useApi<ServiceDetail>(`/services/${uid}`)
  if (!data) return null

  return (
    <Section title={data.name} description={`${data.stages.length} estágios · ${data.agents.length} agentes`}>
      {data.stages.length === 0 ? (
        <p className="text-sm text-ink-400">Sem estágios definidos.</p>
      ) : (
        <ol className="flex flex-wrap items-center gap-2">
          {data.stages.map((stage, index) => (
            <li key={stage.uid} className="flex items-center gap-2">
              <span className="rounded-lg border border-ink-200 bg-white px-3 py-2">
                <span className="block font-mono text-[11px] text-brand-700">{stage.code}</span>
                <span className="block text-sm text-ink-800">{stage.name}</span>
              </span>
              {index < data.stages.length - 1 && <span className="text-ink-300">→</span>}
            </li>
          ))}
          {data.handoff_enabled && (
            <li className="flex items-center gap-2">
              <span className="text-ink-300">→</span>
              <Badge tone="warning">operador humano</Badge>
            </li>
          )}
        </ol>
      )}
    </Section>
  )
}

export function OperationsPage() {
  const monitoring = useApi<MonitoringOverview>('/monitoring', { period: '1D' })
  const services = useApi<Service[]>('/services')

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconOps />}
        title="Operações"
        subtitle="Estado operacional do dia: volume, serviços publicados e rascunhos pendentes."
      />

      {(monitoring.loading || services.loading) && <Loading />}
      {monitoring.error && <ErrorBanner message={monitoring.error} onRetry={monitoring.reload} />}

      {monitoring.data && services.data && (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Conversas hoje" value={monitoring.data.conversations} icon={<IconChat />} />
            <StatCard label="Tarefas hoje" value={monitoring.data.tasks} icon={<IconTask />} />
            <StatCard label="Traces hoje" value={monitoring.data.traces} icon={<IconTrace />} />
            <StatCard
              label="Rascunhos pendentes"
              value={services.data.filter((service) => service.has_draft).length}
              hint="Serviços alterados sem versão salva"
              icon={<IconOps />}
              accent
            />
          </div>

          <Section title="Serviços publicados" description="Versão ativa em produção por serviço">
            <DataTable
              rows={services.data}
              rowKey={(row) => row.uid}
              empty={<EmptyState title="Nenhum serviço cadastrado" />}
              columns={[
                { key: 'name', header: 'Serviço', render: (row) => <span className="font-medium text-ink-900">{row.name}</span> },
                { key: 'type', header: 'Tipo', render: (row) => <Badge tone="info">{SERVICE_TYPE_LABEL[row.type]}</Badge> },
                {
                  key: 'status',
                  header: 'Status',
                  render: (row) => <Badge tone={row.status === 'active' ? 'success' : 'neutral'}>{row.status}</Badge>,
                },
                { key: 'version', header: 'Versão ativa', render: (row) => row.active_version ?? '—' },
                { key: 'draft', header: 'Rascunho', render: (row) => (row.has_draft ? <Badge tone="warning">pendente</Badge> : '—') },
                { key: 'owner', header: 'Responsável', render: (row) => row.owner_email ?? '—' },
              ]}
            />
          </Section>
        </>
      )}
    </div>
  )
}

export function DeveloperPortalPage() {
  const { user } = useAuth()
  const base = import.meta.env.VITE_API_URL ?? window.location.origin

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconDev />}
        title="Portal do Desenvolvedor"
        subtitle="Como integrar sistemas da Vanguarda à plataforma VKB."
      />

      <Section title="Autenticação" description="Duas formas de credencial, ambas auditadas">
        <div className="space-y-4 text-sm text-ink-700">
          <div>
            <p className="mb-1.5 font-medium text-ink-900">Token de sessão (console)</p>
            <pre className="overflow-x-auto rounded-lg bg-ink-900 p-3 text-[11px] text-ink-100">{`curl -X POST ${base}/api/v1/auth/login \\
  -H 'Content-Type: application/json' \\
  -d '{"email":"${user?.email ?? 'usuario@vanguardamartech.com.br'}","password":"···"}'`}</pre>
          </div>
          <div>
            <p className="mb-1.5 font-medium text-ink-900">Chave de API (integração servidor a servidor)</p>
            <pre className="overflow-x-auto rounded-lg bg-ink-900 p-3 text-[11px] text-ink-100">{`curl ${base}/api/v1/services \\
  -H 'X-API-Key: vkb_···'`}</pre>
            <p className="mt-1.5 text-xs text-ink-500">
              Emita e revogue chaves em Segurança → Chaves de API. O segredo aparece uma única vez.
            </p>
          </div>
        </div>
      </Section>

      <Section title="Endpoints principais">
        <DataTable
          rows={[
            { path: '/api/v1/services', method: 'GET', description: 'Lista serviços do tenant, com filtro por tipo e status.' },
            { path: '/api/v1/services/{uid}', method: 'GET', description: 'Detalhe do serviço com agentes e estágios.' },
            { path: '/api/v1/services/{uid}/versions', method: 'POST', description: 'Salva uma versão a partir do rascunho atual.' },
            { path: '/api/v1/versions/{uid}/deploy', method: 'POST', description: 'Publica a versão em um ambiente.' },
            { path: '/api/v1/versions/{uid}/rollback', method: 'POST', description: 'Reverte a produção para uma versão anterior.' },
            { path: '/api/v1/conversations', method: 'GET', description: 'Histórico de conversas paginado.' },
            { path: '/api/v1/traces/{uid}', method: 'GET', description: 'Árvore de spans com tokens e custo.' },
            { path: '/api/v1/analytics/llm', method: 'GET', description: 'Consumo e custo por modelo, provedor e serviço.' },
            { path: '/api/v1/portability/export', method: 'POST', description: 'Exporta os ativos em JSON aberto.' },
          ]}
          rowKey={(row) => `${row.method} ${row.path}`}
          columns={[
            { key: 'method', header: 'Método', render: (row) => <Badge tone={row.method === 'GET' ? 'info' : 'brand'}>{row.method}</Badge> },
            { key: 'path', header: 'Rota', render: (row) => <code className="text-xs text-ink-700">{row.path}</code> },
            { key: 'description', header: 'Descrição', render: (row) => row.description },
          ]}
        />
        <p className="mt-4 text-sm text-ink-500">
          Especificação completa em <code className="rounded bg-ink-100 px-1.5 py-0.5 text-xs">{base}/docs</code> (OpenAPI).
        </p>
      </Section>

      <Section title="Limites e boas práticas">
        <ul className="space-y-2 text-sm text-ink-700">
          <li>• Toda escrita é registrada na trilha de auditoria com autor, IP e resumo.</li>
          <li>• Publicação em produção exige versão aprovada por pessoa distinta de quem a criou.</li>
          <li>• Agentes com autonomia N4 são rejeitados pela política de governança.</li>
          <li>• Credenciais de provedores e integrações ficam em cofre; a API armazena apenas a referência.</li>
          <li>• Respostas paginadas trazem no máximo {formatNumber(200)} itens por página.</li>
        </ul>
      </Section>
    </div>
  )
}
