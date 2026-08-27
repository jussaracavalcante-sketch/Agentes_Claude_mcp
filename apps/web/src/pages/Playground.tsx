/** Executar um serviço: conversar com o agente e ver o custo real do turno. */

import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../lib/api'
import { describeError, useAuth } from '../lib/auth'
import { useApi } from '../lib/useApi'
import type { RunResponse, Service, ToolCallResult } from '../lib/types'
import { SERVICE_TYPE_LABEL, formatNumber, formatUsd } from '../lib/format'
import { Badge, ErrorBanner, Loading, PageHeader, Section } from '../components/ui'
import { IconAlert, IconPlay, IconTrace } from '../components/Icons'

interface Turn {
  role: 'user' | 'assistant'
  text: string
  meta?: RunResponse
}

export default function Playground() {
  const { can } = useAuth()
  const services = useApi<Service[]>('/services')
  const [serviceUid, setServiceUid] = useState('')
  const [message, setMessage] = useState('')
  const [turns, setTurns] = useState<Turn[]>([])
  const [conversationUid, setConversationUid] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const bottom = useRef<HTMLDivElement>(null)

  const runnable = (services.data ?? []).filter((service) => service.type !== 'task')
  const selected = runnable.find((service) => service.uid === serviceUid)

  useEffect(() => {
    if (!serviceUid && runnable.length > 0) setServiceUid(runnable[0].uid)
  }, [runnable, serviceUid])

  useEffect(() => {
    bottom.current?.scrollIntoView({ behavior: 'smooth' })
  }, [turns])

  async function send(event: React.FormEvent) {
    event.preventDefault()
    const text = message.trim()
    if (!text || !serviceUid) return

    setBusy(true)
    setError(null)
    setMessage('')
    setTurns((current) => [...current, { role: 'user', text }])

    try {
      const response = await api.post<RunResponse>(`/services/${serviceUid}/run`, {
        message: text,
        conversation_uid: conversationUid,
      })
      setConversationUid(response.conversation_uid)
      setTurns((current) => [...current, { role: 'assistant', text: response.text, meta: response }])
    } catch (caught) {
      setError(describeError(caught))
    } finally {
      setBusy(false)
    }
  }

  function reset() {
    setTurns([])
    setConversationUid(null)
    setError(null)
  }

  if (services.loading) return <Loading />
  if (services.error) return <ErrorBanner message={services.error} onRetry={services.reload} />

  return (
    <div className="space-y-5">
      <PageHeader
        icon={<IconPlay />}
        title="Executar serviço"
        subtitle="Converse com o agente e acompanhe tokens, custo e trace de cada turno."
        actions={
          turns.length > 0 && (
            <button type="button" className="btn-ghost" onClick={reset}>
              Nova conversa
            </button>
          )
        }
      />

      {!can('runtime:execute') && (
        <div className="flex items-start gap-3 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <IconAlert className="mt-0.5" />
          <span>
            Seu papel não tem a permissão <code>runtime:execute</code>. Você pode ver a tela, mas
            não executar.
          </span>
        </div>
      )}

      <div className="card p-4">
        <label htmlFor="servico" className="mb-1.5 block text-sm font-medium text-ink-700">
          Serviço
        </label>
        <div className="flex flex-wrap items-center gap-3">
          <select
            id="servico"
            className="input max-w-md"
            value={serviceUid}
            onChange={(event) => {
              setServiceUid(event.target.value)
              reset()
            }}
          >
            {runnable.map((service) => (
              <option key={service.uid} value={service.uid}>
                {service.name}
              </option>
            ))}
          </select>
          {selected && (
            <>
              <Badge tone={selected.type === 'copilot' ? 'brand' : 'info'}>
                {SERVICE_TYPE_LABEL[selected.type]}
              </Badge>
              <Badge tone={selected.status === 'active' ? 'success' : 'neutral'}>
                {selected.status}
              </Badge>
              {conversationUid && (
                <Link
                  to={`/conversas/${conversationUid}`}
                  className="text-sm font-medium text-brand-700 hover:underline"
                >
                  ver conversa registrada →
                </Link>
              )}
            </>
          )}
        </div>
        {selected?.description && (
          <p className="mt-3 text-sm text-ink-500">{selected.description}</p>
        )}
      </div>

      <Section title="Conversa" description="Cada resposta traz o trace, os tokens e o custo do turno">
        <div className="max-h-[26rem] space-y-3 overflow-y-auto pr-1">
          {turns.length === 0 && (
            <p className="py-10 text-center text-sm text-ink-400">
              Envie uma mensagem para executar o serviço.
            </p>
          )}
          {turns.map((turn, index) => (
            <div key={index} className={`flex ${turn.role === 'user' ? 'justify-start' : 'justify-end'}`}>
              <div className="max-w-[85%]">
                <div
                  className={`whitespace-pre-wrap rounded-2xl px-4 py-2.5 text-sm ${
                    turn.role === 'user'
                      ? 'rounded-tl-sm bg-ink-100 text-ink-800'
                      : 'rounded-tr-sm bg-brand-600 text-white'
                  }`}
                >
                  {turn.text}
                </div>
                {turn.meta && <TurnFooter meta={turn.meta} />}
              </div>
            </div>
          ))}
          <div ref={bottom} />
        </div>

        {error && <div className="mt-4"><ErrorBanner message={error} /></div>}

        <form onSubmit={send} className="mt-4 flex items-end gap-2">
          <textarea
            className="input min-h-[3rem] flex-1"
            placeholder="Escreva a mensagem…"
            value={message}
            onChange={(event) => setMessage(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' && !event.shiftKey) {
                event.preventDefault()
                void send(event)
              }
            }}
            disabled={busy || !can('runtime:execute')}
          />
          <button
            type="submit"
            className="btn-primary"
            disabled={busy || !message.trim() || !can('runtime:execute')}
          >
            {busy ? 'Executando…' : 'Enviar'}
          </button>
        </form>
      </Section>
    </div>
  )
}

function TurnFooter({ meta }: { meta: RunResponse }) {
  return (
    <div className="mt-1.5 flex flex-wrap items-center justify-end gap-2 text-[11px] text-ink-500">
      {meta.status === 'awaiting_approval' && <Badge tone="warning">aguardando aprovação</Badge>}
      {meta.status === 'error' && <Badge tone="danger">falhou</Badge>}
      <span className="tabular-nums">
        {formatNumber(meta.tokens_in)} → {formatNumber(meta.tokens_out)} tokens
      </span>
      <span className="tabular-nums">{formatUsd(meta.cost_usd)}</span>
      {meta.provider && <Badge>{meta.provider}</Badge>}
      {meta.tool_calls.map((call: ToolCallResult, index) => (
        <Badge key={index} tone={call.ok ? 'success' : 'danger'}>
          {call.tool}
        </Badge>
      ))}
      <Link
        to={`/traces/${meta.trace_uid}`}
        className="inline-flex items-center gap-1 text-brand-700 hover:underline"
      >
        <IconTrace className="h-3 w-3" />
        trace
      </Link>
    </div>
  )
}
