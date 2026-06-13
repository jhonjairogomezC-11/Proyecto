<template>
  <div :class="['spinner', small ? 'spinner-sm' : '']" role="status" aria-label="Cargando…"></div>
</template>

<script setup>
defineProps({ small: Boolean })
</script>
