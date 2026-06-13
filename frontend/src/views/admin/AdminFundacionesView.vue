<template>
  <div>
    <h1 class="page-title mb-6">Gestión de Fundaciones</h1>

    <!-- Filtros -->
    <div class="flex gap-3 mb-6 flex-wrap">
      <button v-for="tab in tabs" :key="tab.value" :class="['tab-btn', estadoFiltro === tab.value ? 'active' : '']" @click="cambiarEstado(tab.value)">
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <div v-if="fundaciones.length === 0" class="empty-state">
        <div class="icon">🏛️</div>
        <h3>Sin fundaciones</h3>
        <p>No hay fundaciones en este estado.</p>
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
              <td class="text-sm">{{ f.nit }}</td>
              <td class="text-sm">{{ f.representante_legal }}</td>
              <td class="text-sm text-muted">{{ f.municipio?.nombre }}, {{ f.municipio?.departamento?.nombre }}</td>
              <td><BadgeEstado :estado="f.estado_verificacion" tipo="fundacion" /></td>
              <td class="text-sm text-muted">{{ formatDate(f.fecha_creacion) }}</td>
              <td>
                <div style="display:flex;gap:6px;flex-wrap:wrap">
                  <button class="btn btn-ghost btn-sm" @click="verDetalle(f)">👁 Ver</button>
                  <button v-if="f.estado_verificacion === 'PENDIENTE'" class="btn btn-secondary btn-sm" @click="gestionar(f, 'APROBADA')">✓ Aprobar</button>
                  <button v-if="f.estado_verificacion === 'PENDIENTE'" class="btn btn-danger btn-sm" @click="pedirMotivoRec(f, 'RECHAZADA')">✗ Rechazar</button>
                  <button v-if="f.estado_verificacion === 'APROBADA'" class="btn btn-danger btn-sm" @click="pedirMotivoRec(f, 'SUSPENDIDA')">⚠️ Suspender</button>
                  <button v-if="['RECHAZADA','SUSPENDIDA'].includes(f.estado_verificacion)" class="btn btn-outline btn-sm" @click="gestionar(f, 'PENDIENTE')">🔄 Reactivar</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AppPagination :meta="meta" @page="cargar" />
    </template>

    <!-- Modal detalle -->
    <AppModal v-model="showDetalle" :title="seleccionada?.nombre || ''">
      <div v-if="seleccionada">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">NIT</span><span>{{ seleccionada.nit }}</span></div>
          <div class="detail-item"><span class="detail-label">Representante</span><span>{{ seleccionada.representante_legal }}</span></div>
          <div class="detail-item"><span class="detail-label">Teléfono</span><span>{{ seleccionada.telefono }}</span></div>
          <div v-if="seleccionada.correo_institucional" class="detail-item"><span class="detail-label">Correo inst.</span><span>{{ seleccionada.correo_institucional }}</span></div>
          <div class="detail-item"><span class="detail-label">Dirección</span><span>{{ seleccionada.direccion }}</span></div>
          <div class="detail-item"><span class="detail-label">Estado</span><BadgeEstado :estado="seleccionada.estado_verificacion" tipo="fundacion" /></div>
        </div>
        <p class="mb-3"><strong>Descripción:</strong> {{ seleccionada.descripcion }}</p>
        <p v-if="seleccionada.documento_legal" class="mb-3">
          <strong>Documento legal:</strong>
          <a :href="seleccionada.documento_legal" target="_blank" class="btn btn-outline btn-sm ml-2">Ver documento</a>
        </p>
        <div v-if="seleccionada.areas?.length" class="mb-3">
          <strong>Áreas:</strong>
          <div class="tags-container mt-1">
            <span v-for="a in seleccionada.areas" :key="a.id" class="badge badge-primary">{{ a.nombre }}</span>
          </div>
        </div>
        <div v-if="seleccionada.motivo_rechazo" class="alert alert-danger">
          <span>Motivo:</span> {{ seleccionada.motivo_rechazo }}
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showDetalle = false">Cerrar</button>
      </template>
    </AppModal>

    <!-- Modal motivo -->
    <AppModal v-model="showMotivo" :title="accionPendiente === 'RECHAZADA' ? 'Rechazar fundación' : 'Suspender fundación'">
      <div class="form-group">
        <label class="form-label">Motivo <span class="required">*</span></label>
        <textarea v-model="motivoGestion" class="form-control" rows="3" placeholder="Describe el motivo…"></textarea>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showMotivo = false">Cancelar</button>
        <button class="btn btn-danger" :disabled="gestionando" @click="confirmarGestion">
          <AppSpinner v-if="gestionando" :small="true" />
          Confirmar
        </button>
      </template>
    </AppModal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const fundaciones  = ref([])
const meta         = ref(null)
const loading      = ref(true)
const estadoFiltro = ref('')
const showDetalle  = ref(false)
const seleccionada = ref(null)
const showMotivo   = ref(false)
const motivoGestion = ref('')
const accionPendiente = ref('')
const fundPendiente   = ref(null)
const gestionando     = ref(false)

const tabs = [
  { value: '',          label: 'Todas' },
  { value: 'PENDIENTE', label: 'Pendientes' },
  { value: 'APROBADA',  label: 'Aprobadas' },
  { value: 'RECHAZADA', label: 'Rechazadas' },
  { value: 'SUSPENDIDA',label: 'Suspendidas' },
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
  const params = { page }
  if (estadoFiltro.value) params.estado = estadoFiltro.value
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

async function gestionar(f, estado) {
  try {
    const { data } = await api.put(`/admin/fundaciones/${f.id}/gestionar`, { estado })
    const idx = fundaciones.value.findIndex(x => x.id === f.id)
    if (idx !== -1) fundaciones.value[idx] = data
  } catch (e) {
    alert(e.response?.data?.message || 'Error.')
  }
}

function pedirMotivoRec(f, accion) {
  fundPendiente.value   = f
  accionPendiente.value = accion
  motivoGestion.value   = ''
  showMotivo.value      = true
}

async function confirmarGestion() {
  if (!motivoGestion.value.trim()) { alert('El motivo es obligatorio.'); return }
  gestionando.value = true
  try {
    const { data } = await api.put(`/admin/fundaciones/${fundPendiente.value.id}/gestionar`, {
      estado: accionPendiente.value, motivo: motivoGestion.value
    })
    const idx = fundaciones.value.findIndex(x => x.id === fundPendiente.value.id)
    if (idx !== -1) fundaciones.value[idx] = data
    showMotivo.value = false
  } catch (e) {
    alert(e.response?.data?.message || 'Error.')
  } finally {
    gestionando.value = false
  }
}

onMounted(() => cargar())
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.tab-btn { display: inline-flex; align-items: center; gap: 6px; padding: 7px 14px; border-radius: 99px; border: 1.5px solid var(--gray-300); background: var(--white); font-size: 13px; font-weight: 500; cursor: pointer; color: var(--gray-700); transition: all .18s; }
.tab-btn:hover  { border-color: var(--primary); color: var(--primary); }
.tab-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }
.tags-container { display: flex; flex-wrap: wrap; gap: 8px; }
.ml-2 { margin-left: 8px; }
</style>
