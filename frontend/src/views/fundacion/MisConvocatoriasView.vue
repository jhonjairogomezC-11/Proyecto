<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="page-title">Mis Convocatorias</h1>
      <button class="btn btn-primary" @click="abrirFormulario(null)">+ Nueva convocatoria</button>
    </div>

    <AppAlert :message="successMsg" type="success" />
    <AppAlert :message="errorMsg" />

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <div v-if="publicaciones.length === 0" class="empty-state">
        <div class="icon">📢</div>
        <h3>Sin convocatorias</h3>
        <p>Crea tu primera convocatoria para comenzar a recibir voluntarios.</p>
        <button class="btn btn-primary mt-4" @click="abrirFormulario(null)">Crear convocatoria</button>
      </div>

      <div v-else>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Título</th>
                <th>Modalidad</th>
                <th>Fechas</th>
                <th>Cupos</th>
                <th>Estado</th>
                <th>Postulantes</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="p in publicaciones" :key="p.id">
                <td>
                  <p class="font-medium">{{ p.titulo }}</p>
                  <p class="text-xs text-muted">{{ p.categoria?.nombre }}</p>
                </td>
                <td class="text-sm">{{ p.modalidad }}</td>
                <td class="text-sm text-muted">
                  {{ formatDate(p.fecha_inicio) }}<br>{{ formatDate(p.fecha_fin) }}
                </td>
                <td class="text-sm">{{ p.cupo_maximo }}</td>
                <td><BadgeEstado :estado="p.estado" tipo="publicacion" /></td>
                <td>
                  <button class="btn btn-ghost btn-sm" @click="verPostulantes(p)">
                    Ver postulantes
                  </button>
                </td>
                <td>
                  <div style="display:flex;gap:6px">
                    <button class="btn btn-ghost btn-sm" @click="abrirFormulario(p)" title="Editar">✏️</button>
                    <button
                      v-if="p.estado === 'BORRADOR'"
                      class="btn btn-secondary btn-sm"
                      :disabled="publicando === p.id"
                      @click="publicar(p)"
                      title="Enviar a revisión del administrador"
                    >
                      <AppSpinner v-if="publicando === p.id" :small="true" />
                      <span v-else>📤 Enviar a revisión</span>
                    </button>
                    <span v-if="p.estado === 'PENDIENTE_APROBACION'" class="badge badge-warning" style="font-size:11px">⏳ En revisión</span>
                    <button
                      v-if="!['CANCELADA','FINALIZADA','PENDIENTE_APROBACION'].includes(p.estado)"
                      class="btn btn-danger btn-sm"
                      @click="cancelar(p)"
                      title="Cancelar"
                    >Cancelar</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <AppPagination :meta="meta" @page="cargar" />
      </div>
    </template>

    <!-- Modal formulario convocatoria -->
    <AppModal v-model="showForm" :title="editando ? 'Editar convocatoria' : 'Nueva convocatoria'">
      <AppAlert :message="formError" />
      <form @submit.prevent="guardarConvocatoria" novalidate>
        <div class="form-group">
          <label class="form-label">Título <span class="required">*</span></label>
          <input v-model="form.titulo" type="text" class="form-control" :class="{ error: formErrors.titulo }" />
          <span v-if="formErrors.titulo" class="form-error">{{ formErrors.titulo }}</span>
        </div>
        <div class="form-group">
          <label class="form-label">Descripción <span class="required">*</span></label>
          <textarea v-model="form.descripcion" class="form-control" rows="3" :class="{ error: formErrors.descripcion }"></textarea>
          <span v-if="formErrors.descripcion" class="form-error">{{ formErrors.descripcion }}</span>
        </div>
        <div class="grid grid-2">
          <div class="form-group">
            <label class="form-label">Área de impacto <span class="required">*</span></label>
            <select v-model="form.categoria_id" class="form-control" :class="{ error: formErrors.categoria_id }">
              <option value="">Seleccionar…</option>
              <option v-for="a in catalogos.areasImpacto" :key="a.id" :value="a.id">{{ a.nombre }}</option>
            </select>
            <span v-if="formErrors.categoria_id" class="form-error">{{ formErrors.categoria_id }}</span>
          </div>
          <div class="form-group">
            <label class="form-label">Modalidad <span class="required">*</span></label>
            <select v-model="form.modalidad" class="form-control" :class="{ error: formErrors.modalidad }">
              <option value="">Seleccionar…</option>
              <option value="PRESENCIAL">Presencial</option>
              <option value="VIRTUAL">Virtual</option>
              <option value="HIBRIDA">Híbrida</option>
            </select>
            <span v-if="formErrors.modalidad" class="form-error">{{ formErrors.modalidad }}</span>
          </div>
          <div v-if="form.modalidad !== 'VIRTUAL'" class="form-group">
            <label class="form-label">Departamento <span class="required">*</span></label>
            <select v-model="formDept" class="form-control" @change="onFormDeptChange">
              <option value="">Seleccionar…</option>
              <option v-for="d in catalogos.departamentos" :key="d.id" :value="d.id">{{ d.nombre }}</option>
            </select>
          </div>
          <div v-if="form.modalidad !== 'VIRTUAL'" class="form-group">
            <label class="form-label">Municipio <span class="required">*</span></label>
            <select v-model="form.municipio_id" class="form-control" :class="{ error: formErrors.municipio_id }" :disabled="!formDept">
              <option value="">Seleccionar…</option>
              <option v-for="m in formMunicipios" :key="m.id" :value="m.id">{{ m.nombre }}</option>
            </select>
            <span v-if="formErrors.municipio_id" class="form-error">{{ formErrors.municipio_id }}</span>
          </div>
          <div class="form-group">
            <label class="form-label">Fecha inicio <span class="required">*</span></label>
            <input v-model="form.fecha_inicio" type="date" class="form-control" :class="{ error: formErrors.fecha_inicio }" />
            <span v-if="formErrors.fecha_inicio" class="form-error">{{ formErrors.fecha_inicio }}</span>
          </div>
          <div class="form-group">
            <label class="form-label">Fecha fin <span class="required">*</span></label>
            <input v-model="form.fecha_fin" type="date" class="form-control" :class="{ error: formErrors.fecha_fin }" />
            <span v-if="formErrors.fecha_fin" class="form-error">{{ formErrors.fecha_fin }}</span>
          </div>
          <div class="form-group">
            <label class="form-label">Hora inicio</label>
            <input v-model="form.hora_inicio" type="time" class="form-control" />
          </div>
          <div class="form-group">
            <label class="form-label">Hora fin</label>
            <input v-model="form.hora_fin" type="time" class="form-control" />
          </div>
          <div class="form-group">
            <label class="form-label">Cupo máximo <span class="required">*</span></label>
            <input v-model.number="form.cupo_maximo" type="number" min="1" class="form-control" :class="{ error: formErrors.cupo_maximo }" />
            <span v-if="formErrors.cupo_maximo" class="form-error">{{ formErrors.cupo_maximo }}</span>
          </div>
          <div class="form-group">
            <label class="form-label">Edad mínima</label>
            <input v-model.number="form.edad_minima" type="number" min="14" class="form-control" />
          </div>
          <div class="form-group">
            <label class="form-label">Edad máxima</label>
            <input v-model.number="form.edad_maxima" type="number" class="form-control" />
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Dirección exacta</label>
          <input v-model="form.direccion_exacta" type="text" class="form-control" />
        </div>
        <div v-if="form.modalidad !== 'PRESENCIAL'" class="form-group">
          <label class="form-label">Enlace virtual</label>
          <input v-model="form.enlace_virtual" type="text" class="form-control" placeholder="https://meet.google.com/..." />
        </div>
        <div class="form-group">
          <label class="form-label">Requisitos adicionales</label>
          <textarea v-model="form.requisitos_adicionales" class="form-control" rows="2"></textarea>
        </div>
        <div class="form-group">
          <label class="form-label">Habilidades requeridas</label>
          <div class="tags-container">
            <label v-for="h in catalogos.habilidades" :key="h.id" :class="['tag', form.habilidades.includes(h.id) ? 'selected' : '']">
              <input type="checkbox" :value="h.id" v-model="form.habilidades" style="display:none" />
              {{ h.nombre }}
            </label>
          </div>
        </div>
      </form>
      <template #footer>
        <button class="btn btn-outline" @click="showForm = false">Cancelar</button>
        <button class="btn btn-primary" :disabled="guardando" @click="guardarConvocatoria">
          <AppSpinner v-if="guardando" :small="true" />
          {{ guardando ? 'Guardando…' : 'Guardar' }}
        </button>
      </template>
    </AppModal>

    <!-- Modal postulantes -->
    <AppModal v-model="showPostulantes" :title="`Postulantes: ${pubSeleccionada?.titulo || ''}`">
      <div v-if="loadingPostulantes" class="loading-center"><AppSpinner /></div>
      <div v-else-if="postulantes.length === 0" class="empty-state">
        <div class="icon">👥</div>
        <h3>Sin postulantes</h3>
        <p>Aún no hay voluntarios postulados.</p>
      </div>
      <div v-else>
        <div v-for="p in postulantes" :key="p.id" class="postulante-card">
          <div class="postulante-info">
            <div class="mini-avatar">{{ p.voluntario?.usuario?.nombre?.charAt(0).toUpperCase() }}</div>
            <div>
              <p class="font-medium text-sm">{{ p.voluntario?.usuario?.nombre }}</p>
              <p class="text-xs text-muted">{{ p.voluntario?.usuario?.email }}</p>
              <p class="text-xs text-muted" v-if="p.mensaje_voluntario">💬 {{ p.mensaje_voluntario }}</p>
            </div>
          </div>
          <div style="display:flex;align-items:center;gap:8px">
            <BadgeEstado :estado="p.estado" tipo="postulacion" />
            <div v-if="p.estado === 'PENDIENTE'" style="display:flex;gap:4px">
              <button class="btn btn-secondary btn-sm" :disabled="respondiendo === p.id" @click="responder(p, 'ACEPTADO')">
                <AppSpinner v-if="respondiendo === p.id + '_A'" :small="true" />
                <span v-else>✓</span>
              </button>
              <button class="btn btn-danger btn-sm" :disabled="respondiendo === p.id" @click="pedirMotivo(p)">✗</button>
            </div>
            <div v-if="p.estado === 'ACEPTADO'" style="display:flex;gap:4px">
              <button class="btn btn-primary btn-sm" @click="confirmarAsistencia(p, true)">✓ Asistió</button>
              <button class="btn btn-outline btn-sm" @click="confirmarAsistencia(p, false)">✗ No asistió</button>
            </div>
          </div>
        </div>
        <AppPagination :meta="metaPost" @page="cargarPostulantes(pubSeleccionada, $event)" />
      </div>

      <!-- Modal rechazo -->
      <AppModal v-model="showMotivoRechazo" title="Motivo de rechazo">
        <div class="form-group">
          <label class="form-label">Motivo <span class="required">*</span></label>
          <textarea v-model="motivoRechazo" class="form-control" rows="3" placeholder="Explica el motivo del rechazo…"></textarea>
        </div>
        <template #footer>
          <button class="btn btn-outline" @click="showMotivoRechazo = false">Cancelar</button>
          <button class="btn btn-danger" @click="confirmarRechazo">Rechazar</button>
        </template>
      </AppModal>

      <!-- Modal calificación -->
      <AppModal v-model="showCalificacion" title="Registrar asistencia y calificación">
        <div class="form-group">
          <label class="form-label">Calificación (1–5) <span class="required">*</span></label>
          <div style="display:flex;gap:8px">
            <button
              v-for="n in 5" :key="n"
              type="button"
              :class="['btn', form.calificacion >= n ? 'btn-primary' : 'btn-outline']"
              @click="form.calificacion = n"
            >⭐ {{ n }}</button>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Comentario</label>
          <textarea v-model="form.comentario_fundacion" class="form-control" rows="3"></textarea>
        </div>
        <template #footer>
          <button class="btn btn-outline" @click="showCalificacion = false">Cancelar</button>
          <button class="btn btn-primary" :disabled="confirmandoAsist" @click="enviarAsistencia">
            <AppSpinner v-if="confirmandoAsist" :small="true" />
            Confirmar
          </button>
        </template>
      </AppModal>
    </AppModal>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted, onUnmounted } from 'vue'
