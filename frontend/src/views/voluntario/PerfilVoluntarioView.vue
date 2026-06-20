<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="page-title">Mi Perfil de Voluntario</h1>
      <button v-if="!editMode && voluntario" class="btn btn-outline" @click="editMode = true">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 4px;"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 1 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
        <span>Editar</span>
      </button>
    </div>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <!-- Sin perfil -->
    <div v-else-if="!voluntario && !editMode">
      <div class="alert alert-info mb-4">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        <span>Aún no tienes un perfil de voluntario. Complétalo para poder postularte a convocatorias.</span>
      </div>
      <button class="btn btn-primary" @click="editMode = true">Crear mi perfil</button>
    </div>

    <!-- Formulario -->
    <div v-else-if="editMode" class="card">
      <div class="card-header">
        <h3>{{ voluntario ? 'Editar perfil' : 'Crear perfil de voluntario' }}</h3>
      </div>
      <div class="card-body">
        <AppAlert :message="error" />
        <AppAlert :message="successMsg" type="success" />

        <form @submit.prevent="handleGuardar" novalidate>
          <div class="grid grid-2">
            <div class="form-group">
              <label class="form-label">Tipo de documento <span class="required">*</span></label>
              <select v-model="form.tipo_documento" class="form-control" :class="{ error: errors.tipo_documento }">
                <option value="">Seleccionar…</option>
                <option v-for="t in tiposDoc" :key="t" :value="t">{{ t }}</option>
              </select>
              <span v-if="errors.tipo_documento" class="form-error">{{ errors.tipo_documento }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Número de documento <span class="required">*</span></label>
              <input v-model="form.numero_documento" type="text" class="form-control" :class="{ error: errors.numero_documento }" />
              <span v-if="errors.numero_documento" class="form-error">{{ errors.numero_documento }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Fecha de nacimiento <span class="required">*</span></label>
              <input v-model="form.fecha_nacimiento" type="date" class="form-control" :class="{ error: errors.fecha_nacimiento }" :max="maxFechaNac" />
              <span v-if="errors.fecha_nacimiento" class="form-error">{{ errors.fecha_nacimiento }}</span>
            </div>
            <div class="form-group">
              <label class="form-label">Género <span class="required">*</span></label>
              <select v-model="form.genero" class="form-control" :class="{ error: errors.genero }">
                <option value="">Seleccionar…</option>
                <option v-for="g in generos" :key="g.value" :value="g.value">{{ g.label }}</option>
              </select>
              <span v-if="errors.genero" class="form-error">{{ errors.genero }}</span>
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
            <div class="form-group">
              <label class="form-label">Disponibilidad <span class="required">*</span></label>
              <select v-model="form.disponibilidad" class="form-control" :class="{ error: errors.disponibilidad }">
                <option value="">Seleccionar…</option>
                <option v-for="d in disponibilidades" :key="d.value" :value="d.value">{{ d.label }}</option>
              </select>
              <span v-if="errors.disponibilidad" class="form-error">{{ errors.disponibilidad }}</span>
            </div>
          </div>

          <div class="form-group mt-2">
            <label class="form-label">Experiencia previa en voluntariado</label>
            <textarea v-model="form.experiencia" class="form-control" rows="3" placeholder="Describe brevemente tu experiencia…"></textarea>
          </div>

          <div class="form-group mt-2">
            <label class="form-label">Habilidades</label>
            <div class="tags-container mt-2">
              <label v-for="h in catalogos.habilidades" :key="h.id" :class="['tag', form.habilidades.includes(h.id) ? 'selected' : '']">
                <input type="checkbox" :value="h.id" v-model="form.habilidades" style="display:none" />
                <span>{{ h.nombre }}</span>
              </label>
            </div>
          </div>

          <div class="form-group mt-2">
            <label class="form-label">Intereses</label>
            <div class="tags-container mt-2">
              <label v-for="i in catalogos.intereses" :key="i.id" :class="['tag', form.intereses.includes(i.id) ? 'selected' : '']">
                <input type="checkbox" :value="i.id" v-model="form.intereses" style="display:none" />
                <span>{{ i.nombre }}</span>
              </label>
            </div>
          </div>

          <div class="flex gap-3 justify-end mt-4">
            <button v-if="voluntario" type="button" class="btn btn-outline" @click="editMode = false">Cancelar</button>
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <AppSpinner v-if="saving" :small="true" />
              <span>{{ saving ? 'Guardando…' : 'Guardar perfil' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Vista del perfil -->
    <div v-else-if="voluntario" class="card">
      <div class="card-body">
        <div class="profile-header">
          <div class="avatar-lg">{{ auth.user?.nombre?.charAt(0).toUpperCase() }}</div>
          <div>
            <h2>{{ auth.user?.nombre }}</h2>
            <p class="text-muted text-sm">{{ auth.user?.email }}</p>
          </div>
        </div>

        <div class="detail-grid mt-6">
          <div class="detail-item"><span class="detail-label">Documento</span><span>{{ voluntario.tipo_documento }} {{ voluntario.numero_documento }}</span></div>
          <div class="detail-item"><span class="detail-label">Nacimiento</span><span>{{ voluntario.fecha_nacimiento }}</span></div>
          <div class="detail-item"><span class="detail-label">Género</span><span>{{ voluntario.genero }}</span></div>
          <div class="detail-item"><span class="detail-label">Disponibilidad</span><span>{{ voluntario.disponibilidad }}</span></div>
          <div class="detail-item"><span class="detail-label">Municipio</span><span>{{ voluntario.municipio?.nombre }}, {{ voluntario.municipio?.departamento?.nombre }}</span></div>
        </div>

        <div v-if="voluntario.experiencia" class="mt-6 border-top">
          <p class="detail-label">Experiencia</p>
          <p class="text-sm mt-2 experience-box">{{ voluntario.experiencia }}</p>
        </div>

        <div v-if="voluntario.habilidades?.length" class="mt-6">
          <p class="detail-label mb-2">Habilidades</p>
          <div class="tags-container">
            <span v-for="h in voluntario.habilidades" :key="h.id" class="tag selected">{{ h.nombre }}</span>
          </div>
        </div>

        <div v-if="voluntario.intereses?.length" class="mt-6">
          <p class="detail-label mb-2">Intereses</p>
          <div class="tags-container">
            <span v-for="i in voluntario.intereses" :key="i.id" class="tag selected">{{ i.nombre }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useCatalogosStore } from '@/stores/catalogos'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import AppAlert from '@/components/AppAlert.vue'

const auth     = useAuthStore()
const catalogos = useCatalogosStore()

const loading     = ref(true)
const saving      = ref(false)
const editMode    = ref(false)
const voluntario  = ref(null)
const error       = ref('')
const successMsg  = ref('')
const departamentoId   = ref('')
const municipiosFiltrados = ref([])
const errors = reactive({})

const tiposDoc       = ['CC', 'TI', 'CE', 'PASAPORTE']
const generos        = [{ value: 'MASCULINO', label: 'Masculino' }, { value: 'FEMENINO', label: 'Femenino' }, { value: 'OTRO', label: 'Otro' }]
const disponibilidades = [{ value: 'ENTRE_SEMANA', label: 'Entre semana' }, { value: 'FINES_DE_SEMANA', label: 'Fines de semana' }, { value: 'FLEXIBLE', label: 'Flexible' }]

const maxFechaNac = computed(() => {
  const d = new Date(); d.setFullYear(d.getFullYear() - 14)
  return d.toISOString().split('T')[0]
})

const form = reactive({
  tipo_documento: '', numero_documento: '', fecha_nacimiento: '',
  genero: '', municipio_id: '', disponibilidad: '', experiencia: '',
  habilidades: [], intereses: []
})

async function onDeptChange() {
  form.municipio_id = ''
  if (!departamentoId.value) { municipiosFiltrados.value = []; return }
  const data = await catalogos.cargarMunicipios(departamentoId.value)
  municipiosFiltrados.value = data
}

function poblarForm(v) {
  form.tipo_documento   = v.tipo_documento
  form.numero_documento = v.numero_documento
  form.fecha_nacimiento = v.fecha_nacimiento
  form.genero           = v.genero
  form.municipio_id     = v.municipio?.id || ''
  form.disponibilidad   = v.disponibilidad
  form.experiencia      = v.experiencia || ''
  form.habilidades      = (v.habilidades || []).map(h => h.id)
  form.intereses        = (v.intereses   || []).map(i => i.id)
  if (v.municipio?.departamento) {
    departamentoId.value = v.municipio.departamento.id
    municipiosFiltrados.value = [v.municipio]
  }
}

function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.tipo_documento)   errors.tipo_documento   = 'Requerido.'
  if (!form.numero_documento) errors.numero_documento = 'Requerido.'
  if (!form.fecha_nacimiento) errors.fecha_nacimiento = 'Requerido.'
  if (!form.genero)           errors.genero           = 'Requerido.'
  if (!form.municipio_id)     errors.municipio_id     = 'Requerido.'
  if (!form.disponibilidad)   errors.disponibilidad   = 'Requerido.'
  return !Object.keys(errors).length
}

async function handleGuardar() {
  if (!validate()) return
  saving.value = true
  error.value = successMsg.value = ''
  try {
    const payload = { ...form }
    if (voluntario.value) {
      const { data } = await api.put('/voluntario', payload)
      voluntario.value = data
    } else {
      const { data } = await api.post('/voluntario', payload)
      voluntario.value = data
    }
    successMsg.value = 'Perfil guardado correctamente.'
    editMode.value = false
  } catch (e) {
    const errs = e.response?.data?.errors
    if (errs) Object.entries(errs).forEach(([k, v]) => { errors[k] = v[0] })
    else error.value = e.response?.data?.message || 'Error al guardar.'
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await Promise.all([
    catalogos.cargarDepartamentos(),
    catalogos.cargarHabilidades(),
    catalogos.cargarIntereses()
  ])
  try {
    const { data } = await api.get('/voluntario')
    voluntario.value = data
    poblarForm(data)
  } catch {}
  loading.value = false
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }
.profile-header { display: flex; align-items: center; gap: 20px; }
.avatar-lg {
  width: 72px; height: 72px;
  background: var(--primary);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 28px; font-weight: 800; color: #fff;
  flex-shrink: 0;
  font-family: 'Outfit', sans-serif;
  box-shadow: 0 4px 10px rgba(13, 148, 136, 0.2);
}
.profile-header h2 { font-size: 20px; font-weight: 700; color: var(--gray-900); font-family: 'Outfit', sans-serif; }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
.detail-item { display: flex; flex-direction: column; gap: 4px; }
.detail-label { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; color: var(--gray-500); }
.tags-container { display: flex; flex-wrap: wrap; gap: 8px; }
.tag {
  padding: 6px 14px;
  border-radius: 99px;
  border: 1.5px solid var(--gray-300);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  color: var(--gray-600);
  transition: var(--transition);
}
.tag:hover   { border-color: var(--primary); color: var(--primary); }
.tag.selected { background: var(--primary); color: #fff; border-color: var(--primary); }

.experience-box {
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
