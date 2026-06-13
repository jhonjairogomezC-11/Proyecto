<template>
  <div v-if="meta && meta.last_page > 1" class="pagination mt-4">
    <button :disabled="meta.current_page === 1" @click="$emit('page', meta.current_page - 1)">← Anterior</button>
    <template v-for="p in pages" :key="p">
      <button v-if="p !== '...'" :class="{ active: p === meta.current_page }" @click="$emit('page', p)">{{ p }}</button>
      <span v-else style="padding:6px 4px;color:var(--gray-400)">…</span>
    </template>
    <button :disabled="meta.current_page === meta.last_page" @click="$emit('page', meta.current_page + 1)">Siguiente →</button>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ meta: Object })
defineEmits(['page'])

const pages = computed(() => {
  if (!props.meta) return []
  const { current_page, last_page } = props.meta
  const range = []
  for (let i = 1; i <= last_page; i++) {
    if (i === 1 || i === last_page || (i >= current_page - 2 && i <= current_page + 2)) {
      range.push(i)
    } else if (range[range.length - 1] !== '...') {
      range.push('...')
    }
  }
  return range
})
</script>
