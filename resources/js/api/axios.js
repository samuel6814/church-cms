import axios from 'axios'

/** Local Herd: unset → `/api`. Vercel: set `VITE_API_URL` to Render API (e.g. https://church-cms-api.onrender.com/api). */
const apiBase = (import.meta.env.VITE_API_URL || '/api').replace(/\/$/, '')

const api = axios.create({
  baseURL: apiBase,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('wis_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('wis_token')
      localStorage.removeItem('wis_user')
      window.location.href = '/login'
    }
    if (error.response?.status === 423 && window.location.pathname !== '/change-password') {
      window.location.href = '/change-password'
    }
    return Promise.reject(error)
  }
)

export default api
