import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';

class PostulacionStatusPill extends StatelessWidget {
  const PostulacionStatusPill({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class EstadoPostulacionBadge extends StatelessWidget {
  const EstadoPostulacionBadge({super.key, required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      'PENDIENTE' => ('Pendiente', AppColors.warning),
      'ACEPTADO' => ('Aceptada', AppColors.success),
      'RECHAZADO' => ('Rechazada', AppColors.danger),
      'RETIRADO' => ('Retirado', AppColors.textSecondary),
      'ASISTIO' => ('Asistió', AppColors.primary),
      _ => (estado, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
