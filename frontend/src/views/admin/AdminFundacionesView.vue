<template>
  <div class="admin-page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="page-title">Gestión de Fundaciones</h1>
        <p class="page-subtitle">Revisa, aprueba y gestiona el estado de las fundaciones registradas.</p>
      </div>
    </div>

    <AppAlert :message="successMsg" type="success" />
    <AppAlert :message="errorMsg" />

    <!-- Filters -->
    <div class="filter-bar card">
      <div class="filter-inner">
        <div class="filter-field flex-1">
          <label class="form-label">Buscar por nombre</label>
          <div class="input-icon-wrap">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
            <input v-model="filtros.nombre" type="text" class="form-control pl-icon" placeholder="Nombre de la fundación…" @input="buscarDebounced" />
          </div>
        </div>
        <div class="filter-field">
          <label class="form-label">Estado</label>
          <select v-model="filtros.estado" class="form-control" @change="cargar(1)">
            <option value="">Todos</option>
            <option value="PENDIENTE">Pendiente</option>
            <option value="APROBADA">Aprobada</option>
            <option value="RECHAZADA">Rechazada</option>
            <option value="SUSPENDIDA">Suspendida</option>
          </select>
        </div>
        <button class="btn btn-ghost" @click="limpiarFiltros">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/></svg>
          Limpiar
        </button>
      </div>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <p class="result-count">{{ meta?.total || 0 }} fundaciones encontradas</p>

      <div v-if="fundaciones.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="40" height="40"><path d="M3 21h18M9 21V7l-3-4h12l-3 4v14M12 3v4M9 11h6M9 15h6"/></svg>
        </div>
        <h3>Sin fundaciones</h3>
        <p>No hay fundaciones que coincidan con los filtros.</p>
      </div>

      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Fundación</th>
              <th>NIT</th>
              <th>Representante</th>
              <th>Ubicación</th>
              <th>Estado</th>
              <th>Registro</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="f in fundaciones" :key="f.id">
              <td>
                <p class="font-medium">{{ f.nombre }}</p>
                <p class="text-xs text-muted">{{ f.correo_institucional }}</p>
              </td>
              <td class="text-sm mono">{{ f.nit }}</td>
              <td class="text-sm">{{ f.representante_legal }}</td>
              <td class="text-sm text-muted">{{ f.municipio?.nombre }}</td>
              <td><BadgeEstado :estado="f.estado_verificacion" tipo="fundacion" /></td>
              <td class="text-sm text-muted">{{ formatDate(f.fecha_creacion) }}</td>
              <td>
                <div class="action-btns">
                  <button class="icon-btn" @click="verDetalle(f)" title="Ver detalle">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  </button>
                  <button class="icon-btn" @click="verHistorial(f)" title="Historial">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M12 8v4l3 3m6-3a9 9 0 1 1-18 0 9 9 0 0 1 18 0z"/></svg>
                  </button>
                  <button v-if="f.estado_verificacion === 'PENDIENTE'" class="btn btn-secondary btn-xs" @click="aprobar(f)">Aprobar</button>
                  <button v-if="f.estado_verificacion === 'PENDIENTE'" class="btn btn-danger btn-xs" @click="pedirMotivo(f, 'rechazar')">Rechazar</button>
                  <button v-if="f.estado_verificacion === 'APROBADA'" class="btn btn-warning btn-xs" @click="pedirMotivo(f, 'suspender')">Suspender</button>
                  <button v-if="['RECHAZADA','SUSPENDIDA'].includes(f.estado_verificacion)" class="btn btn-outline btn-xs" @click="reactivar(f)">Reactivar</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AppPagination :meta="meta" @page="cargar" />
    </template>

    <!-- Modal detalle -->
    <AppModal v-model="showDetalle" :title="seleccionada?.nombre || 'Detalle'">
      <div v-if="seleccionada">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">NIT</span><span class="mono">{{ seleccionada.nit }}</span></div>
          <div class="detail-item"><span class="detail-label">Representante</span><span>{{ seleccionada.representante_legal }}</span></div>
          <div class="detail-item"><span class="detail-label">Teléfono</span><span>{{ seleccionada.telefono }}</span></div>
          <div class="detail-item"><span class="detail-label">Estado</span><BadgeEstado :estado="seleccionada.estado_verificacion" tipo="fundacion" /></div>
          <div v-if="seleccionada.correo_institucional" class="detail-item"><span class="detail-label">Correo inst.</span><span>{{ seleccionada.correo_institucional }}</span></div>
          <div v-if="seleccionada.pagina_web" class="detail-item"><span class="detail-label">Web</span><a :href="seleccionada.pagina_web" target="_blank" class="link">{{ seleccionada.pagina_web }}</a></div>
        </div>
        <p class="mb-3 text-sm"><strong>Descripción:</strong> {{ seleccionada.descripcion }}</p>
        <div v-if="seleccionada.areas?.length" class="mb-3">
          <p class="detail-label mb-2">Áreas de impacto</p>
          <div class="tags-row">
            <span v-for="a in seleccionada.areas" :key="a.id" class="tag">{{ a.nombre }}</span>
          </div>
        </div>
        <div v-if="seleccionada.motivo_rechazo" class="alert-inline alert-inline--danger">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <span><strong>Motivo:</strong> {{ seleccionada.motivo_rechazo }}</span>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showDetalle = false">Cerrar</button>
        <button v-if="seleccionada?.estado_verificacion === 'PENDIENTE'" class="btn btn-secondary" @click="aprobar(seleccionada); showDetalle = false">Aprobar</button>
        <button v-if="seleccionada?.estado_verificacion === 'PENDIENTE'" class="btn btn-danger" @click="showDetalle = false; pedirMotivo(seleccionada, 'rechazar')">Rechazar</button>
      </template>
    </AppModal>

    <!-- Modal historial -->
    <AppModal v-model="showHistorial" title="Historial de estados">
      <div v-if="loadingHistorial" class="loading-center"><AppSpinner /></div>
      <div v-else-if="historial.length === 0" class="empty-state" style="padding:24px">
        <p class="text-muted">Sin cambios de estado registrados.</p>
      </div>
      <div v-else class="timeline">
        <div v-for="h in historial" :key="h.id" class="timeline-item">
          <div class="timeline-dot"></div>
          <div class="timeline-content">
            <div class="timeline-states">
              <BadgeEstado :estado="h.estado_anterior" tipo="fundacion" />
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14" class="text-muted"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
              <BadgeEstado :estado="h.estado_nuevo" tipo="fundacion" />
              <span class="text-xs text-muted">{{ formatDate(h.fecha) }}</span>
            </div>
            <p v-if="h.motivo" class="text-sm text-muted mt-1">{{ h.motivo }}</p>
            <p class="text-xs text-muted">Por: {{ h.admin?.usuario?.nombre || 'Admin' }}</p>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showHistorial = false">Cerrar</button>
      </template>
    </AppModal>

    <!-- Modal motivo (rechazar / suspender) -->
    <AppModal v-model="showMotivo" :title="accionPendiente === 'rechazar' ? 'Rechazar fundación' : 'Suspender fundación'">
      <AppAlert :message="motivoError" />
      <div class="form-group">
        <label class="form-label">Motivo <span class="required">*</span></label>
        <textarea v-model="motivoTexto" class="form-control" rows="4"
          :placeholder="accionPendiente === 'rechazar' ? 'Describe el motivo del rechazo (mín. 10 caracteres)…' : 'Describe el motivo de la suspensión…'">
        </textarea>
        <span class="char-count">{{ motivoTexto.length }} caracteres</span>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showMotivo = false">Cancelar</button>
        <button class="btn btn-danger" :disabled="accionando" @click="confirmarAccion">
          <AppSpinner v-if="accionando" :small="true" />
          {{ accionPendiente === 'rechazar' ? 'Rechazar' : 'Suspender' }}
        </button>
      </template>
    </AppModal>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const fundaciones  = ref([])
