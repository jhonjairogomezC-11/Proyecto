<template>
  <div class="stat-card-modern" :class="variant">
    <div class="stat-icon-wrap">
      <slot name="icon">{{ icon }}</slot>
    </div>
    <div class="stat-body">
      <p class="stat-value">{{ value }}</p>
      <p class="stat-label">{{ label }}</p>
      <p v-if="sub" class="stat-sub">{{ sub }}</p>
    </div>
  </div>
</template>

<script setup>
defineProps({
  icon: { type: String, default: '📊' },
  value: { type: [String, Number], required: true },
  label: { type: String, required: true },
  sub: { type: String, default: '' },
  variant: { type: String, default: 'blue' },
})
</script>

<style scoped>
.stat-card-modern {
  border-radius: 16px;
  padding: 20px;
  color: #fff;
  display: flex;
  gap: 14px;
  align-items: flex-start;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.08);
  transition: var(--transition);
  min-height: 110px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}
.stat-card-modern:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 32px rgba(15, 23, 42, 0.15);
}
.stat-card-modern.blue   { background: linear-gradient(135deg, #0ea5e9, #0284c7); }
.stat-card-modern.purple { background: linear-gradient(135deg, #6366f1, #4f46e5); }
.stat-card-modern.green  { background: linear-gradient(135deg, #10b981, #059669); }
.stat-card-modern.orange { background: linear-gradient(135deg, #f59e0b, #d97706); }
.stat-card-modern.teal   { background: linear-gradient(135deg, #14b8a6, #0d9488); }

.stat-icon-wrap {
  background: rgba(255,255,255,.18);
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #fff;
}
.stat-icon-wrap :deep(svg) {
  width: 24px;
  height: 24px;
}
.stat-value {
  font-size: 28px;
  font-weight: 800;
  line-height: 1.1;
  margin-bottom: 2px;
  font-family: 'Outfit', sans-serif;
}
.stat-label {
  font-size: 13px;
  font-weight: 600;
  opacity: 0.95;
}
.stat-sub {
  font-size: 11px;
  opacity: 0.85;
  margin-top: 4px;
}
</style>
