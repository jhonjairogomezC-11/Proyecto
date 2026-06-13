<template>
  <Teleport to="body">
    <div v-if="modelValue" class="modal-backdrop" @click.self="$emit('update:modelValue', false)">
      <div class="modal" role="dialog" :aria-label="title">
        <div class="modal-header">
          <h3>{{ title }}</h3>
          <button class="btn btn-ghost btn-icon" @click="$emit('update:modelValue', false)" aria-label="Cerrar">✕</button>
        </div>
        <div class="modal-body">
          <slot />
        </div>
        <div v-if="$slots.footer" class="modal-footer">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
defineProps({ modelValue: Boolean, title: String })
defineEmits(['update:modelValue'])
</script>
