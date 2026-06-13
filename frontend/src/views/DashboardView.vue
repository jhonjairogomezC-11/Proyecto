<template>
  <div>
    <h1 class="page-title">Bienvenido, {{ auth.user?.nombre }} 👋</h1>
    <p class="text-muted mb-6">{{ subtitulo }}</p>

    <div v-if="loading" class="loading-center"><AppSpinner /></div>

    <!-- Dashboard Voluntario -->
    <template v-else-if="auth.isVoluntario">
      <div v-if="!tienePerfilCompleto" class="alert alert-warning mb-6">
        <span>⚠️</span>
        <span>Completa tu <RouterLink :to="{ name: 'perfil-voluntario' }">perfil de voluntario</RouterLink> para poder postularte a convocatorias.</span>
      </div>
      <div class="grid grid-4 mb-6">
        <div class="stat-card">
          <div class="stat-icon">📋</div>
          <div class="stat-number">{{ stats.totalPostulaciones }}</div>
          <div class="stat-label">Total postulaciones</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">⏳</div>
          <div class="stat-number">{{ stats.pendientes }}</div>
          <div class="stat-label">Pendientes</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">✅</div>
          <div class="stat-number">{{ stats.aceptadas }}</div>
          <div class="stat-label">Aceptadas</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">🏆</div>
          <div class="stat-number">{{ stats.asistio }}</div>
          <div class="stat-label">Actividades completadas</div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <h3>Convocatorias recientes</h3>
          <RouterLink :to="{ name: 'convocatorias' }" class="btn btn-outline btn-sm">Ver todas</RouterLink>
        </div>
        <div class="card-body">
          <div v-if="convocatorias.length === 0" class="empty-state">
            <div class="icon">🔍</div>
            <h3>Sin convocatorias disponibles</h3>
            <p>Vuelve pronto para ver nuevas oportunidades.</p>
          </div>
          <div v-else class="convocatorias-grid">
            <div v-for="c in convocatorias" :key="c.id" class="conv-card">
              <div class="conv-badge">
                <BadgeEstado :estado="c.modalidad" tipo="publicacion" />
                <BadgeEstado :estado="c.estado" tipo="publicacion" />
              </div>
              <h4>{{ c.titulo }}</h4>
              <p class="text-sm text-muted">{{ c.fundacion?.nombre }}</p>
              <p class="text-sm text-muted">📅 {{ formatDate(c.fecha_inicio) }} – {{ formatDate(c.fecha_fin) }}</p>
              <RouterLink :to="{ name: 'convocatorias' }" class="btn btn-primary btn-sm mt-2">Ver convocatorias</RouterLink>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Dashboard Fundación -->
    <template v-else-if="auth.isFundacion">
      <div v-if="!tienePerfil" class="alert alert-warning mb-6">
        <span>⚠️</span>
        <span>Registra tu <RouterLink :to="{ name: 'perfil-fundacion' }">perfil de fundación</RouterLink> para comenzar a publicar convocatorias.</span>
      </div>
      <div v-else-if="fundacionPendiente" class="alert alert-info mb-6">
        <span>ℹ️</span>
        <span>Tu fundación está pendiente de aprobación. Te notificaremos cuando sea revisada.</span>
      </div>
      <div class="grid grid-4 mb-6">
        <div class="stat-card">
          <div class="stat-icon">📢</div>
          <div class="stat-number">{{ statsFund.publicaciones }}</div>
          <div class="stat-label">Publicaciones</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">📥</div>
          <div class="stat-number">{{ statsFund.postulaciones }}</div>
          <div class="stat-label">Postulaciones recibidas</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">⏳</div>
          <div class="stat-number">{{ statsFund.pendientes }}</div>
          <div class="stat-label">Pendientes por revisar</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">✅</div>
          <div class="stat-number">{{ statsFund.aceptadas }}</div>
          <div class="stat-label">Voluntarios aceptados</div>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <h3>Acciones rápidas</h3>
        </div>
        <div class="card-body" style="display:flex;gap:12px;flex-wrap:wrap">
          <RouterLink :to="{ name: 'mis-convocatorias' }" class="btn btn-primary">📢 Mis convocatorias</RouterLink>
          <RouterLink :to="{ name: 'perfil-fundacion' }" class="btn btn-outline">🏢 Mi perfil</RouterLink>
        </div>
      </div>
    </template>

    <!-- Dashboard Admin -->
    <template v-else-if="auth.isAdmin">
      <div class="grid grid-4 mb-6">
        <div class="stat-card">
          <div class="stat-icon">🏛️</div>
          <div class="stat-number">{{ statsAdmin.fundacionesPendientes }}</div>
          <div class="stat-label">Fundaciones pendientes</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">🚨</div>
          <div class="stat-number">{{ statsAdmin.reportesPendientes }}</div>
          <div class="stat-label">Reportes pendientes</div>
        </div>
      </div>
      <div class="card">
        <div class="card-header"><h3>Acciones rápidas</h3></div>
        <div class="card-body" style="display:flex;gap:12px;flex-wrap:wrap">
          <RouterLink :to="{ name: 'admin-fundaciones' }" class="btn btn-primary">🏛️ Revisar fundaciones</RouterLink>
          <RouterLink :to="{ name: 'admin-reportes' }" class="btn btn-outline">🚨 Ver reportes</RouterLink>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'
