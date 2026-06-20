<template>
  <div>
    <template v-if="!auth.isVoluntario">
      <h1 class="page-title">Bienvenido, {{ auth.user?.nombre }} 👋</h1>
      <p class="text-muted mb-6">{{ subtitulo }}</p>
    </template>

    <div v-if="loading && !auth.isVoluntario" class="loading-center"><AppSpinner /></div>

    <!-- Dashboard Voluntario -->
    <VoluntarioDashboard v-else-if="auth.isVoluntario" />

    <!-- Dashboard Fundación (oculto cuando voluntario) -->
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
import VoluntarioDashboard from '@/components/VoluntarioDashboard.vue'

const auth    = useAuthStore()
const loading = ref(true)

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

async function loadFundacion() {
  try {
    const { data } = await api.get('/mi-fundacion')
    tienePerfil.value = true
    fundacionPendiente.value = data.estado_verificacion === 'PENDIENTE'
    // Cachear el fundacion_id para que DashboardLayout no tenga que volver a pedirlo
    if (data?.id) auth.setFundacionId(data.id)
    const pubs = await api.get('/mis-publicaciones')
    const list = pubs.data.data || []
    statsFund.value.publicaciones = pubs.data.meta?.total || list.length

    // Solicitar postulaciones de las primeras 5 publicaciones en paralelo
    const resultados = await Promise.all(
      list.slice(0, 5).map(p =>
        api.get(`/publicaciones/${p.id}/postulaciones`).then(r => r.data.data || []).catch(() => [])
      )
    )

    let post = 0, pend = 0, acept = 0
    for (const d of resultados) {
      post  += d.length
      pend  += d.filter(x => x.estado === 'PENDIENTE').length
      acept += d.filter(x => x.estado === 'ACEPTADO').length
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
    if (auth.isFundacion) await loadFundacion()
    else if (auth.isAdmin) await loadAdmin()
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.page-title { font-size: 24px; font-weight: 700; color: var(--gray-900); margin-bottom: 6px; }
</style>
