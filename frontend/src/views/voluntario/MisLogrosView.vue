<template>
  <div>
    <h1 class="page-title mb-2">Mis Logros y Puntos</h1>
    <p class="text-muted text-sm mb-6">Tu progreso y reconocimientos por participar en voluntariado.</p>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <template v-else>
      <!-- Resumen de puntos -->
      <div class="puntos-banner mb-6">
        <div class="puntos-main">
          <div class="puntos-icono">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          </div>
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
            <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>
            <h3>Sin logros aún</h3>
            <p>Participa en convocatorias para desbloquear tus primeros logros.</p>
          </div>
          <div v-else class="logros-grid">
            <div v-for="l in logros.obtenidos" :key="l.id" class="logro-card obtenido">
              <div class="logro-icono" v-html="obtenerIconoLogro(l.codigo)"></div>
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
            <svg class="empty-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>
            <h3>¡Has desbloqueado todos los logros disponibles!</h3>
          </div>
          <div v-else class="pendientes-list">
            <div v-for="l in logros.pendientes" :key="l.id" class="pendiente-item">
              <div class="pend-icono" v-html="obtenerIconoLogro(l.codigo)"></div>
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
            <div class="trans-icono">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
            </div>
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

// Mapear código de logro a SVG vectorial e interactivo
function obtenerIconoLogro(codigo) {
  const icons = {
    PRIMER_PASO: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 16v1a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-1"/><polyline points="16 12 12 16 8 12"/><line x1="12" y1="16" x2="12" y2="4"/></svg>',
    COMPROMETIDO: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m11 17 2 2a1 1 0 0 0 1.4 0l4-4a1 1 0 0 0 0-1.4l-2-2"/><path d="m13 13-2-2a1 1 0 0 0-1.4 0l-4 4a1 1 0 0 0 0 1.4l2 2"/><circle cx="12" cy="12" r="10"/></svg>',
    VOLUNTARIO_ACTIVO: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>',
    IMPACTO_SOCIAL: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>',
    LEYENDA_SOLIDARIA: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></svg>',
    ACUMULADOR: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 6v12"/><path d="M17 12H7"/></svg>',
    VETERANO: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>',
    ELITE: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h12l4 6-10 13L2 9z"/></svg>',
    VALIENTE: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M12 2v9"/><path d="M8 5h8"/></svg>',
    HEROE: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><circle cx="12" cy="11" r="3"/></svg>',
    URGENTE_RESPONDER: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>'
  }
  return icons[codigo] || '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>'
}

onMounted(async () => {
  try {
    const pResp = await api.get('/voluntario/puntos')
    puntos.value = pResp.data || { saldo: 0, total_historico: 0, transacciones: [] }
    const lResp = await api.get('/voluntario/logros')
    logros.value = lResp.data || { obtenidos: [], pendientes: [] }
  } catch (e) {
    console.warn('[Logros]', e)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 800; color: var(--gray-900); font-family: 'Outfit', sans-serif; letter-spacing: -0.02em; }

.puntos-banner {
  background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
  border-radius: var(--radius-lg);
  padding: 24px 32px;
  color: var(--white);
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: var(--shadow-md);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
.puntos-main { display: flex; align-items: center; gap: 16px; }
.puntos-icono {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--white);
}
.puntos-valor { font-size: 32px; font-weight: 800; line-height: 1.1; font-family: 'Outfit', sans-serif; }
.puntos-lbl { font-size: 13px; font-weight: 600; opacity: 0.9; }
.puntos-historico { text-align: right; }
.puntos-hist-val { font-size: 20px; font-weight: 700; font-family: 'Outfit', sans-serif; }

.logros-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}
.logro-card {
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-lg);
  padding: 20px;
  text-align: center;
  background: var(--white);
  transition: var(--transition);
}
.logro-card:hover { transform: translateY(-3px); box-shadow: var(--shadow); }
.logro-card.obtenido { border-top: 4px solid var(--success); }
.logro-icono {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--primary-light);
  color: var(--primary);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 12px;
}
.logro-nombre { font-size: 14px; font-weight: 700; color: var(--gray-800); font-family: 'Outfit', sans-serif; margin-bottom: 4px; }
.logro-desc { font-size: 12px; color: var(--gray-500); line-height: 1.4; margin-bottom: 8px; }
.logro-fecha { font-size: 11px; }

.pendientes-list { display: flex; flex-direction: column; gap: 14px; }
.pendiente-item {
  display: flex;
  gap: 16px;
  padding: 16px;
  border: 1px solid var(--gray-200);
  border-radius: var(--radius-lg);
  background: var(--white);
}
.pend-icono {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--gray-100);
  color: var(--gray-400);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.pend-info { flex: 1; min-width: 0; }
.progress-bar { height: 6px; background: var(--gray-100); border-radius: 99px; overflow: hidden; }
.progress-fill { height: 100%; background: var(--primary); border-radius: 99px; }

.trans-row {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--gray-100);
}
.trans-row:last-child { border-bottom: none; }
.trans-icono {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: var(--success-light);
  color: var(--success);
  display: flex;
  align-items: center;
  justify-content: center;
}
.trans-info { flex: 1; min-width: 0; }
.trans-fecha { margin-left: auto; }

.empty-icon {
  margin: 0 auto 12px;
  color: var(--gray-300);
  display: block;
}
</style>
