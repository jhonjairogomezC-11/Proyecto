<template>
  <div class="app-shell" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    <!-- Sidebar -->
    <aside class="sidebar" :class="{ open: sidebarOpen, collapsed: sidebarCollapsed }">
      <div class="sidebar-brand">
        <span class="brand-icon">
          <svg class="brand-logo-svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="color: var(--primary);">
            <path d="m11 17 2 2a1 1 0 0 0 1.4 0l4-4a1 1 0 0 0 0-1.4l-2-2"/>
            <path d="m13 13-2-2a1 1 0 0 0-1.4 0l-4 4a1 1 0 0 0 0 1.4l2 2"/>
            <circle cx="12" cy="12" r="10"/>
          </svg>
        </span>
        <span class="brand-name" v-if="!sidebarCollapsed">VoluntApp</span>
        <button class="sidebar-close" @click="sidebarOpen = false">✕</button>
      </div>

      <nav class="sidebar-nav" @click="sidebarOpen = false">
        <RouterLink :to="{ name: 'dashboard' }" class="nav-item" active-class="active" title="Dashboard">
          <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
          <span class="nav-label" v-if="!sidebarCollapsed">Dashboard</span>
        </RouterLink>

        <!-- Voluntario -->
        <template v-if="auth.isVoluntario">
          <RouterLink :to="{ name: 'convocatorias' }" class="nav-item" active-class="active" title="Actividades disponibles">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Actividades</span>
          </RouterLink>
          <RouterLink :to="{ name: 'mis-postulaciones' }" class="nav-item" active-class="active" title="Mis Postulaciones">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Mis Postulaciones</span>
          </RouterLink>
          <RouterLink :to="{ name: 'favoritos' }" class="nav-item" active-class="active" title="Favoritos">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Favoritos</span>
          </RouterLink>
          <RouterLink :to="{ name: 'mis-logros' }" class="nav-item" active-class="active" title="Logros y Puntos">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="7"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Logros y Puntos</span>
          </RouterLink>
          <RouterLink :to="{ name: 'ranking' }" class="nav-item" active-class="active" title="Ranking">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34"/><path d="M12 2a6.3 6.3 0 0 0-6 6.5C6 13.4 9.4 15 12 15s6-1.6 6-6.5C18 3.4 15.6 2 12 2Z"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Ranking</span>
          </RouterLink>
          <RouterLink :to="{ name: 'perfil-voluntario' }" class="nav-item" active-class="active" title="Mi Perfil">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Mi Perfil</span>
          </RouterLink>
        </template>

        <!-- Fundación -->
        <template v-if="auth.isFundacion">
          <RouterLink :to="{ name: 'perfil-fundacion' }" class="nav-item" active-class="active" title="Mi Fundación">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="9" y2="16"/><line x1="15" y1="22" x2="15" y2="16"/><line x1="9" y1="16" x2="15" y2="16"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M8 10h.01"/><path d="M16 10h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Mi Fundación</span>
          </RouterLink>
          <RouterLink :to="{ name: 'mis-convocatorias' }" class="nav-item" active-class="active" title="Mis Convocatorias">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Mis Convocatorias</span>
          </RouterLink>
        </template>

        <!-- Admin -->
        <template v-if="auth.isAdmin">
          <RouterLink :to="{ name: 'admin-fundaciones' }" class="nav-item" active-class="active" title="Fundaciones">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h16"/><path d="m12 2-10 6h20z"/><path d="M6 10v12"/><path d="M10 10v12"/><path d="M14 10v12"/><path d="M18 10v12"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Fundaciones</span>
          </RouterLink>
          <RouterLink :to="{ name: 'admin-publicaciones' }" class="nav-item" active-class="active" title="Publicaciones">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Publicaciones</span>
          </RouterLink>
          <RouterLink :to="{ name: 'admin-voluntarios' }" class="nav-item" active-class="active" title="Voluntarios">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Voluntarios</span>
          </RouterLink>
          <RouterLink :to="{ name: 'admin-reportes' }" class="nav-item" active-class="active" title="Reportes">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span class="nav-label" v-if="!sidebarCollapsed">Reportes</span>
          </RouterLink>
        </template>

        <!-- Común -->
        <RouterLink :to="{ name: 'notificaciones' }" class="nav-item" active-class="active" title="Notificaciones">
          <div style="position: relative; display: flex; align-items: center;">
            <svg class="nav-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
            <span v-if="notiStore.noLeidas > 0 && sidebarCollapsed" class="notif-dot-small"></span>
          </div>
          <span class="nav-label" v-if="!sidebarCollapsed">Notificaciones</span>
          <span v-if="notiStore.noLeidas > 0 && !sidebarCollapsed" class="notif-badge">{{ notiStore.noLeidas }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info" v-if="!sidebarCollapsed">
          <div class="user-avatar">{{ auth.user?.nombre?.charAt(0).toUpperCase() }}</div>
          <div class="user-details">
            <p class="user-name">{{ auth.user?.nombre }}</p>
            <p class="user-role">{{ rolLabel }}</p>
          </div>
        </div>
        <button class="btn btn-ghost btn-sm logout-btn" :title="sidebarCollapsed ? 'Cerrar Sesión' : ''" @click="handleLogout">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          <span v-if="!sidebarCollapsed">Salir</span>
        </button>
      </div>
    </aside>

    <!-- Overlay -->
    <div v-if="sidebarOpen" class="sidebar-overlay" @click="sidebarOpen = false"></div>

    <!-- Main -->
    <main class="main-content">
      <header class="topbar">
        <div class="topbar-left">
          <button class="btn btn-ghost btn-icon sidebar-toggle" @click="sidebarOpen = true" aria-label="Menú">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="6" x2="20" y2="6"/><line x1="4" y1="18" x2="20" y2="18"/></svg>
          </button>
          
          <!-- Botón de colapso para Escritorio -->
          <button class="btn btn-ghost btn-icon collapse-toggle hide-mobile" @click="toggleSidebar" aria-label="Colapsar panel">
            <svg v-if="sidebarCollapsed" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M9 3v18"/><path d="m14 15 3-3-3-3"/></svg>
            <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M9 3v18"/><path d="m16 15-3-3 3-3"/></svg>
          </button>
        </div>

        <div class="topbar-right">
          <!-- Indicador de conexión WebSocket -->
          <span class="ws-indicator" :class="wsConnected ? 'ws-online' : 'ws-offline'" :title="wsConnected ? 'Conexión activa en tiempo real' : 'Sin conexión en tiempo real'">
            <span class="ws-dot"></span>
          </span>
          
          <RouterLink :to="{ name: 'notificaciones' }" class="notif-btn" title="Ver Notificaciones">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
            <span v-if="notiStore.noLeidas > 0" class="notif-badge-top">{{ notiStore.noLeidas }}</span>
          </RouterLink>

          <span class="user-chip">
            <span class="user-chip-avatar">{{ auth.user?.nombre?.charAt(0).toUpperCase() }}</span>
            <span class="user-chip-name">{{ auth.user?.nombre }}</span>
          </span>
        </div>
      </header>

      <div class="page-content">
        <RouterView />
      </div>
    </main>

    <!-- Toast para notificaciones push en tiempo real -->
    <AppToast ref="toastRef" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useNotificacionesStore } from '@/stores/notificaciones'
