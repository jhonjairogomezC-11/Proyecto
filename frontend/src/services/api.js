import axios from 'axios'
import { updateEchoToken } from '@/services/echo'

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
})

// Leer token con la misma prioridad que el auth store:
// sessionStorage (pestaña aislada) > localStorage (respaldo)
function getToken() {
  return sessionStorage.getItem('auth_token') || localStorage.getItem('auth_token')
}

const initialToken = getToken()
if (initialToken) {
  api.defaults.headers.common['Authorization'] = `Bearer ${initialToken}`
}

// ── Inyectar JWT en cada request ──────────────────────────────
api.interceptors.request.use(config => {
  const token = getToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// ── Refresh automático cuando el token expira (401) ───────────
let isRefreshing = false
let pendingRequests = []

function procesarPendientes(error, nuevoToken) {
  pendingRequests.forEach(({ resolve, reject, original }) => {
    if (error || !nuevoToken) {
      reject(error || new Error('No auth token available after refresh'))
      return
    }
    original.headers.Authorization = `Bearer ${nuevoToken}`
    resolve(api(original))
  })
  pendingRequests = []
}

api.interceptors.response.use(
  response => response,
  async error => {
    const original = error.config

    // Solo intentar refresh en 401 y una sola vez por request
    if (error.response?.status !== 401 || original._retry) {
      return Promise.reject(error)
    }

    const refreshToken = sessionStorage.getItem('refresh_token') || localStorage.getItem('refresh_token')

    // Sin refresh token → ir al login directamente
    if (!refreshToken) {
      procesarPendientes(error, null)
      limpiarSesion()
      return Promise.reject(error)
    }

    // Si ya hay un refresh en curso, encolar este request para reintentarlo
    if (isRefreshing) {
      return new Promise((resolve, reject) => {
        pendingRequests.push({ resolve, reject, original })
      })
    }

    original._retry  = true
    isRefreshing     = true

    try {
      const { data } = await axios.post('/api/v1/auth/refresh', {
        refresh_token: refreshToken,
      })

      // Guardar los nuevos tokens (sessionStorage: esta pestaña, localStorage: respaldo)
      sessionStorage.setItem('auth_token',    data.token)
      sessionStorage.setItem('refresh_token', data.refresh_token)
      localStorage.setItem('auth_token',    data.token)
      localStorage.setItem('refresh_token', data.refresh_token)
      api.defaults.headers.common['Authorization'] = `Bearer ${data.token}`
      await syncAuthStore(false, data.token, data.refresh_token)
      updateEchoToken(data.token)

      // Resolver requests que estaban esperando
      procesarPendientes(null, data.token)

      // Reintentar el request original
      original.headers.Authorization = `Bearer ${data.token}`
      return api(original)

    } catch (refreshError) {
      // Refresh falló → sesión expirada, redirigir al login
      procesarPendientes(refreshError, null)
      limpiarSesion()
      return Promise.reject(refreshError)

    } finally {
      isRefreshing = false
    }
  }
)

async function syncAuthStore(clear = false, token = null, refreshToken = null) {
  try {
    const { useAuthStore } = await import('@/stores/auth')
    const auth = useAuthStore()

    if (clear) {
      auth.clearSession()
      return
    }

    if (token) auth.token = token
    if (refreshToken) auth.refreshToken = refreshToken
  } catch (err) {
    console.warn('[API] No se pudo sincronizar el auth store:', err)
  }
}

async function limpiarSesion() {
  sessionStorage.removeItem('auth_token')
  sessionStorage.removeItem('refresh_token')
  sessionStorage.removeItem('auth_user')
  localStorage.removeItem('auth_token')
  localStorage.removeItem('refresh_token')
  localStorage.removeItem('auth_user')
  delete api.defaults.headers.common['Authorization']
  updateEchoToken(null)
  await syncAuthStore(true)
  // Redirigir solo si no estamos ya en login
  if (!window.location.pathname.startsWith('/auth')) {
    window.location.href = '/auth/login'
  }
}

export default api
