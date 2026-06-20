<template>
  <div class="vol-dashboard">
    <!-- Hero -->
    <section class="hero-banner">
      <div class="hero-content">
        <p class="hero-greeting">¡Hola, {{ auth.user?.nombre?.split(' ')[0] }}! 👋</p>
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
      <span>⚠️</span>
      <span>Completa tu <RouterLink :to="{ name: 'perfil-voluntario' }">perfil de voluntario</RouterLink> para postularte a convocatorias.</span>
    </div>

    <!-- Stats -->
    <div class="stats-grid">
      <GradientStatCard
        icon="✅"
        :value="data?.actividades_completadas?.total || 0"
        label="Actividades completadas"
        :sub="`+${data?.actividades_completadas?.este_mes || 0} este mes · ${data?.actividades_completadas?.esta_semana || 0} esta semana`"
        variant="blue"
      />
      <GradientStatCard
        icon="⭐"
        :value="data?.puntos?.total_historico || 0"
        label="Puntos acumulados"
        :sub="data?.nivel?.puntos_faltan ? `${data.nivel.puntos_faltan} pts para ${data.nivel.nivel_siguiente?.nombre}` : 'Nivel máximo alcanzado'"
        variant="purple"
      />
      <GradientStatCard
        icon="🎖️"
        :value="data?.logros?.desbloqueados || 0"
        label="Logros desbloqueados"
        :sub="data?.logro_proximo ? `Próximo: ${data.logro_proximo.nombre}` : '¡Todos desbloqueados!'"
        variant="green"
      />
      <GradientStatCard
        icon="🏆"
        :value="data?.ranking?.posicion ? `#${data.ranking.posicion}` : '—'"
        label="Posición en ranking"
        :sub="data?.ranking?.top_percent ? `Top ${data.ranking.top_percent}%` : 'Sin ranking aún'"
        variant="orange"
      />
    </div>

    <!-- Postulaciones resumen -->
    <div class="post-summary">
      <div class="post-pill pending">
        <span class="pill-num">{{ data?.postulaciones_resumen?.pendientes || 0 }}</span>
        <span class="pill-label">Pendientes</span>
      </div>
      <div class="post-pill accepted">
        <span class="pill-num">{{ data?.postulaciones_resumen?.aceptadas || 0 }}</span>
        <span class="pill-label">Aprobadas</span>
      </div>
      <div class="post-pill rejected">
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
          <span>📅</span>
          <p>No tienes actividades próximas. <RouterLink :to="{ name: 'convocatorias' }">Explora convocatorias</RouterLink></p>
        </div>
        <div v-else class="activity-list">
          <div v-for="p in proximas" :key="p.id" class="activity-item">
            <div class="activity-icon">{{ estadoIcon(p.estado) }}</div>
            <div class="activity-info">
              <p class="activity-title">{{ p.publicacion?.titulo }}</p>
              <p class="activity-meta">{{ p.publicacion?.fundacion?.nombre }}</p>
              <p class="activity-date">📅 {{ formatDate(p.publicacion?.fecha_inicio) }}</p>
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
            <span>🎯 Próximo logro</span>
            <span class="progress-nums">{{ data.logro_proximo.progreso }} / {{ data.logro_proximo.umbral }}</span>
          </div>
          <p class="logro-name">{{ data.logro_proximo.icono }} {{ data.logro_proximo.nombre }}</p>
          <div class="progress-bar">
            <div class="progress-fill logro" :style="{ width: `${data.logro_proximo.porcentaje || 0}%` }"></div>
          </div>
        </div>

        <div v-if="logrosRecientes.length" class="recent-logros">
          <p class="recent-title">Últimos logros desbloqueados</p>
          <div v-for="l in logrosRecientes" :key="l.id" class="logro-item">
            <span class="logro-icon">{{ l.icono }}</span>
            <div>
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
import { ref, computed, onMounted } from 'vue'
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

