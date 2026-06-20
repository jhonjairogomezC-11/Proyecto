<template>
  <Teleport to="body">
    <TransitionGroup name="toast" tag="div" class="toast-container">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        :class="['toast', `toast--${toast.type}`]"
        @click="removeToast(toast.id)"
      >
        <!-- Left accent bar is handled by CSS border-left -->
        <!-- Icon -->
        <div class="toast-icon" :class="`toast-icon--${toast.type}`">
          <!-- success -->
          <svg v-if="toast.type === 'success'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="16" height="16"><polyline points="20 6 9 17 4 12"/></svg>
          <!-- error -->
          <svg v-else-if="toast.type === 'error'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="16" height="16"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          <!-- warning -->
          <svg v-else-if="toast.type === 'warning'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
          <!-- postulacion -->
          <svg v-else-if="toast.type === 'postulacion'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
          <!-- publicacion / info / default bell -->
          <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        </div>

        <div class="toast-body">
          <p class="toast-title">{{ toast.title }}</p>
          <p v-if="toast.message" class="toast-message">{{ toast.message }}</p>
        </div>

        <button class="toast-close" @click.stop="removeToast(toast.id)" aria-label="Cerrar">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="12" height="12"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
    </TransitionGroup>
  </Teleport>
</template>

<script setup>
import { ref } from 'vue'

const toasts = ref([])
let nextId = 0

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
  top: 20px;
  right: 20px;
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
  background: var(--white);
  border: 1px solid var(--gray-200);
  border-left-width: 4px;
  box-shadow: 0 10px 30px rgba(0,0,0,.12), 0 2px 8px rgba(0,0,0,.06);
  cursor: pointer;
  pointer-events: auto;
  backdrop-filter: blur(12px);
}

/* Left accent colors */
.toast--notification  { border-left-color: var(--primary); }
.toast--success       { border-left-color: #16a34a; }
.toast--error         { border-left-color: var(--danger); }
.toast--warning       { border-left-color: var(--warning); }
.toast--info          { border-left-color: var(--accent); }
.toast--postulacion   { border-left-color: #7c3aed; }
.toast--publicacion   { border-left-color: var(--secondary); }

/* Icon containers */
.toast-icon {
  display: flex; align-items: center; justify-content: center;
  width: 28px; height: 28px; border-radius: 8px;
  flex-shrink: 0;
}
.toast-icon--success    { background: #d1fae5; color: #16a34a; }
.toast-icon--error      { background: var(--danger-light); color: var(--danger); }
.toast-icon--warning    { background: #fef3c7; color: #d97706; }
.toast-icon--postulacion{ background: #ede9fe; color: #7c3aed; }
.toast-icon--notification,
.toast-icon--info,
.toast-icon--publicacion{ background: var(--primary-light); color: var(--primary); }

.toast-body {
  flex: 1;
  min-width: 0;
}

.toast-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--gray-900);
  line-height: 1.4;
  margin: 0;
}

.toast-message {
  font-size: 12px;
  color: var(--gray-500);
  margin: 2px 0 0;
  line-height: 1.4;
}

.toast-close {
  display: flex; align-items: center; justify-content: center;
  width: 22px; height: 22px; border-radius: 6px;
  border: none; background: none;
  color: var(--gray-400); cursor: pointer;
  transition: all .15s; flex-shrink: 0;
  margin-top: 1px;
}
.toast-close:hover { background: var(--gray-100); color: var(--gray-700); }

/* Transitions */
.toast-enter-active { animation: toast-in .3s cubic-bezier(.21,1.02,.73,1); }
.toast-leave-active { animation: toast-in .2s ease reverse; position: absolute; right: 0; }
.toast-move         { transition: transform .3s ease; }

@keyframes toast-in {
  from { opacity: 0; transform: translateX(100%) scale(.9); }
  to   { opacity: 1; transform: translateX(0) scale(1); }
}

@media (max-width: 480px) {
  .toast-container { right: 8px; left: 8px; max-width: none; }
}
</style>
