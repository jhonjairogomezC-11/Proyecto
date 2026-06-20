<template>
  <nav v-if="meta && meta.last_page > 1" class="pagination" aria-label="Paginación">
    <!-- Prev -->
    <button
      class="page-btn page-nav"
      :disabled="meta.current_page === 1"
      @click="$emit('page', meta.current_page - 1)"
      aria-label="Página anterior"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><polyline points="15 18 9 12 15 6"/></svg>
    </button>

    <!-- Pages -->
    <template v-for="p in pages" :key="p">
      <button
        v-if="p !== '...'"
        :class="['page-btn', p === meta.current_page ? 'page-btn--active' : '']"
        @click="$emit('page', p)"
        :aria-current="p === meta.current_page ? 'page' : undefined"
      >
        {{ p }}
      </button>
      <span v-else class="page-ellipsis">…</span>
    </template>

    <!-- Next -->
    <button
      class="page-btn page-nav"
      :disabled="meta.current_page === meta.last_page"
      @click="$emit('page', meta.current_page + 1)"
      aria-label="Página siguiente"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="14" height="14"><polyline points="9 18 15 12 9 6"/></svg>
    </button>
  </nav>
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

<style scoped>
.pagination {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 20px;
  justify-content: center;
}

.page-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 34px;
  height: 34px;
  padding: 0 8px;
  border-radius: 8px;
  border: 1px solid var(--gray-200);
  background: var(--white);
  color: var(--gray-600);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all .15s;
  line-height: 1;
}

.page-btn:hover:not(:disabled):not(.page-btn--active) {
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-light);
}

.page-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.page-btn--active {
  background: var(--primary);
  color: #fff;
  border-color: var(--primary);
  font-weight: 600;
  pointer-events: none;
}

.page-nav {
  color: var(--gray-500);
}

.page-ellipsis {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  color: var(--gray-400);
  font-size: 13px;
  letter-spacing: .1em;
}
</style>
