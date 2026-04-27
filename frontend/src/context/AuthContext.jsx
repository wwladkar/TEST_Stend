import { createContext, useContext, useState, useEffect } from 'react'
import api from '../api/axios'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('token'))
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (token) {
      setLoading(true)
      api.get('/api/users/me')
        .then(res => {
          setUser(res.data)
          setLoading(false)
        })
        .catch(() => {
          setToken(null)
          localStorage.removeItem('token')
          setLoading(false)
        })
    } else {
      setUser(null)
      setLoading(false)
    }
  }, [token])

  // Listen for unauthorized events from axios interceptor
  useEffect(() => {
    const handleUnauthorized = () => {
      setToken(null)
      setUser(null)
    }
    window.addEventListener('unauthorized', handleUnauthorized)
    return () => window.removeEventListener('unauthorized', handleUnauthorized)
  }, [])

  const login = (newToken) => {
    localStorage.setItem('token', newToken)
    setToken(newToken)
  }

  const logout = () => {
    localStorage.removeItem('token')
    setToken(null)
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ token, user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
