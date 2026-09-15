import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import type { ReactNode } from 'react'
import { AuthProvider, useAuth } from './context/AuthContext'
import { AdminPage } from './pages/AdminPage'
import { EmployeePage } from './pages/EmployeePage'
import { LoginPage } from './pages/LoginPage'
import { ManagerPage } from './pages/ManagerPage'
import type { UserRole } from './services/auth'
import './App.css'

function destinationForUser(user: { id: number; role: UserRole }) {
  if (user.role === 'admin') return '/admin'
  if (user.role === 'manager') return '/manager'
  return `/home`
}

function RequireRole({ role, children }: { role: UserRole; children: ReactNode }) {
  const { user } = useAuth()

  if (!user) return <Navigate to="/" replace />
  if (user.role !== role) return <Navigate to={destinationForUser(user)} replace />

  return children
}

function LoginRoute() {
  const { user } = useAuth()

  if (user) return <Navigate to={destinationForUser(user)} replace />

  return <LoginPage />
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  )
}

function AppRoutes() {
  const { user, logout } = useAuth()
  const fallback = user ? destinationForUser(user) : '/'

  return (
    <Routes>
      <Route path="/" element={<LoginRoute />} />
      <Route path="/home" element={<RequireRole role="employee"><EmployeePage onLogout={logout} /></RequireRole>} />
      <Route path="/manager" element={<RequireRole role="manager"><ManagerPage onLogout={logout} /></RequireRole>} />
      <Route path="/admin" element={<RequireRole role="admin"><AdminPage onLogout={logout} /></RequireRole>} />
      <Route path="*" element={<Navigate to={fallback} replace />} />
    </Routes>
  )
}

export default App
