<template>
  <div>
    <template v-if="!auth.isVoluntario">
      <h1 class="page-title">Bienvenido, {{ auth.user?.nombre }}</h1>
      <p class="text-muted mb-6">{{ subtitulo }}</p>
    </template>

    <div v-if="loading && !auth.isVoluntario" class="loading-center"><AppSpinner /></div>

    <!-- Dashboard Voluntario -->
    <VoluntarioDashboard v-else-if="auth.isVoluntario" />

    <!-- Dashboard Fundación -->
    <template v-else-if="auth.isFundacion">
      <div v-if="!tienePerfil" class="alert alert-warning mb-6">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
        <span>Registra tu <RouterLink :to="{ name: 'perfil-fundacion' }">perfil de fundación</RouterLink> para comenzar a publicar convocatorias.</span>
      </div>
      <div v-else-if="fundacionPendiente" class="alert alert-info mb-6">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
        <span>Tu fundación está pendiente de aprobación. Te notificaremos cuando sea revisada.</span>
      </div>
      
      <div class="grid grid-4 mb-6">
        <div class="stat-card">
          <div class="stat-header">
            <span class="stat-label">Convocatorias</span>
            <span class="stat-icon-wrapper">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>
            </span>
          </div>
          <div class="stat-number">{{ statsFund.publicaciones }}</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-header">
            <span class="stat-label">Postulaciones</span>
            <span class="stat-icon-wrapper">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>
            </span>
          </div>
          <div class="stat-number">{{ statsFund.postulaciones }}</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-header">
            <span class="stat-label">Pendientes</span>
            <span class="stat-icon-wrapper warning">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            </span>
          </div>
          <div class="stat-number">{{ statsFund.pendientes }}</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-header">
            <span class="stat-label">Aceptados</span>
            <span class="stat-icon-wrapper success">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            </span>
          </div>
          <div class="stat-number">{{ statsFund.aceptadas }}</div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <h3>Acciones rápidas</h3>
        </div>
        <div class="card-body" style="display:flex;gap:12px;flex-wrap:wrap">
          <RouterLink :to="{ name: 'mis-convocatorias' }" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>
            <span>Mis convocatorias</span>
          </RouterLink>
          <RouterLink :to="{ name: 'perfil-fundacion' }" class="btn btn-outline">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/></svg>
            <span>Mi perfil</span>
          </RouterLink>
        </div>
      </div>
    </template>

    <!-- Dashboard Admin -->
    <template v-else-if="auth.isAdmin">
      <div class="grid grid-2 mb-6">
        <div class="stat-card">
          <div class="stat-header">
            <span class="stat-label">Fundaciones pendientes</span>
            <span class="stat-icon-wrapper warning">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h16"/><path d="m12 2-10 6h20z"/><path d="M6 10v12"/><path d="M18 10v12"/></svg>
            </span>
          </div>
          <div class="stat-number">{{ statsAdmin.fundacionesPendientes }}</div>
        </div>
        
        <div class="stat-card">
          <div class="stat-header">
            <span class="stat-label">Reportes pendientes</span>
            <span class="stat-icon-wrapper danger">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
            </span>
          </div>
          <div class="stat-number">{{ statsAdmin.reportesPendientes }}</div>
        </div>
      </div>

      <div class="card">
        <div class="card-header"><h3>Acciones rápidas</h3></div>
        <div class="card-body" style="display:flex;gap:12px;flex-wrap:wrap">
          <RouterLink :to="{ name: 'admin-fundaciones' }" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h16"/><path d="m12 2-10 6h20z"/><path d="M6 10v12"/><path d="M18 10v12"/></svg>
            <span>Revisar fundaciones</span>
          </RouterLink>
          <RouterLink :to="{ name: 'admin-reportes' }" class="btn btn-outline">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span>Ver reportes</span>
          </RouterLink>
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

const tienePerfil     = ref(false)
const fundacionPendiente = ref(false)
const statsFund = ref({ publicaciones: 0, postulaciones: 0, pendientes: 0, aceptadas: 0 })

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
    if (data?.id) auth.setFundacionId(data.id)
    const pubs = await api.get('/mis-publicaciones')
    const list = pubs.data.data || []
    statsFund.value.publicaciones = pubs.data.meta?.total || list.length

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
.page-title {
  font-size: 28px;
  font-weight: 800;
  color: var(--gray-900);
  font-family: 'Outfit', sans-serif;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}
.stat-card {
  background: var(--white);
  border-radius: var(--radius-lg);
  border: 1px solid var(--gray-200);
  padding: 24px;
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.stat-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--gray-500);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.stat-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: var(--primary-light);
  color: var(--primary);
}
.stat-icon-wrapper.warning {
  background: var(--warning-light);
  color: var(--warning);
}
.stat-icon-wrapper.success {
  background: var(--success-light);
  color: var(--success);
}
.stat-icon-wrapper.danger {
  background: var(--danger-light);
  color: var(--danger);
}
.stat-number {
  font-size: 32px;
  font-weight: 800;
  color: var(--gray-900);
  line-height: 1.1;
  font-family: 'Outfit', sans-serif;
}
</style>
