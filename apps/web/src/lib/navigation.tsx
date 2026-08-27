/** Estrutura de navegação do console — espelha as áreas da plataforma. */

import type { ReactNode } from 'react'
import {
  IconAnalytics,
  IconChat,
  IconCuration,
  IconDev,
  IconEval,
  IconEye,
  IconFlow,
  IconGateway,
  IconHome,
  IconLifecycle,
  IconLock,
  IconOps,
  IconPlay,
  IconPrivacy,
  IconStudio,
  IconTask,
  IconTrace,
} from '../components/Icons'

export interface NavItem {
  label: string
  to: string
  icon?: ReactNode
  children?: { label: string; to: string }[]
  permission?: string
}

export const NAVIGATION: NavItem[] = [
  { label: 'Home', to: '/', icon: <IconHome /> },
  {
    label: 'Executar',
    to: '/executar',
    icon: <IconPlay />,
    permission: 'services:read',
  },
  {
    label: 'Conversas',
    to: '/conversas',
    icon: <IconChat />,
    permission: 'observability:read',
  },
  { label: 'Tarefas', to: '/tarefas', icon: <IconTask />, permission: 'observability:read' },
  { label: 'Traces', to: '/traces', icon: <IconTrace />, permission: 'observability:read' },
  {
    label: 'AI Studio',
    to: '/studio',
    icon: <IconStudio />,
    permission: 'services:read',
    children: [
      { label: 'Serviços', to: '/studio/servicos' },
      { label: 'Agentes', to: '/studio/agentes' },
      { label: 'Skills', to: '/studio/skills' },
      { label: 'Conhecimento', to: '/studio/conhecimento' },
      { label: 'Ferramentas', to: '/studio/ferramentas' },
      { label: 'Integrações', to: '/studio/integracoes' },
      { label: 'LLM', to: '/studio/llm' },
    ],
  },
  {
    label: 'Observabilidade',
    to: '/observabilidade',
    icon: <IconEye />,
    permission: 'observability:read',
    children: [
      { label: 'Serviços', to: '/observabilidade' },
      { label: 'Conversas', to: '/conversas' },
      { label: 'Conversas Ativas', to: '/conversas?status=active' },
      { label: 'Tarefas', to: '/tarefas' },
      { label: 'Traces', to: '/traces' },
    ],
  },
  { label: 'Fluxos de Trabalho', to: '/fluxos', icon: <IconFlow />, permission: 'services:read' },
  { label: 'Operações', to: '/operacoes', icon: <IconOps />, permission: 'observability:read' },
  {
    label: 'Ciclo de Vida',
    to: '/ciclo-de-vida',
    icon: <IconLifecycle />,
    permission: 'lifecycle:read',
    children: [
      { label: 'Versões', to: '/ciclo-de-vida/versoes' },
      { label: 'Implantações', to: '/ciclo-de-vida/implantacoes' },
      { label: 'Importar / Exportar', to: '/ciclo-de-vida/portabilidade' },
    ],
  },
  {
    label: 'Analytics',
    to: '/analytics',
    icon: <IconAnalytics />,
    permission: 'analytics:read',
    children: [
      { label: 'Serviços', to: '/analytics/servicos' },
      { label: 'Consumo LLM', to: '/analytics/consumo-llm' },
    ],
  },
  { label: 'LLM Gateway', to: '/llm-gateway', icon: <IconGateway />, permission: 'llm:read' },
  {
    label: 'Aprovações',
    to: '/aprovacoes',
    icon: <IconCuration />,
    permission: 'observability:read',
  },
  { label: 'Curadoria', to: '/curadoria', icon: <IconCuration />, permission: 'curation:read' },
  { label: 'Evaluations', to: '/evaluations', icon: <IconEval />, permission: 'evaluations:read' },
  { label: 'Privacidade', to: '/privacidade', icon: <IconPrivacy />, permission: 'privacy:read' },
  {
    label: 'Segurança',
    to: '/seguranca',
    icon: <IconLock />,
    permission: 'security:read',
    children: [
      { label: 'Visão Geral', to: '/seguranca' },
      { label: 'Usuários', to: '/seguranca/usuarios' },
      { label: 'Papéis & Permissões', to: '/seguranca/papeis' },
      { label: 'Unidades', to: '/seguranca/unidades' },
      { label: 'Chaves de API', to: '/seguranca/chaves' },
      { label: 'Funcionalidades', to: '/seguranca/funcionalidades' },
      { label: 'Logs de Auditoria', to: '/seguranca/auditoria' },
    ],
  },
  { label: 'Portal do Desenvolvedor', to: '/portal-do-desenvolvedor', icon: <IconDev /> },
]
