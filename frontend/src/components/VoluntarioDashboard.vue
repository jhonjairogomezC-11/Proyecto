<template>
  <div class="vol-dashboard">
    <!-- Hero -->
    <section class="hero-banner">
      <div class="hero-content">
        <p class="hero-greeting">Hola, {{ auth.user?.nombre?.split(' ')[0] }}</p>
        <h2 class="hero-title">Estás haciendo una diferencia increíble</h2>
        <p class="hero-sub">Aquí está tu resumen de impacto y próximos compromisos.</p>
        <RouterLink :to="{ name: 'convocatorias' }" class="btn-hero">Explorar actividades</RouterLink>
      </div>
      <div class="hero-level">
        <span class="level-badge" :style="{ background: data?.nivel?.nivel_actual?.color || '#cd7f32' }">
          {{ data?.nivel?.nivel_actual?.nombre || 'Bronce' }}
        </span>
        <p class="level-pts">{{ data?.puntos?.total_historico || 0 }} pts</p>
      </div>
    </section>

    <div v-if="!tienePerfil" class="alert alert-warning mb-6">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
      <span>Completa tu <RouterLink :to="{ name: 'perfil-voluntario' }">perfil de voluntario</RouterLink> para postularte a convocatorias.</span>
    </div>

    <!-- Stats -->
    <div class="stats-grid">
      <GradientStatCard
        :value="data?.actividades_completadas?.total || 0"
        label="Actividades completadas"
        :sub="`+${data?.actividades_completadas?.este_mes || 0} este mes · ${data?.actividades_completadas?.esta_semana || 0} esta semana`"
        variant="blue"
      >
        <template #icon>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        </template>
      </GradientStatCard>
      
      <GradientStatCard
        :value="data?.puntos?.total_historico || 0"
        label="Puntos acumulados"
        :sub="data?.nivel?.puntos_faltan ? `${data.nivel.puntos_faltan} pts para ${data.nivel.nivel_siguiente?.nombre}` : 'Nivel máximo alcanzado'"
        variant="purple"
      >
        <template #icon>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
        </template>
      </GradientStatCard>

      <GradientStatCard
        :value="data?.logros?.desbloqueados || 0"
        label="Logros desbloqueados"
        :sub="data?.logro_proximo ? `Próximo: ${data.logro_proximo.nombre}` : '¡Todos desbloqueados!'"
        variant="green"
      >
        <template #icon>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>
        </template>
      </GradientStatCard>

      <GradientStatCard
        :value="data?.ranking?.posicion ? `#${data.ranking.posicion}` : '—'"
        label="Posición en ranking"
        :sub="data?.ranking?.top_percent ? `Top ${data.ranking.top_percent}%` : 'Sin ranking aún'"
        variant="orange"
      >
        <template #icon>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34"/><path d="M12 2a6.3 6.3 0 0 0-6 6.5C6 13.4 9.4 15 12 15s6-1.6 6-6.5C18 3.4 15.6 2 12 2Z"/></svg>
        </template>
      </GradientStatCard>
    </div>

    <!-- Postulaciones resumen -->
    <div class="post-summary">
      <div class="post-pill pending">
        <span class="pill-dot"></span>
        <span class="pill-num">{{ data?.postulaciones_resumen?.pendientes || 0 }}</span>
        <span class="pill-label">Pendientes</span>
      </div>
      <div class="post-pill accepted">
        <span class="pill-dot"></span>
        <span class="pill-num">{{ data?.postulaciones_resumen?.aceptadas || 0 }}</span>
        <span class="pill-label">Aprobadas</span>
      </div>
      <div class="post-pill rejected">
        <span class="pill-dot"></span>
        <span class="pill-num">{{ data?.postulaciones_resumen?.rechazadas || 0 }}</span>
        <span class="pill-label">Rechazadas</span>
      </div>
    </div>

    <div class="dashboard-grid">
      <!-- Próximas actividades -->
      <section class="panel">
        <div class="panel-header">
          <div>
            <h3>Próximas actividades</h3>
            <p class="panel-sub">Tus compromisos confirmados y pendientes</p>
          </div>
          <RouterLink :to="{ name: 'mis-postulaciones' }" class="link-more">Ver todas →</RouterLink>
        </div>
        
        <div v-if="!proximas.length" class="empty-mini">
          <svg class="empty-mini-icon" width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          <p>No tienes actividades próximas. <RouterLink :to="{ name: 'convocatorias' }">Explora convocatorias</RouterLink></p>
        </div>
        
        <div v-else class="activity-list">
          <div v-for="p in proximas" :key="p.id" class="activity-item">
            <div class="activity-icon-wrap" :class="p.estado.toLowerCase()">
              <component :is="estadoSvg(p.estado)" />
            </div>
            <div class="activity-info">
              <p class="activity-title">{{ p.publicacion?.titulo }}</p>
              <p class="activity-meta">{{ p.publicacion?.fundacion?.nombre }}</p>
              <p class="activity-date">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align: middle; margin-right: 4px;"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                <span>{{ formatDate(p.publicacion?.fecha_inicio) }}</span>
              </p>
            </div>
            <BadgeEstado :estado="p.estado" tipo="postulacion" />
          </div>
        </div>
      </section>

      <!-- Tu progreso -->
      <section class="panel">
        <div class="panel-header">
          <div>
            <h3>Tu progreso</h3>
            <p class="panel-sub">Camino al siguiente nivel y logros</p>
          </div>
        </div>

        <div class="progress-block">
          <div class="progress-head">
            <span>Nivel: {{ data?.nivel?.nivel_actual?.nombre || 'Bronce' }}</span>
            <span class="progress-nums">{{ data?.puntos?.total_historico || 0 }} / {{ data?.nivel?.umbral_siguiente || '∞' }} pts</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill level" :style="{ width: `${data?.nivel?.porcentaje || 0}%` }"></div>
          </div>
          <p v-if="data?.nivel?.puntos_faltan" class="progress-hint">
            Te faltan <strong>{{ data.nivel.puntos_faltan }} puntos</strong> para nivel {{ data.nivel.nivel_siguiente?.nombre }}
          </p>
        </div>

        <div class="progress-block">
          <div class="progress-head">
            <span>Participación este mes</span>
            <span class="progress-nums">{{ data?.progreso_mensual?.completadas || 0 }} / {{ data?.progreso_mensual?.meta || 5 }}</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill month" :style="{ width: `${data?.progreso_mensual?.porcentaje || 0}%` }"></div>
          </div>
          <p v-if="data?.progreso_mensual?.faltan" class="progress-hint">
            <strong>{{ data.progreso_mensual.faltan }} más</strong> para cumplir tu meta mensual
          </p>
        </div>

        <div v-if="data?.logro_proximo" class="progress-block logro-block">
          <div class="progress-head">
            <span class="flex items-center gap-2">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              <span>Próximo logro</span>
            </span>
            <span class="progress-nums">{{ data.logro_proximo.progreso }} / {{ data.logro_proximo.umbral }}</span>
          </div>
          <p class="logro-name">{{ data.logro_proximo.nombre }}</p>
          <div class="progress-bar">
            <div class="progress-fill logro" :style="{ width: `${data.logro_proximo.porcentaje || 0}%` }"></div>
          </div>
        </div>

        <div v-if="logrosRecientes.length" class="recent-logros">
          <p class="recent-title">Últimos logros desbloqueados</p>
          <div v-for="l in logrosRecientes" :key="l.id" class="logro-item">
            <span class="logro-icon-wrap">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>
            </span>
            <div class="logro-details">
              <p class="logro-item-name">{{ l.nombre }}</p>
              <p class="logro-item-date">{{ formatRelative(l.fecha_obtencion) }}</p>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'
