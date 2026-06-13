<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="page-title">Notificaciones</h1>
      <button v-if="hayNoLeidas" class="btn btn-outline btn-sm" :disabled="marcando" @click="marcarTodas">
        <AppSpinner v-if="marcando" :small="true" />
        ✓ Marcar todas como leídas
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <div v-if="notificaciones.length === 0" class="empty-state">
        <div class="icon">🔔</div>
        <h3>Sin notificaciones</h3>
        <p>Cuando tengas actividad, las notificaciones aparecerán aquí.</p>
      </div>

      <div v-else class="notif-list">
        <div
          v-for="n in notificaciones"
          :key="n.id"
          :class="['notif-item', !n.leida ? 'unread' : '']"
          @click="marcarLeida(n)"
        >
          <div class="notif-icon">{{ iconForTipo(n.tipo) }}</div>
          <div class="notif-content">
            <p class="notif-msg">{{ n.mensaje }}</p>
            <p class="notif-time text-xs text-muted">{{ formatRelative(n.fecha_creacion) }}</p>
          </div>
          <div v-if="!n.leida" class="notif-dot"></div>
        </div>
      </div>

      <AppPagination :meta="meta" @page="cargar" />
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '@/services/api'
import { useNotificacionesStore } from '@/stores/notificaciones'
import AppSpinner from '@/components/AppSpinner.vue'
import AppPagination from '@/components/AppPagination.vue'

const notiStore       = useNotificacionesStore()
const notificaciones  = ref([])
const meta            = ref(null)
const loading         = ref(true)
const marcando        = ref(false)

const hayNoLeidas = computed(() => notificaciones.value.some(n => !n.leida))

const ICONS = {
  NUEVA_POSTULACION:    '📥',
  POSTULACION_RETIRADA: '↩️',
  VOLUNTARIO_ASISTIO:   '✅',
  VOLUNTARIO_NO_ASISTIO:'❌',
  POSTULACION_ACEPTADA: '🎉',
  POSTULACION_RECHAZADA:'😕',
  ACTIVIDAD_CANCELADA:  '🚫',
  ACTIVIDAD_MODIFICADA: '✏️',
  FUNDACION_APROBADA:   '✅',
  FUNDACION_RECHAZADA:  '❌',
  FUNDACION_SUSPENDIDA: '⚠️',
  FUNDACION_REACTIVADA: '🔄',
  RECORDATORIO_ACTIVIDAD:'⏰',
}
function iconForTipo(tipo) { return ICONS[tipo] || '🔔' }

function formatRelative(d) {
  if (!d) return ''
  const diff = Date.now() - new Date(d).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'Ahora mismo'
  if (mins < 60) return `Hace ${mins} min`
  const hs = Math.floor(mins / 60)
  if (hs < 24) return `Hace ${hs}h`
  const ds = Math.floor(hs / 24)
  if (ds < 7) return `Hace ${ds} días`
  return new Date(d).toLocaleDateString('es-CO')
}

async function cargar(page = 1) {
  loading.value = true
  try {
    const { data } = await api.get('/notificaciones', { params: { page } })
    notificaciones.value = data.data || []
    meta.value           = data.meta || null
  } finally {
    loading.value = false
  }
}

async function marcarLeida(n) {
  if (n.leida) return
  try {
    const { data } = await api.put(`/notificaciones/${n.id}/marcar-leida`)
    const idx = notificaciones.value.findIndex(x => x.id === n.id)
    if (idx !== -1) notificaciones.value[idx] = data
    notiStore.decrementar()
  } catch {}
}

async function marcarTodas() {
  marcando.value = true
  try {
    await api.post('/notificaciones/marcar-todas-leidas')
    notificaciones.value.forEach(n => n.leida = true)
    notiStore.resetear()
  } catch {}
  finally { marcando.value = false }
}

onMounted(() => cargar())
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.notif-list { display: flex; flex-direction: column; gap: 0; background: var(--white); border: 1px solid var(--gray-200); border-radius: var(--radius-lg); overflow: hidden; }
.notif-item {
  display: flex; align-items: flex-start; gap: 14px;
  padding: 16px 18px;
  border-bottom: 1px solid var(--gray-100);
  cursor: pointer;
  transition: background .15s;
  position: relative;
}
.notif-item:last-child { border-bottom: none; }
.notif-item:hover { background: var(--gray-50); }
.notif-item.unread { background: var(--primary-light); }
.notif-item.unread:hover { background: #bfdbfe; }
.notif-icon { font-size: 22px; flex-shrink: 0; margin-top: 2px; }
.notif-content { flex: 1; min-width: 0; }
.notif-msg  { font-size: 14px; color: var(--gray-800); line-height: 1.4; }
.notif-time { margin-top: 4px; }
.notif-dot {
  width: 10px; height: 10px;
  background: var(--primary);
  border-radius: 50%;
  flex-shrink: 0;
  margin-top: 6px;
}
</style>
