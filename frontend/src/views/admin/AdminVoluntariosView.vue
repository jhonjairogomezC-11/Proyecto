<template>
  <div>
    <h1 class="page-title mb-2">Gestión de Voluntarios</h1>
    <p class="text-muted text-sm mb-6">Administra el estado y las sanciones de los voluntarios registrados.</p>

    <AppAlert :message="successMsg" type="success" />
    <AppAlert :message="errorMsg" />

    <!-- Filtros -->
    <div class="card mb-6">
      <div class="card-body" style="padding:14px 18px">
        <div style="display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end">
          <div style="flex:1;min-width:180px">
            <label class="form-label">Buscar por nombre</label>
            <input v-model="filtros.nombre" type="text" class="form-control" placeholder="Nombre del voluntario…" @input="buscarDebounced" />
          </div>
          <div>
            <label class="form-label">Estado</label>
            <select v-model="filtros.estado" class="form-control" @change="cargar(1)">
              <option value="">Todos</option>
              <option value="ACTIVO">Activo</option>
              <option value="SUSPENDIDO">Suspendido</option>
              <option value="BLOQUEADO">Bloqueado</option>
            </select>
          </div>
          <button class="btn btn-outline" @click="limpiarFiltros">Limpiar</button>
        </div>
      </div>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <p class="text-sm text-muted mb-3">{{ meta?.total || 0 }} voluntarios encontrados</p>

      <div v-if="voluntarios.length === 0" class="empty-state">
        <div class="icon">👤</div>
        <h3>Sin voluntarios</h3>
        <p>No hay voluntarios que coincidan con los filtros.</p>
      </div>

      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Voluntario</th>
              <th>Documento</th>
              <th>Municipio</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="v in voluntarios" :key="v.id">
              <td>
                <p class="font-medium">{{ v.usuario?.nombre }}</p>
                <p class="text-xs text-muted">{{ v.usuario?.email }}</p>
              </td>
              <td class="text-sm">{{ v.tipo_documento }} {{ v.numero_documento }}</td>
              <td class="text-sm text-muted">{{ v.municipio?.nombre }}</td>
              <td>
                <span :class="['badge', estadoBadge(v.usuario?.estado)]">
                  {{ v.usuario?.estado }}
                </span>
              </td>
              <td>
                <div style="display:flex;gap:5px;flex-wrap:wrap">
                  <button class="btn btn-ghost btn-sm" @click="verPerfil(v)" title="Ver perfil">👁</button>
                  <button class="btn btn-ghost btn-sm" @click="verHistorial(v)" title="Historial">📋</button>
                  <button v-if="v.usuario?.estado === 'ACTIVO'" class="btn btn-warning btn-sm" @click="abrirAccion(v, 'suspender')">⏸ Suspender</button>
                  <button v-if="v.usuario?.estado === 'ACTIVO'" class="btn btn-danger btn-sm" @click="abrirAccion(v, 'bloquear')">🚫 Bloquear</button>
                  <button v-if="['SUSPENDIDO','BLOQUEADO'].includes(v.usuario?.estado)" class="btn btn-secondary btn-sm" @click="reactivar(v)">✓ Reactivar</button>
                  <button class="btn btn-outline btn-sm" @click="abrirAdvertencia(v)">⚠️ Advertencia</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AppPagination :meta="meta" @page="cargar" />
    </template>

    <!-- Modal perfil completo -->
    <AppModal v-model="showPerfil" :title="perfilData?.usuario?.nombre || 'Perfil'">
      <div v-if="loadingPerfil" class="loading-center"><AppSpinner /></div>
      <div v-else-if="perfilData">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Email</span><span>{{ perfilData.usuario?.email }}</span></div>
          <div class="detail-item"><span class="detail-label">Teléfono</span><span>{{ perfilData.usuario?.telefono || '—' }}</span></div>
          <div class="detail-item"><span class="detail-label">Documento</span><span>{{ perfilData.tipo_documento }} {{ perfilData.numero_documento }}</span></div>
          <div class="detail-item"><span class="detail-label">Nacimiento</span><span>{{ perfilData.fecha_nacimiento }}</span></div>
          <div class="detail-item"><span class="detail-label">Municipio</span><span>{{ perfilData.municipio }}, {{ perfilData.departamento }}</span></div>
          <div class="detail-item"><span class="detail-label">Disponibilidad</span><span>{{ perfilData.disponibilidad }}</span></div>
        </div>
        <div class="stats-row mb-4">
          <div class="stat-mini"><span class="stat-num">{{ perfilData.total_participaciones }}</span><span class="stat-lbl">Participaciones</span></div>
          <div class="stat-mini"><span class="stat-num">{{ perfilData.calificacion_promedio }}</span><span class="stat-lbl">Calificación prom.</span></div>
          <div class="stat-mini"><span class="stat-num">{{ perfilData.advertencias_activas }}</span><span class="stat-lbl">Advertencias activas</span></div>
        </div>
        <div v-if="perfilData.habilidades?.length" class="mb-3">
          <p class="detail-label mb-1">Habilidades</p>
          <div style="display:flex;flex-wrap:wrap;gap:6px">
            <span v-for="h in perfilData.habilidades" :key="h" class="badge badge-gray">{{ h }}</span>
          </div>
        </div>
        <div v-if="perfilData.experiencia" class="mb-3">
          <p class="detail-label mb-1">Experiencia</p>
          <p class="text-sm">{{ perfilData.experiencia }}</p>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showPerfil = false">Cerrar</button>
      </template>
    </AppModal>

    <!-- Modal historial -->
    <AppModal v-model="showHistorial" title="Historial del voluntario">
      <div v-if="loadingHistorial" class="loading-center"><AppSpinner /></div>
      <div v-else-if="historial.length === 0" class="empty-state" style="padding:24px">
        <p class="text-muted">Sin actividad registrada.</p>
      </div>
      <div v-else style="display:flex;flex-direction:column;gap:10px">
        <div v-for="(h, i) in historial" :key="i" class="historial-item">
          <span :class="['hist-tipo', `hist-${h.tipo.toLowerCase()}`]">{{ h.tipo }}</span>
          <div style="flex:1">
            <p class="text-sm font-medium">
              <template v-if="h.tipo === 'PARTICIPACION'">
                {{ h.publicacion }} — <BadgeEstado :estado="h.estado" tipo="postulacion" />
              </template>
              <template v-else-if="h.tipo === 'SANCION'">
                {{ h.estado_anterior }} → {{ h.estado_nuevo }}
              </template>
              <template v-else>
                Advertencia emitida
              </template>
            </p>
            <p v-if="h.motivo" class="text-xs text-muted">{{ h.motivo }}</p>
            <p class="text-xs text-muted">{{ formatDate(h.fecha) }}</p>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showHistorial = false">Cerrar</button>
      </template>
    </AppModal>

    <!-- Modal acción (suspender / bloquear) -->
    <AppModal v-model="showAccion" :title="accionTipo === 'suspender' ? 'Suspender voluntario' : 'Bloquear voluntario'">
      <AppAlert :message="accionError" />
      <div class="form-group">
        <label class="form-label">Motivo <span class="required">*</span></label>
        <textarea v-model="accionMotivo" class="form-control" rows="3" placeholder="Describe el motivo…"></textarea>
      </div>
      <div v-if="accionTipo === 'suspender'" class="form-group">
        <label class="form-label">Duración (días, opcional)</label>
        <input v-model.number="accionDias" type="number" min="1" max="365" class="form-control" placeholder="Dejar vacío para indefinido" />
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showAccion = false">Cancelar</button>
        <button class="btn btn-danger" :disabled="accionando" @click="confirmarAccion">
          <AppSpinner v-if="accionando" :small="true" />
          Confirmar
        </button>
      </template>
    </AppModal>

    <!-- Modal advertencia -->
    <AppModal v-model="showAdvertencia" title="Emitir advertencia">
      <AppAlert :message="advError" />
      <div class="form-group">
        <label class="form-label">Motivo de la advertencia <span class="required">*</span></label>
        <textarea v-model="advMotivo" class="form-control" rows="3" placeholder="Describe el motivo de la advertencia…"></textarea>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="showAdvertencia = false">Cancelar</button>
        <button class="btn btn-warning" :disabled="advEnviando" @click="confirmarAdvertencia">
          <AppSpinner v-if="advEnviando" :small="true" />
          Emitir advertencia
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

