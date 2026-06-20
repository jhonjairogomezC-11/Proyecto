import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  // ── Auth (con AuthLayout) ─────────────────────────────
  {
    path: '/auth',
    component: () => import('@/layouts/AuthLayout.vue'),
    meta: { guest: true },
    children: [
      { path: 'login',    name: 'login',           component: () => import('@/views/auth/LoginView.vue') },
      { path: 'register', name: 'register',         component: () => import('@/views/auth/RegisterView.vue') },
      { path: 'forgot',   name: 'forgot-password',  component: () => import('@/views/auth/ForgotPasswordView.vue') },
      { path: 'reset-password', name: 'reset-password', component: () => import('@/views/auth/ResetPasswordView.vue') },
    ]
  },

  // ── Dashboard (con DashboardLayout) ──────────────────
  {
    path: '/dashboard',
    component: () => import('@/layouts/DashboardLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        component: () => import('@/views/DashboardView.vue')
      },

      // Voluntario
      {
        path: 'perfil-voluntario',
        name: 'perfil-voluntario',
        component: () => import('@/views/voluntario/PerfilVoluntarioView.vue'),
        meta: { role: 'VOLUNTARIO' }
      },
      {
        path: 'convocatorias',
        name: 'convocatorias',
        component: () => import('@/views/voluntario/ConvocatoriasView.vue'),
        meta: { role: 'VOLUNTARIO' }
      },
      {
        path: 'mis-postulaciones',
        name: 'mis-postulaciones',
        component: () => import('@/views/voluntario/MisPostulacionesView.vue'),
        meta: { role: 'VOLUNTARIO' }
      },
      {
        path: 'favoritos',
        name: 'favoritos',
        component: () => import('@/views/voluntario/FavoritosView.vue'),
        meta: { role: 'VOLUNTARIO' }
      },
      {
        path: 'mis-logros',
        name: 'mis-logros',
        component: () => import('@/views/voluntario/MisLogrosView.vue'),
        meta: { role: 'VOLUNTARIO' }
      },
      {
        path: 'ranking',
        name: 'ranking',
        component: () => import('@/views/voluntario/RankingView.vue'),
        meta: { role: 'VOLUNTARIO' }
      },

      // Fundación
      {
        path: 'perfil-fundacion',
        name: 'perfil-fundacion',
        component: () => import('@/views/fundacion/PerfilFundacionView.vue'),
        meta: { role: 'FUNDACION' }
      },
      {
        path: 'mis-convocatorias',
        name: 'mis-convocatorias',
        component: () => import('@/views/fundacion/MisConvocatoriasView.vue'),
        meta: { role: 'FUNDACION' }
      },

      // Admin
      {
        path: 'admin/fundaciones',
        name: 'admin-fundaciones',
        component: () => import('@/views/admin/AdminFundacionesView.vue'),
        meta: { role: 'ADMIN' }
      },
      {
        path: 'admin/publicaciones',
        name: 'admin-publicaciones',
        component: () => import('@/views/admin/AdminPublicacionesView.vue'),
        meta: { role: 'ADMIN' }
      },
      {
        path: 'admin/voluntarios',
        name: 'admin-voluntarios',
        component: () => import('@/views/admin/AdminVoluntariosView.vue'),
        meta: { role: 'ADMIN' }
      },
      {
        path: 'admin/reportes',
        name: 'admin-reportes',
        component: () => import('@/views/admin/AdminReportesView.vue'),
        meta: { role: 'ADMIN' }
      },

      // Común
      {
        path: 'notificaciones',
        name: 'notificaciones',
        component: () => import('@/views/NotificacionesView.vue')
      },
    ]
  },

  // Redireccionamientos
  { path: '/',          redirect: '/auth/login' },
  { path: '/login',     redirect: '/auth/login' },
  { path: '/register',  redirect: '/auth/register' },
  { path: '/:pathMatch(.*)*', redirect: '/auth/login' }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return next({ name: 'login' })
  }

  if (to.meta.guest && auth.isLoggedIn) {
    return next({ name: 'dashboard' })
  }

  if (to.meta.role) {
    const userRol = auth.user?.rol
    if (userRol !== to.meta.role) {
      return next({ name: 'dashboard' })
    }
  }

  next()
})

export default router
