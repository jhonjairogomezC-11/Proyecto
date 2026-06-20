<template>
  <div>
    <h1 class="page-title mb-6">Mis Postulaciones</h1>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <!-- Filtro por estado -->
      <div class="estado-tabs mb-6">
        <button
          v-for="tab in tabs"
          :key="tab.value"
          :class="['tab-btn', tabActivo === tab.value ? 'active' : '']"
          @click="tabActivo = tab.value"
        >
          {{ tab.label }}
          <span v-if="conteo(tab.value)" class="tab-count">{{ conteo(tab.value) }}</span>
        </button>
      </div>

      <div v-if="postulacionesFiltradas.length === 0" class="empty-state">
        <div class="icon">📋</div>
        <h3>Sin postulaciones</h3>
        <p v-if="tabActivo === 'all'">Aún no te has postulado a ninguna convocatoria.</p>
        <p v-else>No tienes postulaciones en este estado.</p>
        <RouterLink :to="{ name: 'convocatorias' }" class="btn btn-primary mt-4">Buscar convocatorias</RouterLink>
      </div>

      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Convocatoria</th>
              <th>Fundación</th>
              <th>Fecha</th>
              <th>Estado</th>
              <th>Calificación</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in postulacionesFiltradas" :key="p.id">
              <td>
                <p class="font-medium">{{ p.publicacion?.titulo }}</p>
                <p class="text-xs text-muted">{{ formatDate(p.publicacion?.fecha_inicio) }} – {{ formatDate(p.publicacion?.fecha_fin) }}</p>
              </td>
              <td class="text-sm">{{ p.publicacion?.fundacion?.nombre }}</td>
              <td class="text-sm text-muted">{{ formatDate(p.fecha_postulacion) }}</td>
              <td><BadgeEstado :estado="p.estado" tipo="postulacion" /></td>
              <td>
                <span v-if="p.calificacion">
                  {{ '⭐'.repeat(p.calificacion) }}
                  <span class="text-xs text-muted">({{ p.calificacion }}/5)</span>
                </span>
                <span v-else class="text-muted text-xs">—</span>
              </td>
              <td>
                <div style="display:flex;gap:6px">
                  <button class="btn btn-ghost btn-sm" @click="abrirDetalle(p)" title="Ver detalle">👁</button>
                  <button
                    v-if="['PENDIENTE', 'ACEPTADO'].includes(p.estado)"
                    class="btn btn-danger btn-sm"
                    :disabled="retirando === p.id"
                    @click="retirar(p)"
                    title="Retirar postulación"
                  >
                    <AppSpinner v-if="retirando === p.id" :small="true" />
                    <span v-else>Retirar</span>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <AppPagination :meta="meta" @page="cargar" />
    </template>

    <!-- Modal detalle -->
    <AppModal v-model="showDetalle" title="Detalle de postulación">
      <div v-if="seleccionada">
        <h4 class="mb-2 font-medium">{{ seleccionada.publicacion?.titulo }}</h4>
        <p class="text-sm text-muted mb-4">{{ seleccionada.publicacion?.fundacion?.nombre }}</p>
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Estado</span><BadgeEstado :estado="seleccionada.estado" tipo="postulacion" /></div>
          <div class="detail-item"><span class="detail-label">Postulación</span><span>{{ formatDate(seleccionada.fecha_postulacion) }}</span></div>
          <div v-if="seleccionada.fecha_respuesta" class="detail-item"><span class="detail-label">Respuesta</span><span>{{ formatDate(seleccionada.fecha_respuesta) }}</span></div>
          <div v-if="seleccionada.calificacion" class="detail-item"><span class="detail-label">Calificación</span><span>{{ seleccionada.calificacion }}/5</span></div>
        </div>
        <div v-if="seleccionada.mensaje_voluntario" class="mb-4">
          <p class="detail-label">Tu mensaje</p>
          <p class="text-sm mt-1">{{ seleccionada.mensaje_voluntario }}</p>
        </div>
        <div v-if="seleccionada.motivo_rechazo" class="alert alert-danger">
          <span>Motivo de rechazo:</span> {{ seleccionada.motivo_rechazo }}
        </div>
        <div v-if="seleccionada.comentario_fundacion" class="alert alert-info">
          <span>💬 Comentario de la fundación:</span> {{ seleccionada.comentario_fundacion }}
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showDetalle = false">Cerrar</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { connectEcho } from '@/services/echo'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const auth          = useAuthStore()
const postulaciones = ref([])
const meta          = ref(null)
const loading       = ref(true)
const retirando     = ref(null)
const showDetalle   = ref(false)
const seleccionada  = ref(null)
const tabActivo     = ref('all')

