<template>
  <div>
    <h1 class="page-title mb-6">Convocatorias disponibles</h1>

    <!-- Filtros -->
    <div class="card mb-6">
      <div class="card-body">
        <div class="filters-grid">
          <div class="form-group" style="margin:0">
            <label class="form-label">Buscar</label>
            <input v-model="filtros.buscar" type="text" class="form-control" placeholder="Título o fundación…" @input="buscarDebounced" />
          </div>
          <div class="form-group" style="margin:0">
            <label class="form-label">Área de impacto</label>
            <select v-model="filtros.categoria_id" class="form-control" @change="cargar(1)">
              <option value="">Todas las áreas</option>
              <option v-for="a in catalogos.areasImpacto" :key="a.id" :value="a.id">{{ a.nombre }}</option>
            </select>
          </div>
          <div class="form-group" style="margin:0">
            <label class="form-label">Modalidad</label>
            <select v-model="filtros.modalidad" class="form-control" @change="cargar(1)">
              <option value="">Todas</option>
              <option value="PRESENCIAL">Presencial</option>
              <option value="VIRTUAL">Virtual</option>
              <option value="HIBRIDA">Híbrida</option>
            </select>
          </div>
          <div class="form-group" style="margin:0">
            <label class="form-label">Departamento</label>
            <select v-model="filtros.departamento_id" class="form-control" @change="onDeptFiltro">
              <option value="">Todos</option>
              <option v-for="d in catalogos.departamentos" :key="d.id" :value="d.id">{{ d.nombre }}</option>
            </select>
          </div>
          <div class="form-group" style="margin:0">
            <label class="form-label">Municipio</label>
            <select v-model="filtros.municipio_id" class="form-control" @change="cargar(1)" :disabled="!filtros.departamento_id">
              <option value="">Todos</option>
              <option v-for="m in municipiosFiltro" :key="m.id" :value="m.id">{{ m.nombre }}</option>
            </select>
          </div>
          <div style="display:flex;align-items:flex-end">
            <button class="btn btn-outline btn-full" @click="limpiarFiltros">Limpiar</button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <p class="text-sm text-muted mb-4" v-if="meta">{{ meta.total }} convocatoria{{ meta.total !== 1 ? 's' : '' }} encontrada{{ meta.total !== 1 ? 's' : '' }}</p>

      <div v-if="publicaciones.length === 0" class="empty-state">
        <div class="icon">🔍</div>
        <h3>Sin resultados</h3>
        <p>Prueba con otros filtros o vuelve más tarde.</p>
      </div>

      <div v-else class="pub-grid">
        <div v-for="p in publicaciones" :key="p.id" class="pub-card">
          <div class="pub-img" :style="p.imagen ? `background-image:url(${p.imagen})` : ''">
            <span v-if="!p.imagen" class="pub-img-placeholder">🤝</span>
          </div>
          <div class="pub-content">
            <div class="pub-badges">
              <BadgeEstado :estado="p.modalidad" tipo="publicacion" />
              <span v-if="p.categoria" class="badge badge-gray">{{ p.categoria.nombre }}</span>
            </div>
            <h3 class="pub-title">{{ p.titulo }}</h3>
            <p class="text-sm text-muted">🏢 {{ p.fundacion?.nombre }}</p>
            <p class="text-sm text-muted" v-if="p.municipio">📍 {{ p.municipio.nombre }}, {{ p.municipio.departamento?.nombre }}</p>
            <p class="text-sm text-muted">📅 {{ formatDate(p.fecha_inicio) }} – {{ formatDate(p.fecha_fin) }}</p>
            <p class="text-sm text-muted">👥 {{ p.cupo_maximo }} cupos</p>
            <p class="pub-desc text-sm">{{ p.descripcion?.slice(0, 120) }}{{ p.descripcion?.length > 120 ? '…' : '' }}</p>
            <div class="pub-actions">
              <button class="btn btn-primary btn-sm" @click="abrirDetalle(p)">Ver detalles</button>
              <button
                class="btn btn-outline btn-sm"
                :disabled="!!yaPostulado(p.id) || postulando === p.id"
                @click="postularse(p)"
              >
                <AppSpinner v-if="postulando === p.id" :small="true" />
                <span v-else-if="yaPostulado(p.id)">✓ Postulado</span>
                <span v-else>Postularme</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <AppPagination :meta="meta" @page="cargar" />
    </template>

    <!-- Modal detalle -->
    <AppModal v-model="showDetalle" :title="seleccionada?.titulo || ''">
      <div v-if="seleccionada">
        <div class="detail-grid mb-4">
          <div class="detail-item"><span class="detail-label">Fundación</span><span>{{ seleccionada.fundacion?.nombre }}</span></div>
          <div class="detail-item"><span class="detail-label">Modalidad</span><span>{{ seleccionada.modalidad }}</span></div>
          <div class="detail-item"><span class="detail-label">Inicio</span><span>{{ formatDate(seleccionada.fecha_inicio) }}</span></div>
          <div class="detail-item"><span class="detail-label">Fin</span><span>{{ formatDate(seleccionada.fecha_fin) }}</span></div>
          <div v-if="seleccionada.hora_inicio" class="detail-item"><span class="detail-label">Horario</span><span>{{ seleccionada.hora_inicio }} – {{ seleccionada.hora_fin }}</span></div>
          <div class="detail-item"><span class="detail-label">Cupos</span><span>{{ seleccionada.cupo_maximo }}</span></div>
          <div v-if="seleccionada.municipio" class="detail-item"><span class="detail-label">Lugar</span><span>{{ seleccionada.municipio.nombre }}, {{ seleccionada.municipio.departamento?.nombre }}</span></div>
          <div v-if="seleccionada.direccion_exacta" class="detail-item"><span class="detail-label">Dirección</span><span>{{ seleccionada.direccion_exacta }}</span></div>
          <div v-if="seleccionada.enlace_virtual" class="detail-item"><span class="detail-label">Enlace</span><a :href="seleccionada.enlace_virtual" target="_blank">Ver enlace</a></div>
          <div v-if="seleccionada.edad_minima || seleccionada.edad_maxima" class="detail-item">
            <span class="detail-label">Edad</span>
            <span>{{ seleccionada.edad_minima || '—' }} – {{ seleccionada.edad_maxima || '—' }} años</span>
          </div>
        </div>
        <p class="mb-4"><strong>Descripción:</strong> {{ seleccionada.descripcion }}</p>
        <div v-if="seleccionada.requisitos_adicionales" class="mb-4">
          <strong>Requisitos:</strong> {{ seleccionada.requisitos_adicionales }}
        </div>
        <div v-if="seleccionada.habilidades?.length" class="mb-4">
          <strong>Habilidades requeridas:</strong>
          <div class="tags-container mt-2">
            <span v-for="h in seleccionada.habilidades" :key="h.id" class="tag selected">{{ h.nombre }}</span>
          </div>
        </div>
        <div v-if="seleccionada.contacto_nombre || seleccionada.contacto_email" class="mb-4">
          <strong>Contacto:</strong> {{ seleccionada.contacto_nombre }}
          <span v-if="seleccionada.contacto_email"> · {{ seleccionada.contacto_email }}</span>
          <span v-if="seleccionada.contacto_telefono"> · {{ seleccionada.contacto_telefono }}</span>
        </div>

        <AppAlert :message="errorPostular" />
        <AppAlert :message="successPostular" type="success" />

        <div v-if="!yaPostulado(seleccionada.id)" class="form-group">
          <label class="form-label">Mensaje (opcional)</label>
          <textarea v-model="mensajePostulacion" class="form-control" rows="3" placeholder="¿Por qué quieres participar?"></textarea>
        </div>
      </div>

      <template #footer>
        <button class="btn btn-outline" @click="showDetalle = false">Cerrar</button>
        <button
          v-if="seleccionada && !yaPostulado(seleccionada.id)"
          class="btn btn-primary"
          :disabled="postulando === seleccionada?.id"
          @click="confirmarPostulacion"
        >
          <AppSpinner v-if="postulando === seleccionada?.id" :small="true" />
          Confirmar postulación
        </button>
        <span v-else-if="seleccionada && yaPostulado(seleccionada.id)" class="badge badge-success">✓ Ya estás postulado</span>
      </template>
    </AppModal>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useCatalogosStore } from '@/stores/catalogos'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const catalogos = useCatalogosStore()