import AppSpinner from '@/components/AppSpinner.vue'
import BadgeEstado from '@/components/BadgeEstado.vue'

const auth    = useAuthStore()
const loading = ref(true)

// Voluntario
const tienePerfilCompleto = ref(false)
const stats = ref({ totalPostulaciones: 0, pendientes: 0, aceptadas: 0, asistio: 0 })
const convocatorias = ref([])

// Fundación
const tienePerfil     = ref(false)
const fundacionPendiente = ref(false)
const statsFund = ref({ publicaciones: 0, postulaciones: 0, pendientes: 0, aceptadas: 0 })

// Admin
const statsAdmin = ref({ fundacionesPendientes: 0, reportesPendientes: 0 })

const subtitulo = computed(() => ({
  VOLUNTARIO: 'Encuentra oportunidades de voluntariado y marca la diferencia.',
  FUNDACION:  'Gestiona tus convocatorias y conecta con voluntarios.',
  ADMIN:      'Panel de administración del sistema.',
}[auth.user?.rol] || ''))

function formatDate(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
}

async function loadVoluntario() {
  try {
    await api.get('/voluntario')
    tienePerfilCompleto.value = true
    const { data } = await api.get('/mis-postulaciones')
    const list = data.data || []
    stats.value = {
      totalPostulaciones: data.meta?.total || list.length,
      pendientes: list.filter(p => p.estado === 'PENDIENTE').length,
      aceptadas:  list.filter(p => p.estado === 'ACEPTADO').length,
      asistio:    list.filter(p => p.estado === 'ASISTIO').length,
    }
    const pub = await api.get('/publicaciones', { params: { per_page: 3 } })
    convocatorias.value = (pub.data.data || []).slice(0, 3)
  } catch {}
}

async function loadFundacion() {
  try {
    const { data } = await api.get('/mi-fundacion')
    tienePerfil.value = true
    fundacionPendiente.value = data.estado_verificacion === 'PENDIENTE'
    const pubs = await api.get('/mis-publicaciones')
    const list = pubs.data.data || []
    statsFund.value.publicaciones = pubs.data.meta?.total || list.length
    // calcular postulaciones desde mis publicaciones
    let post = 0, pend = 0, acept = 0
    for (const p of list.slice(0, 5)) {
      try {
        const r = await api.get(`/publicaciones/${p.id}/postulaciones`)
        const d = r.data.data || []
        post  += d.length
        pend  += d.filter(x => x.estado === 'PENDIENTE').length
        acept += d.filter(x => x.estado === 'ACEPTADO').length
      } catch {}
    }
    statsFund.value.postulaciones = post
    statsFund.value.pendientes    = pend
    statsFund.value.aceptadas     = acept
  } catch {}
}

async function loadAdmin() {
  try {
    const f = await api.get('/admin/fundaciones', { params: { estado: 'PENDIENTE' } })
    statsAdmin.value.fundacionesPendientes = f.data.meta?.total || (f.data.data || []).length
    const r = await api.get('/admin/reportes', { params: { estado: 'PENDIENTE' } })
    statsAdmin.value.reportesPendientes = r.data.meta?.total || (r.data.data || []).length
  } catch {}
}

onMounted(async () => {
  try {
    if (auth.isVoluntario) await loadVoluntario()
    else if (auth.isFundacion) await loadFundacion()
    else if (auth.isAdmin) await loadAdmin()
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 700; color: var(--gray-900); margin-bottom: 6px; }
.convocatorias-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
.conv-card {
  padding: 16px;
  border: 1px solid var(--gray-200);
  border-radius: var(--radius);
  transition: box-shadow .18s;
}
.conv-card:hover { box-shadow: var(--shadow-md); }
.conv-card h4 { font-size: 15px; font-weight: 600; margin: 8px 0 4px; }
.conv-badge { display: flex; gap: 6px; flex-wrap: wrap; }
</style>
