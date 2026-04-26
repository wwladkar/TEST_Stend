import { useState, useEffect } from 'react'
import api from '../api/axios'

const STATUSES = ['NEW', 'IN_PROGRESS', 'DONE']
const PRIORITIES = ['LOW', 'MEDIUM', 'HIGH']

export default function Tasks() {
  const [tasks, setTasks] = useState([])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState('MEDIUM')
  const [error, setError] = useState('')

  const fetchTasks = async () => {
    try {
      const res = await api.get('/api/tasks')
      setTasks(res.data.content || res.data)
    } catch {
      setError('Не удалось загрузить задачи')
    }
  }

  useEffect(() => { fetchTasks() }, [])

  const createTask = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await api.post('/api/tasks', { title, description, priority })
      setTitle(''); setDescription(''); setPriority('MEDIUM')
      fetchTasks()
    } catch (err) {
      setError(err.response?.data || 'Ошибка создания')
    }
  }

  const deleteTask = async (id) => {
    try {
      await api.delete(`/api/tasks/${id}`)
      fetchTasks()
    } catch {}
  }

  const changeStatus = async (id, status) => {
    try {
      await api.put(`/api/tasks/${id}`, { status })
      fetchTasks()
    } catch {}
  }

  return (
    <div>
      <h2>Мои задачи</h2>
      {error && <div style={{ color: 'red', marginBottom: 12 }}>{error}</div>}

      <form onSubmit={createTask} style={{
        display: 'flex', gap: 8, marginBottom: 20, alignItems: 'flex-end', flexWrap: 'wrap'
      }}>
        <div>
          <label>Название</label><br />
          <input value={title} onChange={e => setTitle(e.target.value)} required
            style={{ padding: 6, width: 220 }} />
        </div>
        <div>
          <label>Описание</label><br />
          <input value={description} onChange={e => setDescription(e.target.value)}
            style={{ padding: 6, width: 220 }} />
        </div>
        <div>
          <label>Приоритет</label><br />
          <select value={priority} onChange={e => setPriority(e.target.value)} style={{ padding: 6 }}>
            {PRIORITIES.map(p => <option key={p} value={p}>{p}</option>)}
          </select>
        </div>
        <button type="submit"
          style={{ padding: '8px 16px', background: '#1976d2', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>
          Создать
        </button>
      </form>

      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ background: '#f5f5f5' }}>
            <th style={thStyle}>ID</th>
            <th style={thStyle}>Название</th>
            <th style={thStyle}>Описание</th>
            <th style={thStyle}>Статус</th>
            <th style={thStyle}>Приоритет</th>
            <th style={thStyle}>Действия</th>
          </tr>
        </thead>
        <tbody>
          {tasks.map(t => (
            <tr key={t.id} style={{ borderBottom: '1px solid #eee' }}>
              <td style={tdStyle}>{t.id}</td>
              <td style={tdStyle}>{t.title}</td>
              <td style={tdStyle}>{t.description}</td>
              <td style={tdStyle}>
                <select value={t.status} onChange={e => changeStatus(t.id, e.target.value)}
                  style={{ padding: 4 }}>
                  {STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </td>
              <td style={tdStyle}>{t.priority}</td>
              <td style={tdStyle}>
                <button onClick={() => deleteTask(t.id)}
                  style={{ background: '#d32f2f', color: '#fff', border: 'none', padding: '4px 8px', borderRadius: 4, cursor: 'pointer' }}>
                  Удалить
                </button>
              </td>
            </tr>
          ))}
          {tasks.length === 0 && (
            <tr><td colSpan={6} style={{ textAlign: 'center', padding: 20, color: '#888' }}>
              Нет задач
            </td></tr>
          )}
        </tbody>
      </table>
    </div>
  )
}

const thStyle = { padding: '8px 12px', textAlign: 'left', borderBottom: '2px solid #ccc' }
const tdStyle = { padding: '8px 12px' }
