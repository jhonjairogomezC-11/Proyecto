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
  ConsumerState<MisPostulacionesScreen> createState() =>
      _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends ConsumerState<MisPostulacionesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    ('all', 'Todas'),
    ('PENDIENTE', 'Pendientes'),
    ('ACEPTADO', 'Aceptadas'),
    ('RECHAZADO', 'Rechazadas'),
    ('ASISTIO', 'Asistí'),
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
      final result = await ref
          .read(postulacionRepositoryProvider)
          .fetchMisPostulaciones(page: page);
      if (!mounted) return;
      setState(() {
        _items = result.data;
        _meta = result.meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          e is ApiException ? e.message : 'Error al cargar postulaciones.');
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Retirar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _retirandoId = p.id);
    try {
      final updated =
          await ref.read(postulacionRepositoryProvider).retirar(p.id);
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((x) => x.id == p.id);
        if (idx != -1) _items[idx] = updated;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E3E0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.publicacion?.titulo ?? 'Postulación',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (p.publicacion?.fundacionNombre != null) ...[
                    const SizedBox(height: 4),
                    Text(p.publicacion!.fundacionNombre!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 14),
                  EstadoPostulacionBadge(estado: p.estado),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE3E3E0), height: 1),
                  const SizedBox(height: 16),
                  _detalleRow(Icons.calendar_today_outlined,
                      'Postulación', formatShortDate(p.fechaPostulacion)),
                  if (p.fechaRespuesta != null)
                    _detalleRow(Icons.check_circle_outline,
                        'Respuesta', formatShortDate(p.fechaRespuesta)),
                  if (p.calificacion != null)
                    _detalleRow(Icons.star_outline,
                        'Calificación', '${p.calificacion}/5'),
                  if (p.mensajeVoluntario != null &&
                      p.mensajeVoluntario!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Tu mensaje',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(p.mensajeVoluntario!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                  if (p.motivoRechazo != null && p.motivoRechazo!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Motivo de rechazo',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.danger)),
                    const SizedBox(height: 4),
                    Text(p.motivoRechazo!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ],
                  if (p.comentarioFundacion != null &&
                      p.comentarioFundacion!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Comentario de la fundación',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(p.comentarioFundacion!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detalleRow(IconData icon, String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
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
                text:
                    tab.$1 == 'all' ? tab.$2 : '${tab.$2} (${_count(tab.$1)})',
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
              const Icon(Icons.inbox_outlined,
                  size: 48, color: AppColors.textSecondary),
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
          final accentColor = switch (p.estado) {
            'PENDIENTE' => AppColors.warning,
            'ACEPTADO' => AppColors.success,
            'RECHAZADO' => AppColors.danger,
            'ASISTIO' => AppColors.primary,
            _ => AppColors.textSecondary,
          };

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE3E3E0)),
            ),
            child: InkWell(
              onTap: () => _showDetalle(p),
              borderRadius: BorderRadius.circular(8),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Borde izquierdo de color según estado
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pub?.titulo ?? 'Convocatoria',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  if (pub?.fundacionNombre != null)
                                    Text(
                                      pub!.fundacionNombre!,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Postulado: ${formatShortDate(p.fechaPostulacion)}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                EstadoPostulacionBadge(estado: p.estado),
                                if (p.puedeRetirar) ...[
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: _retirandoId == p.id
                                        ? null
                                        : () => _retirar(p),
                                    child: _retirandoId == p.id
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 1.5),
                                          )
                                        : const Text('Retirar',
                                            style: TextStyle(
                                                color: AppColors.danger,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
