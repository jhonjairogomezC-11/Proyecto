<template>
  <div>
    <h1 class="page-title mb-2">Mis Postulaciones</h1>
    <p class="page-subtitle mb-6">Revisa el estado de tus postulaciones: pendientes, aprobadas o rechazadas.</p>

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
        <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
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
                <p class="font-medium table-title">{{ p.publicacion?.titulo }}</p>
                <p class="text-xs text-muted">{{ formatDate(p.publicacion?.fecha_inicio) }} – {{ formatDate(p.publicacion?.fecha_fin) }}</p>
              </td>
              <td class="text-sm font-medium">{{ p.publicacion?.fundacion?.nombre }}</td>
              <td class="text-sm text-muted">{{ formatDate(p.fecha_postulacion) }}</td>
              <td><BadgeEstado :estado="p.estado" tipo="postulacion" /></td>
              <td>
                <span v-if="p.calificacion" class="rating-stars">
                  <svg v-for="n in p.calificacion" :key="n" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" style="color: var(--warning);"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                  <svg v-for="n in (5 - p.calificacion)" :key="'empty-'+n" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" style="color: var(--gray-300);"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                  <span class="text-xs text-muted" style="margin-left:4px">({{ p.calificacion }}/5)</span>
                </span>
                <span v-else class="text-muted text-xs">—</span>
              </td>
              <td>
                <div style="display:flex;gap:6px">
                  <button class="btn btn-ghost btn-sm btn-icon" @click="abrirDetalle(p)" title="Ver detalle">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  </button>
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
        <h4 class="mb-2 font-medium modal-pub-title">{{ seleccionada.publicacion?.titulo }}</h4>
        <p class="text-sm text-muted mb-4">{{ seleccionada.publicacion?.fundacion?.nombre }}</p>
        
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Estado</span><BadgeEstado :estado="seleccionada.estado" tipo="postulacion" /></div>
          <div class="detail-item"><span class="detail-label">Postulación</span><span>{{ formatDate(seleccionada.fecha_postulacion) }}</span></div>
          <div v-if="seleccionada.fecha_respuesta" class="detail-item"><span class="detail-label">Respuesta</span><span>{{ formatDate(seleccionada.fecha_respuesta) }}</span></div>
          <div v-if="seleccionada.calificacion" class="detail-item">
            <span class="detail-label">Calificación</span>
            <span class="rating-stars flex items-center">
              <svg v-for="n in seleccionada.calificacion" :key="n" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" style="color: var(--warning);"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
              <span class="text-xs text-muted" style="margin-left:4px">({{ seleccionada.calificacion }}/5)</span>
            </span>
          </div>
        </div>

        <div v-if="seleccionada.mensaje_voluntario" class="mb-4">
          <p class="detail-label">Tu mensaje</p>
          <p class="text-sm mt-1 message-box">{{ seleccionada.mensaje_voluntario }}</p>
        </div>
        
        <div v-if="seleccionada.motivo_rechazo" class="alert alert-danger">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
          <div>
            <strong>Motivo de rechazo:</strong> {{ seleccionada.motivo_rechazo }}
          </div>
        </div>
        
        <div v-if="seleccionada.comentario_fundacion" class="alert alert-info">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          <div>
            <strong>Comentario de la fundación:</strong> {{ seleccionada.comentario_fundacion }}
          </div>
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
import { connectEcho, getEcho } from '@/services/echo'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const auth          = useAuthStore()
const postulaciones = ref([])
const meta          = ref(null)
const loading       = ref(false)
const retirando     = ref(null)
const showDetalle   = ref(false)
const seleccionada  = ref(null)
const tabActivo     = ref('all')
const loadToken     = ref(0)
const loadError     = ref(null)

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
  if (loading.value) return
  loading.value = true
  loadError.value = null
  loadToken.value += 1
  const currentToken = loadToken.value

  try {
    const { data } = await api.get('/mis-postulaciones', { params: { page } })
    if (currentToken !== loadToken.value) return
    postulaciones.value = Array.isArray(data.data) ? data.data : []
    meta.value          = data.meta || null
  } catch (error) {
    if (currentToken !== loadToken.value) return
    loadError.value = error
    postulaciones.value = []
    meta.value = null
  } finally {
    if (currentToken === loadToken.value) {
      loading.value = false
    }
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

onMounted(async () => {
  await cargar()

  const echo = connectEcho()
  if (echo && auth.user?.id) {
    echo.private(`usuario.${auth.user.id}`)
      .listen('.PostulacionActualizada', onWebSocketEvent)
  }
})

function onWebSocketEvent(e) {
  cargar(meta.value?.current_page || 1)
  if (showDetalle.value && seleccionada.value?.id === e.postulacion_id) {
    setTimeout(() => {
      const actualizada = postulaciones.value.find(p => p.id === e.postulacion_id)
      if (actualizada) seleccionada.value = actualizada
    }, 500)
  }
}

onUnmounted(() => {
  const echo = getEcho()
  if (echo && auth.user?.id) {
    echo.private(`usuario.${auth.user.id}`)
      .stopListening('.PostulacionActualizada', onWebSocketEvent)
  }
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }
.page-subtitle { font-size: 14px; color: var(--gray-500); }
.estado-tabs { display: flex; gap: 8px; flex-wrap: wrap; }
.tab-btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 16px;
  border-radius: 99px;
  border: 1.5px solid var(--gray-300);
  background: var(--white);
  font-size: 13px; font-weight: 600;
  cursor: pointer; color: var(--gray-600);
  transition: var(--transition);
}
.tab-btn:hover  { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.tab-count {
  background: var(--gray-100);
  color: var(--gray-600);
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 99px;
  font-weight: 700;
}
.tab-btn.active .tab-count { background: rgba(255, 255, 255, 0.25); color: #fff; }

.table-title {
  color: var(--gray-900);
  font-family: 'Outfit', sans-serif;
  font-size: 14px;
}
.rating-stars {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}
.rating-stars svg {
  flex-shrink: 0;
}

.modal-pub-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--gray-900);
  font-family: 'Outfit', sans-serif;
}
.message-box {
  background: var(--gray-50);
  border: 1px solid var(--gray-200);
  border-radius: var(--radius);
  padding: 12px;
  color: var(--gray-700);
  line-height: 1.5;
}

.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 4px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }

.empty-icon {
  margin: 0 auto 12px;
  color: var(--gray-300);
  display: block;
}
</style>
