import 'package:flutter/material.dart';

IconData iconForNotificacionTipo(String tipo) {
  switch (tipo) {
    case 'NUEVA_POSTULACION':
      return Icons.inbox_outlined;
    case 'POSTULACION_RETIRADA':
      return Icons.undo_outlined;
    case 'VOLUNTARIO_ASISTIO':
    case 'POSTULACION_ACEPTADA':
    case 'FUNDACION_APROBADA':
      return Icons.check_circle_outline;
    case 'VOLUNTARIO_NO_ASISTIO':
    case 'POSTULACION_RECHAZADA':
    case 'FUNDACION_RECHAZADA':
      return Icons.cancel_outlined;
    case 'ACTIVIDAD_CANCELADA':
      return Icons.block_outlined;
    case 'ACTIVIDAD_MODIFICADA':
      return Icons.edit_outlined;
    case 'FUNDACION_SUSPENDIDA':
      return Icons.warning_amber_outlined;
    case 'FUNDACION_REACTIVADA':
      return Icons.refresh;
    case 'RECORDATORIO_ACTIVIDAD':
      return Icons.alarm_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

String formatRelativeNotificacion(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final diff = DateTime.now().difference(date);
  final mins = diff.inMinutes;
  if (mins < 1) return 'Ahora mismo';
  if (mins < 60) return 'Hace $mins min';
  final hours = diff.inHours;
  if (hours < 24) return 'Hace ${hours}h';
  final days = diff.inDays;
  if (days < 7) return 'Hace $days días';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
