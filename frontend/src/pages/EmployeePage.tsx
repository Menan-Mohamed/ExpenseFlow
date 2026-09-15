import { RoleDashboard } from '../components/RoleDashboard'

export function EmployeePage({ onLogout }: { onLogout: () => void }) {
  return <RoleDashboard role="employee" title="Your spending, simplified." description="Submit expenses, follow their progress, and stay close to your budget." onLogout={onLogout} />
}