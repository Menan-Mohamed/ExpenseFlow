import { createContext, useContext, useState, type ReactNode } from 'react'
import { login as requestLogin, logout as requestLogout, type User } from '../services/auth'

interface AuthContextValue {
  user: User | null
  isLoading: boolean
  error: string | null
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const USER_KEY = 'expenseflow_user'
const TOKEN_KEY = 'expenseflow_token'

function getStoredUser(): User | null {
  const storedUser = sessionStorage.getItem(USER_KEY)
  if (!storedUser) return null

  try {
    return JSON.parse(storedUser) as User
  } catch {
    sessionStorage.removeItem(USER_KEY)
    sessionStorage.removeItem(TOKEN_KEY)
    return null
  }
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(getStoredUser)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function login(email: string, password: string) {
    setIsLoading(true)
    setError(null)

    try {
      const result = await requestLogin(email, password)
      sessionStorage.setItem(TOKEN_KEY, result.token)
      sessionStorage.setItem(USER_KEY, JSON.stringify(result.user))
      setUser(result.user)
    } catch (loginError) {
      setError(loginError instanceof Error ? loginError.message : 'Unable to sign in.')
      throw loginError
    } finally {
      setIsLoading(false)
    }
  }

  async function logout() {
    const token = sessionStorage.getItem(TOKEN_KEY)

    try {
      if (token) await requestLogout(token)
    } finally {
      sessionStorage.removeItem(TOKEN_KEY)
      sessionStorage.removeItem(USER_KEY)
      setUser(null)
    }
  }

  return (
    <AuthContext.Provider value={{ user, isLoading, error, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within an AuthProvider')
  return context
}