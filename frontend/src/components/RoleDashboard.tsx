import type { UserRole } from '../services/auth'

interface RoleDashboardProps {
  role: UserRole
  title: string
  description: string
  onLogout: () => void
}

export function RoleDashboard({ role, title, description, onLogout }: RoleDashboardProps) {
  return (
    <main className="dashboard">
      <nav className="dashboard-nav" aria-label="Main navigation">
        <div className="brand"><span className="brand-mark">+</span>expenseflow</div>
        <button className="logout-button" type="button" onClick={onLogout}>Sign out</button>
      </nav>
      <section className="dashboard-content">
        <p className="eyebrow">{role} workspace</p>
        <h1>{title}</h1>
        <p>{description}</p>
        <span className="role-badge">{role} access</span>
      </section>
    </main>
  )
}