const meta         = ref(null)
const loading      = ref(true)
const successMsg   = ref('')
const errorMsg     = ref('')

const filtros = reactive({ nombre: '', estado: '' })

const showDetalle    = ref(false)
const seleccionada   = ref(null)
const showHistorial  = ref(false)
const historial      = ref([])
const loadingHistorial = ref(false)
const showMotivo     = ref(false)
const motivoTexto    = ref('')
const motivoError    = ref('')
const accionPendiente = ref('')
const fundAccion     = ref(null)
const accionando     = ref(false)

let debounceTimer = null

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function buscarDebounced() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => cargar(1), 400)
}

function limpiarFiltros() {
  filtros.nombre = filtros.estado = ''
  cargar(1)
}

async function cargar(page = 1) {
  loading.value = true
  const params = { page }
  if (filtros.estado) params.estado = filtros.estado
  if (filtros.nombre) params.nombre = filtros.nombre
  try {
    const { data } = await api.get('/admin/fundaciones', { params })
    fundaciones.value = data.data || []
    meta.value        = data.meta || null
  } finally {
    loading.value = false
  }
}

function verDetalle(f) {
  seleccionada.value = f
  showDetalle.value  = true
}

async function verHistorial(f) {
  seleccionada.value   = f
  showHistorial.value  = true
  loadingHistorial.value = true
  historial.value = []
  try {
    const { data } = await api.get(`/admin/fundaciones/${f.id}/historial`)
    historial.value = data
  } finally {
    loadingHistorial.value = false
  }
}

