import { useState, type FormEvent } from 'react'
import { downloadAdminReportCsv, getAdminReport, type Report } from '../services/admin'

function formatAmount(amount: string) {
  return Number(amount).toFixed(2)
}

export function AdminReport() {
  const [report, setReport] = useState<Report | null>(null)
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [isExporting, setIsExporting] = useState(false)

  function params() {
    return { from, to }
  }

  async function generate(event: FormEvent) {
    event.preventDefault()
    setError('')
    setIsLoading(true)
    try {
      setReport(await getAdminReport(params()))
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to create report.')
    } finally {
      setIsLoading(false)
    }
  }

  async function exportCsv() {
    setError('')
    setIsExporting(true)
    try {
      const blob = await downloadAdminReportCsv(params())
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `expense-report-${from}-to-${to}.csv`
      link.click()
      URL.revokeObjectURL(url)
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to export report.')
    } finally {
      setIsExporting(false)
    }
  }

  return <div>
    <div className="panel-title"><div><p className="eyebrow">Insights</p><h2>Monthly expense report</h2></div>{report && <button className="primary-button" type="button" disabled={isExporting} onClick={exportCsv}>{isExporting ? 'Exporting...' : 'Export CSV'}</button>}</div>
    <form className="report-filters" onSubmit={generate}>
      <label className="field"><span>From</span><input type="date" value={from} required onChange={(event) => setFrom(event.target.value)} /></label>
      <label className="field"><span>To</span><input type="date" value={to} required onChange={(event) => setTo(event.target.value)} /></label>
      <button className="primary-button" type="submit" disabled={isLoading}>{isLoading ? 'Generating...' : 'Generate'}</button>
    </form>
    {error && <p className="error-message">{error}</p>}
    {report && <>
      <div className="report-grid"><div className="report-stat"><span>Approved and reimbursed expenses</span><strong>{report.summary.total_expenses}</strong></div><div className="report-stat"><span>Total amount</span><strong>${formatAmount(report.summary.total_amount)}</strong></div></div>
      <div className="report-table-wrap"><table className="report-table"><thead><tr><th>Month</th><th>Category</th><th>Approved count</th><th>Approved amount</th><th>Reimbursed count</th><th>Reimbursed amount</th></tr></thead><tbody>{report.rows.length === 0 ? <tr><td colSpan={6}>No approved or reimbursed expenses in this date range.</td></tr> : report.rows.map((row) => <tr key={`${row.month}-${row.category}`}><td>{row.month}</td><td>{row.category}</td><td>{row.approved_count}</td><td>${formatAmount(row.approved_amount)}</td><td>{row.reimbursed_count}</td><td>${formatAmount(row.reimbursed_amount)}</td></tr>)}</tbody></table></div>
    </>}
  </div>
}
