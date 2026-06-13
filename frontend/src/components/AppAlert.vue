<template>
  <div v-if="message" :class="['alert', `alert-${type}`]" role="alert">
    <span>{{ icon }}</span>
    <span>{{ message }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  message: String,
  type: { type: String, default: 'danger' }
})

const icon = computed(() => ({
  danger: '⚠️', success: '✅', warning: '⚠️', info: 'ℹ️'
}[props.type] || '⚠️'))
</script>