const tabs = [
  { value: 'all',       label: 'Todas' },
  { value: 'PENDIENTE', label: 'Pendientes' },
  { value: 'ACEPTADO',  label: 'Aceptadas' },
  { value: 'RECHAZADO', label: 'Rechazadas' },
  { value: 'ASISTIO',   label: 'Completadas' },
]

const postulacionesFiltradas = computed(() => {
  if (tabActivo.value === 'all') return postulaciones.value
  return postulaciones.value.filter(p => p.estado === tabActivo.value)
})

function conteo(estado) {
  if (estado === 'all') return 0
  return postulaciones.value.filter(p => p.estado === estado).length
}

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function abrirDetalle(p) {
  seleccionada.value = p
  showDetalle.value  = true
}

async function cargar(page = 1) {
  loading.value = true
  try {
    const { data } = await api.get('/mis-postulaciones', { params: { page } })
    postulaciones.value = data.data || []
    meta.value          = data.meta || null
  } finally {
    loading.value = false
  }
}

async function retirar(p) {
  if (!confirm('¿Confirmas que deseas retirar esta postulación?')) return
  retirando.value = p.id
  try {
    const { data } = await api.post(`/postulaciones/${p.id}/retirar`)
    const idx = postulaciones.value.findIndex(x => x.id === p.id)
    if (idx !== -1) postulaciones.value[idx] = data
  } catch (e) {
    alert(e.response?.data?.message || 'Error al retirar.')
  } finally {
    retirando.value = null
  }
}

onMounted(() => {
  cargar()

  // Conectar WebSocket para tiempo real
  const echo = connectEcho()
  if (echo && auth.user?.id) {
    echo.private(`usuario.${auth.user.id}`)
      .listen('.PostulacionActualizada', onWebSocketEvent)
  }
})

function onWebSocketEvent(e) {
  cargar(meta.value?.current_page || 1)
  if (showDetalle.value && seleccionada.value?.id === e.postulacion_id) {
    // Para actualizar el detalle si está abierto, lo ideal es recargarlo o cerrar el modal
    // Recargar el detalle buscando en la lista actualizada
    setTimeout(() => {
      const actualizada = postulaciones.value.find(p => p.id === e.postulacion_id)
      if (actualizada) seleccionada.value = actualizada
    }, 500)
  }
}

onUnmounted(() => {
  const echo = connectEcho()
  if (echo && auth.user?.id) {
    echo.private(`usuario.${auth.user.id}`)
      .stopListening('.PostulacionActualizada', onWebSocketEvent)
  }
})
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.estado-tabs { display: flex; gap: 8px; flex-wrap: wrap; }
.tab-btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 7px 14px;
  border-radius: 99px;
  border: 1.5px solid var(--gray-300);
  background: var(--white);
  font-size: 13px; font-weight: 500;
  cursor: pointer; color: var(--gray-700);
  transition: all .18s;
}
.tab-btn:hover  { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.tab-count {
  background: rgba(255,255,255,.3);
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 99px;
  font-weight: 700;
}
.tab-btn.active .tab-count { background: rgba(255,255,255,.3); }
.tab-btn:not(.active) .tab-count { background: var(--gray-200); color: var(--gray-600); }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 4px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }
</style>
