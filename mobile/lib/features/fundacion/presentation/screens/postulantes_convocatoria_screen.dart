import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/models/postulacion.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/repositories/postulacion_repository.dart';

/// Screen 13.2 — Postulantes de una convocatoria
class PostulantesConvocatoriaScreen extends ConsumerStatefulWidget {
  const PostulantesConvocatoriaScreen({
    super.key,
    required this.publicacionId,
    required this.titulo,
  });

  final String publicacionId;
  final String titulo;

  @override
  ConsumerState<PostulantesConvocatoriaScreen> createState() => _PostulantesConvocatoriaScreenState();
}

class _PostulantesConvocatoriaScreenState extends ConsumerState<PostulantesConvocatoriaScreen> {
  List<Postulacion> _items = [];
  bool _loading = true;
  String? _error;
  String? _actionId;

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
      final result = await ref.read(postulacionRepositoryProvider).fetchPostulantesDePublicacion(
            publicacionId: widget.publicacionId,
          );
      if (!mounted) return;
      setState(() => _items = result.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar postulantes.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _responder(Postulacion p, String estado, {String? motivo}) async {
    setState(() => _actionId = p.id);
    try {
      await ref.read(postulacionRepositoryProvider).responder(
            postulacionId: p.id,
            estado: estado,
            motivoRechazo: motivo,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Error al responder.')),
      );
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  Future<void> _rechazar(Postulacion p) async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Explica el motivo…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (motivo == null || motivo.isEmpty) return;
    await _responder(p, 'RECHAZADO', motivo: motivo);
  }

  Future<void> _confirmarAsistencia(Postulacion p, bool asistio) async {
    if (!asistio) {
      await _responderAsistencia(p, asistio: false);
      return;
    }

    var calificacion = 5;
    final comentarioController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Calificar voluntario'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      onPressed: () => setDialogState(() => calificacion = i + 1),
                      icon: Icon(
                        i < calificacion ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: comentarioController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
            ],
          );
        },
      ),
    );
    final comentario = comentarioController.text.trim();
    comentarioController.dispose();
    if (ok != true) return;
    await _responderAsistencia(
      p,
      asistio: true,
      calificacion: calificacion,
      comentario: comentario.isEmpty ? null : comentario,
    );
  }

  Future<void> _responderAsistencia(
    Postulacion p, {
    required bool asistio,
    int? calificacion,
    String? comentario,
  }) async {
    setState(() => _actionId = p.id);
    try {
      await ref.read(postulacionRepositoryProvider).confirmarAsistencia(
            postulacionId: p.id,
            asistio: asistio,
            calificacion: calificacion,
            comentarioFundacion: comentario,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Error al confirmar asistencia.')),
      );
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Postulantes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              widget.titulo,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aún no hay voluntarios postulados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Text(
                                widget.titulo,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              );
                            }
                            final p = _items[index - 1];
                            final nombre = p.voluntario?.nombreUsuario ?? 'Voluntario';
                            final email = p.voluntario?.emailUsuario ?? '';
                            final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
                            final busy = _actionId == p.id;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(child: Text(initial)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                        EstadoBadge(estado: p.estado, tipo: 'postulacion'),
                                      ],
                                    ),
                                    if (p.mensajeVoluntario != null && p.mensajeVoluntario!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('“${p.mensajeVoluntario}”', style: const TextStyle(fontSize: 12)),
                                    ],
                                    if (p.estado == 'PENDIENTE') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          FilledButton(
                                            onPressed: busy ? null : () => _responder(p, 'ACEPTADO'),
                                            child: const Text('Aceptar'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: busy ? null : () => _rechazar(p),
                                            child: const Text('Rechazar'),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (p.estado == 'ACEPTADO') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          FilledButton(
                                            onPressed: busy ? null : () => _confirmarAsistencia(p, true),
                                            child: const Text('Asistió'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: busy ? null : () => _confirmarAsistencia(p, false),
                                            child: const Text('No asistió'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
