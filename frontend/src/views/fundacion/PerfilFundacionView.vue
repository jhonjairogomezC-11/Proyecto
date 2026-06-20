<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="page-title">Mi Fundación</h1>
      <button v-if="!editMode && fundacion" class="btn btn-outline" @click="iniciarEdicion">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 4px;"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 1 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
        <span>Editar</span>
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <!-- Sin perfil -->
    <div v-else-if="!fundacion && !editMode">
      <div class="alert alert-info mb-4">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        <span>Aún no has registrado tu fundación. Completa el formulario para comenzar el proceso de aprobación.</span>
      </div>
      <button class="btn btn-primary" @click="editMode = true">Registrar fundación</button>
    </div>

    <!-- Formulario -->
    <div v-else-if="editMode" class="card">
      <div class="card-header">
        <h3>{{ fundacion ? 'Editar fundación' : 'Registrar fundación' }}</h3>
      </div>
      <div class="card-body">
        <AppAlert :message="error" />

        <form @submit.prevent="handleGuardar" novalidate>
          <h4 class="section-title">Información básica</h4>
          <div class="grid grid-2">
            <div class="form-group">
              <label class="form-label">Nombre de la fundación <span class="required">*</span></label>
              <input v-model="form.nombre" type="text" class="form-control" :class="{ error: errors.nombre }" />
              <span v-if="errors.nombre" class="form-error">{{ errors.nombre }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">NIT <span class="required">*</span></label>
              <input v-model="form.nit" type="text" class="form-control" :class="{ error: errors.nit }" placeholder="000000000-0" :disabled="!!fundacion" />
              <span v-if="errors.nit" class="form-error">{{ errors.nit }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Representante legal <span class="required">*</span></label>
              <input v-model="form.representante_legal" type="text" class="form-control" :class="{ error: errors.representante_legal }" />
              <span v-if="errors.representante_legal" class="form-error">{{ errors.representante_legal }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Correo institucional</label>
              <input v-model="form.correo_institucional" type="email" class="form-control" :class="{ error: errors.correo_institucional }" />
              <span v-if="errors.correo_institucional" class="form-error">{{ errors.correo_institucional }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Teléfono <span class="required">*</span></label>
              <input v-model="form.telefono" type="tel" class="form-control" :class="{ error: errors.telefono }" />
              <span v-if="errors.telefono" class="form-error">{{ errors.telefono }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Página web</label>
              <input v-model="form.pagina_web" type="url" class="form-control" placeholder="https://..." />
            </div>
          </div>

          <h4 class="section-title">Ubicación</h4>
          <div class="grid grid-2">
            <div class="form-group">
              <label class="form-label">Dirección <span class="required">*</span></label>
              <input v-model="form.direccion" type="text" class="form-control" :class="{ error: errors.direccion }" />
              <span v-if="errors.direccion" class="form-error">{{ errors.direccion }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Departamento <span class="required">*</span></label>
              <select v-model="departamentoId" class="form-control" @change="onDeptChange">
                <option value="">Seleccionar…</option>
                <option v-for="d in catalogos.departamentos" :key="d.id" :value="d.id">{{ d.nombre }}</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Municipio <span class="required">*</span></label>
              <select v-model="form.municipio_id" class="form-control" :class="{ error: errors.municipio_id }" :disabled="!departamentoId">
                <option value="">Seleccionar…</option>
                <option v-for="m in municipiosFiltrados" :key="m.id" :value="m.id">{{ m.nombre }}</option>
              </select>
              <span v-if="errors.municipio_id" class="form-error">{{ errors.municipio_id }}</span>
            </div>
          </div>

          <h4 class="section-title">Descripción y documentos</h4>
          <div class="form-group">
            <label class="form-label">Descripción <span class="required">*</span></label>
            <textarea v-model="form.descripcion" class="form-control" rows="4" :class="{ error: errors.descripcion }"></textarea>
            <span v-if="errors.descripcion" class="form-error">{{ errors.descripcion }}</span>
          </div>
          <div class="form-group">
            <label class="form-label">URL documento legal <span class="required">*</span></label>
            <input v-model="form.documento_legal" type="text" class="form-control" :class="{ error: errors.documento_legal }" placeholder="URL o ruta al documento (personería jurídica, RUT…)" />
            <span v-if="errors.documento_legal" class="form-error">{{ errors.documento_legal }}</span>
          </div>

          <h4 class="section-title">Áreas de impacto</h4>
          <div class="tags-container mb-4">
            <label v-for="a in catalogos.areasImpacto" :key="a.id" :class="['tag', form.areas.includes(a.id) ? 'selected' : '']">
              <input type="checkbox" :value="a.id" v-model="form.areas" style="display:none" />
              <span>{{ a.nombre }}</span>
            </label>
          </div>

          <div class="flex gap-3 justify-end mt-4">
            <button v-if="fundacion" type="button" class="btn btn-outline" @click="editMode = false">Cancelar</button>
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <AppSpinner v-if="saving" :small="true" />
              <span>{{ saving ? 'Guardando…' : 'Guardar' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Vista del perfil -->
    <div v-else-if="fundacion">
      <div class="grid grid-2 mb-6" style="grid-template-columns:auto 1fr">
        <div class="card header-card" style="padding:24px;display:flex;align-items:center;gap:20px;grid-column:1/-1">
          <div class="fund-avatar">{{ fundacion.nombre?.charAt(0).toUpperCase() }}</div>
          <div style="flex:1">
            <h2 class="fund-title">{{ fundacion.nombre }}</h2>
            <p class="text-muted text-sm">NIT: {{ fundacion.nit }}</p>
          </div>
          <BadgeEstado :estado="fundacion.estado_verificacion" tipo="fundacion" />
        </div>
      </div>

      <div class="grid grid-2">
        <div class="card">
          <div class="card-header"><h3>Información</h3></div>
          <div class="card-body">
            <div class="detail-grid">
              <div class="detail-item"><span class="detail-label">Representante</span><span>{{ fundacion.representante_legal }}</span></div>
              <div class="detail-item"><span class="detail-label">Teléfono</span><span>{{ fundacion.telefono }}</span></div>
              <div v-if="fundacion.correo_institucional" class="detail-item"><span class="detail-label">Correo inst.</span><span>{{ fundacion.correo_institucional }}</span></div>
              <div v-if="fundacion.pagina_web" class="detail-item"><span class="detail-label">Web</span><a :href="fundacion.pagina_web" target="_blank" class="text-sm web-link">{{ fundacion.pagina_web }}</a></div>
              <div class="detail-item"><span class="detail-label">Dirección</span><span>{{ fundacion.direccion }}</span></div>
              <div v-if="fundacion.municipio" class="detail-item"><span class="detail-label">Ubicación</span><span>{{ fundacion.municipio.nombre }}, {{ fundacion.municipio.departamento?.nombre }}</span></div>
            </div>
            <div class="mt-6 border-top">
              <p class="detail-label">Descripción</p>
              <p class="text-sm mt-2 desc-box">{{ fundacion.descripcion }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header"><h3>Áreas de impacto</h3></div>
          <div class="card-body">
            <div v-if="fundacion.areas?.length" class="tags-container">
              <span v-for="a in fundacion.areas" :key="a.id" class="tag selected">{{ a.nombre }}</span>
            </div>
            <p v-else class="text-muted text-sm">Sin áreas registradas.</p>
          </div>
        </div>
      </div>

      <div v-if="fundacion.estado_verificacion === 'RECHAZADA' && fundacion.motivo_rechazo" class="alert alert-danger mt-4">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
        <div>
          <strong>Motivo de rechazo:</strong> {{ fundacion.motivo_rechazo }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useCatalogosStore } from '@/stores/catalogos'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const catalogos = useCatalogosStore()

const loading     = ref(true)
const saving      = ref(false)
const editMode    = ref(false)
const fundacion   = ref(null)
const error       = ref('')
const errors      = reactive({})
const departamentoId    = ref('')
const municipiosFiltrados = ref([])

const form = reactive({
  nombre: '', nit: '', representante_legal: '', correo_institucional: '',
  telefono: '', pagina_web: '', direccion: '', municipio_id: '',
  descripcion: '', documento_legal: '', areas: []
})

async function onDeptChange() {
  form.municipio_id = ''
  if (!departamentoId.value) { municipiosFiltrados.value = []; return }
  const data = await catalogos.cargarMunicipios(departamentoId.value)
  municipiosFiltrados.value = data
}

function iniciarEdicion() {
  if (fundacion.value) poblarForm(fundacion.value)
  editMode.value = true
}

function poblarForm(f) {
  form.nombre               = f.nombre
  form.nit                  = f.nit
  form.representante_legal  = f.representante_legal
  form.correo_institucional = f.correo_institucional || ''
  form.telefono             = f.telefono
  form.pagina_web           = f.pagina_web || ''
  form.direccion            = f.direccion
  form.municipio_id         = f.municipio?.id || ''
  form.descripcion          = f.descripcion
  form.documento_legal      = f.documento_legal
  form.areas                = (f.areas || []).map(a => a.id)
  if (f.municipio?.departamento) {
    departamentoId.value = f.municipio.departamento.id
    municipiosFiltrados.value = [f.municipio]
  }
}

function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.nombre)              errors.nombre              = 'Requerido.'
  if (!form.nit)                 errors.nit                 = 'Requerido.'
  if (!form.representante_legal) errors.representante_legal = 'Requerido.'
  if (!form.telefono)            errors.telefono            = 'Requerido.'
  if (!form.direccion)           errors.direccion           = 'Requerido.'
  if (!form.municipio_id)        errors.municipio_id        = 'Requerido.'
  if (!form.descripcion)         errors.descripcion         = 'Requerido.'
  if (!form.documento_legal)     errors.documento_legal     = 'Requerido.'
  return !Object.keys(errors).length
}

async function handleGuardar() {
  if (!validate()) return
  saving.value = true
  error.value  = ''
  try {
    let data
    if (fundacion.value) {
      const res = await api.put(`/fundaciones/${fundacion.value.id}`, form)
      data = res.data
    } else {
      const res = await api.post('/fundaciones', form)
      data = res.data
    }
    fundacion.value = data
    editMode.value  = false
  } catch (e) {
    const errs = e.response?.data?.errors
    if (errs) Object.entries(errs).forEach(([k, v]) => { errors[k] = v[0] })
    else error.value = e.response?.data?.message || 'Error al guardar.'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  console.log('[PerfilFundacion] onMounted START')
  await Promise.all([catalogos.cargarDepartamentos(), catalogos.cargarAreasImpacto()])
  console.log('[PerfilFundacion] catalogos OK')
  try {
    const { data } = await api.get('/mi-fundacion')
    fundacion.value = data
    console.log('[PerfilFundacion] mi-fundacion OK, id=', data?.id)
  } catch (e) {
    console.warn('[PerfilFundacion] mi-fundacion ERROR:', e?.response?.status, e?.message)
  }
  loading.value = false
  console.log('[PerfilFundacion] onMounted DONE, loading=false')
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }
.section-title { font-size: 13px; font-weight: 700; color: var(--gray-500); text-transform: uppercase; letter-spacing: .06em; margin: 24px 0 14px; border-bottom: 1px solid var(--gray-100); padding-bottom: 6px; }

.header-card {
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
}
.fund-avatar {
  width: 64px; height: 64px;
  background: var(--primary);
  border-radius: var(--radius);
  display: flex; align-items: center; justify-content: center;
  font-size: 28px; font-weight: 800; color: #fff;
  flex-shrink: 0;
  font-family: 'Outfit', sans-serif;
  box-shadow: 0 4px 10px rgba(13, 148, 136, 0.2);
}
.fund-title { font-size: 22px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; }

.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
.detail-item { display: flex; flex-direction: column; gap: 4px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; color: var(--gray-500); }
.tags-container { display: flex; flex-wrap: wrap; gap: 8px; }
.tag { padding: 6px 14px; border-radius: 99px; font-size: 13px; border: 1.5px solid var(--gray-300); color: var(--gray-600); font-weight: 600; cursor: pointer; transition: var(--transition); }
.tag:hover { border-color: var(--primary); color: var(--primary); }
.tag.selected { background: var(--primary); color: #fff; border-color: var(--primary); }

.web-link {
  color: var(--accent);
  font-weight: 600;
  text-decoration: none;
  transition: var(--transition);
}
.web-link:hover {
  color: var(--accent-dark);
  text-decoration: underline;
}

.desc-box {
  background: var(--gray-50);
  border: 1px solid var(--gray-200);
  border-radius: var(--radius);
  padding: 14px;
  color: var(--gray-700);
  line-height: 1.6;
}
.border-top {
  border-top: 1px solid var(--gray-200);
  padding-top: 20px;
}
</style>
