/** Shell do console: marca, navegação lateral, trilha e área de conteúdo. */

import { useMemo, useState } from 'react'
import { Link, NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../lib/auth'
import { NAVIGATION } from '../lib/navigation'
import type { NavItem } from '../lib/navigation'
import { IconChat, IconChevronDown, IconClose, IconGateway, IconSearch } from '../components/Icons'

function Brand() {
  return (
    <Link to="/" className="flex items-center gap-2 px-4 py-4">
      <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-brand-600 text-sm font-bold text-white">
        V
      </span>
      <span className="text-lg font-semibold tracking-tight text-ink-900">
        vkb<span className="text-brand-600">.</span>
      </span>
    </Link>
  )
}

function NavGroup({ item, currentPath }: { item: NavItem; currentPath: string }) {
  const groupActive = useMemo(() => {
    if (item.children) {
      return item.children.some((child) => currentPath.startsWith(child.to.split('?')[0]))
    }
    return item.to === '/' ? currentPath === '/' : currentPath.startsWith(item.to)
  }, [item, currentPath])

  const [open, setOpen] = useState(groupActive)

  if (!item.children) {
    return (
      <NavLink
        to={item.to}
        end={item.to === '/'}
        className={({ isActive }) =>
          `flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm transition-colors ${
            isActive ? 'bg-brand-50 font-medium text-brand-700' : 'text-ink-600 hover:bg-ink-100'
          }`
        }
      >
        <span className="text-ink-500">{item.icon}</span>
        {item.label}
      </NavLink>
    )
  }

  return (
    <div>
      <button
        type="button"
        onClick={() => setOpen((value) => !value)}
        aria-expanded={open}
        className={`flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-sm transition-colors ${
          groupActive ? 'font-medium text-brand-700' : 'text-ink-600 hover:bg-ink-100'
        }`}
      >
        <span className="text-ink-500">{item.icon}</span>
        <span className="flex-1 text-left">{item.label}</span>
        <IconChevronDown className={`h-3.5 w-3.5 transition-transform ${open ? '' : '-rotate-90'}`} />
      </button>
      {open && (
        <div className="ml-4 mt-0.5 space-y-0.5 border-l border-ink-200 pl-3">
          {item.children.map((child) => (
            <NavLink
              key={child.to}
              to={child.to}
              end
              className={({ isActive }) =>
                `block rounded-md px-2.5 py-1.5 text-sm transition-colors ${
                  isActive ? 'bg-brand-50 font-medium text-brand-700' : 'text-ink-500 hover:bg-ink-100'
                }`
              }
            >
              {child.label}
            </NavLink>
          ))}
        </div>
      )}
    </div>
  )
}

function Breadcrumb({ path }: { path: string }) {
  const segments = path.split('/').filter(Boolean)
  const labels: Record<string, string> = {
    studio: 'AI Studio',
    servicos: 'Serviços',
    agentes: 'Agentes',
    skills: 'Skills',
    conhecimento: 'Conhecimento',
    ferramentas: 'Ferramentas',
    integracoes: 'Integrações',
    llm: 'LLM',
    conversas: 'Conversas',
    tarefas: 'Tarefas',
    traces: 'Traces',
    observabilidade: 'Observabilidade',
    fluxos: 'Fluxos de Trabalho',
    operacoes: 'Operações',
    'ciclo-de-vida': 'Ciclo de Vida',
    versoes: 'Versões',
    implantacoes: 'Implantações',
    portabilidade: 'Importar / Exportar',
    analytics: 'Analytics',
    'consumo-llm': 'Consumo LLM',
    'llm-gateway': 'LLM Gateway',
    curadoria: 'Curadoria',
    evaluations: 'Evaluations',
    privacidade: 'Privacidade',
    seguranca: 'Segurança',
    usuarios: 'Usuários',
    papeis: 'Papéis & Permissões',
    unidades: 'Unidades',
    chaves: 'Chaves de API',
    funcionalidades: 'Funcionalidades',
    auditoria: 'Logs de Auditoria',
    'portal-do-desenvolvedor': 'Portal do Desenvolvedor',
  }

  return (
    <nav aria-label="Trilha" className="flex items-center gap-1.5 text-sm text-ink-500">
      <Link to="/" className="hover:text-ink-800">
        Home
      </Link>
      {segments.map((segment, index) => (
        <span key={segment + index} className="flex items-center gap-1.5">
          <span className="text-ink-300">/</span>
          <span className={index === segments.length - 1 ? 'font-medium text-ink-800' : ''}>
            {labels[segment] ?? decodeURIComponent(segment)}
          </span>
        </span>
      ))}
    </nav>
  )
}

export default function ConsoleLayout() {
  const { user, signOut, can } = useAuth()
  const location = useLocation()
  const [menuOpen, setMenuOpen] = useState(false)
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const visible = NAVIGATION.filter((item) => !item.permission || can(item.permission))

  return (
    <div className="flex h-full">
      {sidebarOpen && (
        <button
          type="button"
          aria-label="Fechar navegação"
          className="fixed inset-0 z-20 bg-ink-900/30 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-30 flex w-64 shrink-0 flex-col border-r border-ink-200 bg-white transition-transform lg:static lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center justify-between">
          <Brand />
          <button
            type="button"
            className="mr-3 rounded-md p-1.5 text-ink-500 hover:bg-ink-100 lg:hidden"
            onClick={() => setSidebarOpen(false)}
            aria-label="Fechar"
          >
            <IconClose />
          </button>
        </div>

        <div className="px-3 pb-3">
          <div className="relative">
            <IconSearch className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-400" />
            <input className="input py-1.5 pl-9 text-sm" placeholder="Buscar" aria-label="Buscar" />
          </div>
        </div>

        <nav className="flex-1 space-y-0.5 overflow-y-auto px-3 pb-4">
          {visible.map((item) => (
            <NavGroup key={item.to} item={item} currentPath={location.pathname} />
          ))}
        </nav>

        <div className="relative border-t border-ink-200 p-3">
          <button
            type="button"
            onClick={() => setMenuOpen((value) => !value)}
            className="flex w-full items-center gap-2.5 rounded-lg px-2 py-2 text-left hover:bg-ink-100"
          >
            <span className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-600 text-xs font-semibold text-white">
              {user?.name?.slice(0, 2).toUpperCase() ?? '··'}
            </span>
            <span className="min-w-0 flex-1">
              <span className="block truncate text-sm font-medium text-ink-800">{user?.name}</span>
              <span className="block truncate text-xs text-ink-500">{user?.tenant_name}</span>
            </span>
          </button>

          {menuOpen && (
            <div className="absolute bottom-16 left-3 right-3 rounded-lg border border-ink-200 bg-white p-1 shadow-pop">
              <p className="px-3 py-2 text-xs text-ink-500">
                {user?.email}
                <br />
                <span className="text-ink-400">Papéis: {user?.roles.join(', ') || '—'}</span>
              </p>
              <button
                type="button"
                onClick={signOut}
                className="w-full rounded-md px-3 py-2 text-left text-sm text-rose-600 hover:bg-rose-50"
              >
                Encerrar sessão
              </button>
            </div>
          )}
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between gap-4 border-b border-ink-200 bg-white px-4 py-3 lg:px-6">
          <div className="flex items-center gap-3">
            <button
              type="button"
              className="rounded-md p-1.5 text-ink-500 hover:bg-ink-100 lg:hidden"
              onClick={() => setSidebarOpen(true)}
              aria-label="Abrir navegação"
            >
              <IconGateway />
            </button>
            <Breadcrumb path={location.pathname} />
          </div>
          <div className="flex items-center gap-2">
            <Link to="/conversas" className="btn-ghost px-2.5 py-1.5 text-xs">
              <IconChat className="h-3.5 w-3.5" />
              Chat
            </Link>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto bg-ink-100 p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
