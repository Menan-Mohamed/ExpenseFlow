import { useEffect, useState } from 'react'
import { getExpense, type Expense, type ExpenseDetails as ExpenseDetailsData } from '../services/expenses'

interface ExpenseDetailsProps {
  expense: Expense
  onClose: () => void
}

const states = ['draft', 'submitted', 'approved', 'rejected', 'reimbursed']

function stateName(state: number | null) {
  return state === null ? 'Unknown' : states[state] ?? 'Unknown'
}

export function ExpenseDetails({ expense, onClose }: ExpenseDetailsProps) {
  const [details, setDetails] = useState<ExpenseDetailsData | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    getExpense(expense.id)
      .then(setDetails)
      .catch((loadError) => setError(loadError instanceof Error ? loadError.message : 'Unable to load expense history.'))
  }, [expense.id])

  return (
    <aside className="expense-details" aria-label="Expense details">
      <div className="details-heading"><div><p className="eyebrow">Expense details</p><h2>{expense.title}</h2></div><button className="text-button" type="button" onClick={onClose}>Close</button></div>
      <p className="details-summary">{expense.category_name} · {Number(expense.amount).toFixed(2)} · {expense.state}</p>
      {error && <p className="error-message" role="alert">{error}</p>}
      {!error && !details && <p className="empty-state">Loading history...</p>}
      {details && <div className="history-list"><h3>History</h3>{details.history.length === 0 ? <p className="empty-state">No status history yet.</p> : details.history.map((entry) => <div className="history-item" key={entry.id}><strong>{stateName(entry.prev_state)} to {stateName(entry.next_state)}</strong><span>{entry.comment ?? 'Status changed'} · {entry.changed_by ?? 'System'}</span><time dateTime={entry.created_at}>{new Date(entry.created_at).toLocaleString()}</time></div>)}</div>}
    </aside>
  )
}
