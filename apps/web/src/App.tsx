import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from './lib/auth'
import ConsoleLayout from './layouts/ConsoleLayout'
import { Loading } from './components/ui'

import Login from './pages/Login'
import Home from './pages/Home'
import Services from './pages/studio/Services'
import ServiceDetail from './pages/studio/ServiceDetail'
import {
  AgentsPage,
  IntegrationsPage,
  KnowledgePage,
  LLMGatewayPage,
  SkillsPage,
  ToolsPage,
} from './pages/studio/Catalogs'
import Monitoring from './pages/observability/Monitoring'
import Conversations from './pages/observability/Conversations'
import ConversationDetail from './pages/observability/ConversationDetail'
import Tasks from './pages/observability/Tasks'
import Traces from './pages/observability/Traces'
import { DeploymentsPage, PortabilityPage, VersionsPage } from './pages/lifecycle/Lifecycle'
import { LLMConsumptionPage, ServiceAnalyticsPage } from './pages/analytics/Analytics'
import {
  ApiKeysPage,
  AuditLogsPage,
  FeatureFlagsPage,
  RolesPage,
  SecurityOverviewPage,
  UnitsPage,
  UsersPage,
} from './pages/security/Security'
import { CurationPage, EvaluationsPage, PrivacyPage } from './pages/governance/Governance'
import { DeveloperPortalPage, OperationsPage, WorkflowsPage } from './pages/Operations'
import Playground from './pages/Playground'
import Approvals from './pages/Approvals'

function RequireAuth({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  if (loading) return <Loading label="Verificando sessão…" />
  if (!user) return <Navigate to="/entrar" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <Routes>
      <Route path="/entrar" element={<Login />} />

      <Route
        element={
          <RequireAuth>
            <ConsoleLayout />
          </RequireAuth>
        }
      >
        <Route index element={<Home />} />
        <Route path="executar" element={<Playground />} />
        <Route path="aprovacoes" element={<Approvals />} />

        <Route path="studio" element={<Navigate to="/studio/servicos" replace />} />
        <Route path="studio/servicos" element={<Services />} />
        <Route path="studio/servicos/:uid" element={<ServiceDetail />} />
        <Route path="studio/agentes" element={<AgentsPage />} />
        <Route path="studio/skills" element={<SkillsPage />} />
        <Route path="studio/ferramentas" element={<ToolsPage />} />
        <Route path="studio/integracoes" element={<IntegrationsPage />} />
        <Route path="studio/conhecimento" element={<KnowledgePage />} />
        <Route path="studio/llm" element={<LLMGatewayPage />} />

        <Route path="observabilidade" element={<Monitoring />} />
        <Route path="conversas" element={<Conversations />} />
        <Route path="conversas/:uid" element={<ConversationDetail />} />
        <Route path="tarefas" element={<Tasks />} />
        <Route path="traces" element={<Traces />} />
        <Route path="traces/:uid" element={<Traces />} />

        <Route path="fluxos" element={<WorkflowsPage />} />
        <Route path="operacoes" element={<OperationsPage />} />

        <Route path="ciclo-de-vida" element={<Navigate to="/ciclo-de-vida/versoes" replace />} />
        <Route path="ciclo-de-vida/versoes" element={<VersionsPage />} />
        <Route path="ciclo-de-vida/implantacoes" element={<DeploymentsPage />} />
        <Route path="ciclo-de-vida/portabilidade" element={<PortabilityPage />} />

        <Route path="analytics" element={<Navigate to="/analytics/servicos" replace />} />
        <Route path="analytics/servicos" element={<ServiceAnalyticsPage />} />
        <Route path="analytics/consumo-llm" element={<LLMConsumptionPage />} />

        <Route path="llm-gateway" element={<LLMGatewayPage />} />
        <Route path="curadoria" element={<CurationPage />} />
        <Route path="evaluations" element={<EvaluationsPage />} />
        <Route path="privacidade" element={<PrivacyPage />} />

        <Route path="seguranca" element={<SecurityOverviewPage />} />
        <Route path="seguranca/usuarios" element={<UsersPage />} />
        <Route path="seguranca/papeis" element={<RolesPage />} />
        <Route path="seguranca/unidades" element={<UnitsPage />} />
        <Route path="seguranca/chaves" element={<ApiKeysPage />} />
        <Route path="seguranca/funcionalidades" element={<FeatureFlagsPage />} />
        <Route path="seguranca/auditoria" element={<AuditLogsPage />} />

        <Route path="portal-do-desenvolvedor" element={<DeveloperPortalPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
