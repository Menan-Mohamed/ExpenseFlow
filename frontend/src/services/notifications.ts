import { apiError, apiFetch } from './api'

export interface Notification {
  id: number
  content: string
  created_at: string
}

export async function getUnreadNotifications(): Promise<Notification[]> {
  const response = await apiFetch('/notifications')

  if (!response.ok) {
    throw await apiError(response, 'Unable to load notifications.')
  }

  return response.json() as Promise<Notification[]>
}