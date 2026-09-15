import { AuthProvider, useAuth } from './context/AuthContext'
import { AdminPage } from './pages/AdminPage'
import { EmployeePage } from './pages/EmployeePage'
import { LoginPage } from './pages/LoginPage'
import { ManagerPage } from './pages/ManagerPage'
import './App.css'

function AuthenticatedApp() {
  const { user, logout } = useAuth()

  if (!user) return <LoginPage />
  if (user.role === 'admin') return <AdminPage onLogout={logout} />
  if (user.role === 'manager') return <ManagerPage onLogout={logout} />
  return <EmployeePage onLogout={logout} />
}

function App() {
  return (
    <AuthProvider>
      <AuthenticatedApp />
    </AuthProvider>
  )
}

export default App
