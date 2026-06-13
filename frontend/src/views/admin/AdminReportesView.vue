<template>
  <div>
    <h1 class="page-title mb-6">Gestión de Reportes</h1>

    <div class="flex gap-3 mb-6 flex-wrap">
      <button v-for="tab in tabs" :key="tab.value" :class="['tab-btn', estadoFiltro === tab.value ? 'active' : '']" @click="cambiarEstado(tab.value)">
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <div v-if="reportes.length === 0" class="empty-state">
        <div class="icon">🚨</div>
        <h3>Sin reportes</h3>
        <p>No hay reportes en este estado.</p>
      </div>

      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Reportante</th>
              <th>Objeto</th>
              <th>Motivo</th>
              <th>Estado</th>
              <th>Fecha</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in reportes" :key="r.id">
              <td class="text-sm">{{ r.reportante?.nombre || 'Anónimo' }}</td>
              <td class="text-sm"><span class="badge badge-gray">{{ r.objeto_tipo }}</span></td>
              <td class="text-sm">{{ motivoLabel(r.motivo) }}</td>
              <td><BadgeEstado :estado="r.estado" tipo="reporte" /></td>
              <td class="text-sm text-muted">{{ formatDate(r.fecha_creacion) }}</td>
              <td>
                <div style="display:flex;gap:6px">
                  <button class="btn btn-ghost btn-sm" @click="verDetalle(r)">👁 Ver</button>
                  <button
                    v-if="['PENDIENTE','EN_REVISION'].includes(r.estado)"
                    class="btn btn-secondary btn-sm"
                    @click="abrirResolucion(r)"
                  >Resolver</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AppPagination :meta="meta" @page="cargar" />
    </template>

    <!-- Modal detalle -->
    <AppModal v-model="showDetalle" title="Detalle del reporte">
      <div v-if="seleccionado">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Motivo</span><span>{{ motivoLabel(seleccionado.motivo) }}</span></div>
          <div class="detail-item"><span class="detail-label">Objeto</span><span>{{ seleccionado.objeto_tipo }}</span></div>
          <div class="detail-item"><span class="detail-label">Estado</span><BadgeEstado :estado="seleccionado.estado" tipo="reporte" /></div>
          <div class="detail-item"><span class="detail-label">Fecha</span><span>{{ formatDate(seleccionado.fecha_creacion) }}</span></div>
        </div>
        <div v-if="seleccionado.detalle" class="mb-4">
          <p class="detail-label mb-1">Descripción</p>
          <p class="text-sm">{{ seleccionado.detalle }}</p>
        </div>
        <div v-if="seleccionado.resolucion" class="alert alert-success">
          <span>✅ Resolución:</span> {{ seleccionado.resolucion }}
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showDetalle = false">Cerrar</button>
      </template>
    </AppModal>

    <!-- Modal resolución -->
    <AppModal v-model="showResolucion" title="Resolver reporte">
      <div class="form-group">
        <label class="form-label">Decisión <span class="required">*</span></label>
        <select v-model="decisionForm.estado" class="form-control">
          <option value="RESUELTO">Resuelto</option>
          <option value="DESESTIMADO">Desestimado</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Descripción de la resolución <span class="required">*</span></label>
        <textarea v-model="decisionForm.resolucion" class="form-control" rows="3" placeholder="Describe qué acción se tomó…"></textarea>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showResolucion = false">Cancelar</button>
        <button class="btn btn-primary" :disabled="resolviendo" @click="resolver">
          <AppSpinner v-if="resolviendo" :small="true" />
          Confirmar
        </button>
      </template>
    </AppModal>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const reportes     = ref([])
const meta         = ref(null)
const loading      = ref(true)
const estadoFiltro = ref('')
const showDetalle  = ref(false)
const seleccionado = ref(null)
const showResolucion = ref(false)
const reportePendiente = ref(null)
const resolviendo  = ref(false)
const decisionForm = reactive({ estado: 'RESUELTO', resolucion: '' })

const tabs = [
  { value: '',           label: 'Todos' },
  { value: 'PENDIENTE',  label: 'Pendientes' },
  { value: 'EN_REVISION',label: 'En revisión' },
  { value: 'RESUELTO',   label: 'Resueltos' },
  { value: 'DESESTIMADO',label: 'Desestimados' },
]

const MOTIVOS = {
  INFORMACION_FALSA:    'Información falsa',
  CONTENIDO_INAPROPIADO:'Contenido inapropiado',
  ACTIVIDAD_SOSPECHOSA: 'Actividad sospechosa',
  PERFIL_SOSPECHOSO:    'Perfil sospechoso',
  OTRO:                 'Otro',
}
function motivoLabel(m) { return MOTIVOS[m] || m }

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function cambiarEstado(e) { estadoFiltro.value = e; cargar(1) }

async function cargar(page = 1) {
  loading.value = true
  const params = { page }
  if (estadoFiltro.value) params.estado = estadoFiltro.value
  try {
    const { data } = await api.get('/admin/reportes', { params })
    reportes.value = data.data || []
    meta.value     = data.meta || null
  } finally { loading.value = false }
}

function verDetalle(r) { seleccionado.value = r; showDetalle.value = true }

function abrirResolucion(r) {
  reportePendiente.value   = r
  decisionForm.estado      = 'RESUELTO'
  decisionForm.resolucion  = ''
  showResolucion.value     = true
}

async function resolver() {
  if (!decisionForm.resolucion.trim()) { alert('La resolución es obligatoria.'); return }
  resolviendo.value = true
  try {
    const { data } = await api.put(`/admin/reportes/${reportePendiente.value.id}/resolver`, decisionForm)
    const idx = reportes.value.findIndex(r => r.id === reportePendiente.value.id)
    if (idx !== -1) reportes.value[idx] = data
    showResolucion.value = false
  } catch (e) {
    alert(e.response?.data?.message || 'Error.')
  } finally { resolviendo.value = false }
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
