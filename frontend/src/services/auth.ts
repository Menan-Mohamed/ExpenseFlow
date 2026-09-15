export type UserRole = 'admin' | 'manager' | 'employee'

export interface User {
  id: number
  email: string
  role: UserRole
  team_id: number | null
  team_name?: string | null
}

export interface LoginResponse {
  token: string
  user: User
}

interface LoginErrorResponse {
  error?: string
}

const API_URL = 'http://localhost:3000/api/v1'
const TOKEN_KEY = 'expenseflow_token'

export async function login(email: string, password: string): Promise<LoginResponse> {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })

  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as LoginErrorResponse
    throw new Error(body.error ?? 'Unable to sign in. Check your credentials.')
  }

  return (await response.json()) as LoginResponse
}

export async function logout(token: string): Promise<void> {
  await fetch(`${API_URL}/auth/logout`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  })
}

export async function getMe(): Promise<User> {
  const response = await fetch(`${API_URL}/me`, {
    headers: { Authorization: `Bearer ${sessionStorage.getItem(TOKEN_KEY)}` },
  })

  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as LoginErrorResponse
    throw new Error(body.error ?? 'Unable to load your profile.')
  }

  return (await response.json()) as User
}