/** Blocos de UI reaproveitados pelas telas do console. */

import { Link } from 'react-router-dom'
import type { ReactNode } from 'react'
import { IconAlert, IconArrowRight, IconSearch } from './Icons'

export function PageHeader({
  icon,
  title,
  subtitle,
  actions,
}: {
  icon?: ReactNode
  title: string
  subtitle?: string
  actions?: ReactNode
}) {
  return (
    <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
      <div className="flex items-start gap-3">
        {icon && (
          <span className="mt-0.5 flex h-10 w-10 items-center justify-center rounded-lg bg-ink-100 text-ink-600">
            {icon}
          </span>
        )}
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-ink-900">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-ink-500">{subtitle}</p>}
        </div>
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  )
}

export function StatCard({
  label,
  value,
  hint,
  icon,
  to,
  accent,
}: {
  label: string
  value: ReactNode
  hint?: string
  icon?: ReactNode
  to?: string
  accent?: boolean
}) {
  const content = (
    <div
      className={`card flex h-full flex-col gap-3 p-5 transition-shadow ${
        to ? 'hover:shadow-pop' : ''
      } ${accent ? 'ring-1 ring-brand-200' : ''}`}
    >
      <div className="flex items-start justify-between">
        <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-ink-100 text-ink-600">
          {icon}
        </span>
        {to && <IconArrowRight className="h-4 w-4 text-ink-400" />}
      </div>
      <div>
        <p className="text-sm text-brand-700">{label}</p>
        <p className="mt-1 text-3xl font-semibold tracking-tight text-ink-900">{value}</p>
        {hint && <p className="mt-1 text-xs text-ink-500">{hint}</p>}
      </div>
    </div>
  )
  return to ? <Link to={to}>{content}</Link> : content
}

const BADGE_TONES: Record<string, string> = {
  neutral: 'bg-ink-100 text-ink-600',
  brand: 'bg-brand-50 text-brand-700',
  success: 'bg-emerald-50 text-emerald-700',
  warning: 'bg-amber-50 text-amber-700',
  danger: 'bg-rose-50 text-rose-700',
  info: 'bg-sky-50 text-sky-700',
}

export function Badge({
  children,
  tone = 'neutral',
  icon,
}: {
  children: ReactNode
  tone?: keyof typeof BADGE_TONES | string
  icon?: ReactNode
}) {
  return (
    <span className={`chip ${BADGE_TONES[tone] ?? BADGE_TONES.neutral}`}>
      {icon}
      {children}
    </span>
  )
}

export function SearchInput({
  value,
  onChange,
  placeholder = 'Buscar…',
  className = '',
}: {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
}) {
  return (
    <div className={`relative ${className}`}>
      <IconSearch className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-400" />
      <input
        className="input pl-9"
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
      />
    </div>
  )
}

