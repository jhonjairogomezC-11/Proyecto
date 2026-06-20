<template>
  <div>
    <h1 class="page-title mb-2">Actividades disponibles</h1>
    <p class="page-subtitle mb-6">Explora convocatorias de voluntariado y postúlate a las que más te inspiren.</p>

    <!-- Filtros -->
    <div class="card mb-6">
      <div class="card-body">
        <div class="filters-grid">
          <div class="form-group" style="margin:0">
            <label class="form-label">Buscar</label>
            <input v-model="filtros.buscar" type="text" class="form-control" placeholder="Nombre, fundación o ubicación…" @input="buscarDebounced" />
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
        <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <h3>Sin resultados</h3>
        <p>Prueba con otros filtros o vuelve más tarde.</p>
      </div>

      <div v-else class="pub-grid">
        <div v-for="p in publicaciones" :key="p.id" class="pub-card">
          <div class="pub-img-wrap">
            <ImageCarousel :images="imagenesDe(p)" />
            <button
              :class="['btn-fav', esFavorito(p.id) ? 'active' : '']"
              :title="esFavorito(p.id) ? 'Quitar de favoritos' : 'Agregar a favoritos'"
              @click.stop="toggleFav(p)"
            >
              <svg v-if="esFavorito(p.id)" width="18" height="18" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" style="color: var(--danger);"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
              <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
            </button>
          </div>
          <div class="pub-content">
            <div class="pub-badges">
              <BadgeEstado :estado="p.modalidad" tipo="publicacion" />
              <span v-if="p.categoria" class="badge badge-gray">{{ p.categoria.nombre }}</span>
            </div>
            <h3 class="pub-title">{{ p.titulo }}</h3>
            
            <div class="pub-info-list">
              <p class="pub-info-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/></svg>
                <span>{{ p.fundacion?.nombre }}</span>
              </p>
              <p class="pub-info-item" v-if="p.municipio">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
                <span>{{ p.municipio.nombre }}, {{ p.municipio.departamento?.nombre }}</span>
              </p>
              <p class="pub-info-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                <span>{{ formatDate(p.fecha_inicio) }} – {{ formatDate(p.fecha_fin) }}</span>
              </p>
              <p class="pub-info-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                <span>{{ p.cupo_maximo }} cupos</span>
              </p>
            </div>
            
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
              <button
                v-if="p.fundacion?.id"
                class="btn-fav-fund"
                :class="{ active: esFavFundacion(p.fundacion.id) }"
                :title="esFavFundacion(p.fundacion.id) ? 'Fundación en favoritos' : 'Guardar fundación'"
                @click="toggleFavFundacion(p.fundacion.id)"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/></svg>
                <svg v-if="esFavFundacion(p.fundacion.id)" class="fund-heart" width="10" height="10" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
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
        <div class="modal-carousel mb-4">
          <ImageCarousel :images="imagenesDe(seleccionada)" :autoplay="false" />
        </div>
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
import { reactive, ref, onMounted, onUnmounted } from 'vue'
import { useCatalogosStore } from '@/stores/catalogos'
import { useFavoritosStore } from '@/stores/favoritos'
import { connectEcho, getEcho } from '@/services/echo'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'
import ImageCarousel from '@/components/ImageCarousel.vue'

const catalogos = useCatalogosStore()
const favoritos = useFavoritosStore()

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
const togglingFav       = ref(null)

function imagenesDe(p) {
  if (p?.imagenes?.length) return p.imagenes
  if (p?.imagen) return [p.imagen]
  return []
}

function esFavorito(id) {
  return favoritos.esFavoritoPublicacion(id)
}

function esFavFundacion(id) {
  return favoritos.esFavoritoFundacion(id)
}

async function toggleFav(p) {
  if (togglingFav.value) return
  togglingFav.value = p.id
  try {
    await favoritos.togglePublicacion(p.id)
  } finally {
    togglingFav.value = null
  }
}

async function toggleFavFundacion(id) {
  await favoritos.toggleFundacion(id)
}

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
    if (filtros.buscar)       params.buscar       = filtros.buscar
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
    await api.post('/postulaciones', {
      publicacion_id:     seleccionada.value.id,
      mensaje_voluntario: mensajePostulacion.value || null
    })
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
    catalogos.cargarDepartamentos(),
    favoritos.cargarIds(),
  ])
  await cargar()
  try {
    const { data } = await api.get('/mis-postulaciones', { params: { per_page: 100 } })
    misPostulaciones.value = data.data || []
  } catch {}

  const echo = connectEcho()
  if (echo) {
    echo.channel('convocatorias')
      .listen('.NuevaPublicacion', onNuevaPublicacion)
  }
})

function onNuevaPublicacion() {
  if (!filtros.buscar && !filtros.categoria_id && !filtros.modalidad && (meta.value?.current_page === 1 || !meta.value)) {
    cargar(1)
  }
}

onUnmounted(() => {
  const echo = getEcho()
  if (echo) {
    echo.channel('convocatorias')
      .stopListening('.NuevaPublicacion', onNuevaPublicacion)
  }
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }
.page-subtitle { font-size: 14px; color: var(--gray-500); }
.filters-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; align-items: end; }
.pub-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-bottom: 24px; }
.pub-card {
  background: var(--white);
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-lg);
  overflow: hidden;
  transition: var(--transition);
}
.pub-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-md); }
.pub-img-wrap {
  position: relative;
  height: 180px;
  border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  overflow: hidden;
}
.btn-fav {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 3;
  background: rgba(255,255,255,.9);
  border: none;
  border-radius: 50%;
  width: 38px;
  height: 38px;
  cursor: pointer;
  box-shadow: 0 4px 10px rgba(0,0,0,.08);
  transition: var(--transition);
  display: flex;
  align-items: center;
  justify-content: center;
}
.btn-fav:hover { transform: scale(1.1); }
.btn-fav.active { background: #fff1f2; }
.modal-carousel { height: 220px; border-radius: 12px; overflow: hidden; }
.pub-content { padding: 20px; display: flex; flex-direction: column; gap: 8px; }
.pub-badges { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 4px; }
.pub-title { font-size: 17px; font-weight: 700; color: var(--gray-900); line-height: 1.35; font-family: 'Outfit', sans-serif; }

.pub-info-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 8px 0;
}
.pub-info-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--gray-500);
  font-weight: 500;
}
.pub-info-item svg {
  color: var(--gray-400);
  flex-shrink: 0;
}

.pub-desc { color: var(--gray-600); line-height: 1.6; margin: 4px 0 12px; }
.pub-actions { display: flex; gap: 10px; margin-top: 8px; align-items: center; }

.btn-fav-fund {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: 1px solid var(--gray-200);
  background: transparent;
  color: var(--gray-400);
  cursor: pointer;
  transition: var(--transition);
  position: relative;
}
.btn-fav-fund:hover {
  border-color: var(--primary);
  color: var(--primary);
}
.btn-fav-fund.active {
  border-color: var(--primary);
  background: var(--primary-light);
  color: var(--primary);
}
.fund-heart {
  position: absolute;
  top: -2px;
  right: -2px;
  color: var(--danger);
}

.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
.detail-item { display: flex; flex-direction: column; gap: 2px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); }
.tags-container { display: flex; flex-wrap: wrap; gap: 8px; }
.tag { padding: 4px 12px; border-radius: 99px; font-size: 12px; border: 1.5px solid var(--gray-300); color: var(--gray-600); font-weight: 500; }
.tag.selected { background: var(--primary); color: #fff; border-color: var(--primary); }

.empty-icon {
  margin: 0 auto 12px;
  color: var(--gray-300);
  display: block;
}
</style>
