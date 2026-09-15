import { useState } from 'react'
import { AdminCategories } from '../components/AdminCategories'
import { AdminExpenses } from '../components/AdminExpenses'
import { AdminReport } from '../components/AdminReport'
import { AdminTeams } from '../components/AdminTeams'
import { AdminUsers } from '../components/AdminUsers'
import { ProfileButton } from '../components/ProfileButton'

export function AdminPage({ onLogout }: { onLogout: () => void }) {
  const [section, setSection] = useState('users')
  const sections = [['users', 'Manage users'], ['expenses', 'Manage expenses'], ['categories', 'Manage categories'], ['teams', 'Manage teams'], ['report', 'Create report']]
  return <main className="admin-shell"><header className="dashboard-nav"><div className="brand"><span className="brand-mark">+</span>ExpenseFlow <span className="admin-label">Admin</span></div><div className="header-actions"><ProfileButton /><button className="logout-button" onClick={onLogout}>Log out</button></div></header><div className="admin-heading"><p className="eyebrow">Control center</p></div><nav className="admin-tabs" aria-label="Admin sections">{sections.map(([id, label]) => <button key={id} className={section === id ? 'admin-tab active' : 'admin-tab'} onClick={() => setSection(id)}>{label}</button>)}</nav><section className="admin-panel">{section === 'users' && <AdminUsers />}{section === 'expenses' && <AdminExpenses />}{section === 'categories' && <AdminCategories />}{section === 'teams' && <AdminTeams />}{section === 'report' && <AdminReport />}</section></main>
}