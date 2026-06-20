/**
 * Echo Service — Conexión WebSocket con Laravel Reverb
 *
 * Usa laravel-echo + pusher-js para conectarse al servidor
 * Reverb configurado en el backend.
 */
import Echo from 'laravel-echo'
import Pusher from 'pusher-js'

// Pusher debe estar disponible globalmente para Laravel Echo
window.Pusher = Pusher

let echoInstance = null
let echoDisabled = false

function getAuthToken() {
  return sessionStorage.getItem('auth_token') || localStorage.getItem('auth_token')
}

/**
 * Crea y retorna la instancia de Echo conectada a Reverb.
 * Si ya existe una conexión, la retorna sin reconectar.
 * Retorna null si Reverb no está configurado (desarrollo sin WebSocket).
 */
export function connectEcho() {
  if (echoInstance) return echoInstance
  if (echoDisabled) return null

  const key = import.meta.env.VITE_REVERB_APP_KEY
  if (!key) {
    echoDisabled = true
    if (import.meta.env.DEV) {
      console.info('[Echo] Tiempo real deshabilitado: falta VITE_REVERB_APP_KEY en frontend/.env')
    }
    return null
  }

  const token = getAuthToken()

  try {
    echoInstance = new Echo({
      broadcaster: 'reverb',
      key,
      wsHost: import.meta.env.VITE_REVERB_HOST || 'localhost',
      wsPort: import.meta.env.VITE_REVERB_PORT || 8080,
      wssPort: import.meta.env.VITE_REVERB_PORT || 8080,
      forceTLS: (import.meta.env.VITE_REVERB_SCHEME || 'http') === 'https',
      enabledTransports: ['ws', 'wss'],
      disableStats: true,

      // Autenticación con JWT
      authEndpoint: '/api/v1/broadcasting/auth',
      auth: {
        headers: {
          Authorization: token ? `Bearer ${token}` : undefined,
          Accept: 'application/json',
        },
      },
    })
  } catch (err) {
    echoDisabled = true
    console.warn('[Echo] No se pudo inicializar:', err)
    return null
  }

  return echoInstance
}

/**
 * Desconecta y destruye la instancia de Echo.
 */
export function disconnectEcho() {
  if (echoInstance) {
    echoInstance.disconnect()
    echoInstance = null
  }
  echoDisabled = false
}

/**
 * Retorna la instancia actual de Echo (o null si no está conectada).
 */
export function getEcho() {
  return echoInstance
}

/**
 * Actualiza el token de autenticación en la conexión Echo existente.
 * Útil después de un refresh de JWT.
 */
export function updateEchoToken(newToken) {
  if (!echoInstance || !echoInstance.connector?.pusher) return

  const config = echoInstance.connector.pusher.config
  if (!config.auth) {
    config.auth = { headers: { Accept: 'application/json' } }
  }
  if (!config.auth.headers) {
    config.auth.headers = { Accept: 'application/json' }
  }

  if (newToken) {
    config.auth.headers.Authorization = `Bearer ${newToken}`
  } else {
    delete config.auth.headers.Authorization
  }
}