import { useCatalogosStore } from '@/stores/catalogos'
import { useAuthStore } from '@/stores/auth'
import { connectEcho, getEcho } from '@/services/echo'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import AppModal from '@/components/AppModal.vue'
import AppPagination from '@/components/AppPagination.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const catalogos = useCatalogosStore()
const auth      = useAuthStore()

const publicaciones    = ref([])
const meta             = ref(null)
const loading          = ref(true)
const successMsg       = ref('')
const errorMsg         = ref('')

// Formulario nueva/editar
const showForm         = ref(false)
const editando         = ref(null)
const guardando        = ref(false)
const formError        = ref('')
const formErrors       = reactive({})
const formDept         = ref('')
const formMunicipios   = ref([])

const defaultForm = () => ({
  titulo: '', descripcion: '', categoria_id: '', modalidad: '',
  municipio_id: '', direccion_exacta: '', enlace_virtual: '',
  fecha_inicio: '', fecha_fin: '', hora_inicio: '', hora_fin: '',
  cupo_maximo: 1, edad_minima: null, edad_maxima: null,
  requisitos_adicionales: '', habilidades: []
})
const form = reactive(defaultForm())

// Postulantes
const showPostulantes     = ref(false)
const pubSeleccionada     = ref(null)
const postulantes         = ref([])
const metaPost            = ref(null)
const loadingPostulantes  = ref(false)
const respondiendo        = ref(null)
const showMotivoRechazo   = ref(false)
const motivoRechazo       = ref('')
const postPendiente       = ref(null)
const showCalificacion    = ref(false)
const postAsistencia      = ref(null)
const asistioVal          = ref(null)
const confirmandoAsist    = ref(false)
const publicando          = ref(null)

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

