<template>
  <div class="admin-page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Gestión de Reportes</h1>
        <p class="page-subtitle">Revisa y resuelve los reportes enviados por la comunidad.</p>
      </div>
    </div>

    <!-- Tab bar -->
    <div class="tab-bar">
      <button v-for="tab in tabs" :key="tab.value"
        :class="['tab-btn', estadoFiltro === tab.value ? 'active' : '']"
        @click="cambiarEstado(tab.value)">
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <div v-if="reportes.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="40" height="40"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
        </div>
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
              <td class="text-sm font-medium">{{ r.reportante?.nombre || 'Anónimo' }}</td>
              <td class="text-sm"><span class="objeto-badge">{{ r.objeto_tipo }}</span></td>
              <td class="text-sm">{{ motivoLabel(r.motivo) }}</td>
              <td><BadgeEstado :estado="r.estado" tipo="reporte" /></td>
              <td class="text-sm text-muted">{{ formatDate(r.fecha_creacion) }}</td>
              <td>
                <div class="action-btns">
                  <button class="icon-btn" @click="verDetalle(r)" title="Ver detalle">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  </button>
                  <button
                    v-if="['PENDIENTE','EN_REVISION'].includes(r.estado)"
                    class="btn btn-secondary btn-xs"
                    @click="abrirResolucion(r)">
                    Resolver
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
    <AppModal v-model="showDetalle" title="Detalle del reporte">
      <div v-if="seleccionado">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Motivo</span><span>{{ motivoLabel(seleccionado.motivo) }}</span></div>
          <div class="detail-item"><span class="detail-label">Objeto</span><span class="objeto-badge">{{ seleccionado.objeto_tipo }}</span></div>
          <div class="detail-item"><span class="detail-label">Estado</span><BadgeEstado :estado="seleccionado.estado" tipo="reporte" /></div>
          <div class="detail-item"><span class="detail-label">Fecha</span><span>{{ formatDate(seleccionado.fecha_creacion) }}</span></div>
        </div>
        <div v-if="seleccionado.detalle" class="mb-4">
          <p class="detail-label mb-1">Descripción</p>
          <p class="text-sm">{{ seleccionado.detalle }}</p>
        </div>
        <div v-if="seleccionado.resolucion" class="alert-inline alert-inline--success">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><polyline points="20 6 9 17 4 12"/></svg>
          <span><strong>Resolución:</strong> {{ seleccionado.resolucion }}</span>
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
  { value: '',            label: 'Todos' },
  { value: 'PENDIENTE',   label: 'Pendientes' },
  { value: 'EN_REVISION', label: 'En revisión' },
  { value: 'RESUELTO',    label: 'Resueltos' },
  { value: 'DESESTIMADO', label: 'Desestimados' },
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
  if (!decisionForm.resolucion.trim()) { return }
  resolviendo.value = true
  try {
    const { data } = await api.put(`/admin/reportes/${reportePendiente.value.id}/resolver`, decisionForm)
    const idx = reportes.value.findIndex(r => r.id === reportePendiente.value.id)
    if (idx !== -1) reportes.value[idx] = data
    showResolucion.value = false
  } catch (e) {
    console.error(e)
  } finally { resolviendo.value = false }
}

onMounted(() => cargar())
</script>

<style scoped>
.admin-page { display: flex; flex-direction: column; gap: 20px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 22px; font-weight: 700; color: var(--gray-900); margin: 0 0 4px; }
.page-subtitle { font-size: 13px; color: var(--gray-500); margin: 0; }

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

.objeto-badge {
  display: inline-block; padding: 2px 8px;
  background: var(--gray-100); color: var(--gray-700);
  border-radius: 4px; font-size: 11px; font-weight: 600;
  text-transform: uppercase; letter-spacing: .04em;
}

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

.alert-inline {
  display: flex; align-items: flex-start; gap: 8px;
  padding: 10px 14px; border-radius: var(--radius); font-size: 13px;
}
.alert-inline--success { background: #d1fae5; color: #065f46; }
</style>
