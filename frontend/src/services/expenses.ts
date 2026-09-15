export interface Category {
  id: number
  name: string
  auto_approve_limit: string
}

export type ExpenseState = 'draft' | 'submitted' | 'approved' | 'rejected' | 'reimbursed'

export interface Expense {
  id: number
  title: string
  description: string | null
  amount: string
  category_id: number
  category_name: string
  spent_date: string
  state: ExpenseState
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

const API_URL = 'http://localhost:3000/api/v2'
const TOKEN_KEY = 'expenseflow_token'

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem(TOKEN_KEY)
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  })

  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { error?: string; errors?: string[] }
    throw new Error(body.errors?.join(', ') ?? body.error ?? 'Unable to complete the request.')
  }

  if (response.status === 204) return undefined as T
  return (await response.json()) as T
}

export function getExpenses(page = 1, perPage = 5): Promise<ExpensePage> {
  return request<ExpensePage>(`/expenses?page=${page}&per_page=${perPage}`)
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