async function onFormDeptChange() {
  form.municipio_id = ''
  if (!formDept.value) { formMunicipios.value = []; return }
  const data = await catalogos.cargarMunicipios(formDept.value)
  formMunicipios.value = data
}

function abrirFormulario(pub) {
  Object.assign(form, defaultForm())
  formDept.value = ''
  formMunicipios.value = []
  Object.keys(formErrors).forEach(k => delete formErrors[k])
  formError.value = ''
  if (pub) {
    editando.value = pub
    Object.assign(form, {
      titulo: pub.titulo, descripcion: pub.descripcion,
      categoria_id: pub.categoria?.id || '', modalidad: pub.modalidad,
      municipio_id: pub.municipio?.id || '', direccion_exacta: pub.direccion_exacta || '',
      enlace_virtual: pub.enlace_virtual || '', fecha_inicio: pub.fecha_inicio,
      fecha_fin: pub.fecha_fin, hora_inicio: pub.hora_inicio || '',
      hora_fin: pub.hora_fin || '', cupo_maximo: pub.cupo_maximo,
      edad_minima: pub.edad_minima, edad_maxima: pub.edad_maxima,
      requisitos_adicionales: pub.requisitos_adicionales || '',
      habilidades: (pub.habilidades || []).map(h => h.id)
    })
    if (pub.municipio?.departamento) {
      formDept.value = pub.municipio.departamento.id
      formMunicipios.value = [pub.municipio]
    }
  } else {
    editando.value = null
  }
  showForm.value = true
}

