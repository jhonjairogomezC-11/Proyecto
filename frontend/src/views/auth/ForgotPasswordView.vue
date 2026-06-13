<template>
  <div>
    <h2 style="text-align:center;font-size:20px;font-weight:600;margin-bottom:8px;color:var(--gray-800)">
      Recuperar contraseña
    </h2>
    <p class="text-center text-sm text-muted mb-4">
      Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.
    </p>

    <AppAlert :message="error" type="danger" />
    <AppAlert :message="success" type="success" />

    <form v-if="!success" @submit.prevent="handleSubmit" novalidate>
      <div class="form-group">
        <label class="form-label">Email <span class="required">*</span></label>
        <input v-model="email" type="email" class="form-control" placeholder="correo@ejemplo.com" autocomplete="email" />
      </div>
      <button type="submit" class="btn btn-primary btn-full" :disabled="loading">
        <AppSpinner v-if="loading" :small="true" />
        {{ loading ? 'Enviando…' : 'Enviar enlace' }}
      </button>
    </form>

    <p class="text-center mt-4 text-sm">
      <RouterLink :to="{ name: 'login' }">← Volver al inicio de sesión</RouterLink>
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
