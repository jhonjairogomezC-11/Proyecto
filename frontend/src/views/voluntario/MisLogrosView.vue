<template>
  <div>
    <h1 class="page-title mb-2">🎖️ Mis Logros y Puntos</h1>
    <p class="text-muted text-sm mb-6">Tu progreso y reconocimientos por participar en voluntariado.</p>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <!-- Resumen de puntos -->
      <div class="puntos-banner mb-6">
        <div class="puntos-main">
          <div class="puntos-icono">⭐</div>
          <div>
            <p class="puntos-valor">{{ puntos.saldo ?? 0 }}</p>
            <p class="puntos-lbl">Puntos disponibles</p>
          </div>
        </div>
        <div class="puntos-historico">
          <p class="puntos-hist-val">{{ puntos.total_historico ?? 0 }}</p>
          <p class="text-xs text-muted">Total histórico</p>
        </div>
      </div>

      <!-- Logros obtenidos -->
      <div class="card mb-6">
        <div class="card-header">
          <h3>Logros obtenidos <span class="badge badge-success" style="margin-left:6px">{{ logros.obtenidos?.length || 0 }}</span></h3>
        </div>
        <div class="card-body">
          <div v-if="!logros.obtenidos?.length" class="empty-state" style="padding:32px">
            <div class="icon">🎯</div>
            <h3>Sin logros aún</h3>
            <p>Participa en convocatorias para desbloquear tus primeros logros.</p>
          </div>
          <div v-else class="logros-grid">
            <div v-for="l in logros.obtenidos" :key="l.id" class="logro-card obtenido">
              <div class="logro-icono">{{ l.icono }}</div>
              <p class="logro-nombre">{{ l.nombre }}</p>
              <p class="logro-desc">{{ l.descripcion }}</p>
              <p class="logro-fecha text-xs text-muted">{{ formatDate(l.fecha_obtencion) }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Logros pendientes con progreso -->
      <div class="card">
        <div class="card-header">
          <h3>En progreso <span class="badge badge-gray" style="margin-left:6px">{{ logros.pendientes?.length || 0 }}</span></h3>
        </div>
        <div class="card-body">
          <div v-if="!logros.pendientes?.length" class="empty-state" style="padding:32px">
            <p class="text-muted">¡Has desbloqueado todos los logros disponibles! 🏆</p>
          </div>
          <div v-else class="pendientes-list">
            <div v-for="l in logros.pendientes" :key="l.id" class="pendiente-item">
              <div class="pend-icono">{{ l.icono }}</div>
              <div class="pend-info">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:4px">
                  <p class="font-medium text-sm">{{ l.nombre }}</p>
                  <span class="text-xs text-muted">{{ l.progreso }}/{{ l.umbral }}</span>
                </div>
                <p class="text-xs text-muted mb-2">{{ l.descripcion }}</p>
                <div class="progress-bar">
                  <div class="progress-fill" :style="{ width: l.porcentaje + '%' }"></div>
                </div>
                <p class="text-xs text-muted mt-1">{{ l.porcentaje }}% completado</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Últimas transacciones -->
      <div v-if="puntos.transacciones?.length" class="card mt-6">
        <div class="card-header"><h3>Últimas ganancias de puntos</h3></div>
        <div class="card-body" style="padding:0">
          <div v-for="t in puntos.transacciones" :key="t.id" class="trans-row">
            <div class="trans-icono">⭐</div>
            <div class="trans-info">
              <p class="text-sm font-medium">+{{ t.puntos_total }} pts</p>
              <p class="text-xs text-muted">{{ t.motivo }}</p>
            </div>
            <p class="text-xs text-muted trans-fecha">{{ formatDate(t.fecha) }}</p>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'

const loading = ref(true)
const puntos  = ref({ saldo: 0, total_historico: 0, transacciones: [] })
const logros  = ref({ obtenidos: [], pendientes: [] })

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

onMounted(async () => {
  try {
    const [rPuntos, rLogros] = await Promise.all([
      api.get('/voluntario/puntos'),
      api.get('/voluntario/logros'),
    ])
    puntos.value = rPuntos.data
    logros.value = rLogros.data
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.page-title { font-size: 22px; font-weight: 700; }

/* Banner de puntos */
.puntos-banner {
  background: linear-gradient(135deg, #1d4ed8, #059669);
  border-radius: var(--radius-lg);
  padding: 24px 28px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: #fff;
}
.puntos-main { display: flex; align-items: center; gap: 16px; }
.puntos-icono { font-size: 40px; }
.puntos-valor { font-size: 40px; font-weight: 800; line-height: 1; }
.puntos-lbl   { font-size: 14px; opacity: .85; margin-top: 4px; }
.puntos-historico { text-align: right; }
.puntos-hist-val { font-size: 28px; font-weight: 700; }

/* Logros obtenidos */
.logros-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 16px; }
.logro-card {
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  padding: 18px 12px;
  border-radius: var(--radius-lg);
  text-align: center;
  transition: transform .18s;
}
.logro-card:hover { transform: translateY(-2px); }
.logro-card.obtenido { background: linear-gradient(135deg, #fffbeb, #fef3c7); border: 1.5px solid #fcd34d; }
.logro-icono { font-size: 36px; }
.logro-nombre { font-size: 13px; font-weight: 700; color: var(--gray-800); }
.logro-desc   { font-size: 11px; color: var(--gray-500); line-height: 1.4; }
.logro-fecha  { font-size: 10px; }

/* Pendientes */
.pendientes-list { display: flex; flex-direction: column; gap: 0; }
.pendiente-item {
  display: flex; gap: 14px; padding: 14px 0;
  border-bottom: 1px solid var(--gray-100);
  align-items: flex-start;
}
.pendiente-item:last-child { border-bottom: none; }
.pend-icono { font-size: 28px; flex-shrink: 0; opacity: .5; }
.pend-info  { flex: 1; }
.progress-bar { height: 6px; background: var(--gray-200); border-radius: 99px; overflow: hidden; }
.progress-fill { height: 100%; background: linear-gradient(90deg, var(--primary), var(--secondary)); border-radius: 99px; transition: width .4s; }

/* Transacciones */
.trans-row { display: flex; align-items: center; gap: 12px; padding: 11px 18px; border-bottom: 1px solid var(--gray-100); }
.trans-row:last-child { border-bottom: none; }
.trans-icono { font-size: 18px; flex-shrink: 0; }
.trans-info  { flex: 1; min-width: 0; }
.trans-fecha { flex-shrink: 0; }
</style>
