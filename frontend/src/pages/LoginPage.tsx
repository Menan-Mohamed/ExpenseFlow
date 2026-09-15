import { useState, type FormEvent } from 'react'
import { useAuth } from '../context/AuthContext'

export function LoginPage() {
  const { login, isLoading, error } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    await login(email, password).catch(() => undefined)
  }

  return (
    <main className="login-shell">
      <aside className="login-aside">
        <div className="brand"><span className="brand-mark">+</span>expenseflow</div>
        <div className="aside-copy">
          <h1>Make every expense count.</h1>
          <p>A calmer way to manage spending, approvals, and the people behind them.</p>
        </div>
      </aside>
      <section className="login-main">
        <div className="login-card">
          <p className="eyebrow">Welcome back</p>
          <h2>Sign in to continue</h2>
          <p className="intro">Use your ExpenseFlow account to access your workspace.</p>
          <form onSubmit={handleSubmit}>
            <label className="field">
              <span>Email address</span>
              <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="you@company.com" autoComplete="email" required />
            </label>
            <label className="field">
              <span>Password</span>
              <input type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter your password" autoComplete="current-password" required />
            </label>
            {error && <p className="error-message" role="alert">{error}</p>}
            <button className="submit-button" type="submit" disabled={isLoading}>
              {isLoading ? 'Signing in...' : 'Sign in'}
            </button>
          </form>
        </div>
      </section>
    </main>
  )
}