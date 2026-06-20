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

/**
 * Crea y retorna la instancia de Echo conectada a Reverb.
 * Si ya existe una conexión, la retorna sin reconectar.
 */
export function connectEcho() {
  if (echoInstance) return echoInstance

  const token = localStorage.getItem('auth_token')

  echoInstance = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
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
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
      },
    },
  })

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
  if (echoInstance && echoInstance.connector?.pusher?.config?.auth) {
    echoInstance.connector.pusher.config.auth.headers.Authorization = `Bearer ${newToken}`
  }
}
