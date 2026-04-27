import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login from './pages/Login'
import Register from './pages/Register'
import Tasks from './pages/Tasks'
import Admin from './pages/Admin'
import Navbar from './components/Navbar'
import { useEffect } from 'react'

function UnauthorizedHandler() {
  const navigate = useNavigate()
  useEffect(() => {
    const handler = () => navigate('/login', { replace: true })
    window.addEventListener('unauthorized', handler)
    return () => window.removeEventListener('unauthorized', handler)
  }, [navigate])
  return null
}

function ProtectedRoute({ children, adminOnly = false }) {
  const { user, token, loading } = useAuth()
  if (loading) return <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>Загрузка...</div>
  if (!token) return <Navigate to="/login" />
  if (adminOnly && user?.role !== 'ADMIN') return <Navigate to="/tasks" />
  return children
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <UnauthorizedHandler />
        <Navbar />
        <div style={{ maxWidth: 900, margin: '20px auto', padding: '0 16px' }}>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/tasks" element={
              <ProtectedRoute><Tasks /></ProtectedRoute>
            } />
            <Route path="/admin" element={
              <ProtectedRoute adminOnly><Admin /></ProtectedRoute>
            } />
            <Route path="*" element={<Navigate to="/tasks" />} />
          </Routes>
        </div>
      </AuthProvider>
    </BrowserRouter>
  )
}
