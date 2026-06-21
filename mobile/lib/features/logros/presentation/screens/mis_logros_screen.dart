import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/features/logros/data/models/logros_models.dart';
import 'package:voluntapp_mobile/features/logros/data/repositories/gamificacion_repository.dart';
import 'package:voluntapp_mobile/features/logros/presentation/utils/logro_icons.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';

/// Screen 10 — Logros y Puntos
class MisLogrosScreen extends ConsumerStatefulWidget {
  const MisLogrosScreen({super.key});

  @override
  ConsumerState<MisLogrosScreen> createState() => _MisLogrosScreenState();
}

class _MisLogrosScreenState extends ConsumerState<MisLogrosScreen> {
  PuntosDetalle? _puntos;
  LogrosDetalle? _logros;
  bool _loading = true;
  String? _error;

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
      final repo = ref.read(gamificacionRepositoryProvider);
      final results = await Future.wait([repo.fetchPuntos(), repo.fetchLogros()]);
      if (!mounted) return;
      setState(() {
        _puntos = results[0] as PuntosDetalle;
        _logros = results[1] as LogrosDetalle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Error al cargar logros.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Logros y Puntos')),
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
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PuntosBanner(puntos: _puntos!),
                      const SizedBox(height: 20),
                      _LogrosObtenidosSection(logros: _logros!.obtenidos),
                      const SizedBox(height: 20),
                      _LogrosPendientesSection(pendientes: _logros!.pendientes),
                      if (_puntos!.transacciones.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _TransaccionesSection(transacciones: _puntos!.transacciones),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _PuntosBanner extends StatelessWidget {
  const _PuntosBanner({required this.puntos});

  final PuntosDetalle puntos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Text(
                      '${puntos.saldo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Puntos disponibles',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${puntos.totalHistorico}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Total histórico',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogrosObtenidosSection extends StatelessWidget {
  const _LogrosObtenidosSection({required this.logros});

  final List<LogroObtenidoDetalle> logros;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Logros obtenidos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${logros.length}'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  labelStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logros.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Participa en convocatorias para desbloquear tus primeros logros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: logros.length,
                itemBuilder: (context, index) {
                  final logro = logros[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconForLogroCodigo(logro.codigo), color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          logro.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (logro.descripcion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            logro.descripcion!,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          formatShortDate(logro.fechaObtencion),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LogrosPendientesSection extends StatelessWidget {
  const _LogrosPendientesSection({required this.pendientes});

  final List<LogroPendiente> pendientes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('En progreso', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${pendientes.length}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendientes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '¡Has desbloqueado todos los logros disponibles!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...pendientes.map(
                (logro) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(iconForLogroCodigo(logro.codigo), color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    logro.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '${logro.progreso}/${logro.umbral}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (logro.descripcion != null)
                              Text(
                                logro.descripcion!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: logro.porcentaje / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${logro.porcentaje}% completado',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransaccionesSection extends StatelessWidget {
  const _TransaccionesSection({required this.transacciones});

  final List<TransaccionPuntos> transacciones;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Últimas ganancias de puntos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...transacciones.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                  child: const Icon(Icons.star, color: AppColors.warning, size: 18),
                ),
                title: Text('+${t.puntosTotal} pts', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(t.motivo ?? ''),
                trailing: Text(
                  formatShortDate(t.fecha),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
