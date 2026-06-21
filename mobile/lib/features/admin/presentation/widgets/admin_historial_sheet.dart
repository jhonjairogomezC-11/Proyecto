import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/models/admin_historial_item.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

Future<void> showAdminHistorialSheet(
  BuildContext context,
  WidgetRef ref, {
  required String titulo,
  required Future<List<AdminHistorialItem>> Function() fetch,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollController) => _AdminHistorialContent(
        titulo: titulo,
        scrollController: scrollController,
        fetch: fetch,
      ),
    ),
  );
}

class _AdminHistorialContent extends ConsumerStatefulWidget {
  const _AdminHistorialContent({
    required this.titulo,
    required this.scrollController,
    required this.fetch,
  });

  final String titulo;
  final ScrollController scrollController;
  final Future<List<AdminHistorialItem>> Function() fetch;

  @override
  ConsumerState<_AdminHistorialContent> createState() =>
      _AdminHistorialContentState();
}

class _AdminHistorialContentState
    extends ConsumerState<_AdminHistorialContent> {
  List<AdminHistorialItem>? _items;
  String? _error;
  bool _loading = true;

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
      final items = await widget.fetch();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          e is ApiException ? e.message : 'Error al cargar historial.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.titulo,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Historial de cambios y eventos',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger)))
                    : (_items == null || _items!.isEmpty)
                        ? const Center(
                            child: Text('Sin registros en el historial.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              controller: widget.scrollController,
                              itemCount: _items!.length,
                              itemBuilder: (context, index) {
                                final item = _items![index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(item.titulo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item.fecha != null)
                                          Text(formatShortDate(item.fecha),
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        if (item.motivo != null &&
                                            item.motivo!.isNotEmpty)
                                          Text(item.motivo!,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        if (item.adminNombre != null)
                                          Text(
                                            'Por: ${item.adminNombre}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary),
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
