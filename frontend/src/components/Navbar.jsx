import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useState } from 'react'
import api from '../api/axios'

export default function Navbar() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  if (!user) return null

  return (
    <nav style={{
      display: 'flex', alignItems: 'center', gap: 16,
      padding: '12px 24px', background: '#1976d2', color: '#fff'
    }}>
      <Link to="/tasks" style={{ color: '#fff', fontWeight: 'bold', textDecoration: 'none' }}>
        Test Stend
      </Link>
      <Link to="/tasks" style={{ color: '#fff', textDecoration: 'none' }}>Задачи</Link>
      {user.role === 'ADMIN' && (
        <Link to="/admin" style={{ color: '#fff', textDecoration: 'none' }}>Админка</Link>
      )}
      <div style={{ flex: 1 }} />
      <span>{user.username} ({user.role})</span>
      <button onClick={handleLogout}
        style={{ background: 'transparent', border: '1px solid #fff', color: '#fff', cursor: 'pointer', padding: '4px 12px', borderRadius: 4 }}>
        Выйти
      </button>
    </nav>
  )
}
