<template>
  <div>
    <h1 class="page-title mb-2">Publicaciones pendientes de aprobación</h1>
    <p class="text-muted text-sm mb-6">Revisa y aprueba o rechaza las convocatorias enviadas por las fundaciones.</p>

    <AppAlert :message="successMsg" type="success" />
    <AppAlert :message="errorMsg" />

    <!-- Filtros por estado -->
    <div class="flex gap-3 mb-6 flex-wrap">
      <button v-for="tab in tabs" :key="tab.value"
        :class="['tab-btn', estadoFiltro === tab.value ? 'active' : '']"
        @click="cambiarEstado(tab.value)">
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <p class="text-sm text-muted mb-3">{{ meta?.total || 0 }} publicaciones</p>

      <div v-if="publicaciones.length === 0" class="empty-state">
        <div class="icon">📢</div>
        <h3>Sin publicaciones pendientes</h3>
        <p>No hay convocatorias en este estado.</p>
      </div>

      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Convocatoria</th>
              <th>Fundación</th>
              <th>Modalidad</th>
              <th>Dificultad</th>
              <th>Fechas</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in publicaciones" :key="p.id">
              <td>
                <p class="font-medium">{{ p.titulo }}</p>
                <p class="text-xs text-muted">{{ p.categoria?.nombre }}</p>
                <p v-if="p.urgente" class="text-xs" style="color:var(--danger)">🚨 Urgente</p>
              </td>
              <td class="text-sm">{{ p.fundacion?.nombre }}</td>
              <td class="text-sm">{{ p.modalidad }}</td>
              <td class="text-sm">{{ p.dificultad }}</td>
              <td class="text-xs text-muted">
                {{ formatDate(p.fecha_inicio) }}<br>{{ formatDate(p.fecha_fin) }}
              </td>
              <td><BadgeEstado :estado="p.estado" tipo="publicacion" /></td>
              <td>
                <div style="display:flex;gap:6px;flex-wrap:wrap">
                  <button class="btn btn-ghost btn-sm" @click="verDetalle(p)">👁 Ver</button>
                  <button v-if="p.estado === 'PENDIENTE_APROBACION'"
                    class="btn btn-secondary btn-sm"
                    :disabled="accionando === p.id"
                    @click="aprobar(p)">
                    <AppSpinner v-if="accionando === p.id + '_A'" :small="true" />
                    <span v-else>✓ Aprobar</span>
                  </button>
                  <button v-if="p.estado === 'PENDIENTE_APROBACION'"
                    class="btn btn-danger btn-sm"
                    @click="pedirMotivo(p)">
                    ✗ Rechazar
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
    <AppModal v-model="showDetalle" :title="seleccionada?.titulo || 'Detalle'">
      <div v-if="seleccionada">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Fundación</span><span>{{ seleccionada.fundacion?.nombre }}</span></div>
          <div class="detail-item"><span class="detail-label">Modalidad</span><span>{{ seleccionada.modalidad }}</span></div>
          <div class="detail-item"><span class="detail-label">Dificultad</span><span>{{ seleccionada.dificultad }}</span></div>
          <div class="detail-item"><span class="detail-label">Urgente</span><span>{{ seleccionada.urgente ? 'Sí 🚨' : 'No' }}</span></div>
          <div class="detail-item"><span class="detail-label">Inicio</span><span>{{ formatDate(seleccionada.fecha_inicio) }}</span></div>
          <div class="detail-item"><span class="detail-label">Fin</span><span>{{ formatDate(seleccionada.fecha_fin) }}</span></div>
          <div class="detail-item"><span class="detail-label">Cupos</span><span>{{ seleccionada.cupo_maximo }}</span></div>
          <div v-if="seleccionada.municipio" class="detail-item"><span class="detail-label">Municipio</span><span>{{ seleccionada.municipio.nombre }}</span></div>
        </div>
        <p class="text-sm mb-3"><strong>Descripción:</strong> {{ seleccionada.descripcion }}</p>
        <div v-if="seleccionada.requisitos_adicionales" class="text-sm mb-3">
          <strong>Requisitos:</strong> {{ seleccionada.requisitos_adicionales }}
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showDetalle = false">Cerrar</button>
        <button v-if="seleccionada?.estado === 'PENDIENTE_APROBACION'" class="btn btn-secondary" @click="aprobar(seleccionada); showDetalle = false">✓ Aprobar</button>
        <button v-if="seleccionada?.estado === 'PENDIENTE_APROBACION'" class="btn btn-danger" @click="showDetalle = false; pedirMotivo(seleccionada)">✗ Rechazar</button>
      </template>
    </AppModal>

    <!-- Modal motivo rechazo -->
    <AppModal v-model="showMotivo" title="Rechazar publicación">
      <AppAlert :message="motivoError" />
      <div class="form-group">
        <label class="form-label">Motivo del rechazo <span class="required">*</span></label>
        <textarea v-model="motivoTexto" class="form-control" rows="4"
          placeholder="Explica por qué se devuelve esta convocatoria (mín. 10 caracteres)…"></textarea>
        <span class="text-xs text-muted">{{ motivoTexto.length }} caracteres</span>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showMotivo = false">Cancelar</button>
        <button class="btn btn-danger" :disabled="accionando !== null" @click="confirmarRechazo">
          <AppSpinner v-if="accionando !== null" :small="true" />
          Rechazar y devolver
        </button>
      </template>
    </AppModal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const publicaciones = ref([])
