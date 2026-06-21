import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/widgets/notificacion_app_bar_action.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/models/postulacion.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/repositories/postulacion_repository.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/postulacion_status_pill.dart';

/// Screen 08 — Mis Postulaciones
class MisPostulacionesScreen extends ConsumerStatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  ConsumerState<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends ConsumerState<MisPostulacionesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    ('all', 'Todas'),
    ('PENDIENTE', 'Pendientes'),
    ('ACEPTADO', 'Aceptadas'),
    ('RECHAZADO', 'Rechazadas'),
    ('ASISTIO', 'Completadas'),
  ];

  List<Postulacion> _items = [];
  PaginationMeta? _meta;
  bool _loading = true;
  String? _error;
  String? _retirandoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(postulacionRepositoryProvider).fetchMisPostulaciones(page: page);
      if (!mounted) return;
      setState(() {
        _items = result.data;
        _meta = result.meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar postulaciones.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Postulacion> _filtered(String tab) {
    if (tab == 'all') return _items;
    return _items.where((p) => p.estado == tab).toList();
  }

  int _count(String tab) {
    if (tab == 'all') return _items.length;
    return _items.where((p) => p.estado == tab).length;
  }

  Future<void> _retirar(Postulacion p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar postulación'),
        content: const Text('¿Confirmas que deseas retirar esta postulación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _retirandoId = p.id);
    try {
      final updated = await ref.read(postulacionRepositoryProvider).retirar(p.id);
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((x) => x.id == p.id);
        if (idx != -1) _items[idx] = updated;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al retirar la postulación.')),
        );
      }
    } finally {
      if (mounted) setState(() => _retirandoId = null);
    }
  }

  void _showDetalle(Postulacion p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.publicacion?.titulo ?? 'Postulación',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (p.publicacion?.fundacionNombre != null) ...[
                  const SizedBox(height: 4),
                  Text(p.publicacion!.fundacionNombre!, style: const TextStyle(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),
                EstadoPostulacionBadge(estado: p.estado),
                const SizedBox(height: 12),
                Text('Postulación: ${formatShortDate(p.fechaPostulacion)}'),
                if (p.fechaRespuesta != null) Text('Respuesta: ${formatShortDate(p.fechaRespuesta)}'),
                if (p.calificacion != null) Text('Calificación: ${p.calificacion}/5'),
                if (p.mensajeVoluntario != null && p.mensajeVoluntario!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Tu mensaje', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(p.mensajeVoluntario!),
                ],
                if (p.motivoRechazo != null && p.motivoRechazo!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Motivo de rechazo: ${p.motivoRechazo}', style: const TextStyle(color: AppColors.danger)),
                ],
                if (p.comentarioFundacion != null && p.comentarioFundacion!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Comentario fundación: ${p.comentarioFundacion}'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Postulaciones'),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final tab in _tabs)
              Tab(
                text: tab.$1 == 'all'
                    ? tab.$2
                    : '${tab.$2} (${_count(tab.$1)})',
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    for (final tab in _tabs) _buildList(tab.$1),
                  ],
                ),
    );
  }

  Widget _buildList(String tab) {
    final list = _filtered(tab);

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(tab == 'all'
                  ? 'Aún no te has postulado a ninguna convocatoria.'
                  : 'No tienes postulaciones en este estado.'),
              if (tab == 'all') ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.voluntarioActividades),
                  child: const Text('Buscar convocatorias'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: _meta?.currentPage ?? 1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final p = list[index];
          final pub = p.publicacion;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => _showDetalle(p),
              title: Text(pub?.titulo ?? 'Convocatoria', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pub?.fundacionNombre != null) Text(pub!.fundacionNombre!),
                  Text('Postulado: ${formatShortDate(p.fechaPostulacion)}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EstadoPostulacionBadge(estado: p.estado),
                  if (p.puedeRetirar) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _retirandoId == p.id ? null : () => _retirar(p),
                      child: _retirandoId == p.id
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Retirar', style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
