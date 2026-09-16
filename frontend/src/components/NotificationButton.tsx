import { useState } from 'react'
import { getUnreadNotifications, type Notification } from '../services/notifications'

export function NotificationButton() {
  const [notifications, setNotifications] = useState<Notification[] | null>(null)
  const [error, setError] = useState('')

  async function showNotifications() {
    setError('')
    try {
      setNotifications(await getUnreadNotifications())
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Unable to load notifications.')
    }
  }

  return <>
    <button className="profile-button notification-button" type="button" aria-label="Open notifications" title="Notifications" onClick={showNotifications}>Alerts</button>
    {notifications && <div className="profile-overlay" role="presentation" onClick={() => setNotifications(null)}><section className="profile-dialog" role="dialog" aria-modal="true" aria-labelledby="notifications-title" onClick={(event) => event.stopPropagation()}><div className="panel-title"><h2 id="notifications-title">Notifications</h2><button className="text-button" type="button" onClick={() => setNotifications(null)}>Close</button></div>{error && <p className="error-message" role="alert">{error}</p>}{notifications.length === 0 ? <p className="empty-state">No unread notifications.</p> : <div className="notification-list">{notifications.map((notification) => <article className="notification-item" key={notification.id}><p>{notification.content}</p><time dateTime={notification.created_at}>{new Date(notification.created_at).toLocaleString()}</time></article>)}</div>}</section></div>}
  </>
}