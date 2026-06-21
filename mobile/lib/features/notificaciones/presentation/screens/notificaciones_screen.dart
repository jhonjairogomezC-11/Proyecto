import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/notificaciones/data/models/notificacion.dart';
import 'package:voluntapp_mobile/features/notificaciones/data/repositories/notificacion_repository.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/providers/notificaciones_badge_provider.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/utils/notificacion_utils.dart';

/// Screen 18 — Notificaciones (shared)
class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  List<Notificacion> _items = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  bool _marcandoTodas = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final result = await ref.read(notificacionRepositoryProvider).fetchNotificaciones(page: page);
      if (!mounted) return;
      setState(() {
        if (page == 1) {
          _items = result.data;
        } else {
          _items = [..._items, ...result.data];
        }
        _meta = result.meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar notificaciones.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _marcarLeida(Notificacion n) async {
    if (n.leida) return;
    try {
      final updated = await ref.read(notificacionRepositoryProvider).marcarLeida(n.id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((item) => item.id == n.id ? updated : item).toList();
      });
      ref.read(notificacionesBadgeProvider.notifier).decrement();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'No se pudo marcar como leída.')),
      );
    }
  }

  Future<void> _marcarTodas() async {
    setState(() => _marcandoTodas = true);
    try {
      await ref.read(notificacionRepositoryProvider).marcarTodasLeidas();
      if (!mounted) return;
      setState(() {
        _items = _items.map((n) => n.copyWith(leida: true)).toList();
      });
      ref.read(notificacionesBadgeProvider.notifier).reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Error al marcar todas.')),
      );
    } finally {
      if (mounted) setState(() => _marcandoTodas = false);
    }
  }

  bool get _hayNoLeidas => _items.any((n) => !n.leida);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_hayNoLeidas)
            TextButton(
              onPressed: _marcandoTodas ? null : _marcarTodas,
              child: _marcandoTodas
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Marcar todas'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => _load(), child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(),
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: const [
                            Icon(Icons.notifications_none, size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text(
                              'Sin notificaciones',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Cuando tengas actividad, las notificaciones aparecerán aquí.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length + (_meta?.hasMore == true ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == _items.length) {
                              if (_loadingMore) {
                                return const Center(child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ));
                              }
                              return Center(
                                child: TextButton(
                                  onPressed: () => _load(page: (_meta?.currentPage ?? 1) + 1),
                                  child: const Text('Cargar más'),
                                ),
                              );
                            }

                            final n = _items[index];
                            return Material(
                              color: n.leida
                                  ? null
                                  : AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _marcarLeida(n),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        iconForNotificacionTipo(n.tipo),
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.mensaje,
                                              style: TextStyle(
                                                fontWeight: n.leida ? FontWeight.normal : FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formatRelativeNotificacion(n.fechaCreacion),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!n.leida)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