async function guardarConvocatoria() {
  Object.keys(formErrors).forEach(k => delete formErrors[k])
  formError.value = ''
  const payload = { ...form }
  if (payload.modalidad === 'VIRTUAL') payload.municipio_id = null
  if (!payload.edad_minima) delete payload.edad_minima
  if (!payload.edad_maxima) delete payload.edad_maxima
  guardando.value = true
  try {
    let data
    if (editando.value) {
      const res = await api.put(`/publicaciones/${editando.value.id}`, payload)
      data = res.data
      const idx = publicaciones.value.findIndex(p => p.id === editando.value.id)
      if (idx !== -1) publicaciones.value[idx] = data
    } else {
      const res = await api.post('/publicaciones', payload)
      data = res.data
      publicaciones.value.unshift(data)
    }
    showForm.value = false
    successMsg.value = 'Convocatoria guardada correctamente.'
    setTimeout(() => successMsg.value = '', 4000)
  } catch (e) {
    const errs = e.response?.data?.errors
    if (errs) Object.entries(errs).forEach(([k, v]) => { formErrors[k] = v[0] })
    else formError.value = e.response?.data?.message || 'Error al guardar.'
  } finally {
    guardando.value = false
  }
}

async function publicar(pub) {
  if (!confirm('¿Enviar esta convocatoria a revisión del administrador?')) return
  publicando.value = pub.id
  try {
    const { data } = await api.post(`/publicaciones/${pub.id}/publicar`)
    const idx = publicaciones.value.findIndex(p => p.id === pub.id)
    if (idx !== -1) publicaciones.value[idx] = data
    successMsg.value = 'Convocatoria publicada.'
  } catch (e) {
    errorMsg.value = e.response?.data?.errors?.estado?.[0] || e.response?.data?.message || 'Error.'
  } finally {
    publicando.value = null
  }
}