import GradientStatCard from '@/components/GradientStatCard.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const auth = useAuthStore()
const data = ref(null)
const tienePerfil = ref(false)

const proximas = computed(() => data.value?.proximas_actividades || [])
const logrosRecientes = computed(() => data.value?.logros?.recientes || [])

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

function formatRelative(d) {
  if (!d) return ''
  const diff = Date.now() - new Date(d).getTime()
  const days = Math.floor(diff / 86400000)
  if (days < 1) return 'Hoy'
  if (days === 1) return 'Ayer'
  if (days < 7) return `Hace ${days} días`
  if (days < 30) return `Hace ${Math.floor(days / 7)} semanas`
  return formatDate(d)
}

function estadoSvg(estado) {
  const icons = {
    PENDIENTE: h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2 }, [
      h('circle', { cx: 12, cy: 12, r: 10 }),
      h('polyline', { points: '12 6 12 12 16 14' })
    ]),
    ACEPTADO: h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2.5 }, [
      h('polyline', { points: '20 6 9 17 4 12' })
    ]),
    RECHAZADO: h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2.5 }, [
      h('line', { x1: 18, y1: 6, x2: 6, y2: 18 }),
      h('line', { x1: 6, y1: 6, x2: 18, y2: 18 })
    ]),
    ASISTIO: h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2 }, [
      h('path', { d: 'M6 9H4.5a2.5 2.5 0 0 1 0-5H6' }),
      h('path', { d: 'M18 9h1.5a2.5 2.5 0 0 0 0-5H18' }),
      h('path', { d: 'M4 22h16' }),
      h('path', { d: 'M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34' }),
      h('path', { d: 'M12 2a6.3 6.3 0 0 0-6 6.5C6 13.4 9.4 15 12 15s6-1.6 6-6.5C18 3.4 15.6 2 12 2Z' })
    ])
  }
  return icons[estado] || h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2 }, [
    h('line', { x1: 8, y1: 6, x2: 21, y2: 6 }),
    h('line', { x1: 8, y1: 12, x2: 21, y2: 12 }),
    h('line', { x1: 8, y1: 18, x2: 21, y2: 18 }),
    h('circle', { cx: 3, cy: 6, r: 1 }),
    h('circle', { cx: 3, cy: 12, r: 1 }),
    h('circle', { cx: 3, cy: 18, r: 1 })
  ])
}

