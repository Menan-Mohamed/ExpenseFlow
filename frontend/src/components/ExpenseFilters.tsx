import type { Category, ExpenseState } from '../services/expenses'

export interface ExpenseFilterValues {
  status: '' | ExpenseState
  category: string
  from_date: string
  to_date: string
  sort: 'date' | 'amount'
  direction: 'asc' | 'desc'
}

interface ExpenseFiltersProps {
  categories: Category[]
  value: ExpenseFilterValues
  onChange: (value: ExpenseFilterValues) => void
}

export function ExpenseFilters({ categories, value, onChange }: ExpenseFiltersProps) {
  function update(key: keyof ExpenseFilterValues, nextValue: string) {
    onChange({ ...value, [key]: nextValue })
  }

  return <div className="toolbar expense-filters"><select aria-label="Filter by status" value={value.status} onChange={(event) => update('status', event.target.value)}><option value="">All statuses</option>{(['draft', 'submitted', 'approved', 'rejected', 'reimbursed'] as ExpenseState[]).map((state) => <option key={state} value={state}>{state}</option>)}</select><select aria-label="Filter by category" value={value.category} onChange={(event) => update('category', event.target.value)}><option value="">All categories</option>{categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}</select><label>From <input type="date" value={value.from_date} onChange={(event) => update('from_date', event.target.value)} /></label><label>To <input type="date" value={value.to_date} onChange={(event) => update('to_date', event.target.value)} /></label><select aria-label="Sort expenses" value={value.sort} onChange={(event) => update('sort', event.target.value)}><option value="date">Date</option><option value="amount">Amount</option></select><select aria-label="Sort direction" value={value.direction} onChange={(event) => update('direction', event.target.value)}><option value="desc">Newest / highest</option><option value="asc">Oldest / lowest</option></select></div>
}