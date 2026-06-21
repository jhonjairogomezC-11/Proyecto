import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/fundacion/data/repositories/fundacion_publicacion_repository.dart';
import 'package:voluntapp_mobile/features/fundacion/presentation/widgets/estado_badge.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

/// Screen 13 — Mis Convocatorias (lista)
class MisConvocatoriasFundacionScreen extends ConsumerStatefulWidget {
  const MisConvocatoriasFundacionScreen({super.key});

  @override
  ConsumerState<MisConvocatoriasFundacionScreen> createState() => _MisConvocatoriasFundacionScreenState();
}

class _MisConvocatoriasFundacionScreenState extends ConsumerState<MisConvocatoriasFundacionScreen> {
  List<Publicacion> _items = [];
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
      final result = await ref.read(fundacionPublicacionRepositoryProvider).fetchMisPublicaciones();
      if (!mounted) return;
      setState(() => _items = result.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar convocatorias.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publicar(Publicacion pub) async {
    setState(() => _actionId = pub.id);
    try {
      await ref.read(fundacionPublicacionRepositoryProvider).publicar(pub.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convocatoria enviada a revisión.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Error al publicar.')),
      );
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  Future<void> _cancelar(Publicacion pub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar convocatoria'),
        content: Text('¿Cancelar "${pub.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _actionId = pub.id);
    try {
      await ref.read(fundacionPublicacionRepositoryProvider).cancelar(pub.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Error al cancelar.')),
      );
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  Future<void> _openForm([Publicacion? pub]) async {
    final changed = await context.push<bool>(
      AppRoutes.fundacionConvocatoriaForm,
      extra: pub,
    );
    if (changed == true) _load();
  }

  void _openPostulantes(Publicacion pub) {
    context.push(AppRoutes.fundacionPostulantesPath(pub.id), extra: pub.titulo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Convocatorias'),
        actions: const [NotificacionAppBarAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
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
                          children: const [
                            Icon(Icons.campaign_outlined, size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text(
                              'Sin convocatorias',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Crea tu primera convocatoria para recibir voluntarios.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final pub = _items[index];
                            final busy = _actionId == pub.id;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pub.titulo,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (pub.categoriaNombre != null)
                                                Text(
                                                  pub.categoriaNombre!,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (pub.estado != null)
                                          EstadoBadge(estado: pub.estado!),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('${pub.modalidad} · Cupos: ${pub.cupoMaximo ?? '—'}'),
                                    Text(
                                      '${formatShortDate(pub.fechaInicio)} — ${formatShortDate(pub.fechaFin)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton(
                                          onPressed: busy ? null : () => _openPostulantes(pub),
                                          child: const Text('Postulantes'),
                                        ),
                                        OutlinedButton(
                                          onPressed: busy ? null : () => _openForm(pub),
                                          child: const Text('Editar'),
                                        ),
                                        if (pub.estado == 'BORRADOR')
                                          FilledButton(
                                            onPressed: busy ? null : () => _publicar(pub),
                                            child: busy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Text('Enviar a revisión'),
                                          ),
                                        if (pub.estado != null &&
                                            !['CANCELADA', 'FINALIZADA', 'PENDIENTE_APROBACION']
                                                .contains(pub.estado))
                                          TextButton(
                                            onPressed: busy ? null : () => _cancelar(pub),
                                            child: const Text(
                                              'Cancelar',
                                              style: TextStyle(color: AppColors.danger),
                                            ),
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
    );
  }
}