onMounted(async () => {
  try {
    await api.get('/voluntario')
    tienePerfil.value = true
    const { data: dash } = await api.get('/voluntario/dashboard')
    data.value = dash
  } catch (e) {
    if (e.response?.status !== 404) console.warn('[Dashboard]', e)
  }
})
</script>

<style scoped>
.vol-dashboard { display: flex; flex-direction: column; gap: 28px; }

.hero-banner {
  background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
  border-radius: 20px;
  padding: 36px 40px;
  color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
  box-shadow: 0 12px 30px rgba(13, 148, 136, 0.15);
  position: relative;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
}
.hero-banner::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle at top right, rgba(255, 255, 255, 0.12) 0%, transparent 60%);
  pointer-events: none;
}
.hero-greeting { font-size: 15px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; opacity: .9; margin-bottom: 6px; }
.hero-title { font-size: 26px; font-weight: 800; margin-bottom: 8px; letter-spacing: -0.02em; font-family: 'Outfit', sans-serif; }
.hero-sub { font-size: 14.5px; opacity: .85; margin-bottom: 24px; max-width: 500px; }
.btn-hero {
  display: inline-flex;
  padding: 11px 24px;
  background: #fff;
  color: var(--primary);
  border-radius: 99px;
  font-weight: 600;
  font-size: 14px;
  text-decoration: none;
  transition: var(--transition);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.btn-hero:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12); text-decoration: none; }
.hero-level { text-align: center; flex-shrink: 0; }
.level-badge {
  display: inline-block;
  padding: 6px 16px;
  border-radius: 99px;
  font-weight: 700;
  font-size: 12.5px;
  color: #fff;
  margin-bottom: 8px;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
}
.level-pts { font-size: 22px; font-weight: 800; font-family: 'Outfit', sans-serif; }

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 20px;
}

.post-summary {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}
.post-pill {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  border-radius: var(--radius);
  background: var(--white);
  border: 1px solid var(--gray-200);
  transition: var(--transition);
}
.post-pill:hover { box-shadow: var(--shadow); }
.pill-dot { width: 8px; height: 8px; border-radius: 50%; }
.pill-num { font-size: 22px; font-weight: 800; font-family: 'Outfit', sans-serif; }
.pill-label { font-size: 13.5px; color: var(--gray-600); font-weight: 500; }

.post-pill.pending .pill-dot { background: var(--warning); }
.post-pill.pending .pill-num { color: var(--warning); }

