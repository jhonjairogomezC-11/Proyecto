import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';

class EstadoBadge extends StatelessWidget {
  const EstadoBadge(
      {super.key, required this.estado, this.tipo = 'publicacion'});

  final String estado;
  final String tipo;

  (String, Color, Color) get _style {
    if (tipo == 'fundacion') {
      return switch (estado) {
        'APROBADA' => ('Aprobada', AppColors.success, AppColors.success),
        'PENDIENTE' => ('Pendiente', AppColors.warning, AppColors.warning),
        'RECHAZADA' => ('Rechazada', AppColors.danger, AppColors.danger),
        'SUSPENDIDA' => ('Suspendida', AppColors.danger, AppColors.danger),
        _ => (estado, AppColors.textSecondary, AppColors.textSecondary),
      };
    }

    if (tipo == 'reporte') {
      return switch (estado) {
        'PENDIENTE' => ('Pendiente', AppColors.warning, AppColors.warning),
        'EN_REVISION' => ('En revisión', AppColors.primary, AppColors.primary),
        'RESUELTO' => ('Resuelto', AppColors.success, AppColors.success),
        'DESESTIMADO' => (
            'Desestimado',
            AppColors.textSecondary,
            AppColors.textSecondary
          ),
        _ => (estado, AppColors.textSecondary, AppColors.textSecondary),
      };
    }

    if (tipo == 'usuario') {
      return switch (estado) {
        'ACTIVO' => ('Activo', AppColors.success, AppColors.success),
        'SUSPENDIDO' => ('Suspendido', AppColors.warning, AppColors.warning),
        'BLOQUEADO' => ('Bloqueado', AppColors.danger, AppColors.danger),
        'PENDIENTE' => ('Pendiente', AppColors.warning, AppColors.warning),
        _ => (estado, AppColors.textSecondary, AppColors.textSecondary),
      };
    }

    if (tipo == 'postulacion') {
      return switch (estado) {
        'PENDIENTE' => ('Pendiente', AppColors.warning, AppColors.warning),
        'ACEPTADO' => ('Aceptado', AppColors.success, AppColors.success),
        'RECHAZADO' => ('Rechazado', AppColors.danger, AppColors.danger),
        'RETIRADO' => (
            'Retirado',
            AppColors.textSecondary,
            AppColors.textSecondary
          ),
        'ASISTIO' => ('Asistió', AppColors.primary, AppColors.primary),
        'NO_ASISTIO' => (
            'No asistió',
            AppColors.textSecondary,
            AppColors.textSecondary
          ),
        _ => (estado, AppColors.textSecondary, AppColors.textSecondary),
      };
    }

    return switch (estado) {
      'BORRADOR' => (
          'Borrador',
          AppColors.textSecondary,
          AppColors.textSecondary
        ),
      'PENDIENTE_APROBACION' => (
          'En revisión',
          AppColors.warning,
          AppColors.warning
        ),
      'PUBLICADA' => ('Publicada', AppColors.success, AppColors.success),
      'CANCELADA' => ('Cancelada', AppColors.danger, AppColors.danger),
      'FINALIZADA' => ('Finalizada', AppColors.primary, AppColors.primary),
      _ => (estado, AppColors.textSecondary, AppColors.textSecondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, _) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
