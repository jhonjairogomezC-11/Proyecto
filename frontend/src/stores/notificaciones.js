import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useNotificacionesStore = defineStore('notificaciones', () => {
  const noLeidas = ref(0)
  // Cola de notificaciones push para el componente Toast
  const pushQueue = ref([])

  async function cargarConteo() {
    try {
      const { data } = await api.get('/notificaciones/no-leidas')
      noLeidas.value = data.total
    } catch {}
  }

  function incrementar(n = 1) {
    noLeidas.value += n
  }

  function decrementar(n = 1) {
    noLeidas.value = Math.max(0, noLeidas.value - n)
  }

  function resetear() {
    noLeidas.value = 0
  }

  /**
   * Encola una notificación push recibida por WebSocket.
   * El componente Toast la consume y muestra visualmente.
   */
  function pushNotificacion({ title, message = '', type = 'notification' }) {
    pushQueue.value.push({ title, message, type, timestamp: Date.now() })
    incrementar()
  }

  /**
   * Extrae y retorna la siguiente notificación pendiente de la cola.
   */
  function popNotificacion() {
    return pushQueue.value.shift() || null
  }

  return {
    noLeidas,
    pushQueue,
    cargarConteo,
    incrementar,
    decrementar,
    resetear,
    pushNotificacion,
    popNotificacion,
  }
})