import { connectEcho, disconnectEcho, getEcho } from '@/services/echo'
import AppToast from '@/components/AppToast.vue'

const auth       = useAuthStore()
const notiStore  = useNotificacionesStore()
const router     = useRouter()
const sidebarOpen = ref(false)
const sidebarCollapsed = ref(localStorage.getItem('sidebar_collapsed') === 'true')
const wsConnected = ref(false)
const toastRef    = ref(null)

const rolLabel = computed(() => ({
  VOLUNTARIO: 'Voluntario',
  FUNDACION:  'Fundación',
  ADMIN:      'Administrador',
}[auth.user?.rol] || auth.user?.rol))

function toggleSidebar() {
  sidebarCollapsed.value = !sidebarCollapsed.value
  localStorage.setItem('sidebar_collapsed', sidebarCollapsed.value ? 'true' : 'false')
}

async function handleLogout() {
  desuscribirCanales()
  disconnectEcho()
  wsConnected.value = false
  await auth.logout()
  notiStore.resetear()
  router.push({ name: 'login' })
}

// ── WebSocket: Suscripción a canales ────────────────────────────

function showToast(opts) {
  if (toastRef.value) {
    toastRef.value.addToast(opts)
  }
}

function suscribirCanales() {
  try {
    const echo = connectEcho()
    if (!echo) return

    wsConnected.value = true

    const userId = auth.user?.id

    // ─── Canal privado del usuario (todos los roles) ───
    if (userId) {
      echo.private(`usuario.${userId}`)
        .listen('.PostulacionActualizada', (data) => {
          const estadoLabel = {
            ACEPTADO: 'aceptada',
            RECHAZADO: 'rechazada',
            ASISTIO: 'confirmada como asistida',
            NO_ASISTIO: 'marcada como no asistida',
          }[data.estado] || data.estado

          showToast({
            title: `Postulación ${estadoLabel}`,
            message: data.publicacion || '',
            type: 'postulacion',
          })

          notiStore.incrementar()
        })
    }

    // ─── Canal privado de la fundación ───
    if (auth.isFundacion) {
      setTimeout(() => {
        obtenerFundacionId().then(fundacionId => {
          if (!fundacionId) return

          echo.private(`fundacion.${fundacionId}`)
            .listen('.PostulacionCreada', (data) => {
              showToast({
                title: 'Nueva postulación',
                message: `${data.voluntario} se postuló a "${data.publicacion}"`,
                type: 'postulacion',
              })
              notiStore.incrementar()
            })
            .listen('.PostulacionActualizada', (data) => {
              if (data.evento === 'cancelada') {
                showToast({
                  title: 'Postulación cancelada',
                  message: `${data.voluntario} canceló su postulación de "${data.publicacion}". Cupos: ${data.cupos_restantes}`,
                  type: 'warning',
                })
                notiStore.incrementar()
              }
            })
        })
      }, 500)
    }

    // ─── Canal público: nuevas convocatorias (voluntarios) ───
    if (auth.isVoluntario) {
      echo.channel('convocatorias')
        .listen('.NuevaPublicacion', (data) => {
          showToast({
            title: 'Nueva convocatoria',
            message: `"${data.titulo}" por ${data.fundacion} en ${data.municipio || 'Cundinamarca'}`,
            type: 'publicacion',
          })
          notiStore.incrementar()
        })
    }

  } catch (err) {
    console.warn('[WebSocket] Error al conectar:', err)
    wsConnected.value = false
  }
}

