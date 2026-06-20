<template>
  <div>
    <h2 class="auth-title">Crear cuenta</h2>

    <AppAlert :message="error" />

    <form @submit.prevent="handleRegister" novalidate class="auth-form">
      <div class="form-group">
        <label class="form-label">Tipo de cuenta <span class="required">*</span></label>
        <div class="role-grid">
          <label :class="['role-card', form.rol === 'VOLUNTARIO' ? 'selected' : '']">
            <input type="radio" v-model="form.rol" value="VOLUNTARIO" style="display:none" />
            <svg class="role-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
            <span class="role-label">Voluntario</span>
          </label>
          
          <label :class="['role-card', form.rol === 'FUNDACION' ? 'selected' : '']">
            <input type="radio" v-model="form.rol" value="FUNDACION" style="display:none" />
            <svg class="role-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="4" y="2" width="16" height="20" rx="2" ry="2"/>
              <line x1="9" y1="22" x2="9" y2="16"/>
              <line x1="15" y1="22" x2="15" y2="16"/>
              <line x1="9" y1="16" x2="15" y2="16"/>
              <path d="M8 6h.01"/>
              <path d="M16 6h.01"/>
              <path d="M8 10h.01"/>
              <path d="M16 10h.01"/>
            </svg>
            <span class="role-label">Fundación</span>
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

      <button type="submit" class="btn btn-primary btn-full btn-lg submit-btn" :disabled="loading">
        <AppSpinner v-if="loading" :small="true" />
        <span>{{ loading ? 'Registrando…' : 'Crear cuenta' }}</span>
      </button>
    </form>

    <p class="text-center mt-4 text-sm text-muted">
      ¿Ya tienes cuenta?
      <RouterLink :to="{ name: 'login' }" class="login-link">Inicia sesión</RouterLink>
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
.auth-title {
  text-align: center;
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 28px;
  color: var(--gray-900);
  font-family: 'Outfit', sans-serif;
}
.auth-form {
  display: flex;
  flex-direction: column;
}
.role-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.role-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 18px 12px;
  border: 1.5px solid var(--gray-200);
  border-radius: var(--radius);
  cursor: pointer;
  transition: var(--transition);
  text-align: center;
  color: var(--gray-500);
}
.role-card:hover {
  border-color: var(--primary);
  background: var(--primary-light);
  color: var(--primary-dark);
}
.role-card.selected {
  border-color: var(--primary);
  background: var(--primary-light);
  color: var(--primary);
  box-shadow: 0 0 0 3px rgba(13, 148, 136, 0.15);
}
.role-icon {
  transition: var(--transition);
}
.role-card.selected .role-icon {
  color: var(--primary);
  transform: scale(1.1);
}
.role-label {
  font-size: 13px;
  font-weight: 600;
}
.submit-btn {
  font-family: 'Outfit', sans-serif;
  font-weight: 600;
  margin-top: 12px;
  box-shadow: 0 4px 12px rgba(13, 148, 136, 0.2);
}
.login-link {
  color: var(--primary);
  font-weight: 600;
  text-decoration: none;
}
.login-link:hover {
  text-decoration: underline;
}
</style>