const publicaciones     = ref([])
const misPostulaciones  = ref([])
const meta              = ref(null)
const loading           = ref(true)
const postulando        = ref(null)
const showDetalle       = ref(false)
const seleccionada      = ref(null)
const mensajePostulacion = ref('')
const errorPostular     = ref('')
const successPostular   = ref('')
const municipiosFiltro  = ref([])

const filtros = reactive({ buscar: '', categoria_id: '', modalidad: '', departamento_id: '', municipio_id: '' })
let debounceTimer = null

function buscarDebounced() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => cargar(1), 400)
}

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function yaPostulado(id) {
  return misPostulaciones.value.find(p => {
    const pubId = p.publicacion?.id || p.publicacion_id
    const estado = typeof p.estado === 'object' ? p.estado?.value : p.estado
    return pubId === id && !['RETIRADO', 'RECHAZADO'].includes(estado)
  })
}

async function onDeptFiltro() {
  filtros.municipio_id = ''
  if (!filtros.departamento_id) { municipiosFiltro.value = []; cargar(1); return }
  const data = await catalogos.cargarMunicipios(filtros.departamento_id)
  municipiosFiltro.value = data
  cargar(1)
}

function limpiarFiltros() {
  filtros.buscar = filtros.categoria_id = filtros.modalidad = filtros.departamento_id = filtros.municipio_id = ''
  municipiosFiltro.value = []
  cargar(1)
}

