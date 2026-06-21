import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:voluntapp_mobile/features/auth/domain/entities/usuario.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/blocked_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:voluntapp_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:voluntapp_mobile/features/bootstrap/presentation/screens/bootstrap_screen.dart';
import 'package:voluntapp_mobile/features/favoritos/presentation/screens/favoritos_screen.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/screens/fundacion_home_screen.dart';
import 'package:voluntapp_mobile/features/logros/presentation/screens/mis_logros_screen.dart';
import 'package:voluntapp_mobile/features/postulaciones/presentation/screens/mis_postulaciones_screen.dart';
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

  static const fundacionHome = '/fundacion';
  static const adminHome = '/admin';

  static const guestRoutes = {
    login,
    register,
    forgotPassword,
    resetPassword,
  };

  static String homeForUser(Usuario? user) {
    if (user == null) return login;
    if (user.isVoluntario) return voluntarioInicio;
    if (user.isFundacion) return fundacionHome;
    if (user.isAdmin) return adminHome;
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
      final isFundacionRoute = location.startsWith(AppRoutes.fundacionHome);
      final isAdminRoute = location.startsWith(AppRoutes.adminHome);

      if (status == AuthStatus.unauthenticated) {
        if (isBootstrap) return AppRoutes.login;
        return isGuestRoute ? null : AppRoutes.login;
      }

      if (status == AuthStatus.authenticated) {
        final user = authState.usuario;
        final home = AppRoutes.homeForUser(user);

        if (isGuestRoute || isBootstrap) return home;

        if (user?.isVoluntario == true && !isVoluntarioRoute) {
          return AppRoutes.voluntarioInicio;
        }
        if (user?.isFundacion == true && !isFundacionRoute) {
          return AppRoutes.fundacionHome;
        }
        if (user?.isAdmin == true && !isAdminRoute) {
          return AppRoutes.adminHome;
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
        path: AppRoutes.fundacionHome,
        builder: (context, state) => const FundacionHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
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
