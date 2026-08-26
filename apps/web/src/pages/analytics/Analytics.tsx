import { useState } from 'react'
import { useApi } from '../../lib/useApi'
import type { LLMConsumption, ServiceAnalytics } from '../../lib/types'
import { formatNumber, formatUsd } from '../../lib/format'
import { BarRanking, LineChart, Sparkbars } from '../../components/charts'
import {
  ErrorBanner,
  Loading,
  PageHeader,
  PeriodPicker,
  Section,
  StatCard,
} from '../../components/ui'
import type { Period } from '../../components/ui'
import { IconAnalytics, IconChat, IconGateway, IconStudio, IconTask } from '../../components/Icons'

export function ServiceAnalyticsPage() {
  const [period, setPeriod] = useState<Period>('7D')
  const { data, error, loading, reload } = useApi<ServiceAnalytics>('/analytics/services', { period })

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconAnalytics />}
        title="Visão geral por serviço"
        subtitle="Volume, ranking e evolução diária de conversas e tarefas"
        actions={<PeriodPicker value={period} onChange={setPeriod} />}
      />

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <>
          <div className="grid gap-4 md:grid-cols-3">
            <StatCard label="Total de Conversas" value={formatNumber(data.total_conversations)} icon={<IconChat />} />
            <StatCard label="Total de Tarefas" value={formatNumber(data.total_tasks)} icon={<IconTask />} />
            <StatCard label="Serviços ativos" value={data.active_services} icon={<IconStudio />} />
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Section title="Ranking de Conversas por Serviço">
              <BarRanking data={data.ranking_conversations} formatValue={formatNumber} />
            </Section>
            <Section title="Ranking de Tarefas por Serviço">
              <BarRanking data={data.ranking_tasks} formatValue={formatNumber} />
            </Section>
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Section title="Conversas por dia" description="Por serviço, cinco maiores volumes">
              <LineChart series={data.conversations_per_day} formatValue={formatNumber} />
            </Section>
            <Section title="Tarefas por dia" description="Por serviço, cinco maiores volumes">
              <LineChart series={data.tasks_per_day} formatValue={formatNumber} />
            </Section>
          </div>
        </>
      )}
    </div>
  )
}

export function LLMConsumptionPage() {
  const [period, setPeriod] = useState<Period>('30D')
  const { data, error, loading, reload } = useApi<LLMConsumption>('/analytics/llm', { period })

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<IconGateway />}
        title="Consumo LLM"
        subtitle="FinOps: tokens e custo por modelo, provedor e serviço"
        actions={<PeriodPicker value={period} onChange={setPeriod} />}
      />

      {loading && <Loading />}
      {error && <ErrorBanner message={error} onRetry={reload} />}

      {data && (
        <>
          <div className="grid gap-4 md:grid-cols-3">
            <StatCard label="Tokens de entrada" value={formatNumber(data.tokens_in)} icon={<IconGateway />} />
            <StatCard label="Tokens de saída" value={formatNumber(data.tokens_out)} icon={<IconGateway />} />
            <StatCard label="Custo no período" value={formatUsd(data.cost_usd)} icon={<IconAnalytics />} accent />
          </div>

          <Section title="Custo por dia" description="Série diária de gasto com provedores de LLM">
            <Sparkbars data={data.cost_per_day} formatValue={formatUsd} />
          </Section>

          <div className="grid gap-4 lg:grid-cols-3">
            <Section title="Custo por modelo">
              <BarRanking data={data.by_model} formatValue={formatUsd} />
            </Section>
            <Section title="Custo por provedor">
              <BarRanking data={data.by_provider} formatValue={formatUsd} />
            </Section>
            <Section title="Custo por serviço">
              <BarRanking data={data.by_service} formatValue={formatUsd} />
            </Section>
          </div>
        </>
      )}
    </div>
  )
}