const voluntarios = ref([])
const meta        = ref(null)
const loading     = ref(true)
const successMsg  = ref('')
const errorMsg    = ref('')
const filtros     = reactive({ nombre: '', estado: '' })

const showPerfil     = ref(false)
const perfilData     = ref(null)
const loadingPerfil  = ref(false)

const showHistorial     = ref(false)
const historial         = ref([])
const loadingHistorial  = ref(false)

const showAccion  = ref(false)
const accionTipo  = ref('')
const accionMotivo = ref('')
const accionDias  = ref(null)
const accionError = ref('')
const accionando  = ref(false)
const volAccion   = ref(null)

const showAdvertencia = ref(false)
const advMotivo       = ref('')
const advError        = ref('')
const advEnviando     = ref(false)
const volAdvertencia  = ref(null)

let debounceTimer = null

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function estadoBadge(estado) {
  return { ACTIVO: 'badge-success', SUSPENDIDO: 'badge-warning', BLOQUEADO: 'badge-danger' }[estado] || 'badge-gray'
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
  console.log('[AdminVoluntarios] cargar() page=', page)
  loading.value = true
  const params = { page }
  if (filtros.estado) params.estado = filtros.estado
  if (filtros.nombre) params.nombre = filtros.nombre
  try {
    const { data } = await api.get('/admin/voluntarios', { params })
    voluntarios.value = data.data || []
    meta.value        = data.meta || null
    console.log('[AdminVoluntarios] cargar() OK, items=', voluntarios.value.length)
  } finally {
    loading.value = false
    console.log('[AdminVoluntarios] cargar() finally done')
  }
}

