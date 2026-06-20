<template>
  <Transition name="alert-slide">
    <div v-if="message" :class="['app-alert', `app-alert--${type}`]" role="alert">
      <!-- Icon -->
      <div class="alert-icon">
        <!-- danger / default -->
        <svg v-if="type === 'danger'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
        <!-- success -->
        <svg v-else-if="type === 'success'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
        <!-- warning -->
        <svg v-else-if="type === 'warning'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
        </svg>
        <!-- info -->
        <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
        </svg>
      </div>
      <span class="alert-text">{{ message }}</span>
    </div>
  </Transition>
</template>

<script setup>
defineProps({
  message: String,
  type: { type: String, default: 'danger' }
})
</script>

<style scoped>
.app-alert {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 11px 14px;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 500;
  line-height: 1.5;
  margin-bottom: 12px;
  border: 1px solid transparent;
}

.app-alert--danger  { background: var(--danger-light);  color: #991b1b; border-color: #fca5a5; }
.app-alert--success { background: #d1fae5;               color: #065f46; border-color: #6ee7b7; }
.app-alert--warning { background: #fef3c7;               color: #92400e; border-color: #fcd34d; }
.app-alert--info    { background: var(--accent-light);   color: #0c4a6e; border-color: #7dd3fc; }

.alert-icon {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  margin-top: 1px;
}

.alert-text {
  flex: 1;
}

/* Transition */
.alert-slide-enter-active { animation: alert-in .2s ease; }
.alert-slide-leave-active { animation: alert-in .15s ease reverse; }

@keyframes alert-in {
  from { opacity: 0; transform: translateY(-6px); }
  to   { opacity: 1; transform: translateY(0); }
}
</style>
