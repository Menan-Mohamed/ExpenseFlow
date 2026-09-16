import type { Expense, ExpenseDetails, ExpenseInput, ExpensePagination, ExpenseQuery } from './expenses'
import { apiError, apiFetch } from './api'

export interface ManagerMember { id: number; email: string; role: string; active: boolean; team_id: number | null }
export interface ManagerReviewExpense extends Expense { user_id: number; user_email: string }
export interface ManagerReviewDetails extends ManagerReviewExpense { history: ExpenseDetails['history'] }
export interface ManagerMemberPage { users: ManagerMember[]; pagination: ExpensePagination }
export interface ManagerReviewPage { expenses: ManagerReviewExpense[]; pagination: ExpensePagination }

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await apiFetch(`/manager${path}`, options)
  if (!response.ok) {
    throw await apiError(response, 'Unable to complete the request.')
  }
  if (response.status === 204) return undefined as T
  return response.json() as Promise<T>
}

function query(params: Record<string, string | number | undefined>) {
  return new URLSearchParams(Object.entries(params).filter(([, value]) => value !== undefined && value !== '') as [string, string][]).toString()
}

export const getManagerExpenses = (page = 1, filters: ExpenseQuery = {}) => request<{ expenses: Expense[]; pagination: ExpensePagination }>(`/expenses?${query({ page, per_page: 5, ...filters })}`)
export const getManagerExpense = (id: number) => request<ExpenseDetails>(`/expenses/${id}`)
export const createManagerExpense = (input: ExpenseInput) => request<Expense>('/expenses', { method: 'POST', body: JSON.stringify({ expense: input }) })
export const updateManagerExpense = (id: number, input: ExpenseInput) => request<Expense>(`/expenses/${id}`, { method: 'PATCH', body: JSON.stringify({ expense: input }) })
export const deleteManagerExpense = (id: number) => request<void>(`/expenses/${id}`, { method: 'DELETE' })
export const submitManagerExpense = (id: number) => request<Expense>(`/expenses/${id}/submit`, { method: 'POST' })
export const getManagerMembers = (page = 1) => request<ManagerMemberPage>(`/team_members?page=${page}&per_page=10`)
export const getManagerReviews = (page = 1) => request<ManagerReviewPage>(`/reviews?page=${page}&per_page=10`)
export const getManagerReview = (id: number) => request<ManagerReviewDetails>(`/reviews/${id}`)
export const approveManagerExpense = (id: number, comment = '') => request<ManagerReviewExpense>(`/reviews/${id}/approve`, { method: 'POST', body: JSON.stringify({ comment }) })
export const rejectManagerExpense = (id: number, comment: string) => request<ManagerReviewExpense>(`/reviews/${id}/reject`, { method: 'POST', body: JSON.stringify({ comment }) })