async function obtenerFundacionId() {
  if (auth.fundacionId) return auth.fundacionId
  try {
    const { default: apiService } = await import('@/services/api')
    const { data } = await apiService.get('/mi-fundacion')
    const id = data?.id || data?.data?.id || null
    if (id) auth.setFundacionId(id)
    return id
  } catch {
    return null
  }
}

function desuscribirCanales() {
  try {
    const echo = getEcho()
    if (!echo) return

    const userId = auth.user?.id
    if (userId) {
      echo.leave(`usuario.${userId}`)
    }
    echo.leave('convocatorias')
  } catch {}
}

// ── Lifecycle ──────────────────────────────────────────────────

onMounted(() => {
  console.log('[Layout] onMounted - diferiendo cargarConteo 300ms')
  setTimeout(() => {
    console.log('[Layout] cargarConteo START')
    notiStore.cargarConteo().then(() => console.log('[Layout] cargarConteo DONE'))
  }, 300)

  suscribirCanales()
})

onUnmounted(() => {
  desuscribirCanales()
})

watch(
  () => notiStore.pushQueue.length,
  () => {
    while (notiStore.pushQueue.length > 0) {
      const noti = notiStore.popNotificacion()
      if (noti) showToast(noti)
    }
  }
)
</script>

<style scoped>
.app-shell {
  display: flex;
  min-height: 100vh;
  background: var(--gray-50);
}

/* ── Sidebar ──────────────────────────── */
.sidebar {
  width: 260px;
  min-height: 100vh;
  background: var(--gray-900);
  color: var(--white);
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  transition: var(--transition);
  border-right: 1px solid var(--gray-800);
}

.sidebar.collapsed {
  width: 72px;
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 24px 20px;
  border-bottom: 1px solid var(--gray-800);
  font-weight: 700;
  font-size: 18px;
  letter-spacing: -0.02em;
  font-family: 'Outfit', sans-serif;
  height: 70px;
  overflow: hidden;
}
.sidebar.collapsed .sidebar-brand {
  justify-content: center;
  padding: 24px 0;
}
.brand-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.brand-name {
  flex: 1;
  background: linear-gradient(135deg, var(--white) 30%, var(--gray-400) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
.sidebar-close {
  display: none;
  background: none;
  border: none;
  color: var(--gray-400);
  cursor: pointer;
  font-size: 16px;
}

.sidebar-nav {
  flex: 1;
  padding: 16px 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  color: var(--gray-400);
  font-size: 14px;
  font-weight: 500;
  transition: var(--transition);
  position: relative;
  text-decoration: none;
}
.sidebar.collapsed .nav-item {
  justify-content: center;
  padding: 12px 0;
}
.nav-item:hover {
  background: var(--gray-800);
  color: var(--white);
}
.nav-item.active {
  background: var(--gray-800);
  color: var(--primary);
}
.nav-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: var(--primary);
  border-radius: 0 4px 4px 0;
}
.nav-icon {
  flex-shrink: 0;
}

.notif-badge {
  margin-left: auto;
  background: var(--danger);
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 99px;
  min-width: 18px;
  text-align: center;
}
.notif-dot-small {
  position: absolute;
  top: -2px;
  right: -2px;
  width: 8px;
  height: 8px;
  background: var(--danger);
  border-radius: 50%;
  border: 1.5px solid var(--gray-900);
}

.sidebar-footer {
  padding: 16px 20px;
  border-top: 1px solid var(--gray-800);
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.sidebar.collapsed .sidebar-footer {
  padding: 16px 0;
  align-items: center;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}
.user-avatar {
  width: 36px;
  height: 36px;
  background: var(--primary);
  color: var(--white);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 14px;
  flex-shrink: 0;
}
.user-details {
  min-width: 0;
}
.user-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--white);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.user-role {
  font-size: 11px;
  color: var(--gray-500);
}
.logout-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  justify-content: center;
  width: 100%;
  color: var(--gray-400);
  border: 1px solid var(--gray-800);
}
.sidebar.collapsed .logout-btn {
  width: 40px;
  height: 40px;
  padding: 0;
  border-radius: 50%;
}

