import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/repositories/admin_repository.dart';
import 'package:voluntapp_mobile/features/admin/presentation/widgets/admin_historial_sheet.dart';
import 'package:voluntapp_mobile/features/admin/presentation/widgets/admin_motivo_dialog.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/fundacion_perfil.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/shared/widgets/avatar_image.dart';

/// Screen 14 — Admin Fundaciones
class AdminFundacionesScreen extends ConsumerStatefulWidget {
  const AdminFundacionesScreen({super.key});

  @override
  ConsumerState<AdminFundacionesScreen> createState() =>
      _AdminFundacionesScreenState();
}

class _AdminFundacionesScreenState
    extends ConsumerState<AdminFundacionesScreen> {
  static const _tabs = [
    ('', 'Todas'),
    ('PENDIENTE', 'Pendientes'),
    ('APROBADA', 'Aprobadas'),
    ('RECHAZADA', 'Rechazadas'),
    ('SUSPENDIDA', 'Suspendidas'),
  ];

  List<FundacionPerfil> _items = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _estado = '';
  String? _actionId;
  String? _expandedId; // ID de la fundación expandida
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final result = await ref.read(adminRepositoryProvider).fetchFundaciones(
            estado: _estado.isEmpty ? null : _estado,
            nombre: _searchController.text.trim(),
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
          e is ApiException ? e.message : 'Error al cargar fundaciones.');
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

  Future<void> _aprobar(FundacionPerfil f) async {
    if (!mounted) return;
    
    setState(() => _actionId = f.id);
    await _runAction(
        () => ref.read(adminRepositoryProvider).aprobarFundacion(f.id));
  }

  Future<void> _rechazar(FundacionPerfil f) async {
    if (!mounted) return;
    
    final motivo =
        await showAdminMotivoDialog(context, title: 'Rechazar fundación');
    if (motivo == null || !mounted) return;
    
    setState(() => _actionId = f.id);
    await _runAction(() =>
        ref.read(adminRepositoryProvider).rechazarFundacion(f.id, motivo));
  }

  Future<void> _suspender(FundacionPerfil f) async {
    if (!mounted) return;
    
    final motivo =
        await showAdminMotivoDialog(context, title: 'Suspender fundación');
    if (motivo == null || !mounted) return;
    
    setState(() => _actionId = f.id);
    await _runAction(() =>
        ref.read(adminRepositoryProvider).suspenderFundacion(f.id, motivo));
  }

  Future<void> _reactivar(FundacionPerfil f) async {
    if (!mounted) return;
    
    setState(() => _actionId = f.id);
    await _runAction(
        () => ref.read(adminRepositoryProvider).reactivarFundacion(f.id));
  }

  void _showHistorial(FundacionPerfil f) {
    showAdminHistorialSheet(
      context,
      ref,
      titulo: f.nombre,
      fetch: () =>
          ref.read(adminRepositoryProvider).fetchFundacionHistorial(f.id),
    );
  }

  void _showDetalle(FundacionPerfil f) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(f.nombre,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              EstadoBadge(estado: f.estadoVerificacion, tipo: 'fundacion'),
              const SizedBox(height: 16),
              _DetailRow('NIT', f.nit),
              _DetailRow('Representante', f.representanteLegal),
              _DetailRow('Correo', f.correoInstitucional ?? '—'),
              _DetailRow('Teléfono', f.telefono),
              _DetailRow('Ubicación', f.municipio?.nombre ?? '—'),
              if (f.motivoRechazo != null) ...[
                const SizedBox(height: 8),
                _DetailRow('Motivo rechazo', f.motivoRechazo!),
              ],
              const SizedBox(height: 8),
              Text(f.descripcion,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundaciones'),
        actions: const [NotificacionAppBarAction()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
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
                                      'No hay fundaciones con estos filtros.')),
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
                              final f = _items[index];
                              final busy = _actionId == f.id;
                              final isExpanded = _expandedId == f.id;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  children: [
                                    // Header compacto siempre visible
                                    ListTile(
                                      leading: AvatarImage(
                                        imageUrl: f.logo,
                                        fallbackText: f.nombre,
                                        radius: 20,
                                      ),
                                      title: Text(
                                        f.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        f.correoInstitucional ?? 'NIT ${f.nit}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          EstadoBadge(estado: f.estadoVerificacion, tipo: 'fundacion'),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isExpanded 
                                              ? Icons.keyboard_arrow_up 
                                              : Icons.keyboard_arrow_down,
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _expandedId = isExpanded ? null : f.id;
                                        });
                                      },
                                    ),
                                    // Sección expandible con detalles y acciones
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            Text(
                                              'NIT ${f.nit} · ${f.municipio?.nombre ?? 'Sin ubicación'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () => _showDetalle(f),
                                                  icon: const Icon(Icons.info_outline, size: 16),
                                                  label: const Text('Detalle'),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () => _showHistorial(f),
                                                  icon: const Icon(Icons.history, size: 16),
                                                  label: const Text('Historial'),
                                                ),
                                                if (f.isPendiente) ...[
                                                  FilledButton.icon(
                                                    onPressed: busy ? null : () => _aprobar(f),
                                                    icon: busy 
                                                        ? const SizedBox(
                                                            height: 16,
                                                            width: 16,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          )
                                                        : const Icon(Icons.check, size: 16),
                                                    label: const Text('Aprobar'),
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: AppColors.success,
                                                    ),
                                                  ),
                                                  OutlinedButton.icon(
                                                    onPressed: busy ? null : () => _rechazar(f),
                                                    icon: const Icon(Icons.close, size: 16),
                                                    label: const Text('Rechazar'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppColors.danger,
                                                    ),
                                                  ),
                                                ],
                                                if (f.isAprobada)
                                                  OutlinedButton.icon(
                                                    onPressed: busy ? null : () => _suspender(f),
                                                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                                                    label: const Text('Suspender'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppColors.warning,
                                                    ),
                                                  ),
                                                if (f.estadoVerificacion == 'RECHAZADA' || 
                                                    f.estadoVerificacion == 'SUSPENDIDA')
                                                  OutlinedButton.icon(
                                                    onPressed: busy ? null : () => _reactivar(f),
                                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                                    label: const Text('Reactivar'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppColors.success,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
