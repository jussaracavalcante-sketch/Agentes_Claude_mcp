/** Sessão do console: token, usuário corrente e verificação de permissão. */

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import { ApiError, api, token } from './api'
import type { CurrentUser } from './types'

interface AuthState {
  user: CurrentUser | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => void
  can: (permission: string) => boolean
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<CurrentUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!token.get()) {
      setLoading(false)
      return
    }
    api
      .get<CurrentUser>('/auth/me')
      .then(setUser)
      .catch(() => token.clear())
      .finally(() => setLoading(false))
  }, [])

  const signIn = useCallback(async (email: string, password: string) => {
    const response = await api.post<{ access_token: string }>('/auth/login', { email, password })
    token.set(response.access_token)
    setUser(await api.get<CurrentUser>('/auth/me'))
  }, [])

  const signOut = useCallback(() => {
    token.clear()
    setUser(null)
  }, [])

  const can = useCallback(
    (permission: string) =>
      Boolean(user && (user.permissions.includes('*') || user.permissions.includes(permission))),
    [user],
  )

  const value = useMemo(
    () => ({ user, loading, signIn, signOut, can }),
    [user, loading, signIn, signOut, can],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthState {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth precisa estar dentro de <AuthProvider>.')
  return context
}

export function describeError(error: unknown): string {
  return error instanceof ApiError ? error.message : 'Não foi possível concluir a operação.'
}
