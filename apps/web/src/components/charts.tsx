/** Gráficos em SVG inline — barras horizontais e séries temporais.
 *  Sem biblioteca externa: o console precisa rodar em rede fechada. */

import type { NamedSeries, SeriesPoint } from '../lib/types'

const SERIES_COLORS = ['#7127e3', '#3b82f6', '#0ea5a4', '#f59e0b', '#ec4899']

export function BarRanking({
  data,
  formatValue = (value: number) => String(value),
  emptyLabel = 'Sem dados no período.',
}: {
  data: SeriesPoint[]
  formatValue?: (value: number) => string
  emptyLabel?: string
}) {
  if (data.length === 0) {
    return <p className="py-10 text-center text-sm text-ink-400">{emptyLabel}</p>
  }
  const max = Math.max(...data.map((point) => point.value), 1)

  return (
    <ul className="space-y-3">
      {data.map((point) => (
        <li key={point.label} className="grid grid-cols-[minmax(0,10rem)_1fr_auto] items-center gap-3">
          <span className="truncate text-xs text-ink-600" title={point.label}>
            {point.label}
          </span>
          <span className="h-4 overflow-hidden rounded bg-ink-100">
            <span
              className="block h-full rounded bg-brand-500"
              style={{ width: `${Math.max((point.value / max) * 100, 2)}%` }}
            />
          </span>
          <span className="w-14 text-right text-xs font-medium tabular-nums text-ink-700">
            {formatValue(point.value)}
          </span>
        </li>
      ))}
    </ul>
  )
}

export function LineChart({
  series,
  height = 200,
  formatValue = (value: number) => String(value),
}: {
  series: NamedSeries[]
  height?: number
  formatValue?: (value: number) => string
}) {
  const labels = series[0]?.points.map((point) => point.label) ?? []
  const values = series.flatMap((entry) => entry.points.map((point) => point.value))
  const max = Math.max(...values, 1)

  if (labels.length === 0) {
    return <p className="py-10 text-center text-sm text-ink-400">Sem dados no período.</p>
  }

  const width = 640
  const padding = { top: 12, right: 12, bottom: 26, left: 34 }
  const plotWidth = width - padding.left - padding.right
  const plotHeight = height - padding.top - padding.bottom
  const stepX = labels.length > 1 ? plotWidth / (labels.length - 1) : 0

  const toX = (index: number) => padding.left + index * stepX
  const toY = (value: number) => padding.top + plotHeight - (value / max) * plotHeight

  // Rótulos do eixo X ficam ilegíveis em janelas longas; mostra no máximo 8.
  const labelStride = Math.max(1, Math.ceil(labels.length / 8))
  const gridLines = [0, 0.25, 0.5, 0.75, 1]

  return (
    <div>
      <div className="overflow-x-auto">
        <svg viewBox={`0 0 ${width} ${height}`} className="h-auto w-full min-w-[420px]" role="img">
          {gridLines.map((ratio) => {
            const y = padding.top + plotHeight * (1 - ratio)
            return (
              <g key={ratio}>
                <line x1={padding.left} y1={y} x2={width - padding.right} y2={y} stroke="#e4e7ee" strokeWidth={1} />
                <text x={padding.left - 6} y={y + 3} textAnchor="end" className="fill-ink-400 text-[9px]">
                  {formatValue(Math.round(max * ratio))}
                </text>
              </g>
            )
          })}

          {series.map((entry, seriesIndex) => {
            const path = entry.points
              .map((point, index) => `${index === 0 ? 'M' : 'L'} ${toX(index)} ${toY(point.value)}`)
              .join(' ')
            return (
              <path
                key={entry.name}
                d={path}
                fill="none"
                stroke={SERIES_COLORS[seriesIndex % SERIES_COLORS.length]}
                strokeWidth={2}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            )
          })}

          {labels.map((label, index) =>
            index % labelStride === 0 ? (
              <text
                key={label + index}
                x={toX(index)}
                y={height - 8}
                textAnchor="middle"
                className="fill-ink-400 text-[9px]"
              >
                {label}
              </text>
            ) : null,
          )}
        </svg>
      </div>

      <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1.5">
        {series.map((entry, index) => (
          <li key={entry.name} className="flex items-center gap-1.5 text-xs text-ink-600">
            <span
              className="h-2 w-2 rounded-full"
              style={{ background: SERIES_COLORS[index % SERIES_COLORS.length] }}
            />
            <span className="max-w-[14rem] truncate" title={entry.name}>
              {entry.name}
            </span>
          </li>
        ))}
      </ul>
    </div>
  )
}

export function Sparkbars({ data, formatValue }: { data: SeriesPoint[]; formatValue?: (v: number) => string }) {
  if (data.length === 0) return <p className="py-6 text-center text-sm text-ink-400">Sem dados.</p>
  const max = Math.max(...data.map((point) => point.value), 0.0001)

  return (
    <div className="flex h-24 items-end gap-1">
      {data.map((point) => (
        <div
          key={point.label}
          className="group relative flex-1"
          title={`${point.label}: ${formatValue ? formatValue(point.value) : point.value}`}
        >
          <div
            className="w-full rounded-t bg-brand-400 transition-colors group-hover:bg-brand-600"
            style={{ height: `${Math.max((point.value / max) * 96, 2)}px` }}
          />
        </div>
      ))}
    </div>
  )
}