async function cancelar(pub) {
  if (!confirm('¿Cancelar esta convocatoria?')) return
  try {
    const { data } = await api.post(`/publicaciones/${pub.id}/cancelar`)
    const idx = publicaciones.value.findIndex(p => p.id === pub.id)
    if (idx !== -1) publicaciones.value[idx] = data
    successMsg.value = 'Convocatoria cancelada.'
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  }
}

async function verPostulantes(pub) {
  pubSeleccionada.value = pub
  showPostulantes.value = true
  await cargarPostulantes(pub)
}

async function cargarPostulantes(pub, page = 1) {
  loadingPostulantes.value = true
  try {
    const { data } = await api.get(`/publicaciones/${pub.id}/postulaciones`, { params: { page } })
    postulantes.value = data.data || []
    metaPost.value    = data.meta || null
  } finally {
    loadingPostulantes.value = false
  }
}

async function responder(p, estado) {
  respondiendo.value = p.id + '_A'
  try {
    const { data } = await api.put(`/postulaciones/${p.id}/responder`, { estado })
    const idx = postulantes.value.findIndex(x => x.id === p.id)
    if (idx !== -1) postulantes.value[idx] = data
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  } finally {
    respondiendo.value = null
  }
}

function pedirMotivo(p) {
  postPendiente.value  = p
  motivoRechazo.value  = ''
  showMotivoRechazo.value = true
}

async function confirmarRechazo() {
  if (!motivoRechazo.value.trim()) { alert('El motivo es obligatorio.'); return }
  respondiendo.value = postPendiente.value.id
  try {
    const { data } = await api.put(`/postulaciones/${postPendiente.value.id}/responder`, {
      estado: 'RECHAZADO', motivo_rechazo: motivoRechazo.value
    })
    const idx = postulantes.value.findIndex(x => x.id === postPendiente.value.id)
    if (idx !== -1) postulantes.value[idx] = data
    showMotivoRechazo.value = false
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  } finally {
    respondiendo.value = null
  }
}