const meta          = ref(null)
const loading       = ref(true)
const estadoFiltro  = ref('PENDIENTE_APROBACION')
const successMsg    = ref('')
const errorMsg      = ref('')

const showDetalle   = ref(false)
const seleccionada  = ref(null)
const showMotivo    = ref(false)
const motivoTexto   = ref('')
const motivoError   = ref('')
const pubRechazar   = ref(null)
const accionando    = ref(null)

const tabs = [
  { value: 'PENDIENTE_APROBACION', label: '⏳ Pendientes' },
  { value: 'PUBLICADA',            label: '✅ Aprobadas'  },
  { value: 'BORRADOR',             label: '📝 Devueltas'  },
]

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function cambiarEstado(estado) {
  estadoFiltro.value = estado
  cargar(1)
}

async function cargar(page = 1) {
  loading.value = true
  try {
    const { data } = await api.get('/admin/publicaciones', {
      params: { page, estado: estadoFiltro.value }
    })
    publicaciones.value = data.data || []
    meta.value          = data.meta || null
  } finally {
    loading.value = false
  }
}

function verDetalle(p) {
  seleccionada.value = p
  showDetalle.value  = true
}

async function aprobar(p) {
  accionando.value = p.id + '_A'
  try {
    const { data } = await api.put(`/admin/publicaciones/${p.id}/aprobar`)
    actualizarLista(data)
    successMsg.value = `"${p.titulo}" aprobada y publicada.`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error al aprobar.'
  } finally {
    accionando.value = null
  }
}

function pedirMotivo(p) {
  pubRechazar.value = p
  motivoTexto.value = ''
  motivoError.value = ''
  showMotivo.value  = true
}

async function confirmarRechazo() {
  if (!motivoTexto.value.trim() || motivoTexto.value.trim().length < 10) {
    motivoError.value = 'El motivo debe tener al menos 10 caracteres.'
    return
  }
  accionando.value = pubRechazar.value.id
  try {
    const { data } = await api.put(`/admin/publicaciones/${pubRechazar.value.id}/rechazar`, {
      motivo: motivoTexto.value
    })
    actualizarLista(data)
    showMotivo.value = false
    successMsg.value = `"${pubRechazar.value.titulo}" devuelta a la fundación.`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    motivoError.value = e.response?.data?.message || 'Error.'
  } finally {
    accionando.value = null
  }
}

function actualizarLista(updated) {
  const idx = publicaciones.value.findIndex(p => p.id === updated.id)
  if (idx !== -1) publicaciones.value.splice(idx, 1)
}

onMounted(() => cargar())
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.tab-btn { display: inline-flex; align-items: center; gap: 6px; padding: 7px 14px; border-radius: 99px; border: 1.5px solid var(--gray-300); background: var(--white); font-size: 13px; font-weight: 500; cursor: pointer; color: var(--gray-700); transition: all .18s; }
.tab-btn:hover  { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }
</style>
