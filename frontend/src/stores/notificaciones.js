import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useNotificacionesStore = defineStore('notificaciones', () => {
  const noLeidas = ref(0)

  async function cargarConteo() {
    try {
      const { data } = await api.get('/notificaciones/no-leidas')
      noLeidas.value = data.total
    } catch {}
  }

  function decrementar(n = 1) {
    noLeidas.value = Math.max(0, noLeidas.value - n)
  }

  function resetear() {
    noLeidas.value = 0
  }

  return { noLeidas, cargarConteo, decrementar, resetear }
})