async function cargar(page = 1) {
  loading.value = true
  try {
    const params = { page }
    if (filtros.categoria_id) params.categoria_id = filtros.categoria_id
    if (filtros.modalidad)    params.modalidad    = filtros.modalidad
    if (filtros.municipio_id) params.municipio_id = filtros.municipio_id
    const { data } = await api.get('/publicaciones', { params })
    publicaciones.value = data.data || []
    meta.value          = data.meta || null
  } finally {
    loading.value = false
  }
}

function abrirDetalle(pub) {
  seleccionada.value      = pub
  mensajePostulacion.value = ''
  errorPostular.value     = ''
  successPostular.value   = ''
  showDetalle.value       = true
}

async function postularse(pub) {
  seleccionada.value = pub
  mensajePostulacion.value = ''
  errorPostular.value = ''
  successPostular.value = ''
  showDetalle.value = true
}

async function confirmarPostulacion() {
  if (!seleccionada.value) return
  postulando.value    = seleccionada.value.id
  errorPostular.value = ''
  try {
    const { data } = await api.post('/postulaciones', {
      publicacion_id:     seleccionada.value.id,
      mensaje_voluntario: mensajePostulacion.value || null
    })
    // Recargar lista completa para sincronizar estado real
    const resp = await api.get('/mis-postulaciones', { params: { per_page: 100 } })
    misPostulaciones.value = resp.data.data || []
    successPostular.value = '¡Te has postulado exitosamente!'
  } catch (e) {
    errorPostular.value = e.response?.data?.errors?.publicacion_id?.[0] || e.response?.data?.message || 'Error al postularse.'
  } finally {
    postulando.value = null
  }
}

onMounted(async () => {
  await Promise.all([
    catalogos.cargarAreasImpacto(),
    catalogos.cargarDepartamentos()
  ])
  await cargar()
  try {
    const { data } = await api.get('/mis-postulaciones', { params: { per_page: 100 } })
    misPostulaciones.value = data.data || []
  } catch {}
})
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.filters-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; align-items: end; }
.pub-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-bottom: 24px; }
.pub-card { background: var(--white); border: 1px solid var(--gray-200); border-radius: var(--radius-lg); overflow: hidden; transition: box-shadow .18s; }
.pub-card:hover { box-shadow: var(--shadow-md); }
.pub-img {
  height: 140px;
  background: linear-gradient(135deg, #2563eb, #059669);
  background-size: cover;
  background-position: center;
  display: flex; align-items: center; justify-content: center;
}
.pub-img-placeholder { font-size: 42px; }
.pub-content { padding: 16px; display: flex; flex-direction: column; gap: 6px; }
.pub-badges { display: flex; gap: 6px; flex-wrap: wrap; }
.pub-title { font-size: 16px; font-weight: 600; color: var(--gray-800); line-height: 1.3; }
.pub-desc { color: var(--gray-600); line-height: 1.5; margin-top: 4px; }
.pub-actions { display: flex; gap: 8px; margin-top: 8px; }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }
.tags-container { display: flex; flex-wrap: wrap; gap: 8px; }
.tag { padding: 4px 10px; border-radius: 99px; font-size: 12px; border: 1.5px solid var(--gray-300); color: var(--gray-600); }
.tag.selected { background: var(--primary); color: #fff; border-color: var(--primary); }
</style>
