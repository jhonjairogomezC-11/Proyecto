import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/repositories/admin_repository.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';

/// Screen 05C — Dashboard Admin
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _fundacionesPendientes = 0;
  int _publicacionesPendientes = 0;
  int _reportesPendientes = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final stats = await repo.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _fundacionesPendientes = stats['fundaciones_pendientes'] ?? 0;
        _publicacionesPendientes = stats['publicaciones_pendientes'] ?? 0;
        _reportesPendientes = stats['reportes_pendientes'] ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e is ApiException ? e.message : 'Error al cargar panel.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          const NotificacionAppBarAction(),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.danger)),
                    ),
                  Text(
                    'Hola, ${user?.nombre ?? 'Admin'}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Revisa pendientes y gestiona la plataforma.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pendientes de revisión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Fundaciones',
                          count: _fundacionesPendientes,
                          icon: Icons.business,
                          color: AppColors.warning,
                          onTap: () => context.go(AppRoutes.adminFundaciones),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Publicaciones',
                          count: _publicacionesPendientes,
                          icon: Icons.campaign,
                          color: AppColors.primary,
                          onTap: () => context.go(AppRoutes.adminPublicaciones),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StatCard(
                    label: 'Reportes',
                    count: _reportesPendientes,
                    icon: Icons.flag,
                    color: AppColors.danger,
                    onTap: () => context.go(AppRoutes.adminReportes),
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Accesos rápidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _QuickTile(
                    icon: Icons.business,
                    title: 'Gestión de fundaciones',
                    subtitle: 'Aprobar, rechazar o suspender',
                    onTap: () => context.go(AppRoutes.adminFundaciones),
                  ),
                  _QuickTile(
                    icon: Icons.campaign,
                    title: 'Publicaciones en revisión',
                    subtitle: 'Aprobar o rechazar convocatorias',
                    onTap: () => context.go(AppRoutes.adminPublicaciones),
                  ),
                  _QuickTile(
                    icon: Icons.people,
                    title: 'Voluntarios',
                    subtitle: 'Suspender, bloquear o reactivar',
                    onTap: () => context.go(AppRoutes.adminVoluntarios),
                  ),
                  _QuickTile(
                    icon: Icons.flag,
                    title: 'Reportes',
                    subtitle: 'Resolver incidencias de la comunidad',
                    onTap: () => context.go(AppRoutes.adminReportes),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
