import type { ExpenseDetails, ExpenseState } from './expenses'
import type { UserRole } from './auth'

export interface AdminPagination { page: number; per_page: number; total_count: number; total_pages: number }
export interface AdminUser { id: number; email: string; role: UserRole; active: boolean; team_id: number | null; team_name: string | null }
export interface AdminCategory { id: number; name: string; auto_approve_limit: string; active: boolean }
export interface AdminTeam { id: number; name: string; manager_id: number | null; manager_email: string | null }
export interface AdminExpense extends ExpenseDetails { user_id: number; user_email: string; user_role: UserRole; payment_reference: string | null }
export interface ReportRow { month: string; category: string; approved_count: number; approved_amount: string; reimbursed_count: number; reimbursed_amount: string }
export interface Report { generated_at: string; filters: { from: string; to: string; state?: string }; rows: ReportRow[]; summary: { total_expenses: number; total_amount: string } }

const API_URL = 'http://localhost:3000/api/v1/admin'
const TOKEN_KEY = 'expenseflow_token'

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`${API_URL}${path}`, { ...options, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${sessionStorage.getItem(TOKEN_KEY)}`, ...options.headers } })
  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { error?: string; errors?: string[] }
    throw new Error(body.errors?.join(', ') ?? body.error ?? 'Unable to complete the request.')
  }
  if (response.status === 204) return undefined as T
  return response.json() as Promise<T>
}

function query(params: Record<string, string | number | undefined>) {
  return new URLSearchParams(Object.entries(params).filter(([, value]) => value !== undefined && value !== '') as [string, string][]).toString()
}

export const getAdminUsers = (params: Record<string, string | number | undefined>) => request<{ users: AdminUser[]; pagination: AdminPagination }>(`/users?${query(params)}`)
export const saveAdminUser = (input: Partial<AdminUser> & { password?: string }) => request<AdminUser>(input.id ? `/users/${input.id}` : '/users', { method: input.id ? 'PATCH' : 'POST', body: JSON.stringify({ user: input }) })
export const setUserActive = (id: number, active: boolean) => request<AdminUser>(`/users/${id}/${active ? 'activate' : 'deactivate'}`, { method: 'POST' })

export const getAdminExpenses = (params: Record<string, string | number | undefined>) => request<{ expenses: AdminExpense[]; pagination: AdminPagination }>(`/expenses?${query(params)}`)
export const getAdminExpense = (id: number) => request<AdminExpense>(`/expenses/${id}`)
export const approveAdminExpense = (id: number, comment = '') => request<AdminExpense>(`/expenses/${id}/approve`, { method: 'POST', body: JSON.stringify({ comment }) })
export const rejectAdminExpense = (id: number, comment: string) => request<AdminExpense>(`/expenses/${id}/reject`, { method: 'POST', body: JSON.stringify({ comment }) })
export const reimburseExpense = (id: number, payment_reference: string) => request<AdminExpense>(`/expenses/${id}/reimburse`, { method: 'POST', body: JSON.stringify({ payment_reference }) })

export const getAdminCategories = (params: Record<string, string | number | undefined>) => request<{ categories: AdminCategory[]; pagination: AdminPagination }>(`/categories?${query(params)}`)
export const saveAdminCategory = (input: Partial<AdminCategory>) => request<AdminCategory>(input.id ? `/categories/${input.id}` : '/categories', { method: input.id ? 'PATCH' : 'POST', body: JSON.stringify({ category: input }) })

export const getAdminTeams = (page = 1) => request<{ teams: AdminTeam[]; pagination: AdminPagination }>(`/teams?page=${page}&per_page=50`)
export const saveAdminTeam = (input: Partial<AdminTeam>) => request<AdminTeam>(input.id ? `/teams/${input.id}` : '/teams', { method: input.id ? 'PATCH' : 'POST', body: JSON.stringify({ team: input }) })
export const deleteAdminTeam = (id: number) => request<void>(`/teams/${id}`, { method: 'DELETE' })

export const getAdminReport = (params: Record<string, string | undefined>) => request<Report>(`/report?${query(params)}`)
export async function downloadAdminReportCsv(params: Record<string, string | undefined>): Promise<Blob> {
  const response = await fetch(`${API_URL}/report.csv?${query(params)}`, { headers: { Accept: 'text/csv', Authorization: `Bearer ${sessionStorage.getItem(TOKEN_KEY)}` } })
  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { error?: string }
    throw new Error(body.error ?? 'Unable to export report.')
  }
  return response.blob()
}

export type { ExpenseState }