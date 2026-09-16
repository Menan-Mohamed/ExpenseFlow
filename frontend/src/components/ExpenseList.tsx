import type { Expense } from '../services/expenses'

interface ExpenseListProps {
  expenses: Expense[]
  onEdit: (expense: Expense) => void
  onDelete: (expense: Expense) => Promise<void>
  onSubmit: (expense: Expense) => Promise<void>
  onReopen?: (expense: Expense) => Promise<void>
  onDetails: (expense: Expense) => void
  pagination: { page: number; total_pages: number; total_count: number }
  onPageChange: (page: number) => void
}

export function ExpenseList({ expenses, onEdit, onDelete, onSubmit, onReopen, onDetails, pagination, onPageChange }: ExpenseListProps) {
  return (
    <section className="expense-list">
      <div className="section-heading"><div><p className="eyebrow">Your records</p><h2>Expenses</h2></div><span className="expense-count">{pagination.total_count} total</span></div>
      {expenses.length === 0 ? <p className="empty-state">No expenses yet. Add your first purchase to get started.</p> : <div className="expense-items">{expenses.map((expense) => <article className="expense-item" key={expense.id}>
        <div className="expense-summary"><h3>{expense.title}</h3><p>{expense.category_name} · {expense.spent_date}</p>{expense.description && <p className="expense-description">{expense.description}</p>}{expense.state === 'reimbursed' && expense.payment_reference && <p className="payment-reference"><strong>Payment reference:</strong> {expense.payment_reference}</p>}</div>
        <div className="expense-meta"><strong>{Number(expense.amount).toFixed(2)}</strong><span className={`state state-${expense.state}`}>{expense.state}</span>{expense.approval_stage !== 'not_applicable' && <span className="approval-stage">{expense.approval_stage === 'awaiting_manager' ? 'Awaiting manager approval' : 'Awaiting admin approval'}</span>}<div className="expense-actions"><button className="text-button" type="button" onClick={() => onDetails(expense)}>Details</button>{expense.state === 'draft' && <><button className="text-button" type="button" onClick={() => onEdit(expense)}>Edit</button><button className="text-button" type="button" onClick={() => onSubmit(expense)}>Submit</button><button className="danger-button" type="button" onClick={() => onDelete(expense)}>Delete</button></>}{expense.state === 'rejected' && onReopen && <button className="text-button" type="button" onClick={() => onReopen(expense)}>Reopen</button>}</div></div>
      </article>)}</div>}
      {pagination.total_pages > 1 && <div className="pagination"><button className="text-button" type="button" disabled={pagination.page === 1} onClick={() => onPageChange(pagination.page - 1)}>Previous</button><span>Page {pagination.page} of {pagination.total_pages}</span><button className="text-button" type="button" disabled={pagination.page === pagination.total_pages} onClick={() => onPageChange(pagination.page + 1)}>Next</button></div>}
    </section>
  )
}
