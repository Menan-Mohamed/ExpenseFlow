import type { ReactNode } from 'react'

export function AdminTable({ headers, children }: { headers: string[]; children: ReactNode }) {
  return <div className="admin-table-wrap"><table className="admin-table"><thead><tr>{headers.map((header) => <th key={header}>{header}</th>)}</tr></thead><tbody>{children}</tbody></table></div>
}

export function AdminPagination({ page, totalPages, onChange }: { page: number; totalPages: number; onChange: (page: number) => void }) {
  return <div className="pagination"><span>Page {page} of {Math.max(totalPages, 1)}</span><span><button className="table-button" disabled={page <= 1} onClick={() => onChange(page - 1)}>Previous</button><button className="table-button" disabled={page >= totalPages} onClick={() => onChange(page + 1)}>Next</button></span></div>
}