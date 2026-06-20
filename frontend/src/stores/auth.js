import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

// ─────────────────────────────────────────────────────────────────────────────
// Estrategia de almacenamiento de sesión:
//
// • sessionStorage  → sesión activa de ESTA pestaña (aislada por pestaña)
// • localStorage    → respaldo de "última sesión conocida" para restaurar al
//                     recargar la página (F5) sin necesidad de volver a hacer
//                     login, pero sin interferir con otras pestañas que ya
//                     tienen su propia sesión en sessionStorage.
//
// Flujo al abrir una nueva pestaña:
//   1. sessionStorage está vacío → se lee desde localStorage como punto de
//      partida (misma sesión que la pestaña original).
//   2. Si el usuario hace login en esa pestaña, sessionStorage se sobreescribe
//      con la nueva sesión sin tocar las demás pestañas ya abiertas.
//
// Esto resuelve el conflicto donde un login en pestaña B afectaba a pestaña A.
// ─────────────────────────────────────────────────────────────────────────────

function leerSesionInicial() {
  // Prioridad: sessionStorage (sesión aislada de esta pestaña) > localStorage (respaldo)
  const fromSession = sessionStorage.getItem('auth_token')
  if (fromSession) {
    return {
      token:        fromSession,
      refreshToken: sessionStorage.getItem('refresh_token'),
      user:         JSON.parse(sessionStorage.getItem('auth_user') || 'null'),
    }
  }
  // Pestaña recién abierta — heredar la sesión de localStorage como punto de partida
  const fromLocal = localStorage.getItem('auth_token')
  if (fromLocal) {
    // Copiar al sessionStorage para que esta pestaña tenga su propia copia
    sessionStorage.setItem('auth_token',    fromLocal)
    sessionStorage.setItem('auth_user',     localStorage.getItem('auth_user') || 'null')
    const rt = localStorage.getItem('refresh_token')
    if (rt) sessionStorage.setItem('refresh_token', rt)
    return {
      token:        fromLocal,
      refreshToken: rt,
      user:         JSON.parse(localStorage.getItem('auth_user') || 'null'),
    }
  }
  return { token: null, refreshToken: null, user: null }
}

export const useAuthStore = defineStore('auth', () => {
  // Normalizar usuario al leer de storage (el rol puede ser objeto o string)
  function normalizarUsuario(u) {
    if (!u) return null
    if (u.rol && typeof u.rol === 'object' && u.rol.value) u.rol = u.rol.value
    if (u.estado && typeof u.estado === 'object' && u.estado.value) u.estado = u.estado.value
    return u
  }

  const inicial = leerSesionInicial()

  const user         = ref(normalizarUsuario(inicial.user))
  const token        = ref(inicial.token)
  const refreshToken = ref(inicial.refreshToken)

  // Cache de datos de perfil obtenidos tras login (evita requests redundantes)
  const fundacionId  = ref(sessionStorage.getItem('fundacion_id') || null)

  const isLoggedIn   = computed(() => !!token.value)
  const isVoluntario = computed(() => user.value?.rol === 'VOLUNTARIO')
  const isFundacion  = computed(() => user.value?.rol === 'FUNDACION')
  const isAdmin      = computed(() => user.value?.rol === 'ADMIN')

  // ── Rol legible ───────────────────────────────────────────────
  const rolLabel = computed(() => ({
    VOLUNTARIO: 'Voluntario',
    FUNDACION:  'Fundación',
    ADMIN:      'Administrador',
  }[user.value?.rol] || user.value?.rol || ''))

  // ── Acciones ──────────────────────────────────────────────────
  async function login(email, password) {
    const { data } = await api.post('/auth/login', { email, password })
    setSession(data)
    return data
  }

  async function register(payload) {
    const { data } = await api.post('/auth/register', payload)
    setSession(data)
    return data
  }

  async function logout() {
    try {
      await api.post('/auth/logout')
    } catch {
      // Si el token ya expiró el backend igual lo invalida — continuar
    } finally {
      clearSession()
    }
  }

  async function fetchMe() {
    const { data } = await api.get('/auth/me')
    const u = normalizarUsuario(data)
    user.value = u
    sessionStorage.setItem('auth_user', JSON.stringify(u))
    localStorage.setItem('auth_user', JSON.stringify(u))
    return u
  }

  // ── Sesión ────────────────────────────────────────────────────
  function setSession({ usuario, token: tok, refresh_token: refTok }) {
    // Normalizar el rol — puede venir como string o como objeto {value: "ROL"}
    if (usuario?.rol && typeof usuario.rol === 'object' && usuario.rol.value) {
      usuario.rol = usuario.rol.value
    }
    if (usuario?.estado && typeof usuario.estado === 'object' && usuario.estado.value) {
      usuario.estado = usuario.estado.value
    }

    user.value         = usuario
    token.value        = tok
    refreshToken.value = refTok ?? null

    // sessionStorage: sesión de esta pestaña (aislada)
    sessionStorage.setItem('auth_user',  JSON.stringify(usuario))
    sessionStorage.setItem('auth_token', tok)
    if (refTok) sessionStorage.setItem('refresh_token', refTok)

    // localStorage: respaldo para restaurar al recargar (F5)
    localStorage.setItem('auth_user',  JSON.stringify(usuario))
    localStorage.setItem('auth_token', tok)
    if (refTok) localStorage.setItem('refresh_token', refTok)
  }

  function clearSession() {
    user.value         = null
    token.value        = null
    refreshToken.value = null
    fundacionId.value  = null

    sessionStorage.removeItem('auth_user')
    sessionStorage.removeItem('auth_token')
    sessionStorage.removeItem('refresh_token')
    sessionStorage.removeItem('fundacion_id')

    localStorage.removeItem('auth_user')
    localStorage.removeItem('auth_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('fundacion_id')
  }

  function setFundacionId(id) {
    fundacionId.value = id
    if (id) {
      sessionStorage.setItem('fundacion_id', id)
      localStorage.setItem('fundacion_id', id)
    }
  }

  return {
    // Estado
    user, token, refreshToken, fundacionId,
    // Computadas
    isLoggedIn, isVoluntario, isFundacion, isAdmin, rolLabel,
    // Acciones
    login, register, logout, fetchMe, setSession, clearSession, setFundacionId,
  }
})