export function Tabs<T extends string>({
  value,
  options,
  onChange,
}: {
  value: T
  options: { value: T; label: string }[]
  onChange: (value: T) => void
}) {
  return (
    <div className="flex flex-wrap items-center gap-1 rounded-lg bg-ink-100 p-1">
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          onClick={() => onChange(option.value)}
          className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
            value === option.value
              ? 'bg-white text-ink-900 shadow-card'
              : 'text-ink-500 hover:text-ink-700'
          }`}
        >
          {option.label}
        </button>
      ))}
    </div>
  )
}

export const PERIODS = ['1D', '7D', '30D', '90D'] as const
export type Period = (typeof PERIODS)[number]

export function PeriodPicker({ value, onChange }: { value: Period; onChange: (value: Period) => void }) {
  return (
    <div className="flex items-center gap-1 rounded-lg border border-ink-200 bg-white p-1">
      {PERIODS.map((period) => (
        <button
          key={period}
          type="button"
          onClick={() => onChange(period)}
          className={`rounded-md px-2.5 py-1 text-xs font-semibold transition-colors ${
            value === period ? 'bg-brand-600 text-white' : 'text-ink-500 hover:text-ink-700'
          }`}
        >
          {period}
        </button>
      ))}
    </div>
  )
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon?: ReactNode
  title: string
  description?: string
  action?: ReactNode
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 px-6 py-20 text-center">
      {icon && (
        <span className="flex h-14 w-14 items-center justify-center rounded-xl bg-ink-100 text-ink-400">
          {icon}
        </span>
      )}
      <h3 className="text-base font-semibold text-ink-900">{title}</h3>
      {description && <p className="max-w-md text-sm text-ink-500">{description}</p>}
      {action && <div className="mt-2 flex items-center gap-2">{action}</div>}
    </div>
  )
}

export function Loading({ label = 'Carregando…' }: { label?: string }) {
  return (
    <div className="flex items-center justify-center gap-3 py-16 text-sm text-ink-500">
      <span className="h-4 w-4 animate-spin rounded-full border-2 border-ink-200 border-t-brand-600" />
      {label}
    </div>
  )
}

export function ErrorBanner({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex items-start gap-3 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
      <IconAlert className="mt-0.5 h-4 w-4 shrink-0" />
      <div className="flex-1">
        <p className="font-medium">Não foi possível carregar</p>
        <p className="mt-0.5 text-rose-700">{message}</p>
      </div>
      {onRetry && (
        <button type="button" onClick={onRetry} className="text-sm font-semibold underline">
          Tentar de novo
        </button>
      )}
    </div>
  )
}

export function Section({
  title,
  description,
  icon,
  children,
  actions,
}: {
  title: string
  description?: string
  icon?: ReactNode
  children: ReactNode
  actions?: ReactNode
}) {
  return (
    <section className="card p-5">
      <div className="mb-4 flex items-start justify-between gap-4">
        <div className="flex items-start gap-3">
          {icon && <span className="mt-0.5 text-brand-600">{icon}</span>}
          <div>
            <h2 className="text-base font-semibold text-ink-900">{title}</h2>
            {description && <p className="mt-0.5 text-sm text-ink-500">{description}</p>}
          </div>
        </div>
        {actions}
      </div>
      {children}
    </section>
  )
}

export function LinkCard({
  to,
  title,
  description,
  icon,
}: {
  to: string
  title: string
  description: string
  icon?: ReactNode
}) {
  return (
    <Link
      to={to}
      className="flex items-start gap-3 rounded-lg border border-ink-200 bg-white px-4 py-3.5 transition-colors hover:border-brand-300 hover:bg-brand-50/40"
    >
      <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-ink-100 text-ink-600">
        {icon}
      </span>
      <span className="min-w-0">
        <span className="block text-sm font-medium text-ink-900">{title}</span>
        <span className="mt-0.5 block truncate text-xs text-ink-500">{description}</span>
      </span>
    </Link>
  )
}

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  onRowClick,
  empty,
}: {
  columns: { key: string; header: string; render: (row: T) => ReactNode; className?: string }[]
  rows: T[]
  rowKey: (row: T) => string
  onRowClick?: (row: T) => void
  empty?: ReactNode
}) {
  if (rows.length === 0 && empty) return <>{empty}</>

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] border-collapse">
        <thead>
          <tr className="border-b border-ink-200">
            {columns.map((column) => (
              <th key={column.key} className={`th ${column.className ?? ''}`}>
                {column.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={rowKey(row)}
              onClick={onRowClick ? () => onRowClick(row) : undefined}
              className={`border-b border-ink-100 last:border-0 ${
                onRowClick ? 'cursor-pointer hover:bg-ink-50' : ''
              }`}
            >
              {columns.map((column) => (
                <td key={column.key} className={`td ${column.className ?? ''}`}>
                  {column.render(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export function Pagination({
  page,
  pageSize,
  total,
  onChange,
}: {
  page: number
  pageSize: number
  total: number
  onChange: (page: number) => void
}) {
  const pages = Math.max(1, Math.ceil(total / pageSize))
  if (total === 0) return null
  const first = (page - 1) * pageSize + 1
  const last = Math.min(page * pageSize, total)

  return (
    <div className="flex items-center justify-between border-t border-ink-100 px-4 py-3 text-sm text-ink-500">
      <span>
        {first}–{last} de {total}
      </span>
      <div className="flex items-center gap-2">
        <button
          type="button"
          className="btn-ghost px-2.5 py-1.5"
          disabled={page <= 1}
          onClick={() => onChange(page - 1)}
        >
          Anterior
        </button>
        <span className="text-xs">
          {page} / {pages}
        </span>
        <button
          type="button"
          className="btn-ghost px-2.5 py-1.5"
          disabled={page >= pages}
          onClick={() => onChange(page + 1)}
        >
          Próxima
        </button>
      </div>
    </div>
  )
}
