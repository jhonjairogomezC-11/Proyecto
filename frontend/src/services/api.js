import axios from 'axios'

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
})

// ── Inyectar JWT en cada request ──────────────────────────────
api.interceptors.request.use(config => {
  const token = localStorage.getItem('auth_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// ── Refresh automático cuando el token expira (401) ───────────
let isRefreshing = false
let pendingRequests = []

function procesarPendientes(nuevoToken) {
  pendingRequests.forEach(cb => cb(nuevoToken))
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

    const refreshToken = localStorage.getItem('refresh_token')

    // Sin refresh token → ir al login directamente
    if (!refreshToken) {
      limpiarSesion()
      return Promise.reject(error)
    }

    // Si ya hay un refresh en curso, encolar este request para reintentarlo
    if (isRefreshing) {
      return new Promise((resolve, reject) => {
        pendingRequests.push(nuevoToken => {
          original.headers.Authorization = `Bearer ${nuevoToken}`
          resolve(api(original))
        })
      })
    }

    original._retry  = true
    isRefreshing     = true

    try {
      const { data } = await axios.post('/api/v1/auth/refresh', {
        refresh_token: refreshToken,
      })

      // Guardar los nuevos tokens
      localStorage.setItem('auth_token',    data.token)
      localStorage.setItem('refresh_token', data.refresh_token)
      api.defaults.headers.common['Authorization'] = `Bearer ${data.token}`

      // Resolver requests que estaban esperando
      procesarPendientes(data.token)

      // Reintentar el request original
      original.headers.Authorization = `Bearer ${data.token}`
      return api(original)

    } catch (refreshError) {
      // Refresh falló → sesión expirada, redirigir al login
      procesarPendientes(null)
      limpiarSesion()
      return Promise.reject(refreshError)

    } finally {
      isRefreshing = false
    }
  }
)

function limpiarSesion() {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('refresh_token')
  localStorage.removeItem('auth_user')
  // Redirigir solo si no estamos ya en login
  if (!window.location.pathname.startsWith('/auth')) {
    window.location.href = '/auth/login'
  }
}

export default api
