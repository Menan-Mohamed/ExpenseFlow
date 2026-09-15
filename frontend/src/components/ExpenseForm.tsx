import { useState, type FormEvent } from 'react'
import type { Category, Expense, ExpenseInput } from '../services/expenses'

interface ExpenseFormProps {
  categories: Category[]
  expense: Expense | null
  isSaving: boolean
  error: string | null
  onSubmit: (input: ExpenseInput) => Promise<void>
  onCancel: () => void
}

function initialInput(expense: Expense | null): ExpenseInput {
  return {
    title: expense?.title ?? '',
    description: expense?.description ?? '',
    amount: expense?.amount ?? '',
    category_id: expense?.category_id ?? 0,
    spent_date: expense?.spent_date ?? new Date().toISOString().slice(0, 10),
  }
}

export function ExpenseForm({ categories, expense, isSaving, error, onSubmit, onCancel }: ExpenseFormProps) {
  const [input, setInput] = useState<ExpenseInput>(() => initialInput(expense))
  const [today] = useState(() => new Date().toISOString().slice(0, 10))
  const earliestDate = new Date(new Date(`${today}T00:00:00`).getTime() - 90 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)

  function updateField<Key extends keyof ExpenseInput>(key: Key, value: ExpenseInput[Key]) {
    setInput((current) => ({ ...current, [key]: value }))
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    await onSubmit(input)
  }

  return (
    <form className="expense-form" onSubmit={handleSubmit}>
      <div className="form-heading">
        <div>
          <p className="eyebrow">{expense ? 'Draft expense' : 'New expense'}</p>
          <h2>{expense ? 'Edit expense' : 'Record a purchase'}</h2>
        </div>
        {expense && <button className="text-button" type="button" onClick={onCancel}>Cancel</button>}
      </div>
      <label className="field"><span>Title</span><input value={input.title} onChange={(event) => updateField('title', event.target.value)} required maxLength={120} placeholder="e.g. Client dinner" /></label>
      <label className="field"><span>Description <small>optional</small></span><textarea value={input.description} onChange={(event) => updateField('description', event.target.value)} rows={3} placeholder="Add context for your manager" /></label>
      <div className="form-grid">
        <label className="field"><span>Amount</span><input type="number" min="0.01" max="100000" step="0.01" value={input.amount} onChange={(event) => updateField('amount', event.target.value)} required placeholder="0.00" /></label>
        <label className="field"><span>Date spent</span><input type="date" min={earliestDate} max={today} value={input.spent_date} onChange={(event) => updateField('spent_date', event.target.value)} required /></label>
      </div>
      <label className="field"><span>Category</span><select value={input.category_id} onChange={(event) => updateField('category_id', Number(event.target.value))} required><option value={0} disabled>Select a category</option>{categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}</select></label>
      {error && <p className="error-message" role="alert">{error}</p>}
      <button className="submit-button" type="submit" disabled={isSaving || categories.length === 0}>{isSaving ? 'Saving...' : expense ? 'Save changes' : 'Save draft'}</button>
    </form>
  )
}
