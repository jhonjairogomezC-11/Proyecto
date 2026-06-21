import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/models/reporte.dart';
import 'package:voluntapp_mobile/features/admin/data/repositories/admin_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

/// Screen 17 — Admin Reportes
class AdminReportesScreen extends ConsumerStatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  ConsumerState<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends ConsumerState<AdminReportesScreen> {
  static const _tabs = [
    ('', 'Todos'),
    ('PENDIENTE', 'Pendientes'),
    ('EN_REVISION', 'En revisión'),
    ('RESUELTO', 'Resueltos'),
    ('DESESTIMADO', 'Desestimados'),
  ];

  List<Reporte> _items = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _estado = '';
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
      final result = await ref.read(adminRepositoryProvider).fetchReportes(
            estado: _estado.isEmpty ? null : _estado,
            page: page,
          );
      if (!mounted) return;
      setState(() {
        _items = append ? [..._items, ...result.data] : result.data;
        _meta = result.meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar reportes.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _resolver(Reporte reporte) async {
    String decision = 'RESUELTO';
    final resolucionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Resolver reporte'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: decision,
                  decoration: const InputDecoration(labelText: 'Decisión'),
                  items: const [
                    DropdownMenuItem(value: 'RESUELTO', child: Text('Resuelto')),
                    DropdownMenuItem(value: 'DESESTIMADO', child: Text('Desestimado')),
                  ],
                  onChanged: (v) => setDialogState(() => decision = v ?? 'RESUELTO'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: resolucionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la resolución',
                  ),
                  validator: (v) {
                    if ((v?.trim().length ?? 0) < 5) return 'Describe la resolución.';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      resolucionController.dispose();
      return;
    }

    setState(() => _actionId = reporte.id);
    try {
      await ref.read(adminRepositoryProvider).resolverReporte(
            reporte.id,
            estado: decision,
            resolucion: resolucionController.text.trim(),
          );
      await _load(page: _meta?.currentPage ?? 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte resuelto.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Error al resolver.')),
      );
    } finally {
      resolucionController.dispose();
      if (mounted) setState(() => _actionId = null);
    }
  }

  void _showDetalle(Reporte r) {
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
                ReporteMotivos.label(r.motivo),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              EstadoBadge(estado: r.estado, tipo: 'reporte'),
              const SizedBox(height: 16),
              _DetailRow('Reportante', r.reportanteNombre ?? 'Anónimo'),
              _DetailRow('Objeto', r.objetoTipo),
              if (r.fechaCreacion != null)
                _DetailRow('Fecha', formatShortDate(r.fechaCreacion)),
              if (r.detalle != null && r.detalle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(r.detalle!, style: const TextStyle(color: AppColors.textSecondary)),
              ],
              if (r.resolucion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Resolución: ${r.resolucion}'),
                ),
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
        title: const Text('Reportes'),
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
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
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
                              Center(child: Text('No hay reportes en este estado.')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length + (_meta?.hasMore == true ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                return TextButton(
                                  onPressed: _loadingMore
                                      ? null
                                      : () => _load(page: (_meta?.currentPage ?? 1) + 1, append: true),
                                  child: _loadingMore
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Cargar más'),
                                );
                              }
                              final r = _items[index];
                              final busy = _actionId == r.id;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ReporteMotivos.label(r.motivo),
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          EstadoBadge(estado: r.estado, tipo: 'reporte'),
                                        ],
                                      ),
                                      Text(
                                        '${r.reportanteNombre ?? 'Anónimo'} · ${r.objetoTipo}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (r.fechaCreacion != null)
                                        Text(
                                          formatShortDate(r.fechaCreacion),
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
                                            onPressed: () => _showDetalle(r),
                                            child: const Text('Detalle'),
                                          ),
                                          if (r.isPendiente)
                                            FilledButton(
                                              onPressed: busy ? null : () => _resolver(r),
                                              child: busy
                                                  ? const SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                  : const Text('Resolver'),
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
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