async function aprobar(f) {
  try {
    const { data } = await api.put(`/admin/fundaciones/${f.id}/aprobar`)
    actualizarEnLista(data)
    successMsg.value = `"${f.nombre}" fue aprobada.`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  }
}

async function reactivar(f) {
  try {
    const { data } = await api.put(`/admin/fundaciones/${f.id}/reactivar`)
    actualizarEnLista(data)
    successMsg.value = `"${f.nombre}" fue reactivada.`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  }
}

function pedirMotivo(f, accion) {
  fundAccion.value     = f
  accionPendiente.value = accion
  motivoTexto.value    = ''
  motivoError.value    = ''
  showMotivo.value     = true
}

async function confirmarAccion() {
  motivoError.value = ''
  if (!motivoTexto.value.trim() || motivoTexto.value.trim().length < 10) {
    motivoError.value = 'El motivo debe tener al menos 10 caracteres.'
    return
  }
  accionando.value = true
  try {
    const ruta = `/admin/fundaciones/${fundAccion.value.id}/${accionPendiente.value}`
    const { data } = await api.put(ruta, { motivo: motivoTexto.value })
    actualizarEnLista(data)
    showMotivo.value = false
    successMsg.value = `Acción completada sobre "${fundAccion.value.nombre}".`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    motivoError.value = e.response?.data?.errors?.motivo?.[0] || e.response?.data?.message || 'Error.'
  } finally {
    accionando.value = false
  }
}

function actualizarEnLista(updated) {
  const idx = fundaciones.value.findIndex(f => f.id === updated.id)
  if (idx !== -1) fundaciones.value[idx] = updated
}

onMounted(() => cargar())
</script>

<style scoped>
.admin-page { display: flex; flex-direction: column; gap: 20px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 22px; font-weight: 700; color: var(--gray-900); margin: 0 0 4px; }
.page-subtitle { font-size: 13px; color: var(--gray-500); margin: 0; }

.filter-bar { margin: 0; }
.filter-inner { display: flex; gap: 12px; flex-wrap: wrap; align-items: flex-end; padding: 14px 18px; }
.filter-field { display: flex; flex-direction: column; gap: 4px; min-width: 160px; }
.filter-field.flex-1 { flex: 1; }
.input-icon-wrap { position: relative; }
.input-icon { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: var(--gray-400); width: 15px; height: 15px; }
.pl-icon { padding-left: 34px !important; }

.result-count { font-size: 13px; color: var(--gray-500); margin: 0; }

.action-btns { display: flex; gap: 5px; flex-wrap: wrap; align-items: center; }
.icon-btn {
  display: inline-flex; align-items: center; justify-content: center;
  width: 30px; height: 30px; border-radius: var(--radius);
  border: 1px solid var(--gray-200); background: var(--white);
  color: var(--gray-500); cursor: pointer; transition: all .15s;
}
.icon-btn:hover { border-color: var(--primary); color: var(--primary); background: var(--primary-light); }
.btn-xs { padding: 4px 10px; font-size: 12px; }
.btn-warning { background: var(--warning); color: #fff; border-color: var(--warning); }
.btn-warning:hover:not(:disabled) { background: #b45309; }
.mono { font-family: 'JetBrains Mono', monospace; font-size: 12px; }

.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 14px; }
.detail-item { display: flex; flex-direction: column; gap: 3px; }
.detail-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--gray-400); }
.link { color: var(--primary); font-size: 13px; text-decoration: none; }
.link:hover { text-decoration: underline; }

.tags-row { display: flex; gap: 6px; flex-wrap: wrap; }
.tag { padding: 3px 10px; background: var(--primary-light); color: var(--primary); border-radius: 99px; font-size: 12px; font-weight: 500; }

.alert-inline {
  display: flex; align-items: flex-start; gap: 8px;
  padding: 10px 14px; border-radius: var(--radius); font-size: 13px;
}
.alert-inline--danger { background: var(--danger-light); color: var(--danger); }

.char-count { font-size: 11px; color: var(--gray-400); margin-top: 4px; display: block; }

.timeline { display: flex; flex-direction: column; gap: 16px; padding: 4px 0; }
.timeline-item { display: flex; gap: 14px; }
.timeline-dot { width: 10px; height: 10px; min-width: 10px; background: var(--primary); border-radius: 50%; margin-top: 5px; }
.timeline-content { flex: 1; }
.timeline-states { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
</style>
