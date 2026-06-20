<template>
  <div class="stat-card-modern" :class="variant">
    <div class="stat-icon-wrap">{{ icon }}</div>
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
  box-shadow: 0 8px 24px rgba(0,0,0,.12);
  transition: transform 0.2s, box-shadow 0.2s;
  min-height: 110px;
}
.stat-card-modern:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 32px rgba(0,0,0,.16);
}
.stat-card-modern.blue   { background: linear-gradient(135deg, #3b82f6, #2563eb); }
.stat-card-modern.purple { background: linear-gradient(135deg, #8b5cf6, #6366f1); }
.stat-card-modern.green  { background: linear-gradient(135deg, #10b981, #059669); }
.stat-card-modern.orange { background: linear-gradient(135deg, #f59e0b, #ea580c); }
.stat-card-modern.teal   { background: linear-gradient(135deg, #14b8a6, #0d9488); }

.stat-icon-wrap {
  font-size: 28px;
  background: rgba(255,255,255,.2);
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.stat-value {
  font-size: 28px;
  font-weight: 800;
  line-height: 1.1;
  margin-bottom: 2px;
}
.stat-label {
  font-size: 13px;
  font-weight: 500;
  opacity: 0.92;
}
.stat-sub {
  font-size: 11px;
  opacity: 0.8;
  margin-top: 4px;
}
</style>
