<template>
  <div>
    <h2 style="text-align:center;font-size:20px;font-weight:600;margin-bottom:24px;color:var(--gray-800)">
      Crear cuenta
    </h2>

    <AppAlert :message="error" />

    <form @submit.prevent="handleRegister" novalidate>
      <div class="form-group">
        <label class="form-label">Tipo de cuenta <span class="required">*</span></label>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
          <label v-for="opt in roles" :key="opt.value" :class="['role-card', form.rol === opt.value ? 'selected' : '']">
            <input type="radio" v-model="form.rol" :value="opt.value" style="display:none" />
            <span style="font-size:22px">{{ opt.icon }}</span>
            <span style="font-size:13px;font-weight:500">{{ opt.label }}</span>
          </label>
        </div>
        <span v-if="errors.rol" class="form-error">{{ errors.rol }}</span>
      </div>

      <div class="form-group">
        <label class="form-label">Nombre completo <span class="required">*</span></label>
        <input v-model="form.nombre" type="text" class="form-control" :class="{ error: errors.nombre }" placeholder="Tu nombre completo" autocomplete="name" />
        <span v-if="errors.nombre" class="form-error">{{ errors.nombre }}</span>
      </div>

      <div class="form-group">
        <label class="form-label">Email <span class="required">*</span></label>
        <input v-model="form.email" type="email" class="form-control" :class="{ error: errors.email }" placeholder="correo@ejemplo.com" autocomplete="email" />
        <span v-if="errors.email" class="form-error">{{ errors.email }}</span>
      </div>

      <div class="form-group">
        <label class="form-label">Teléfono</label>
        <input v-model="form.telefono" type="tel" class="form-control" placeholder="+57 300 000 0000" autocomplete="tel" />
      </div>

      <div class="form-group">
        <label class="form-label">Contraseña <span class="required">*</span></label>
        <input v-model="form.password" type="password" class="form-control" :class="{ error: errors.password }" placeholder="Mínimo 8 caracteres" autocomplete="new-password" />
        <span v-if="errors.password" class="form-error">{{ errors.password }}</span>
      </div>

      <div class="form-group">
        <label class="form-label">Confirmar contraseña <span class="required">*</span></label>
        <input v-model="form.password_confirmation" type="password" class="form-control" :class="{ error: errors.password_confirmation }" placeholder="Repite tu contraseña" autocomplete="new-password" />
        <span v-if="errors.password_confirmation" class="form-error">{{ errors.password_confirmation }}</span>
      </div>

      <button type="submit" class="btn btn-primary btn-full btn-lg" :disabled="loading">
        <AppSpinner v-if="loading" :small="true" />
        {{ loading ? 'Registrando…' : 'Crear cuenta' }}
      </button>
    </form>

    <p class="text-center mt-4 text-sm text-muted">
      ¿Ya tienes cuenta?
      <RouterLink :to="{ name: 'login' }">Inicia sesión</RouterLink>
    </p>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppAlert from '@/components/AppAlert.vue'
import AppSpinner from '@/components/AppSpinner.vue'

const auth   = useAuthStore()
const router = useRouter()

const roles = [
  { value: 'VOLUNTARIO', label: 'Voluntario', icon: '🙋' },
  { value: 'FUNDACION',  label: 'Fundación',  icon: '🏢' },
]

const form   = reactive({ rol: 'VOLUNTARIO', nombre: '', email: '', telefono: '', password: '', password_confirmation: '' })
const errors = reactive({})
const error  = ref('')
const loading = ref(false)

function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.rol)      errors.rol      = 'Selecciona un tipo de cuenta.'
  if (!form.nombre)   errors.nombre   = 'El nombre es obligatorio.'
  if (!form.email)    errors.email    = 'El email es obligatorio.'
  if (!form.password) errors.password = 'La contraseña es obligatoria.'
  else if (form.password.length < 8) errors.password = 'Mínimo 8 caracteres.'
  if (form.password !== form.password_confirmation) errors.password_confirmation = 'Las contraseñas no coinciden.'
  return !Object.keys(errors).length
}

async function handleRegister() {
  if (!validate()) return
  loading.value = true
  error.value   = ''
  try {
    await auth.register(form)
    router.push({ name: 'dashboard' })
  } catch (e) {
    const errs = e.response?.data?.errors
    if (errs) {
      Object.entries(errs).forEach(([k, v]) => { errors[k] = v[0] })
    } else {
      error.value = e.response?.data?.message || 'Error al registrarse.'
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.role-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 14px;
  border: 2px solid var(--gray-200);
  border-radius: var(--radius);
  cursor: pointer;
  transition: all .18s;
  text-align: center;
}
.role-card:hover { border-color: var(--primary); background: var(--primary-light); }
.role-card.selected { border-color: var(--primary); background: var(--primary-light); }
</style>
