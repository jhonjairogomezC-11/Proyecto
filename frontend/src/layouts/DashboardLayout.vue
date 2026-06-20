<template>
  <div class="app-shell">
    <!-- Sidebar -->
    <aside class="sidebar" :class="{ open: sidebarOpen }">
      <div class="sidebar-brand">
        <span class="brand-icon">🤝</span>
        <span class="brand-name">VoluntApp</span>
        <button class="sidebar-close" @click="sidebarOpen = false">✕</button>
      </div>

      <nav class="sidebar-nav" @click="sidebarOpen = false">
        <RouterLink :to="{ name: 'dashboard' }" class="nav-item" active-class="active">
          <span>🏠</span> Dashboard
        </RouterLink>

        <!-- Voluntario -->
        <template v-if="auth.isVoluntario">
          <RouterLink :to="{ name: 'perfil-voluntario' }" class="nav-item" active-class="active">
            <span>👤</span> Mi Perfil
          </RouterLink>
          <RouterLink :to="{ name: 'convocatorias' }" class="nav-item" active-class="active">
            <span>🔍</span> Convocatorias
          </RouterLink>
          <RouterLink :to="{ name: 'mis-postulaciones' }" class="nav-item" active-class="active">
            <span>📋</span> Mis Postulaciones
          </RouterLink>
          <RouterLink :to="{ name: 'mis-logros' }" class="nav-item" active-class="active">
            <span>🎖️</span> Mis Logros
          </RouterLink>
          <RouterLink :to="{ name: 'ranking' }" class="nav-item" active-class="active">
            <span>🏆</span> Ranking
          </RouterLink>
        </template>

        <!-- Fundación -->
        <template v-if="auth.isFundacion">
          <RouterLink :to="{ name: 'perfil-fundacion' }" class="nav-item" active-class="active">
            <span>🏢</span> Mi Fundación
          </RouterLink>
          <RouterLink :to="{ name: 'mis-convocatorias' }" class="nav-item" active-class="active">
            <span>📢</span> Mis Convocatorias
          </RouterLink>
        </template>

        <!-- Admin -->
        <template v-if="auth.isAdmin">
          <RouterLink :to="{ name: 'admin-fundaciones' }" class="nav-item" active-class="active">
            <span>🏛️</span> Fundaciones
          </RouterLink>
          <RouterLink :to="{ name: 'admin-publicaciones' }" class="nav-item" active-class="active">
            <span>📢</span> Publicaciones
          </RouterLink>
          <RouterLink :to="{ name: 'admin-voluntarios' }" class="nav-item" active-class="active">
            <span>👥</span> Voluntarios
          </RouterLink>
          <RouterLink :to="{ name: 'admin-reportes' }" class="nav-item" active-class="active">
            <span>🚨</span> Reportes
          </RouterLink>
        </template>

        <!-- Común -->
        <RouterLink :to="{ name: 'notificaciones' }" class="nav-item" active-class="active">
          <span>🔔</span> Notificaciones
          <span v-if="notiStore.noLeidas > 0" class="notif-badge">{{ notiStore.noLeidas }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <div class="user-info">
          <div class="user-avatar">{{ auth.user?.nombre?.charAt(0).toUpperCase() }}</div>
          <div class="user-details">
            <p class="user-name">{{ auth.user?.nombre }}</p>
            <p class="user-role">{{ rolLabel }}</p>
          </div>
        </div>
        <button class="btn btn-ghost btn-sm" @click="handleLogout">Salir</button>
      </div>
    </aside>

    <!-- Overlay -->
    <div v-if="sidebarOpen" class="sidebar-overlay" @click="sidebarOpen = false"></div>

    <!-- Main -->
    <main class="main-content">
      <header class="topbar">
        <button class="btn btn-ghost btn-icon sidebar-toggle" @click="sidebarOpen = true" aria-label="Menú">☰</button>
        <div class="topbar-right">
          <!-- Indicador de conexión WebSocket -->
          <span class="ws-indicator" :class="wsConnected ? 'ws-online' : 'ws-offline'" :title="wsConnected ? 'Tiempo real activo' : 'Sin conexión en tiempo real'">
            {{ wsConnected ? '🟢' : '🔴' }}
          </span>
          <RouterLink :to="{ name: 'notificaciones' }" class="notif-btn">
            🔔
            <span v-if="notiStore.noLeidas > 0" class="notif-badge-top">{{ notiStore.noLeidas }}</span>
          </RouterLink>
          <span class="user-chip">{{ auth.user?.nombre }}</span>
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
import { connectEcho, disconnectEcho } from '@/services/echo'
import AppToast from '@/components/AppToast.vue'

const auth       = useAuthStore()
const notiStore  = useNotificacionesStore()
const router     = useRouter()
const sidebarOpen = ref(false)
const wsConnected = ref(false)
const toastRef    = ref(null)

const rolLabel = computed(() => ({
  VOLUNTARIO: 'Voluntario',
  FUNDACION:  'Fundación',
  ADMIN:      'Administrador',
}[auth.user?.rol] || auth.user?.rol))

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
          // Voluntario: su postulación fue respondida
          const estadoLabel = {
            ACEPTADO: 'aceptada ✅',
            RECHAZADO: 'rechazada ❌',
            ASISTIO: 'confirmada como asistida ✅',
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
      // Obtener fundacion_id del usuario
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
    }

    // ─── Canal público: nuevas convocatorias (voluntarios) ───
    if (auth.isVoluntario) {
      echo.channel('convocatorias')
        .listen('.NuevaPublicacion', (data) => {
          showToast({
            title: '📢 Nueva convocatoria',
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
  try {
    const { data } = await (await import('@/services/api')).default.get('/mi-fundacion')
    return data?.id || data?.data?.id || null
  } catch {
    return null
  }
}

function desuscribirCanales() {
  try {
    const echo = connectEcho()
    if (!echo) return

    const userId = auth.user?.id
    if (userId) {
      echo.leave(`usuario.${userId}`)
    }
    echo.leave('convocatorias')
    // Los canales de fundación se limpian automáticamente con disconnect
  } catch {}
}

// ── Lifecycle ──────────────────────────────────────────────────

onMounted(() => {
  notiStore.cargarConteo()
  // Iniciar conexión WebSocket
  suscribirCanales()
})

onUnmounted(() => {
  desuscribirCanales()
})

// Consumir notificaciones push del store (si otras partes las encolan)
watch(
  () => notiStore.pushQueue.length,
  (newLen) => {
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
}

/* ── Sidebar ──────────────────────────── */
.sidebar {
  width: 250px;
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
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 20px 18px;
  border-bottom: 1px solid rgba(255,255,255,.1);
  font-weight: 700;
  font-size: 18px;
}
.brand-icon { font-size: 22px; }
.brand-name { flex: 1; }
.sidebar-close { display: none; background: none; border: none; color: #fff; cursor: pointer; font-size: 16px; }

.sidebar-nav { flex: 1; padding: 12px 0; }
.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 11px 18px;
  color: rgba(255,255,255,.75);
  font-size: 14px;
  font-weight: 500;
  transition: all .18s;
  position: relative;
  text-decoration: none;
}
.nav-item:hover { background: rgba(255,255,255,.08); color: #fff; text-decoration: none; }
.nav-item.active { background: var(--primary); color: #fff; }

.notif-badge {
  margin-left: auto;
  background: var(--danger);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 99px;
  min-width: 18px;
  text-align: center;
}

.sidebar-footer {
  padding: 14px 18px;
  border-top: 1px solid rgba(255,255,255,.1);
  display: flex;
  align-items: center;
  gap: 10px;
}
.user-info { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
.user-avatar {
  width: 34px; height: 34px;
  background: var(--primary);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-weight: 700; font-size: 14px;
  flex-shrink: 0;
}
.user-details { min-width: 0; }
.user-name { font-size: 13px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.user-role { font-size: 11px; color: rgba(255,255,255,.5); }

/* ── Main ──────────────────────────────── */
.main-content { flex: 1; min-width: 0; display: flex; flex-direction: column; }

.topbar {
  position: sticky; top: 0; z-index: 100;
  background: var(--white);
  border-bottom: 1px solid var(--gray-200);
  padding: 0 24px;
  height: 58px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: var(--shadow);
}
.topbar-right { display: flex; align-items: center; gap: 16px; }
.sidebar-toggle { display: none !important; }

/* WebSocket indicator */
.ws-indicator {
  font-size: 10px;
  cursor: help;
  transition: opacity 0.3s;
}
.ws-offline { opacity: 0.6; }
.ws-online  { animation: ws-pulse 2s ease-in-out infinite; }

@keyframes ws-pulse {
  0%, 100% { opacity: 1; }
  50%      { opacity: 0.5; }
}

.notif-btn {
  position: relative;
  font-size: 20px;
  text-decoration: none;
  line-height: 1;
}
.notif-badge-top {
  position: absolute;
  top: -6px; right: -8px;
  background: var(--danger);
  color: #fff;
  font-size: 10px; font-weight: 700;
  padding: 1px 5px;
  border-radius: 99px;
  min-width: 16px;
  text-align: center;
}
.user-chip { font-size: 13px; font-weight: 500; color: var(--gray-700); }

.page-content { flex: 1; padding: 28px 28px; max-width: 1200px; }

/* ── Overlay (mobile) ─────────────────── */
.sidebar-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,.5);
  z-index: 200;
  display: none;
}

@media (max-width: 900px) {
  .sidebar {
    position: fixed;
    left: -260px;
    top: 0;
    z-index: 300;
    transition: left .25s;
    height: 100%;
  }
  .sidebar.open { left: 0; }
  .sidebar-close { display: block; }
  .sidebar-overlay { display: block; }
  .sidebar-toggle { display: flex !important; }
  .page-content { padding: 20px 16px; }
}
</style>
