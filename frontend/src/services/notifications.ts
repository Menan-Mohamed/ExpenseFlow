export interface Notification {
  id: number
  content: string
  created_at: string
}

const API_URL = 'http://localhost:3000/api/v1'
const TOKEN_KEY = 'expenseflow_token'

export async function getUnreadNotifications(): Promise<Notification[]> {
  const response = await fetch(`${API_URL}/notifications`, {
    headers: { Authorization: `Bearer ${sessionStorage.getItem(TOKEN_KEY)}` },
  })

  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { error?: string }
    throw new Error(body.error ?? 'Unable to load notifications.')
  }

  return response.json() as Promise<Notification[]>
}