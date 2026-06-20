<template>
  <div class="admin-page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Publicaciones</h1>
        <p class="page-subtitle">Revisa y aprueba o rechaza las convocatorias enviadas por las fundaciones.</p>
      </div>
    </div>

    <AppAlert :message="successMsg" type="success" />
    <AppAlert :message="errorMsg" />

    <!-- Tab bar -->
    <div class="tab-bar">
      <button v-for="tab in tabs" :key="tab.value"
        :class="['tab-btn', estadoFiltro === tab.value ? 'active' : '']"
        @click="cambiarEstado(tab.value)">
        <span class="tab-dot" :class="`dot-${tab.color}`"></span>
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <p class="result-count">{{ meta?.total || 0 }} publicaciones</p>

      <div v-if="publicaciones.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="40" height="40"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        </div>
        <h3>Sin publicaciones</h3>
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
                <span v-if="p.urgente" class="urgente-badge">Urgente</span>
              </td>
              <td class="text-sm">{{ p.fundacion?.nombre }}</td>
              <td class="text-sm">{{ p.modalidad }}</td>
              <td class="text-sm">{{ p.dificultad }}</td>
              <td class="text-xs text-muted">
                <div>{{ formatDate(p.fecha_inicio) }}</div>
                <div>{{ formatDate(p.fecha_fin) }}</div>
              </td>
              <td><BadgeEstado :estado="p.estado" tipo="publicacion" /></td>
              <td>
                <div class="action-btns">
                  <button class="icon-btn" @click="verDetalle(p)" title="Ver detalle">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  </button>
                  <button v-if="p.estado === 'PENDIENTE_APROBACION'"
                    class="btn btn-secondary btn-xs"
                    :disabled="accionando === p.id + '_A'"
                    @click="aprobar(p)">
                    <AppSpinner v-if="accionando === p.id + '_A'" :small="true" />
                    <span v-else>Aprobar</span>
                  </button>
                  <button v-if="p.estado === 'PENDIENTE_APROBACION'"
                    class="btn btn-danger btn-xs"
                    @click="pedirMotivo(p)">
                    Rechazar
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
          <div class="detail-item"><span class="detail-label">Urgente</span>
            <span :class="seleccionada.urgente ? 'text-danger font-medium' : ''">{{ seleccionada.urgente ? 'Sí' : 'No' }}</span>
          </div>
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
        <button v-if="seleccionada?.estado === 'PENDIENTE_APROBACION'" class="btn btn-secondary" @click="aprobar(seleccionada); showDetalle = false">Aprobar</button>
        <button v-if="seleccionada?.estado === 'PENDIENTE_APROBACION'" class="btn btn-danger" @click="showDetalle = false; pedirMotivo(seleccionada)">Rechazar</button>
      </template>
    </AppModal>

    <!-- Modal motivo rechazo -->
    <AppModal v-model="showMotivo" title="Rechazar publicación">
      <AppAlert :message="motivoError" />
      <div class="form-group">
        <label class="form-label">Motivo del rechazo <span class="required">*</span></label>
        <textarea v-model="motivoTexto" class="form-control" rows="4"
          placeholder="Explica por qué se devuelve esta convocatoria (mín. 10 caracteres)…"></textarea>
        <span class="char-count">{{ motivoTexto.length }} caracteres</span>
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
  { value: 'PENDIENTE_APROBACION', label: 'Pendientes',  color: 'warning' },
  { value: 'PUBLICADA',            label: 'Aprobadas',   color: 'success' },
  { value: 'BORRADOR',             label: 'Devueltas',   color: 'neutral' },
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
.admin-page { display: flex; flex-direction: column; gap: 20px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 22px; font-weight: 700; color: var(--gray-900); margin: 0 0 4px; }
.page-subtitle { font-size: 13px; color: var(--gray-500); margin: 0; }
.result-count { font-size: 13px; color: var(--gray-500); margin: 0; }

.tab-bar { display: flex; gap: 8px; flex-wrap: wrap; }
.tab-btn {
  display: inline-flex; align-items: center; gap: 7px;
  padding: 7px 16px; border-radius: 99px;
  border: 1.5px solid var(--gray-200); background: var(--white);
  font-size: 13px; font-weight: 500; cursor: pointer; color: var(--gray-600);
  transition: all .2s;
}
.tab-btn:hover { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.tab-dot { width: 7px; height: 7px; border-radius: 50%; background: currentColor; flex-shrink: 0; }

.urgente-badge { display: inline-block; padding: 1px 7px; background: var(--danger-light); color: var(--danger); border-radius: 4px; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .05em; margin-top: 3px; }
.text-danger { color: var(--danger); }

.action-btns { display: flex; gap: 5px; flex-wrap: wrap; align-items: center; }
.icon-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 30px; height: 30px; border-radius: var(--radius);
  border: 1px solid var(--gray-200); background: var(--white);
  color: var(--gray-500); cursor: pointer; transition: all .15s;
}
.icon-btn:hover { border-color: var(--primary); color: var(--primary); background: var(--primary-light); }
.btn-xs { padding: 4px 10px; font-size: 12px; }

.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 14px; }
.detail-item { display: flex; flex-direction: column; gap: 3px; }
.detail-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--gray-400); }
.char-count { font-size: 11px; color: var(--gray-400); margin-top: 4px; display: block; }
</style>