function estadoIcon(estado) {
  return { PENDIENTE: '⏳', ACEPTADO: '✅', RECHAZADO: '❌', ASISTIO: '🏆' }[estado] || '📋'
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
.vol-dashboard { display: flex; flex-direction: column; gap: 24px; }

.hero-banner {
  background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #a855f7 100%);
  border-radius: 20px;
  padding: 28px 32px;
  color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
  box-shadow: 0 12px 40px rgba(99,102,241,.35);
}
.hero-greeting { font-size: 14px; opacity: .9; margin-bottom: 4px; }
.hero-title { font-size: 22px; font-weight: 800; margin-bottom: 6px; }
.hero-sub { font-size: 14px; opacity: .85; margin-bottom: 16px; }
.btn-hero {
  display: inline-flex;
  padding: 10px 20px;
  background: #fff;
  color: #6366f1;
  border-radius: 99px;
  font-weight: 600;
  font-size: 14px;
  text-decoration: none;
  transition: transform .2s, box-shadow .2s;
}
.btn-hero:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(0,0,0,.15); text-decoration: none; }
.hero-level { text-align: center; flex-shrink: 0; }
.level-badge {
  display: inline-block;
  padding: 6px 16px;
  border-radius: 99px;
  font-weight: 700;
  font-size: 13px;
  color: #fff;
  margin-bottom: 6px;
}
.level-pts { font-size: 20px; font-weight: 800; }

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 16px;
}

.post-summary {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}
.post-pill {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 18px;
  border-radius: 12px;
  background: var(--white);
  border: 1px solid var(--gray-200);
  transition: box-shadow .2s;
}
.post-pill:hover { box-shadow: var(--shadow-md); }
.pill-num { font-size: 20px; font-weight: 800; }
.pill-label { font-size: 13px; color: var(--gray-600); }
.post-pill.pending .pill-num { color: #d97706; }
.post-pill.accepted .pill-num { color: #059669; }
.post-pill.rejected .pill-num { color: #dc2626; }

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
@media (max-width: 900px) { .dashboard-grid { grid-template-columns: 1fr; } }

.panel {
  background: var(--white);
  border-radius: 16px;
  border: 1px solid var(--gray-200);
  padding: 22px;
  box-shadow: var(--shadow);
}
.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 18px;
}
.panel-header h3 { font-size: 17px; font-weight: 700; }
.panel-sub { font-size: 13px; color: var(--gray-500); margin-top: 2px; }
.link-more { font-size: 13px; font-weight: 600; color: var(--primary); text-decoration: none; white-space: nowrap; }
.link-more:hover { text-decoration: underline; }

.empty-mini {
  text-align: center;
  padding: 24px;
  color: var(--gray-500);
  font-size: 14px;
}
.empty-mini span { font-size: 32px; display: block; margin-bottom: 8px; }

.activity-list { display: flex; flex-direction: column; gap: 10px; }
.activity-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  border-radius: 12px;
  background: var(--gray-50);
  border: 1px solid var(--gray-100);
  transition: background .15s;
}
.activity-item:hover { background: var(--primary-light); }
.activity-icon { font-size: 22px; flex-shrink: 0; }
.activity-info { flex: 1; min-width: 0; }
.activity-title { font-weight: 600; font-size: 14px; }
.activity-meta { font-size: 12px; color: var(--gray-500); }
.activity-date { font-size: 12px; color: var(--gray-400); margin-top: 2px; }

.progress-block { margin-bottom: 20px; }
.progress-head {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--gray-700);
}
.progress-nums { color: var(--gray-500); font-weight: 500; }
.progress-bar {
  height: 10px;
  background: var(--gray-200);
  border-radius: 99px;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  border-radius: 99px;
  transition: width .6s cubic-bezier(0.4, 0, 0.2, 1);
}
.progress-fill.level { background: linear-gradient(90deg, #f59e0b, #ea580c); }
.progress-fill.month { background: linear-gradient(90deg, #3b82f6, #6366f1); }
.progress-fill.logro { background: linear-gradient(90deg, #10b981, #059669); }
.progress-hint { font-size: 12px; color: var(--gray-500); margin-top: 6px; }

.logro-block { padding-top: 4px; border-top: 1px solid var(--gray-100); }
.logro-name { font-size: 14px; font-weight: 600; margin-bottom: 8px; }

.recent-logros { margin-top: 8px; padding-top: 16px; border-top: 1px solid var(--gray-100); }
.recent-title { font-size: 12px; font-weight: 600; text-transform: uppercase; color: var(--gray-500); margin-bottom: 12px; letter-spacing: .04em; }
.logro-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
}
.logro-icon { font-size: 22px; }
.logro-item-name { font-size: 13px; font-weight: 600; }
.logro-item-date { font-size: 11px; color: var(--gray-400); }
</style>
