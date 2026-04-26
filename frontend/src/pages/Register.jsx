import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import api from '../api/axios'
import { useAuth } from '../context/AuthContext'

export default function Register() {
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      const res = await api.post('/api/auth/register', { username, email, password })
      login(res.data.token)
      navigate('/tasks')
    } catch (err) {
      setError(err.response?.data || 'Ошибка регистрации')
    }
  }

  return (
    <div style={{ maxWidth: 400, margin: '40px auto' }}>
      <h2>Регистрация</h2>
      {error && <div style={{ color: 'red', marginBottom: 12 }}>{error}</div>}
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: 12 }}>
          <input placeholder="Имя пользователя" value={username}
            onChange={e => setUsername(e.target.value)} required minLength={3}
            style={{ width: '100%', padding: 8, boxSizing: 'border-box' }} />
        </div>
        <div style={{ marginBottom: 12 }}>
          <input placeholder="Email" type="email" value={email}
            onChange={e => setEmail(e.target.value)} required
            style={{ width: '100%', padding: 8, boxSizing: 'border-box' }} />
        </div>
        <div style={{ marginBottom: 12 }}>
          <input placeholder="Пароль" type="password" value={password}
            onChange={e => setPassword(e.target.value)} required minLength={6}
            style={{ width: '100%', padding: 8, boxSizing: 'border-box' }} />
        </div>
        <button type="submit"
          style={{ width: '100%', padding: 10, background: '#1976d2', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
          Зарегистрироваться
        </button>
      </form>
      <p style={{ marginTop: 12 }}>
        Уже есть аккаунт? <Link to="/login">Войти</Link>
      </p>
    </div>
  )
}
