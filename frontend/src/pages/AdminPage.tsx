import { RoleDashboard } from '../components/RoleDashboard'

export function AdminPage({ onLogout }: { onLogout: () => void }) {
  return <RoleDashboard role="admin" title="The whole picture, in one place." description="Manage teams, users, and the systems that keep ExpenseFlow moving." onLogout={onLogout} />
}