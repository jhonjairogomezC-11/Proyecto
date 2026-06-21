import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_fundaciones_screen.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_publicaciones_screen.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_reportes_screen.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_voluntarios_screen.dart';
import 'package:voluntapp_mobile/features/auth/domain/entities/usuario.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/blocked_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:voluntapp_mobile/features/bootstrap/presentation/screens/bootstrap_screen.dart';
import 'package:voluntapp_mobile/features/favoritos/presentation/screens/favoritos_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/convocatoria_form_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/fundacion_dashboard_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/fundacion_shell_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/mis_convocatorias_fundacion_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/perfil_fundacion_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/postulantes_convocatoria_screen.dart';
import 'package:voluntapp_mobile/features/logros/presentation/screens/mis_logros_screen.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/screens/notificaciones_screen.dart';
import 'package:voluntapp_mobile/features/postulaciones/presentation/screens/mis_postulaciones_screen.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/publicaciones/presentation/screens/convocatorias_screen.dart';
import 'package:voluntapp_mobile/features/ranking/presentation/screens/ranking_screen.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/screens/dashboard_voluntario_screen.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/screens/perfil_voluntario_screen.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/screens/voluntario_shell_screen.dart';

abstract final class AppRoutes {
  static const bootstrap = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const blocked = '/blocked';

  static const voluntarioRoot = '/voluntario';
  static const voluntarioInicio = '/voluntario/inicio';
  static const voluntarioActividades = '/voluntario/actividades';
  static const voluntarioPostulaciones = '/voluntario/postulaciones';
  static const voluntarioFavoritos = '/voluntario/favoritos';
  static const voluntarioLogros = '/voluntario/logros';
  static const voluntarioRanking = '/voluntario/ranking';
  static const voluntarioPerfil = '/voluntario/perfil';

  static const fundacionRoot = '/fundacion';
  static const fundacionInicio = '/fundacion/inicio';
  static const fundacionConvocatorias = '/fundacion/convocatorias';
  static const fundacionPerfil = '/fundacion/perfil';
  static const fundacionConvocatoriaForm = '/fundacion/convocatorias/form';

  static String fundacionPostulantesPath(String publicacionId) =>
      '/fundacion/convocatorias/$publicacionId/postulantes';

  static const adminRoot = '/admin';
  static const adminInicio = '/admin/inicio';
  static const adminFundaciones = '/admin/fundaciones';
  static const adminPublicaciones = '/admin/publicaciones';
  static const adminVoluntarios = '/admin/voluntarios';
  static const adminReportes = '/admin/reportes';
  static const adminHome = adminRoot;
  static const notificaciones = '/notificaciones';

  static const guestRoutes = {
    login,
    register,
    forgotPassword,
    resetPassword,
  };

  static String homeForUser(Usuario? user) {
    if (user == null) return login;
    if (user.isVoluntario) return voluntarioInicio;
    if (user.isFundacion) return fundacionInicio;
    if (user.isAdmin) return adminInicio;
    return login;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.bootstrap,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final status = authState.status;

      if (status == AuthStatus.initial) {
        return location == AppRoutes.bootstrap ? null : AppRoutes.bootstrap;
      }

      if (status == AuthStatus.blocked) {
        return location == AppRoutes.blocked ? null : AppRoutes.blocked;
      }

      final isBootstrap = location == AppRoutes.bootstrap;
      final isGuestRoute = AppRoutes.guestRoutes.contains(location);
      final isVoluntarioRoute = location.startsWith(AppRoutes.voluntarioRoot);
      final isFundacionRoute = location.startsWith(AppRoutes.fundacionRoot);
      final isAdminRoute = location.startsWith(AppRoutes.adminRoot);
      final isNotificacionesRoute = location == AppRoutes.notificaciones;

      if (status == AuthStatus.unauthenticated) {
        if (isBootstrap) return AppRoutes.login;
        return isGuestRoute ? null : AppRoutes.login;
      }

      if (status == AuthStatus.authenticated) {
        final user = authState.usuario;
        final home = AppRoutes.homeForUser(user);

        if (isGuestRoute || isBootstrap) return home;

        if (user?.isVoluntario == true && !isVoluntarioRoute && !isNotificacionesRoute) {
          return AppRoutes.voluntarioInicio;
        }
        if (user?.isFundacion == true && !isFundacionRoute && !isNotificacionesRoute) {
          return AppRoutes.fundacionInicio;
        }
        if (user?.isAdmin == true && !isAdminRoute && !isNotificacionesRoute) {
          return AppRoutes.adminInicio;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        builder: (context, state) => const BootstrapScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return ResetPasswordScreen(
            token: params['token'],
            email: params['email'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.blocked,
        builder: (context, state) => const BlockedScreen(),
      ),
      GoRoute(
        path: AppRoutes.fundacionRoot,
        redirect: (_, state) {
          if (state.uri.path == AppRoutes.fundacionRoot) {
            return AppRoutes.fundacionInicio;
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return FundacionShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'inicio',
                    builder: (context, state) => const FundacionDashboardScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'convocatorias',
                    builder: (context, state) => const MisConvocatoriasFundacionScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'perfil',
                    builder: (context, state) => const PerfilFundacionScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'convocatorias/form',
            builder: (context, state) {
              final pub = state.extra;
              return ConvocatoriaFormScreen(
                publicacion: pub is Publicacion ? pub : null,
              );
            },
          ),
          GoRoute(
            path: 'convocatorias/:id/postulantes',
            builder: (context, state) {
              final titulo = state.extra is String ? state.extra as String : 'Convocatoria';
              return PostulantesConvocatoriaScreen(
                publicacionId: state.pathParameters['id']!,
                titulo: titulo,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notificaciones,
        builder: (context, state) => const NotificacionesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRoot,
        redirect: (_, state) {
          if (state.uri.path == AppRoutes.adminRoot) {
            return AppRoutes.adminInicio;
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return AdminShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'inicio',
                    builder: (context, state) => const AdminDashboardScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'fundaciones',
                    builder: (context, state) => const AdminFundacionesScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'publicaciones',
                    builder: (context, state) => const AdminPublicacionesScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'voluntarios',
                    builder: (context, state) => const AdminVoluntariosScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'reportes',
                    builder: (context, state) => const AdminReportesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.voluntarioRoot,
        redirect: (_, state) {
          if (state.uri.path == AppRoutes.voluntarioRoot) {
            return AppRoutes.voluntarioInicio;
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return VoluntarioShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'inicio',
                    builder: (context, state) => const DashboardVoluntarioScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'actividades',
                    builder: (context, state) => const ConvocatoriasScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'postulaciones',
                    builder: (context, state) => const MisPostulacionesScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'favoritos',
                    builder: (context, state) => const FavoritosScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'perfil',
                    builder: (context, state) => const PerfilVoluntarioScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'logros',
            builder: (context, state) => const MisLogrosScreen(),
          ),
          GoRoute(
            path: 'ranking',
            builder: (context, state) => const RankingScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
