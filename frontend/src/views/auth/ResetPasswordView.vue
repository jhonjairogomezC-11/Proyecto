<template>
  <div>
    <h2 class="auth-title">Restablecer contraseña</h2>
    <p class="auth-subtitle">
      Ingresa tu nueva contraseña para restablecer el acceso a tu cuenta.
    </p>

    <AppAlert :message="error" type="danger" />
    <AppAlert :message="success" type="success" />

    <form v-if="!success" @submit.prevent="handleSubmit" novalidate class="auth-form">
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

      <button type="submit" class="btn btn-primary btn-full btn-lg submit-btn" :disabled="loading || !token || !email">
        <AppSpinner v-if="loading" :small="true" />
        <span>{{ loading ? 'Restableciendo…' : 'Restablecer contraseña' }}</span>
      </button>
    </form>

    <p class="text-center mt-6 text-sm">
      <RouterLink :to="{ name: 'login' }" class="back-link">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 4px; vertical-align: middle;"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
        <span>Volver al inicio de sesión</span>
      </RouterLink>
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

<style scoped>
.auth-title {
  text-align: center;
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 8px;
  color: var(--gray-900);
  font-family: 'Outfit', sans-serif;
}
.auth-subtitle {
  text-align: center;
  font-size: 13.5px;
  color: var(--gray-500);
  line-height: 1.5;
  margin-bottom: 24px;
}
.auth-form {
  display: flex;
  flex-direction: column;
}
.submit-btn {
  font-family: 'Outfit', sans-serif;
  font-weight: 600;
  margin-top: 10px;
  box-shadow: 0 4px 12px rgba(13, 148, 136, 0.2);
}
.back-link {
  color: var(--gray-600);
  font-weight: 500;
  text-decoration: none;
  transition: var(--transition);
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.back-link:hover {
  color: var(--primary);
}
</style>
