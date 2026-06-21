import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/models/admin_voluntario_item.dart';
import 'package:voluntapp_mobile/features/admin/data/repositories/admin_repository.dart';
import 'package:voluntapp_mobile/features/admin/presentation/widgets/admin_historial_sheet.dart';
import 'package:voluntapp_mobile/features/admin/presentation/widgets/admin_motivo_dialog.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/voluntario_perfil.dart';

/// Screen 16 — Admin Voluntarios
class AdminVoluntariosScreen extends ConsumerStatefulWidget {
  const AdminVoluntariosScreen({super.key});

  @override
  ConsumerState<AdminVoluntariosScreen> createState() =>
      _AdminVoluntariosScreenState();
}

class _AdminVoluntariosScreenState
    extends ConsumerState<AdminVoluntariosScreen> {
  static const _tabs = [
    ('', 'Todos'),
    ('ACTIVO', 'Activos'),
    ('SUSPENDIDO', 'Suspendidos'),
    ('BLOQUEADO', 'Bloqueados'),
  ];

  List<AdminVoluntarioItem> _items = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _estado = '';
  String? _actionId;
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
      final result = await ref.read(adminRepositoryProvider).fetchVoluntarios(
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
          e is ApiException ? e.message : 'Error al cargar voluntarios.');
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

  Future<void> _suspender(AdminVoluntarioItem item) async {
    final motivo =
        await showAdminMotivoDialog(context, title: 'Suspender voluntario');
    if (motivo == null) return;
    setState(() => _actionId = item.id);
    await _runAction(
      () => ref
          .read(adminRepositoryProvider)
          .suspenderVoluntario(item.id, motivo: motivo),
    );
  }

  Future<void> _bloquear(AdminVoluntarioItem item) async {
    final motivo =
        await showAdminMotivoDialog(context, title: 'Bloquear voluntario');
    if (motivo == null) return;
    setState(() => _actionId = item.id);
    await _runAction(() =>
        ref.read(adminRepositoryProvider).bloquearVoluntario(item.id, motivo));
  }

  Future<void> _reactivar(AdminVoluntarioItem item) async {
    setState(() => _actionId = item.id);
    await _runAction(
        () => ref.read(adminRepositoryProvider).reactivarVoluntario(item.id));
  }

  void _showHistorial(AdminVoluntarioItem item) {
    showAdminHistorialSheet(
      context,
      ref,
      titulo: item.nombreUsuario ?? 'Voluntario',
      fetch: () =>
          ref.read(adminRepositoryProvider).fetchVoluntarioHistorial(item.id),
    );
  }

  void _showDetalle(AdminVoluntarioItem item) {
    final v = item.perfil;
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
              Text(
                item.nombreUsuario ?? 'Voluntario',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (item.estadoUsuario != null)
                EstadoBadge(estado: item.estadoUsuario!, tipo: 'usuario'),
              const SizedBox(height: 16),
              _DetailRow('Email', item.emailUsuario ?? '—'),
              _DetailRow(
                  'Documento', '${v.tipoDocumento} ${v.numeroDocumento}'),
              _DetailRow('Municipio', v.municipio?.nombre ?? '—'),
              _DetailRow(
                'Disponibilidad',
                VoluntarioOptions.labelDisponibilidad(v.disponibilidad),
              ),
              if (v.experiencia != null && v.experiencia!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(v.experiencia!,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
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
        title: const Text('Voluntarios'),
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
                                      'No hay voluntarios con estos filtros.')),
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
                              final item = _items[index];
                              final busy = _actionId == item.id;
                              final estado = item.estadoUsuario ?? 'ACTIVO';
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
                                              item.nombreUsuario ??
                                                  item.perfil.numeroDocumento,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          EstadoBadge(
                                              estado: estado, tipo: 'usuario'),
                                        ],
                                      ),
                                      Text(
                                        item.emailUsuario ??
                                            item.perfil.numeroDocumento,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        item.perfil.municipio?.nombre ??
                                            'Sin municipio',
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
                                            onPressed: () => _showDetalle(item),
                                            child: const Text('Detalle'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                _showHistorial(item),
                                            child: const Text('Historial'),
                                          ),
                                          if (estado == 'ACTIVO') ...[
                                            OutlinedButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _suspender(item),
                                              child: const Text('Suspender'),
                                            ),
                                            OutlinedButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _bloquear(item),
                                              child: const Text('Bloquear'),
                                            ),
                                          ],
                                          if (estado == 'SUSPENDIDO' ||
                                              estado == 'BLOQUEADO')
                                            OutlinedButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _reactivar(item),
                                              child: const Text('Reactivar'),
                                            ),
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
