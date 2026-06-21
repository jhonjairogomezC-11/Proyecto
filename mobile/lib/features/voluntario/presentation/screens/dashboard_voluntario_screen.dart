import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/dashboard_voluntario.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/postulacion_resumen.dart';
import 'package:voluntapp_mobile/features/voluntario/data/repositories/voluntario_repository.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/utils/dashboard_formatters.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/dashboard_progress_bar.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/gradient_stat_card.dart';
import 'package:voluntapp_mobile/features/voluntario/presentation/widgets/postulacion_status_pill.dart';

/// Screen 05A — Dashboard Voluntario
class DashboardVoluntarioScreen extends ConsumerWidget {
  const DashboardVoluntarioScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(voluntarioPerfilProvider);
    ref.invalidate(dashboardVoluntarioProvider);
    await ref.read(dashboardVoluntarioProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(voluntarioPerfilProvider);
    final dashboardAsync = ref.watch(dashboardVoluntarioProvider);
    final user = ref.watch(authNotifierProvider).usuario;
    final firstName = user?.nombre.split(' ').first ?? 'Voluntario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: perfilAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error al cargar: $e'),
              ),
            ],
          ),
          data: (perfil) {
            if (perfil == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroBanner(
                    firstName: firstName,
                    nivelNombre: 'Bronce',
                    nivelColor: '#cd7f32',
                    puntos: 0,
                    onExplore: () => context.go(AppRoutes.voluntarioActividades),
                  ),
                  const SizedBox(height: 16),
                  _PerfilIncompletoBanner(
                    onComplete: () => context.go(AppRoutes.voluntarioPerfil),
                  ),
                ],
              );
            }

            return dashboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error al cargar dashboard: $e'),
                  ),
                ],
              ),
              data: (data) {
                if (data == null) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PerfilIncompletoBanner(
                        onComplete: () => context.go(AppRoutes.voluntarioPerfil),
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeroBanner(
                      firstName: firstName,
                      nivelNombre: data.nivel.nivelActual.nombre,
                      nivelColor: data.nivel.nivelActual.color,
                      puntos: data.puntos.totalHistorico,
                      onExplore: () => context.go(AppRoutes.voluntarioActividades),
                    ),
                    const SizedBox(height: 20),
                    _StatsGrid(data: data),
                    const SizedBox(height: 16),
                    _PostulacionesPills(resumen: data.postulacionesResumen),
                    const SizedBox(height: 16),
                    _ProximasActividadesPanel(
                      actividades: data.proximasActividades,
                      onVerTodas: () => context.go(AppRoutes.voluntarioPostulaciones),
                      onExplorar: () => context.go(AppRoutes.voluntarioActividades),
                    ),
                    const SizedBox(height: 16),
                    _ProgresoPanel(data: data),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.firstName,
    required this.nivelNombre,
    required this.nivelColor,
    required this.puntos,
    required this.onExplore,
  });

  final String firstName;
  final String nivelNombre;
  final String nivelColor;
  final int puntos;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $firstName',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Estás haciendo una diferencia increíble',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aquí está tu resumen de impacto y próximos compromisos.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: onExplore,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Explorar actividades'),
              ),
              const Spacer(),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorFromHex(nivelColor),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      nivelNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$puntos pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerfilIncompletoBanner extends StatelessWidget {
  const _PerfilIncompletoBanner({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completa tu perfil de voluntario para postularte a convocatorias.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onComplete, child: const Text('Completar perfil')),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final DashboardVoluntario data;

  @override
  Widget build(BuildContext context) {
    final nivelSig = data.nivel.nivelSiguiente?.nombre;
    final ptsFaltan = data.nivel.puntosFaltan;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GradientStatCard(
                value: '${data.actividadesCompletadas.total}',
                label: 'Actividades completadas',
                subtitle:
                    '+${data.actividadesCompletadas.esteMes} este mes · ${data.actividadesCompletadas.estaSemana} esta semana',
                icon: Icons.check_circle_outline,
                variant: StatCardVariant.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GradientStatCard(
                value: '${data.puntos.totalHistorico}',
                label: 'Puntos acumulados',
                subtitle: ptsFaltan > 0 && nivelSig != null
                    ? '$ptsFaltan pts para $nivelSig'
                    : 'Nivel máximo alcanzado',
                icon: Icons.star_outline,
                variant: StatCardVariant.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GradientStatCard(
                value: '${data.logros.desbloqueados}',
                label: 'Logros desbloqueados',
                subtitle: data.logroProximo != null
                    ? 'Próximo: ${data.logroProximo!.nombre}'
                    : '¡Todos desbloqueados!',
                icon: Icons.emoji_events_outlined,
                variant: StatCardVariant.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GradientStatCard(
                value: data.ranking.posicion != null ? '#${data.ranking.posicion}' : '—',
                label: 'Posición en ranking',
                subtitle: data.ranking.topPercent != null
                    ? 'Top ${data.ranking.topPercent}%'
                    : 'Sin ranking aún',
                icon: Icons.leaderboard_outlined,
                variant: StatCardVariant.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PostulacionesPills extends StatelessWidget {
  const _PostulacionesPills({required this.resumen});

  final PostulacionesResumen resumen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        PostulacionStatusPill(
          count: resumen.pendientes,
          label: 'Pendientes',
          color: AppColors.warning,
        ),
        PostulacionStatusPill(
          count: resumen.aceptadas,
          label: 'Aprobadas',
          color: AppColors.success,
        ),
        PostulacionStatusPill(
          count: resumen.rechazadas,
          label: 'Rechazadas',
          color: AppColors.danger,
        ),
      ],
    );
  }
}

class _ProximasActividadesPanel extends StatelessWidget {
  const _ProximasActividadesPanel({
    required this.actividades,
    required this.onVerTodas,
    required this.onExplorar,
  });

  final List<PostulacionResumen> actividades;
  final VoidCallback onVerTodas;
  final VoidCallback onExplorar;

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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Próximas actividades', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(
                        'Tus compromisos confirmados y pendientes',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onVerTodas, child: const Text('Ver todas')),
              ],
            ),
            const SizedBox(height: 12),
            if (actividades.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text('No tienes actividades próximas.'),
                    TextButton(onPressed: onExplorar, child: const Text('Explora convocatorias')),
                  ],
                ),
              )
            else
              ...actividades.map((p) {
                final pub = p.publicacion;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pub?.titulo ?? 'Actividad',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (pub?.fundacionNombre != null)
                              Text(
                                pub!.fundacionNombre!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            Text(
                              formatShortDate(pub?.fechaInicio),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      EstadoPostulacionBadge(estado: p.estado),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProgresoPanel extends StatelessWidget {
  const _ProgresoPanel({required this.data});

  final DashboardVoluntario data;

  @override
  Widget build(BuildContext context) {
    final nivel = data.nivel;
    final mensual = data.progresoMensual;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu progreso', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const Text(
              'Camino al siguiente nivel y logros',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            DashboardProgressBar(
              label: 'Nivel: ${nivel.nivelActual.nombre}',
              progressText: '${data.puntos.totalHistorico} / ${nivel.umbralSiguiente ?? '∞'} pts',
              percentage: nivel.porcentaje,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
              hint: nivel.puntosFaltan > 0 && nivel.nivelSiguiente != null
                  ? 'Te faltan ${nivel.puntosFaltan} puntos para ${nivel.nivelSiguiente!.nombre}'
                  : null,
            ),
            const SizedBox(height: 20),
            DashboardProgressBar(
              label: 'Participación este mes',
              progressText: '${mensual.completadas} / ${mensual.meta}',
              percentage: mensual.porcentaje,
              gradientColors: const [Color(0xFF3B82F6), AppColors.primary],
              hint: mensual.faltan > 0
                  ? '${mensual.faltan} más para cumplir tu meta mensual'
                  : null,
            ),
            if (data.logroProximo != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              DashboardProgressBar(
                label: 'Próximo logro: ${data.logroProximo!.nombre}',
                progressText: '${data.logroProximo!.progreso} / ${data.logroProximo!.umbral}',
                percentage: data.logroProximo!.porcentaje,
                gradientColors: const [Color(0xFF10B981), AppColors.success],
              ),
            ],
            if (data.logros.recientes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'ÚLTIMOS LOGROS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...data.logros.recientes.map(
                (l) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.emoji_events, color: AppColors.primary, size: 18),
                  ),
                  title: Text(l.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(formatRelativeDate(l.fechaObtencion)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
