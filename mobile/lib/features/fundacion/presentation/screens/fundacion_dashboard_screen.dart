import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/fundacion/data/repositories/fundacion_publicacion_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/data/repositories/fundacion_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

/// Screen 05B — Dashboard Fundación
class FundacionDashboardScreen extends ConsumerStatefulWidget {
  const FundacionDashboardScreen({super.key});

  @override
  ConsumerState<FundacionDashboardScreen> createState() => _FundacionDashboardScreenState();
}

class _FundacionDashboardScreenState extends ConsumerState<FundacionDashboardScreen> {
  List<Publicacion> _publicaciones = [];
  int _total = 0;
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
      ref.invalidate(fundacionPerfilProvider);
      final result = await ref.read(fundacionPublicacionRepositoryProvider).fetchMisPublicaciones();
      if (!mounted) return;
      setState(() {
        _publicaciones = result.data;
        _total = result.meta.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar datos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _count(String estado) => _publicaciones.where((p) => p.estado == estado).length;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).usuario;
    final perfilAsync = ref.watch(fundacionPerfilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${user?.nombre.split(' ').first ?? 'Fundación'}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          perfilAsync.when(
                            loading: () => const Text('Cargando perfil…'),
                            error: (_, __) => const Text('No se pudo cargar el perfil.'),
                            data: (perfil) {
                              if (perfil == null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Registra tu fundación para publicar convocatorias.',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: () => context.go(AppRoutes.fundacionPerfil),
                                      child: const Text('Registrar fundación'),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      perfil.nombre,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  EstadoBadge(estado: perfil.estadoVerificacion, tipo: 'fundacion'),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatTile(label: 'Convocatorias', value: '$_total')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatTile(label: 'Publicadas', value: '${_count('PUBLICADA')}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatTile(label: 'Borradores', value: '${_count('BORRADOR')}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(label: 'En revisión', value: '${_count('PENDIENTE_APROBACION')}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.fundacionConvocatorias),
                    icon: const Icon(Icons.campaign),
                    label: const Text('Gestionar convocatorias'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
