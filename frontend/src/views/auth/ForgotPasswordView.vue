<template>
  <div>
    <h2 class="auth-title">Recuperar contraseña</h2>
    <p class="auth-subtitle">
      Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.
    </p>

    <AppAlert :message="error" type="danger" />
    <AppAlert :message="success" type="success" />

    <form v-if="!success" @submit.prevent="handleSubmit" novalidate class="auth-form">
      <div class="form-group">
        <label class="form-label">Email <span class="required">*</span></label>
        <input v-model="email" type="email" class="form-control" placeholder="correo@ejemplo.com" autocomplete="email" />
      </div>
      <button type="submit" class="btn btn-primary btn-full btn-lg submit-btn" :disabled="loading">
        <AppSpinner v-if="loading" :small="true" />
        <span>{{ loading ? 'Enviando…' : 'Enviar enlace' }}</span>
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
import api from '@/services/api'
import AppAlert from '@/components/AppAlert.vue'
import AppSpinner from '@/components/AppSpinner.vue'

const email   = ref('')
const error   = ref('')
const success = ref('')
const loading = ref(false)

async function handleSubmit() {
  if (!email.value) { error.value = 'Ingresa tu email.'; return }
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.post('/auth/forgot-password', { email: email.value })
    success.value = data.message
  } catch (e) {
    error.value = e.response?.data?.message || 'Error al enviar el email.'
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
