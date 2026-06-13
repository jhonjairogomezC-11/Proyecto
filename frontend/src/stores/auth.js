import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  const user    = ref(JSON.parse(localStorage.getItem('auth_user') || 'null'))
  const token   = ref(localStorage.getItem('auth_token') || null)

  const isLoggedIn  = computed(() => !!token.value)
  const isVoluntario = computed(() => user.value?.rol === 'VOLUNTARIO')
  const isFundacion  = computed(() => user.value?.rol === 'FUNDACION')
  const isAdmin      = computed(() => user.value?.rol === 'ADMIN')

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
    try { await api.post('/auth/logout') } catch {}
    clearSession()
  }

  async function fetchMe() {
    const { data } = await api.get('/auth/me')
    user.value = data
    localStorage.setItem('auth_user', JSON.stringify(data))
    return data
  }

  function setSession({ usuario, token: tok }) {
    user.value  = usuario
    token.value = tok
    localStorage.setItem('auth_user',  JSON.stringify(usuario))
    localStorage.setItem('auth_token', tok)
  }

  function clearSession() {
    user.value  = null
    token.value = null
    localStorage.removeItem('auth_user')
    localStorage.removeItem('auth_token')
  }

  return { user, token, isLoggedIn, isVoluntario, isFundacion, isAdmin,
           login, register, logout, fetchMe, clearSession }
})
