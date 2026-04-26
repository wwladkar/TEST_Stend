import { useState, useEffect } from 'react'
import api from '../api/axios'

export default function Admin() {
  const [users, setUsers] = useState([])
  const [error, setError] = useState('')

  const fetchUsers = async () => {
    try {
      const res = await api.get('/api/admin/users')
      setUsers(res.data)
    } catch {
      setError('Не удалось загрузить пользователей')
    }
  }

  useEffect(() => { fetchUsers() }, [])

  const changeRole = async (id, role) => {
    try {
      await api.put(`/api/admin/users/${id}/role`, role, {
        headers: { 'Content-Type': 'application/json' }
      })
      fetchUsers()
    } catch {}
  }

  const toggleEnabled = async (id, enabled) => {
    try {
      await api.put(`/api/admin/users/${id}/enabled`, enabled, {
        headers: { 'Content-Type': 'application/json' }
      })
      fetchUsers()
    } catch {}
  }

  return (
    <div>
      <h2>Админка — Пользователи</h2>
      {error && <div style={{ color: 'red', marginBottom: 12 }}>{error}</div>}

      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ background: '#f5f5f5' }}>
            <th style={thStyle}>ID</th>
            <th style={thStyle}>Имя</th>
            <th style={thStyle}>Email</th>
            <th style={thStyle}>Роль</th>
            <th style={thStyle}>Активен</th>
            <th style={thStyle}>Действия</th>
          </tr>
        </thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id} style={{ borderBottom: '1px solid #eee' }}>
              <td style={tdStyle}>{u.id}</td>
              <td style={tdStyle}>{u.username}</td>
              <td style={tdStyle}>{u.email}</td>
              <td style={tdStyle}>
                <select value={u.role}
                  onChange={e => changeRole(u.id, e.target.value)}
                  style={{ padding: 4 }}>
                  <option value="USER">USER</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </td>
              <td style={tdStyle}>{u.enabled ? 'Да' : 'Нет'}</td>
              <td style={tdStyle}>
                <button onClick={() => toggleEnabled(u.id, !u.enabled)}
                  style={{
                    background: u.enabled ? '#d32f2f' : '#388e3c',
                    color: '#fff', border: 'none', padding: '4px 8px',
                    borderRadius: 4, cursor: 'pointer'
                  }}>
                  {u.enabled ? 'Заблокировать' : 'Разблокировать'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

const thStyle = { padding: '8px 12px', textAlign: 'left', borderBottom: '2px solid #ccc' }
const tdStyle = { padding: '8px 12px' }