function confirmarAsistencia(p, asistio) {
  postAsistencia.value = p
  asistioVal.value     = asistio
  form.calificacion    = null
  form.comentario_fundacion = ''
  showCalificacion.value = true
}

async function enviarAsistencia() {
  if (asistioVal.value && !form.calificacion) { alert('La calificación es obligatoria.'); return }
  confirmandoAsist.value = true
  try {
    const { data } = await api.post(`/postulaciones/${postAsistencia.value.id}/confirmar-asistencia`, {
      asistio: asistioVal.value,
      calificacion: asistioVal.value ? form.calificacion : null,
      comentario_fundacion: form.comentario_fundacion || null
    })
    const idx = postulantes.value.findIndex(x => x.id === postAsistencia.value.id)
    if (idx !== -1) postulantes.value[idx] = data
    showCalificacion.value = false
  } catch (e) {
    errorMsg.value = e.response?.data?.message || 'Error.'
  } finally {
    confirmandoAsist.value = false
  }
}

async function cargar(page = 1) {
  console.log('[MisConvocatorias] cargar() page=', page)
  loading.value = true
  try {
    const { data } = await api.get('/mis-publicaciones', { params: { page } })
    publicaciones.value = data.data || []
    meta.value          = data.meta || null
    console.log('[MisConvocatorias] cargar() OK, items=', publicaciones.value.length)
  } finally {
    loading.value = false
    console.log('[MisConvocatorias] cargar() finally, loading=false')
  }
}

onMounted(async () => {
  console.log('[MisConvocatorias] onMounted START')
  await Promise.all([
    catalogos.cargarAreasImpacto(),
    catalogos.cargarDepartamentos(),
    catalogos.cargarHabilidades()
  ])
  console.log('[MisConvocatorias] catalogos cargados')
  await cargar()
  console.log('[MisConvocatorias] cargar() done, loading =', loading.value)

  // Conectar WebSocket para tiempo real
  const echo = connectEcho()
  if (echo && auth.isFundacion) {
    try {
      const { data } = await api.get('/mi-fundacion')
      const fundacionId = data?.id || data?.data?.id
      if (fundacionId) {
        echo.private(`fundacion.${fundacionId}`)
          .listen('.PostulacionCreada', onWebSocketEvent)
          .listen('.PostulacionActualizada', onWebSocketEvent)
      }
    } catch {}
  }
})

function onWebSocketEvent(e) {
  cargar(meta.value?.current_page || 1)
  if (showPostulantes.value && pubSeleccionada.value?.id === e.publicacion_id) {
    cargarPostulantes(pubSeleccionada.value, metaPost.value?.current_page || 1)
  }
}

onUnmounted(() => {
  const echo = getEcho()
  if (echo && auth.isFundacion) {
    api.get('/mi-fundacion').then(({ data }) => {
      const fundacionId = data?.id || data?.data?.id
      if (fundacionId) {
        echo.private(`fundacion.${fundacionId}`)
          .stopListening('.PostulacionCreada', onWebSocketEvent)
          .stopListening('.PostulacionActualizada', onWebSocketEvent)
      }
    }).catch(() => {})
  }
})
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }
.postulante-card {
  display: flex; align-items: center; justify-content: space-between; gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid var(--gray-100);
}
.postulante-card:last-child { border-bottom: none; }
.postulante-info { display: flex; align-items: center; gap: 10px; min-width: 0; }
.mini-avatar {
  width: 36px; height: 36px;
  background: var(--primary);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 700; color: #fff;
  flex-shrink: 0;
}
.tags-container { display: flex; flex-wrap: wrap; gap: 8px; }
.tag { padding: 5px 12px; border-radius: 99px; font-size: 13px; border: 1.5px solid var(--gray-300); color: var(--gray-700); cursor: pointer; transition: all .18s; }
.tag.selected { background: var(--primary); color: #fff; border-color: var(--primary); }
</style>
