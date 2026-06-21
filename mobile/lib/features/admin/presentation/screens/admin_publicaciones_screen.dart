import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/repositories/admin_repository.dart';
import 'package:voluntapp_mobile/features/admin/presentation/widgets/admin_motivo_dialog.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

/// Screen 15 — Admin Publicaciones
class AdminPublicacionesScreen extends ConsumerStatefulWidget {
  const AdminPublicacionesScreen({super.key});

  @override
  ConsumerState<AdminPublicacionesScreen> createState() =>
      _AdminPublicacionesScreenState();
}

class _AdminPublicacionesScreenState
    extends ConsumerState<AdminPublicacionesScreen> {
  static const _tabs = [
    ('PENDIENTE_APROBACION', 'En revisión'),
    ('PUBLICADA', 'Publicadas'),
    ('CANCELADA', 'Canceladas'),
  ];

  List<Publicacion> _items = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _estado = 'PENDIENTE_APROBACION';
  String? _actionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ref.read(adminRepositoryProvider).fetchPublicaciones(
            estado: _estado,
            page: page,
          );
      if (!mounted) return;
      setState(() {
        _items = append ? [..._items, ...result.data] : result.data;
        _meta = result.meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          e is ApiException ? e.message : 'Error al cargar publicaciones.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      await _load(page: _meta?.currentPage ?? 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acción realizada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e is ApiException ? e.message : 'Error en la acción.')),
      );
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  Future<void> _aprobar(Publicacion pub) async {
    setState(() => _actionId = pub.id);
    await _runAction(
        () => ref.read(adminRepositoryProvider).aprobarPublicacion(pub.id));
  }

  Future<void> _rechazar(Publicacion pub) async {
    final motivo =
        await showAdminMotivoDialog(context, title: 'Rechazar publicación');
    if (motivo == null) return;
    setState(() => _actionId = pub.id);
    await _runAction(() =>
        ref.read(adminRepositoryProvider).rechazarPublicacion(pub.id, motivo));
  }

  void _showDetalle(Publicacion pub) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(pub.titulo,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (pub.estado != null) EstadoBadge(estado: pub.estado!),
              const SizedBox(height: 12),
              Text('Fundación: ${pub.fundacionNombre ?? '—'}'),
              Text('Categoría: ${pub.categoriaNombre ?? '—'}'),
              Text('Modalidad: ${pub.modalidad}'),
              if (pub.fechaInicio != null)
                Text('Inicio: ${formatShortDate(pub.fechaInicio)}'),
              const SizedBox(height: 12),
              Text(pub.descripcion),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPendiente = _estado == 'PENDIENTE_APROBACION';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicaciones'),
        actions: const [NotificacionAppBarAction()],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _tabs.map((tab) {
                final selected = _estado == tab.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tab.$2),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _estado = tab.$1);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _load(page: _meta?.currentPage ?? 1),
                    child: _items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                  child: Text(
                                      'No hay publicaciones en este estado.')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length +
                                (_meta?.hasMore == true ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                return TextButton(
                                  onPressed: _loadingMore
                                      ? null
                                      : () => _load(
                                          page: (_meta?.currentPage ?? 1) + 1,
                                          append: true),
                                  child: _loadingMore
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Cargar más'),
                                );
                              }
                              final pub = _items[index];
                              final busy = _actionId == pub.id;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              pub.titulo,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          if (pub.estado != null)
                                            EstadoBadge(estado: pub.estado!),
                                        ],
                                      ),
                                      Text(
                                        pub.fundacionNombre ?? 'Sin fundación',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          TextButton(
                                            onPressed: () => _showDetalle(pub),
                                            child: const Text('Detalle'),
                                          ),
                                          if (isPendiente) ...[
                                            FilledButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _aprobar(pub),
                                              child: busy
                                                  ? const SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : const Text('Aprobar'),
                                            ),
                                            OutlinedButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _rechazar(pub),
                                              child: const Text('Rechazar'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
