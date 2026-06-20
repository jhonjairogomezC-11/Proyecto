<template>
  <div>
    <h2 style="text-align:center;font-size:20px;font-weight:600;margin-bottom:8px;color:var(--gray-800)">
      Restablecer contraseña
    </h2>
    <p class="text-center text-sm text-muted mb-4">
      Ingresa tu nueva contraseña para restablecer el acceso a tu cuenta.
    </p>

    <AppAlert :message="error" type="danger" />
    <AppAlert :message="success" type="success" />

    <form v-if="!success" @submit.prevent="handleSubmit" novalidate>
      <div class="form-group">
        <label class="form-label">Nueva contraseña <span class="required">*</span></label>
        <input
          v-model="password"
          type="password"
          class="form-control"
          placeholder="••••••••"
          autocomplete="new-password"
        />
      </div>

      <div class="form-group">
        <label class="form-label">Confirmar contraseña <span class="required">*</span></label>
        <input
          v-model="passwordConfirmation"
          type="password"
          class="form-control"
          placeholder="••••••••"
          autocomplete="new-password"
        />
      </div>

      <button type="submit" class="btn btn-primary btn-full" :disabled="loading">
        <AppSpinner v-if="loading" :small="true" />
        {{ loading ? 'Restableciendo…' : 'Restablecer contraseña' }}
      </button>
    </form>

    <p class="text-center mt-4 text-sm">
      <RouterLink :to="{ name: 'login' }">← Volver al inicio de sesión</RouterLink>
    </p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import api from '@/services/api'
import AppAlert from '@/components/AppAlert.vue'
import AppSpinner from '@/components/AppSpinner.vue'

const route = useRoute()

const token                = route.query.token || ''
const email                = route.query.email || ''
const password             = ref('')
const passwordConfirmation = ref('')
const error                = ref('')
const success              = ref('')
const loading              = ref(false)

if (!token || !email) {
  error.value = 'El enlace de restablecimiento no es válido. Solicita uno nuevo.'
}

async function handleSubmit() {
  error.value = ''

  if (!password.value || !passwordConfirmation.value) {
    error.value = 'Ambos campos de contraseña son obligatorios.'
    return
  }
  if (password.value.length < 8) {
    error.value = 'La contraseña debe tener al menos 8 caracteres.'
    return
  }
  if (password.value !== passwordConfirmation.value) {
    error.value = 'Las contraseñas no coinciden.'
    return
  }

  loading.value = true
  try {
    const { data } = await api.post('/auth/reset-password', {
      token,
      email,
      password: password.value,
      password_confirmation: passwordConfirmation.value
    })
    success.value = data.message || 'Tu contraseña ha sido restablecida exitosamente.'
  } catch (e) {
    error.value = e.response?.data?.message || 'Error al restablecer la contraseña. El enlace puede haber expirado.'
  } finally {
    loading.value = false
  }
}
</script>