/* ── Main ──────────────────────────────── */
.main-content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  transition: var(--transition);
}

.topbar {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--white);
  border-bottom: 1px solid var(--gray-100);
  padding: 0 32px;
  height: 70px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: var(--shadow);
}
.topbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.topbar-right {
  display: flex;
  align-items: center;
  gap: 20px;
}
.sidebar-toggle {
  display: none !important;
}

/* WebSocket indicator */
.ws-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: help;
}
.ws-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}
.ws-offline .ws-dot {
  background: var(--danger);
  box-shadow: 0 0 8px var(--danger);
}
.ws-online .ws-dot {
  background: var(--success);
  box-shadow: 0 0 8px var(--success);
  animation: ws-pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes ws-pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50%      { opacity: .4; transform: scale(0.85); }
}

.notif-btn {
  position: relative;
  color: var(--gray-600);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
  border-radius: 50%;
  transition: var(--transition);
}
.notif-btn:hover {
  background: var(--gray-100);
  color: var(--gray-900);
}
.notif-badge-top {
  position: absolute;
  top: 2px;
  right: 2px;
  background: var(--danger);
  color: #fff;
  font-size: 9px;
  font-weight: 700;
  padding: 1px 4px;
  border-radius: 99px;
  min-width: 14px;
  text-align: center;
  line-height: 1;
}

.user-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  border-radius: 99px;
  background: var(--gray-100);
  border: 1px solid var(--gray-200);
}
.user-chip-avatar {
  width: 24px;
  height: 24px;
  background: var(--primary);
  color: var(--white);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
}
.user-chip-name {
  font-size: 13px;
  font-weight: 500;
  color: var(--gray-700);
}

.page-content {
  flex: 1;
  padding: 40px;
  max-width: 1440px;
  width: 100%;
  margin: 0 auto;
}

/* ── Overlay (mobile) ─────────────────── */
.sidebar-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.3);
  backdrop-filter: blur(4px);
  z-index: 200;
  display: none;
}

@media (max-width: 900px) {
  .sidebar {
    position: fixed;
    left: -260px;
    top: 0;
    z-index: 300;
    transition: left .3s cubic-bezier(0.4, 0, 0.2, 1);
    height: 100%;
    width: 260px !important;
  }
  .sidebar.collapsed {
    width: 260px !important;
  }
  .sidebar.collapsed .brand-name,
  .sidebar.collapsed .nav-label,
  .sidebar.collapsed .user-info,
  .sidebar.collapsed .logout-btn span {
    display: block !important;
  }
  .sidebar.collapsed .sidebar-brand {
    justify-content: flex-start !important;
    padding: 24px 20px !important;
  }
  .sidebar.collapsed .nav-item {
    justify-content: flex-start !important;
    padding: 12px 20px !important;
  }
  .sidebar.collapsed .sidebar-footer {
    align-items: stretch !important;
    padding: 16px 20px !important;
  }
  .sidebar.collapsed .logout-btn {
    width: 100% !important;
    height: auto !important;
    border-radius: var(--radius) !important;
    padding: 9px 18px !important;
  }
  .sidebar.open {
    left: 0;
  }
  .sidebar-close {
    display: block;
  }
  .sidebar-overlay {
    display: block;
  }
  .sidebar-toggle {
    display: flex !important;
  }
  .page-content {
    padding: 24px 16px;
  }
}
</style>
