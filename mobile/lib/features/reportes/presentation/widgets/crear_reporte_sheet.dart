import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/admin/data/models/reporte.dart';
import 'package:voluntapp_mobile/features/reportes/data/repositories/reporte_repository.dart';

/// Screen 17.1 — Crear reporte (cualquier usuario autenticado)
Future<bool?> showCrearReporteSheet(
  BuildContext context,
  WidgetRef ref, {
  required String objetoTipo,
  required String objetoId,
  String? titulo,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CrearReporteSheet(
      objetoTipo: objetoTipo,
      objetoId: objetoId,
      titulo: titulo,
    ),
  );
}

class _CrearReporteSheet extends ConsumerStatefulWidget {
  const _CrearReporteSheet({
    required this.objetoTipo,
    required this.objetoId,
    this.titulo,
  });

  final String objetoTipo;
  final String objetoId;
  final String? titulo;

  @override
  ConsumerState<_CrearReporteSheet> createState() => _CrearReporteSheetState();
}

class _CrearReporteSheetState extends ConsumerState<_CrearReporteSheet> {
  String _motivo = ReporteMotivos.labels.keys.first;
  final _detalleController = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(reporteRepositoryProvider).crear(
            ReporteInput(
              objetoTipo: widget.objetoTipo,
              objetoId: widget.objetoId,
              motivo: _motivo,
              detalle: _detalleController.text.trim(),
            ),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al enviar reporte.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reportar contenido',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (widget.titulo != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.titulo!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _motivo,
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: ReporteMotivos.labels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: _enviando ? null : (v) => setState(() => _motivo = v ?? _motivo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleController,
              maxLines: 4,
              enabled: !_enviando,
              decoration: const InputDecoration(
                labelText: 'Detalle (opcional)',
                hintText: 'Describe el problema…',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enviando ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _enviando ? null : _enviar,
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enviar reporte'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
