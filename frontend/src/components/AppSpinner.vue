<template>
  <div :class="['spinner-wrap', small ? 'spinner-wrap--sm' : '']" role="status" aria-label="Cargando…">
    <svg
      :class="['spinner-svg', small ? 'spinner-svg--sm' : '']"
      viewBox="0 0 50 50"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle
        cx="25" cy="25" r="20"
        stroke="currentColor"
        stroke-width="4"
        stroke-linecap="round"
        stroke-dasharray="80 40"
        opacity="0.2"
      />
      <circle
        class="spinner-arc"
        cx="25" cy="25" r="20"
        stroke="currentColor"
        stroke-width="4"
        stroke-linecap="round"
        stroke-dasharray="60 60"
        stroke-dashoffset="0"
        fill="none"
      />
    </svg>
  </div>
</template>

<script setup>
defineProps({ small: Boolean })
</script>

<style scoped>
.spinner-wrap {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--primary);
  padding: 4px;
}
.spinner-wrap--sm {
  padding: 0;
}

.spinner-svg {
  width: 40px;
  height: 40px;
  animation: spin 0.9s linear infinite;
}
.spinner-svg--sm {
  width: 18px;
  height: 18px;
}

.spinner-arc {
  stroke: currentColor;
  opacity: 1;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
