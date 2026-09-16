import { useEffect, useState } from 'react'
import { ExpenseForm } from '../components/ExpenseForm'
import { ExpenseDetails } from '../components/ExpenseDetails'
import { ExpenseList } from '../components/ExpenseList'
import { createExpense, deleteExpense, getCategories, getExpenses, reopenExpense, submitExpense, updateExpense, type Category, type Expense, type ExpenseInput, type ExpensePagination } from '../services/expenses'
import { ProfileButton } from '../components/ProfileButton'
import { NotificationButton } from '../components/NotificationButton'
import { ExpenseFilters, type ExpenseFilterValues } from '../components/ExpenseFilters'

export function EmployeePage({ onLogout }: { onLogout: () => void }) {
  const [expenses, setExpenses] = useState<Expense[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [editingExpense, setEditingExpense] = useState<Expense | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [resetFormKey, setResetFormKey] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(1)
  const [pagination, setPagination] = useState<ExpensePagination>({ page: 1, per_page: 10, total_count: 0, total_pages: 0 })
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null)
  const [filters, setFilters] = useState<ExpenseFilterValues>({ status: '', category: '', from_date: '', to_date: '', sort: 'date', direction: 'desc' })

  useEffect(() => {
    Promise.all([getExpenses(page, 5, filters), getCategories()])
      .then(([expensePage, loadedCategories]) => {
        setExpenses(expensePage.expenses)
        setPagination(expensePage.pagination)
        setCategories(loadedCategories)
      })
      .catch((loadError) => setError(loadError instanceof Error ? loadError.message : 'Unable to load expenses.'))
      .finally(() => setIsLoading(false))
  }, [page, filters])

  async function handleSubmit(input: ExpenseInput) {
    setIsSaving(true)
    setError(null)
    try {
      const savedExpense = editingExpense ? await updateExpense(editingExpense.id, input) : await createExpense(input)
      setExpenses((current) => editingExpense ? current.map((expense) => expense.id === savedExpense.id ? savedExpense : expense) : [savedExpense, ...current])
      if (!editingExpense && page !== 1) setPage(1)
      if (!editingExpense) setResetFormKey((current) => current + 1)
      setEditingExpense(null)
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to save expense.')
    } finally {
      setIsSaving(false)
    }
  }

  async function handleDelete(expense: Expense) {
    if (!window.confirm(`Delete "${expense.title}"?`)) return

    try {
      await deleteExpense(expense.id)
      setExpenses((current) => current.filter((item) => item.id !== expense.id))
      setPagination((current) => ({ ...current, total_count: Math.max(current.total_count - 1, 0) }))
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : 'Unable to delete expense.')
    }
  }

  async function handleSubmitExpense(expense: Expense) {
    if (!window.confirm(`Submit "${expense.title}" for review?`)) return

    try {
      const submittedExpense = await submitExpense(expense.id)
      setExpenses((current) => current.map((item) => item.id === submittedExpense.id ? submittedExpense : item))
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to submit expense.')
    }
  }

  async function handleReopenExpense(expense: Expense) {
    try {
      const reopenedExpense = await reopenExpense(expense.id)
      setExpenses((current) => current.map((item) => item.id === reopenedExpense.id ? reopenedExpense : item))
    } catch (reopenError) {
      setError(reopenError instanceof Error ? reopenError.message : 'Unable to reopen expense.')
    }
  }

  return <main className="dashboard">
    <nav className="dashboard-nav" aria-label="Main navigation"><div className="brand"><span className="brand-mark">+</span>expenseflow</div><div className="header-actions"><NotificationButton /><ProfileButton /><button className="logout-button" type="button" onClick={onLogout}>Sign out</button></div></nav>
    <section className="employee-content">
      <div className="employee-intro"><p className="eyebrow">Employee workspace</p></div>
      {error && <p className="error-message" role="alert">{error}</p>}
      {isLoading ? <p className="empty-state">Loading your expenses...</p> : <div className="expense-layout"><ExpenseForm key={`${editingExpense?.id ?? 'new'}-${resetFormKey}`} categories={categories} expense={editingExpense} isSaving={isSaving} error={null} onSubmit={handleSubmit} onCancel={() => setEditingExpense(null)} /><div><ExpenseFilters categories={categories} value={filters} onChange={(value) => { setFilters(value); setPage(1) }} />{selectedExpense && <ExpenseDetails expense={selectedExpense} onClose={() => setSelectedExpense(null)} />}<ExpenseList expenses={expenses} onEdit={setEditingExpense} onDelete={handleDelete} onSubmit={handleSubmitExpense} onReopen={handleReopenExpense} onDetails={setSelectedExpense} pagination={pagination} onPageChange={setPage} /></div></div>}
    </section>
  </main>
}