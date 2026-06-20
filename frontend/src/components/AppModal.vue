<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div v-if="modelValue" class="modal-backdrop" @click.self="$emit('update:modelValue', false)">
        <div class="modal" role="dialog" :aria-label="title">
          <!-- Header -->
          <div class="modal-header">
            <h3 class="modal-title">{{ title }}</h3>
            <button class="modal-close" @click="$emit('update:modelValue', false)" aria-label="Cerrar">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="16" height="16"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
          <!-- Body -->
          <div class="modal-body">
            <slot />
          </div>
          <!-- Footer -->
          <div v-if="$slots.footer" class="modal-footer">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
defineProps({ modelValue: Boolean, title: String })
defineEmits(['update:modelValue'])
</script>

<style scoped>
.modal-backdrop {
  position: fixed; inset: 0; z-index: 9000;
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(6px);
  display: flex; align-items: center; justify-content: center;
  padding: 16px;
}

.modal {
  background: var(--white);
  border-radius: 16px;
  width: 100%;
  max-width: 540px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow:
    0 0 0 1px rgba(0,0,0,.08),
    0 24px 60px rgba(0,0,0,.18),
    0 8px 20px rgba(0,0,0,.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 22px 16px;
  border-bottom: 1px solid var(--gray-100);
  flex-shrink: 0;
}

.modal-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--gray-900);
  margin: 0;
}

.modal-close {
  display: flex; align-items: center; justify-content: center;
  width: 30px; height: 30px;
  border-radius: 8px; border: none;
  background: var(--gray-100); color: var(--gray-500);
  cursor: pointer; transition: all .15s;
}
.modal-close:hover { background: var(--gray-200); color: var(--gray-800); }

.modal-body {
  padding: 20px 22px;
  overflow-y: auto;
  flex: 1;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 14px 22px;
  border-top: 1px solid var(--gray-100);
  flex-shrink: 0;
  background: var(--gray-50);
}

/* Transition */
.modal-fade-enter-active { animation: modal-in .25s cubic-bezier(.21,1.02,.73,1); }
.modal-fade-leave-active { animation: modal-in .18s ease reverse; }

@keyframes modal-in {
  from { opacity: 0; transform: scale(.95) translateY(8px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