async function verPerfil(v) {
  showPerfil.value   = true
  loadingPerfil.value = true
  perfilData.value   = null
  try {
    const { data } = await api.get(`/admin/voluntarios/${v.id}`)
    perfilData.value = data
  } finally {
    loadingPerfil.value = false
  }
}

async function verHistorial(v) {
  showHistorial.value    = true
  loadingHistorial.value = true
  historial.value        = []
  try {
    const { data } = await api.get(`/admin/voluntarios/${v.id}/historial`)
    historial.value = data
  } finally {
    loadingHistorial.value = false
  }
}

function abrirAccion(v, tipo) {
  volAccion.value   = v
  accionTipo.value  = tipo
  accionMotivo.value = ''
  accionDias.value  = null
  accionError.value = ''
  showAccion.value  = true
}

async function confirmarAccion() {
  if (!accionMotivo.value.trim()) { accionError.value = 'El motivo es obligatorio.'; return }
  accionando.value = true
  accionError.value = ''
  try {
    const payload = { motivo: accionMotivo.value }
    if (accionTipo.value === 'suspender' && accionDias.value) payload.duracion_dias = accionDias.value
    await api.put(`/admin/voluntarios/${volAccion.value.id}/${accionTipo.value}`, payload)
    await cargar()
    showAccion.value = false
    successMsg.value = `Acción "${accionTipo.value}" aplicada correctamente.`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    accionError.value = e.response?.data?.message || 'Error.'
  } finally {
    accionando.value = false
  }
}

async function reactivar(v) {
  try {
    await api.put(`/admin/voluntarios/${v.id}/reactivar`)
    await cargar()
    successMsg.value = 'Voluntario reactivado correctamente.'
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  }
}

function abrirAdvertencia(v) {
  volAdvertencia.value = v
  advMotivo.value      = ''
  advError.value       = ''
  showAdvertencia.value = true
}

async function confirmarAdvertencia() {
  if (!advMotivo.value.trim()) { advError.value = 'El motivo es obligatorio.'; return }
  advEnviando.value = true
  advError.value    = ''
  try {
    const { data } = await api.post(`/admin/voluntarios/${volAdvertencia.value.id}/advertencias`, {
      motivo: advMotivo.value
    })
    showAdvertencia.value = false
    successMsg.value = `Advertencia emitida. Total activas: ${data.total_activas}`
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    advError.value = e.response?.data?.message || 'Error.'
  } finally {
    advEnviando.value = false
  }
}

onMounted(() => cargar())
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }
.stats-row { display: flex; gap: 16px; }
.stat-mini { display: flex; flex-direction: column; align-items: center; background: var(--gray-50); border: 1px solid var(--gray-200); border-radius: var(--radius); padding: 12px 20px; }
.stat-num { font-size: 24px; font-weight: 700; color: var(--gray-900); }
.stat-lbl { font-size: 11px; color: var(--gray-500); margin-top: 2px; }
.historial-item { display: flex; gap: 10px; padding: 8px 0; border-bottom: 1px solid var(--gray-100); }
.hist-tipo { font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 4px; height: fit-content; flex-shrink: 0; }
.hist-participacion { background: var(--primary-light); color: var(--primary); }
.hist-sancion { background: var(--danger-light); color: var(--danger); }
.hist-advertencia { background: var(--warning-light); color: var(--warning); }
.btn-warning { background: var(--warning); color: #fff; }
.btn-warning:hover:not(:disabled) { background: #b45309; }
</style>
