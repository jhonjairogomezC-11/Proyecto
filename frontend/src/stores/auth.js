import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  // Normalizar usuario al leer de localStorage (el rol puede ser objeto o string)
  function normalizarUsuario(u) {
    if (!u) return null
    if (u.rol && typeof u.rol === 'object' && u.rol.value) u.rol = u.rol.value
    if (u.estado && typeof u.estado === 'object' && u.estado.value) u.estado = u.estado.value
    return u
  }

  const user         = ref(normalizarUsuario(JSON.parse(localStorage.getItem('auth_user') || 'null')))
  const token        = ref(localStorage.getItem('auth_token') || null)
  const refreshToken = ref(localStorage.getItem('refresh_token') || null)

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

    localStorage.setItem('auth_user',  JSON.stringify(usuario))
    localStorage.setItem('auth_token', tok)

    if (refTok) {
      localStorage.setItem('refresh_token', refTok)
    }
  }

  function clearSession() {
    user.value         = null
    token.value        = null
    refreshToken.value = null

    localStorage.removeItem('auth_user')
    localStorage.removeItem('auth_token')
    localStorage.removeItem('refresh_token')
  }

  return {
    // Estado
    user, token, refreshToken,
    // Computadas
    isLoggedIn, isVoluntario, isFundacion, isAdmin, rolLabel,
    // Acciones
    login, register, logout, fetchMe, setSession, clearSession,
  }
})
