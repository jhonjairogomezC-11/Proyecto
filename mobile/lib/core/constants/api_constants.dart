/// Rutas relativas al baseUrl (/api/v1).
class ApiConstants {
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authLogout = '/auth/logout';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';
  static const authRevokeRefresh = '/auth/revoke-refresh';
  static const authForgotPassword = '/auth/forgot-password';
  static const authResetPassword = '/auth/reset-password';

  static const catalogosDepartamentos = '/catalogos/departamentos';
  static const catalogosMunicipios = '/catalogos/municipios';
  static const catalogosHabilidades = '/catalogos/habilidades';
  static const catalogosIntereses = '/catalogos/intereses';
  static const catalogosAreasImpacto = '/catalogos/areas-impacto';

  static const voluntario = '/voluntario';
  static const voluntarioDashboard = '/voluntario/dashboard';
  static const voluntarioPuntos = '/voluntario/puntos';
  static const voluntarioLogros = '/voluntario/logros';
  static const voluntarioFavoritos = '/voluntario/favoritos';
  static const voluntarioFavoritosIds = '/voluntario/favoritos/ids';

  static const ranking = '/ranking';

  static const publicaciones = '/publicaciones';
  static const misPublicaciones = '/mis-publicaciones';
  static const postulaciones = '/postulaciones';
  static const misPostulaciones = '/mis-postulaciones';

  static const miFundacion = '/mi-fundacion';
  static const fundaciones = '/fundaciones';

  static const notificaciones = '/notificaciones';
  static const notificacionesNoLeidas = '/notificaciones/no-leidas';

  static const reportes = '/reportes';

  static const adminFundaciones = '/admin/fundaciones';
  static const adminPublicaciones = '/admin/publicaciones';
  static const adminVoluntarios = '/admin/voluntarios';
  static const adminReportes = '/admin/reportes';
}
