<template>
  <div>
    <h2 style="text-align:center;font-size:20px;font-weight:600;margin-bottom:24px;color:var(--gray-800)">
      Iniciar sesión
    </h2>

    <AppAlert :message="error" />

    <form @submit.prevent="handleLogin" novalidate>
      <div class="form-group">
        <label class="form-label">Email <span class="required">*</span></label>
        <input v-model="form.email" type="email" class="form-control" :class="{ error: errors.email }" placeholder="correo@ejemplo.com" autocomplete="email" />
        <span v-if="errors.email" class="form-error">{{ errors.email }}</span>
      </div>

      <div class="form-group">
        <label class="form-label">Contraseña <span class="required">*</span></label>
        <input v-model="form.password" type="password" class="form-control" :class="{ error: errors.password }" placeholder="••••••••" autocomplete="current-password" />
        <span v-if="errors.password" class="form-error">{{ errors.password }}</span>
      </div>

      <div style="display:flex;justify-content:flex-end;margin-bottom:16px">
        <RouterLink :to="{ name: 'forgot-password' }" class="text-sm" style="color:var(--primary)">
          ¿Olvidaste tu contraseña?
        </RouterLink>
      </div>

      <button type="submit" class="btn btn-primary btn-full btn-lg" :disabled="loading">
        <AppSpinner v-if="loading" :small="true" />
        {{ loading ? 'Ingresando…' : 'Ingresar' }}
      </button>
    </form>

    <p class="text-center mt-4 text-sm text-muted">
      ¿No tienes cuenta?
      <RouterLink :to="{ name: 'register' }">Regístrate aquí</RouterLink>
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

const form    = reactive({ email: '', password: '' })
const errors  = reactive({})
const error   = ref('')
const loading = ref(false)

function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.email)    errors.email    = 'El email es obligatorio.'
  if (!form.password) errors.password = 'La contraseña es obligatoria.'
  return !Object.keys(errors).length
}

async function handleLogin() {
  if (!validate()) return
  loading.value = true
  error.value   = ''
  try {
    await auth.login(form.email, form.password)
    router.push({ name: 'dashboard' })
  } catch (e) {
    const msg = e.response?.data?.errors?.email?.[0]
              || e.response?.data?.message
              || 'Error al iniciar sesión.'
    error.value = msg
  } finally {
    loading.value = false
  }
}
</script>
