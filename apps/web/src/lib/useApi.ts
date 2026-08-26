/** Hook de leitura: busca, revalida e expõe estado de carregamento e erro. */

import { useCallback, useEffect, useState } from 'react'
import { ApiError, api } from './api'

type Query = Record<string, string | number | boolean | undefined | null>

export function useApi<T>(path: string | null, query?: Query) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(path !== null)

  // A query entra na dependência serializada: o objeto muda de identidade
  // a cada render, mas o conteúdo é o que define uma nova busca.
  const querySignature = JSON.stringify(query ?? {})

  const load = useCallback(async () => {
    if (path === null) return
    setLoading(true)
    setError(null)
    try {
      setData(await api.get<T>(path, JSON.parse(querySignature)))
    } catch (caught) {
      setError(caught instanceof ApiError ? caught.message : 'Erro inesperado.')
    } finally {
      setLoading(false)
    }
  }, [path, querySignature])

  useEffect(() => {
    void load()
  }, [load])

  return { data, error, loading, reload: load }
}
