import { useState } from 'react'
import { getMe, type User } from '../services/auth'

export function ProfileButton() {
  const [profile, setProfile] = useState<User | null>(null)
  const [isOpen, setIsOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  async function showProfile() {
    setIsOpen(true)
    setIsLoading(true)
    setError('')
    try {
      setProfile(await getMe())
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to load your profile.')
    } finally {
      setIsLoading(false)
    }
  }

  return <>
    <button className="profile-button" type="button" aria-label="Open profile" title="Profile" onClick={showProfile}>Profile</button>
    {isOpen && <div className="profile-overlay" role="presentation" onClick={() => setIsOpen(false)}><section className="profile-dialog" role="dialog" aria-modal="true" aria-labelledby="profile-title" onClick={(event) => event.stopPropagation()}><div className="panel-title"><h2 id="profile-title">Profile</h2><button className="text-button" type="button" onClick={() => setIsOpen(false)}>Close</button></div>{isLoading && <p className="empty-state">Loading profile...</p>}{error && <p className="error-message" role="alert">{error}</p>}{profile && <dl className="profile-details"><div><dt>Email</dt><dd>{profile.email}</dd></div><div><dt>Role</dt><dd className="capitalize">{profile.role}</dd></div><div><dt>Team</dt><dd>{profile.team_name ?? 'No team assigned'}</dd></div><div><dt>User ID</dt><dd>{profile.id}</dd></div></dl>}</section></div>}
  </>
}