.post-pill.accepted .pill-dot { background: var(--success); }
.post-pill.accepted .pill-num { color: var(--success); }

.post-pill.rejected .pill-dot { background: var(--danger); }
.post-pill.rejected .pill-num { color: var(--danger); }

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}
@media (max-width: 900px) { .dashboard-grid { grid-template-columns: 1fr; } }

.panel {
  background: var(--white);
  border-radius: var(--radius-lg);
  border: 1px solid var(--gray-200);
  padding: 24px;
  box-shadow: var(--shadow);
}
.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
}
.panel-header h3 { font-size: 18px; font-weight: 700; font-family: 'Outfit', sans-serif; color: var(--gray-900); }
.panel-sub { font-size: 13px; color: var(--gray-500); margin-top: 2px; }
.link-more { font-size: 13px; font-weight: 600; color: var(--primary); text-decoration: none; white-space: nowrap; transition: var(--transition); }
.link-more:hover { color: var(--primary-dark); }

.empty-mini {
  text-align: center;
  padding: 32px 24px;
  color: var(--gray-400);
  font-size: 14px;
  border: 1.5px dashed var(--gray-200);
  border-radius: var(--radius);
}
.empty-mini-icon { display: block; margin: 0 auto 12px; color: var(--gray-300); }

.activity-list { display: flex; flex-direction: column; gap: 12px; }
.activity-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  border-radius: var(--radius);
  background: var(--gray-50);
  border: 1px solid var(--gray-100);
  transition: var(--transition);
}
.activity-item:hover { background: var(--gray-100); }
.activity-icon-wrap {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--gray-200);
  color: var(--gray-600);
  flex-shrink: 0;
}
.activity-icon-wrap.pendiente { background: var(--warning-light); color: var(--warning); }
.activity-icon-wrap.aceptado { background: var(--success-light); color: var(--success); }
.activity-icon-wrap.asistio { background: var(--primary-light); color: var(--primary); }
.activity-icon-wrap.rechazado { background: var(--danger-light); color: var(--danger); }

.activity-info { flex: 1; min-width: 0; }
.activity-title { font-weight: 600; font-size: 14px; color: var(--gray-900); }
.activity-meta { font-size: 12px; color: var(--gray-500); font-weight: 500; margin-top: 1px; }
.activity-date { font-size: 12px; color: var(--gray-400); margin-top: 3px; display: flex; align-items: center; }

.progress-block { margin-bottom: 24px; }
.progress-head {
  display: flex;
  justify-content: space-between;
  font-size: 13.5px;
  font-weight: 600;
  margin-bottom: 10px;
  color: var(--gray-700);
}
.progress-nums { color: var(--gray-500); font-weight: 500; }
.progress-bar {
  height: 8px;
  background: var(--gray-200);
  border-radius: 99px;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  border-radius: 99px;
  transition: width .6s cubic-bezier(0.4, 0, 0.2, 1);
}
.progress-fill.level { background: linear-gradient(90deg, var(--warning), #ea580c); }
.progress-fill.month { background: linear-gradient(90deg, #3b82f6, var(--primary)); }
.progress-fill.logro { background: linear-gradient(90deg, #10b981, var(--success)); }
.progress-hint { font-size: 12px; color: var(--gray-500); margin-top: 8px; }

.logro-block { padding-top: 16px; border-top: 1px solid var(--gray-100); }
.logro-name { font-size: 14px; font-weight: 600; margin-bottom: 10px; color: var(--gray-800); }

.recent-logros { margin-top: 8px; padding-top: 20px; border-top: 1px solid var(--gray-100); }
.recent-title { font-size: 12px; font-weight: 600; text-transform: uppercase; color: var(--gray-400); margin-bottom: 14px; letter-spacing: .05em; }
.logro-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid var(--gray-100);
}
.logro-item:last-child { border-bottom: none; }
.logro-icon-wrap {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: var(--primary-light);
  color: var(--primary);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.logro-details { min-width: 0; }
.logro-item-name { font-size: 13.5px; font-weight: 600; color: var(--gray-800); }
.logro-item-date { font-size: 11px; color: var(--gray-400); margin-top: 1px; }
</style>
