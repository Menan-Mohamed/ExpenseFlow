import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { AdminPagination, AdminTable } from './AdminTable'
import { ExpenseFilters, type ExpenseFilterValues } from './ExpenseFilters'
import { getCategories, type Category } from '../services/expenses'
import { approveAdminExpense, getAdminExpense, getAdminExpenses, rejectAdminExpense, reimburseExpense, type AdminExpense } from '../services/admin'

export function AdminExpenses() {
  const { user } = useAuth()
  const [expenses, setExpenses] = useState<AdminExpense[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [pagination, setPagination] = useState({ page: 1, total_pages: 1 })
  const [search, setSearch] = useState('')
  const [details, setDetails] = useState<AdminExpense | null>(null)
  const [error, setError] = useState('')
  const [filters, setFilters] = useState<ExpenseFilterValues>({ status: '', category: '', from_date: '', to_date: '', sort: 'date', direction: 'desc' })

  function load(page = 1) {
    getAdminExpenses({ page, per_page: 5, status: filters.status, category: filters.category, from_date: filters.from_date, to_date: filters.to_date, sort: filters.sort, direction: filters.direction, search }).then((result) => {
      setExpenses(result.expenses)
      setPagination(result.pagination)
    }).catch((reason: Error) => setError(reason.message))
  }

  useEffect(() => {
    getCategories().then(setCategories).catch((reason: Error) => setError(reason.message))
    load()
  }, [filters, search]) // eslint-disable-line react-hooks/exhaustive-deps

  function canReview(expense: AdminExpense) {
    if (user?.id === expense.user_id || expense.state !== 'submitted') return false
    if (expense.user_role === 'employee') return expense.approval_stage === 'awaiting_admin'
    return expense.approval_stage === 'not_applicable'
  }

  async function reimburse(expense: AdminExpense) {
    const reference = window.prompt('Payment reference')
    if (!reference) return
    try {
      await reimburseExpense(expense.id, reference)
      load(pagination.page)
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to reimburse expense.')
    }
  }

  async function review(expense: AdminExpense, action: 'approve' | 'reject') {
    const comment = window.prompt(action === 'reject' ? 'Reason for rejection (required)' : 'Comment (optional)', '')
    if (action === 'reject' && !comment) return
    try {
      if (action === 'approve') await approveAdminExpense(expense.id, comment ?? '')
      else await rejectAdminExpense(expense.id, comment ?? '')
      load(pagination.page)
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to review expense.')
    }
  }
  
  const states = ['draft', 'submitted', 'approved', 'rejected', 'reimbursed']

  function stateName(state: number | null) {
    return state === null ? 'Unknown' : states[state] ?? 'Unknown'
}

  return <div>
    <div className="panel-title"><div><p className="eyebrow">All non-draft expenses</p><h2>Expenses</h2></div></div>
    {error && <p className="error-message">{error}</p>}
    <div className="toolbar"><input placeholder="Search title or owner" value={search} onChange={(event) => setSearch(event.target.value)} /></div>
    <ExpenseFilters categories={categories} value={filters} onChange={setFilters} />
    <AdminTable headers={['Expense', 'Owner', 'Amount', 'State', 'Actions']}>
      {expenses.map((expense) => <tr key={expense.id}>
        <td>{expense.title}<small>{expense.category_name}</small></td>
        <td>{expense.user_email}<small className="capitalize">{expense.user_role}</small></td>
        <td>${expense.amount}</td>
        <td><span className={`state state-${expense.state}`}>{expense.state}</span>{expense.approval_stage !== 'not_applicable' && <small>{expense.approval_stage === 'awaiting_manager' ? 'Awaiting manager approval' : 'Awaiting admin approval'}</small>}</td>
        <td><button className="table-button" onClick={() => getAdminExpense(expense.id).then(setDetails).catch((reason: Error) => setError(reason.message))}>Details</button>{canReview(expense) && <><button className="table-button" onClick={() => review(expense, 'approve')}>Approve</button><button className="table-button danger-button" onClick={() => review(expense, 'reject')}>Reject</button></>}{expense.state === 'approved' && <button className="table-button" onClick={() => reimburse(expense)}>Reimburse</button>}</td>
      </tr>)}
    </AdminTable>
    <AdminPagination page={pagination.page} totalPages={pagination.total_pages} onChange={load} />
    {details && <div className="detail-drawer"><div className="panel-title"><h3>{details.title}</h3><button className="text-button" onClick={() => setDetails(null)}>Close</button></div><p>{details.description || 'No description.'}</p><p className="muted">{details.user_email} · {details.spent_date} · ${details.amount} · {details.state}</p>{details.payment_reference && <p className="payment-reference"><strong>Payment reference:</strong> {details.payment_reference}</p>}<h4>History</h4>{details.history.map((entry) => <div className="history-row" key={entry.id}><strong>{stateName(entry.prev_state)}</strong> to <strong>{stateName(entry.next_state)}</strong> · {entry.changed_by ?? 'System'}</div>)}</div>}
  </div>
}
