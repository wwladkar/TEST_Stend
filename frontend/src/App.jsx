import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login from './pages/Login'
import Register from './pages/Register'
import Tasks from './pages/Tasks'
import Admin from './pages/Admin'
import Navbar from './components/Navbar'

function ProtectedRoute({ children, adminOnly = false }) {
  const { user, token } = useAuth()
  if (!token) return <Navigate to="/login" />
  if (adminOnly && user?.role !== 'ADMIN') return <Navigate to="/tasks" />
  return children
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
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
