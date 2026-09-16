import { apiError, apiFetch } from './api'

export interface Category {
  id: number
  name: string
  auto_approve_limit: string
}

export type ExpenseState = 'draft' | 'submitted' | 'approved' | 'rejected' | 'reimbursed'
export type ApprovalStage = 'not_applicable' | 'awaiting_manager' | 'awaiting_admin'

export interface Expense {
  id: number
  title: string
  description: string | null
  amount: string
  payment_reference: string | null
  category_id: number
  category_name: string
  spent_date: string
  state: ExpenseState
  approval_stage: ApprovalStage
  created_at: string
  updated_at: string
}

export interface ExpenseInput {
  title: string
  description: string
  amount: string
  category_id: number
  spent_date: string
}

export interface ExpenseHistory {
  id: number
  prev_state: number | null
  next_state: number | null
  comment: string | null
  changed_by: string | null
  created_at: string
}

export interface ExpenseDetails extends Expense {
  history: ExpenseHistory[]
}

export interface ExpensePagination {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface ExpensePage {
  expenses: Expense[]
  pagination: ExpensePagination
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await apiFetch(path, options)

  if (!response.ok) {
    throw await apiError(response, 'Unable to complete the request.')
  }

  if (response.status === 204) return undefined as T
  return (await response.json()) as T
}

export interface ExpenseQuery {
  status?: string
  category?: string
  from_date?: string
  to_date?: string
  sort?: string
  direction?: string
}

function query(params: Record<string, string | number | undefined>) {
  return new URLSearchParams(Object.entries(params).filter(([, value]) => value !== undefined && value !== '') as [string, string][]).toString()
}

export function getExpenses(page = 1, perPage = 5, filters: ExpenseQuery = {}): Promise<ExpensePage> {
  return request<ExpensePage>(`/expenses?${query({ page, per_page: perPage, ...filters })}`)
}

export function getExpense(id: number): Promise<ExpenseDetails> {
  return request<ExpenseDetails>(`/expenses/${id}`)
}

export function getCategories(): Promise<Category[]> {
  return request<Category[]>('/categories')
}

export function createExpense(input: ExpenseInput): Promise<Expense> {
  return request<Expense>('/expenses', {
    method: 'POST',
    body: JSON.stringify({ expense: input }),
  })
}

export function updateExpense(id: number, input: ExpenseInput): Promise<Expense> {
  return request<Expense>(`/expenses/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ expense: input }),
  })
}

export function deleteExpense(id: number): Promise<void> {
  return request<void>(`/expenses/${id}`, { method: 'DELETE' })
}

export function submitExpense(id: number): Promise<Expense> {
  return request<Expense>(`/expenses/${id}/submit`, { method: 'POST' })
}

export function reopenExpense(id: number): Promise<Expense> {
  return request<Expense>(`/expenses/${id}/reopen`, { method: 'POST' })
}
