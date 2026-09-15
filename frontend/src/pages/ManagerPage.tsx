import { RoleDashboard } from '../components/RoleDashboard'

export function ManagerPage({ onLogout }: { onLogout: () => void }) {
  return <RoleDashboard role="manager" title="Keep your team moving." description="Review requests, track team spending, and make confident approvals." onLogout={onLogout} />
}