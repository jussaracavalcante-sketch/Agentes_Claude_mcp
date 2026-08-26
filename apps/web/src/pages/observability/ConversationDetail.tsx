import { Link, useParams } from 'react-router-dom'
import { useApi } from '../../lib/useApi'
import type { ConversationDetail as ConversationDetailType } from '../../lib/types'
import {
  CHANNEL_LABEL,
  CONVERSATION_STATUS_LABEL,
  formatDateTime,
  formatNumber,
  formatTime,
  formatUsd,
} from '../../lib/format'
import { Badge, ErrorBanner, Loading } from '../../components/ui'
import { IconArrowLeft, IconTrace } from '../../components/Icons'

export default function ConversationDetail() {
  const { uid = '' } = useParams()
  const { data, error, loading, reload } = useApi<ConversationDetailType>(
    uid ? `/conversations/${uid}` : null,
  )

  if (loading) return <Loading />
  if (error) return <ErrorBanner message={error} onRetry={reload} />
  if (!data) return null

  return (
    <div>
      <Link to="/conversas" className="mb-4 inline-flex items-center gap-1.5 text-sm text-ink-500 hover:text-ink-800">
        <IconArrowLeft className="h-4 w-4" />
        Voltar para conversas
      </Link>

      <div className="mb-5 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-ink-900">
            Conversa #{data.public_id}
          </h1>
          <p className="mt-1 text-sm text-ink-500">{data.service_name}</p>
        </div>
        {data.trace_uid && (
          <Link to={`/traces/${data.trace_uid}`} className="btn-ghost">
            <IconTrace className="h-4 w-4" />
            Ver trace
          </Link>
        )}
      </div>

      <div className="grid gap-4 lg:grid-cols-[1fr_18rem]">
        <section className="card p-5">
          <h2 className="mb-4 text-base font-semibold text-ink-900">Transcrição</h2>
          <ul className="space-y-3">
            {data.messages.map((message) => (
              <li
                key={message.uid}
                className={`flex ${message.role === 'user' ? 'justify-start' : 'justify-end'}`}
              >
                <div
                  className={`max-w-[80%] rounded-2xl px-4 py-2.5 text-sm ${
                    message.role === 'user'
                      ? 'rounded-tl-sm bg-ink-100 text-ink-800'
                      : 'rounded-tr-sm bg-brand-600 text-white'
                  }`}
                >
                  <p>{message.content}</p>
                  <p
                    className={`mt-1 text-[11px] ${
                      message.role === 'user' ? 'text-ink-400' : 'text-brand-100'
                    }`}
                  >
                    {formatTime(message.sent_at)} · {formatNumber(message.tokens)} tokens
                  </p>
                </div>
              </li>
            ))}
            {data.messages.length === 0 && (
              <li className="py-10 text-center text-sm text-ink-400">Sem mensagens registradas.</li>
            )}
          </ul>
        </section>

        <aside className="card h-fit p-5">
          <h2 className="mb-4 text-base font-semibold text-ink-900">Detalhes</h2>
          <dl className="space-y-3.5 text-sm">
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Status</dt>
              <dd className="mt-1">
                <Badge tone={data.status === 'failed' ? 'danger' : data.status === 'active' ? 'success' : 'neutral'}>
                  {CONVERSATION_STATUS_LABEL[data.status]}
                </Badge>
              </dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Canal</dt>
              <dd className="mt-1 text-ink-800">{CHANNEL_LABEL[data.channel] ?? data.channel}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Intenção</dt>
              <dd className="mt-1 text-ink-800">{data.intent ?? '—'}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Início</dt>
              <dd className="mt-1 text-ink-800">{formatDateTime(data.started_at)}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Encerramento</dt>
              <dd className="mt-1 text-ink-800">{formatDateTime(data.ended_at)}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Transbordo</dt>
              <dd className="mt-1 text-ink-800">
                {data.handoff_at ? `${formatDateTime(data.handoff_at)} — ${data.handoff_reason}` : '—'}
              </dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">CSAT</dt>
              <dd className="mt-1 text-ink-800">{data.csat ? `${data.csat}/5` : '—'}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-wide text-ink-400">Tokens / custo</dt>
              <dd className="mt-1 text-ink-800">
                {formatNumber(data.tokens_total)} · {formatUsd(data.cost_usd)}
              </dd>
            </div>
          </dl>
        </aside>
      </div>
    </div>
  )
}
