<template>
  <Teleport to="body">
    <TransitionGroup name="toast" tag="div" class="toast-container">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        :class="['toast', `toast-${toast.type}`]"
        @click="removeToast(toast.id)"
      >
        <div class="toast-icon">{{ iconMap[toast.type] || '🔔' }}</div>
        <div class="toast-body">
          <p class="toast-title">{{ toast.title }}</p>
          <p v-if="toast.message" class="toast-message">{{ toast.message }}</p>
        </div>
        <button class="toast-close" @click.stop="removeToast(toast.id)">✕</button>
      </div>
    </TransitionGroup>
  </Teleport>
</template>

<script setup>
import { ref } from 'vue'

const toasts = ref([])
let nextId = 0

const iconMap = {
  success: '✅',
  error: '❌',
  warning: '⚠️',
  info: 'ℹ️',
  notification: '🔔',
  postulacion: '📋',
  publicacion: '📢',
}

function addToast({ title, message = '', type = 'notification', duration = 5000 }) {
  const id = ++nextId
  toasts.value.push({ id, title, message, type })

  if (duration > 0) {
    setTimeout(() => removeToast(id), duration)
  }
}

function removeToast(id) {
  const idx = toasts.value.findIndex(t => t.id === id)
  if (idx !== -1) toasts.value.splice(idx, 1)
}

function clearAll() {
  toasts.value = []
}

defineExpose({ addToast, removeToast, clearAll })
</script>

<style scoped>
.toast-container {
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 380px;
  width: 100%;
  pointer-events: none;
}

.toast {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 12px;
  background: var(--white, #fff);
  border: 1px solid var(--gray-200, #e5e7eb);
  box-shadow: 0 8px 24px rgba(0, 0, 0, .12), 0 2px 8px rgba(0, 0, 0, .08);
  cursor: pointer;
  pointer-events: auto;
  backdrop-filter: blur(12px);
  animation: toast-shake 0.4s ease;
}

.toast-notification { border-left: 4px solid var(--primary, #2563eb); }
.toast-success      { border-left: 4px solid var(--success, #16a34a); }
.toast-error        { border-left: 4px solid var(--danger, #dc2626); }
.toast-warning      { border-left: 4px solid var(--warning, #d97706); }
.toast-info         { border-left: 4px solid var(--primary, #2563eb); }
.toast-postulacion  { border-left: 4px solid #8b5cf6; }
.toast-publicacion  { border-left: 4px solid var(--secondary, #059669); }

.toast-icon {
  font-size: 20px;
  flex-shrink: 0;
  margin-top: 1px;
}

.toast-body {
  flex: 1;
  min-width: 0;
}

.toast-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--gray-800, #1f2937);
  line-height: 1.4;
}

.toast-message {
  font-size: 12px;
  color: var(--gray-500, #6b7280);
  margin-top: 2px;
  line-height: 1.4;
}

.toast-close {
  background: none;
  border: none;
  color: var(--gray-400, #9ca3af);
  cursor: pointer;
  font-size: 14px;
  padding: 0;
  line-height: 1;
  flex-shrink: 0;
  transition: color 0.15s;
}
.toast-close:hover { color: var(--gray-700, #374151); }

/* Transitions */
.toast-enter-active {
  animation: toast-slide-in 0.35s cubic-bezier(0.21, 1.02, 0.73, 1);
}
.toast-leave-active {
  animation: toast-slide-out 0.25s ease forwards;
}
.toast-move {
  transition: transform 0.3s ease;
}

@keyframes toast-slide-in {
  from { opacity: 0; transform: translateX(100%) scale(0.9); }
  to   { opacity: 1; transform: translateX(0) scale(1); }
}

@keyframes toast-slide-out {
  from { opacity: 1; transform: translateX(0) scale(1); }
  to   { opacity: 0; transform: translateX(100%) scale(0.9); }
}

@keyframes toast-shake {
  0%, 100% { transform: translateX(0); }
  20% { transform: translateX(-3px); }
  40% { transform: translateX(3px); }
  60% { transform: translateX(-2px); }
  80% { transform: translateX(2px); }
}

@media (max-width: 480px) {
  .toast-container {
    right: 8px;
    left: 8px;
    max-width: none;
  }
}
</style>
