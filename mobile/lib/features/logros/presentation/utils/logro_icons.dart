import 'package:flutter/material.dart';

IconData iconForLogroCodigo(String codigo) {
  switch (codigo) {
    case 'PRIMER_PASO':
      return Icons.file_download_outlined;
    case 'COMPROMETIDO':
      return Icons.handshake_outlined;
    case 'VOLUNTARIO_ACTIVO':
      return Icons.bolt_outlined;
    case 'IMPACTO_SOCIAL':
      return Icons.shield_outlined;
    case 'LEYENDA_SOLIDARIA':
      return Icons.layers_outlined;
    case 'ACUMULADOR':
      return Icons.add_circle_outline;
    case 'VETERANO':
      return Icons.military_tech_outlined;
    case 'VALIENTE':
      return Icons.whatshot_outlined;
    case 'HEROE':
      return Icons.auto_awesome;
    case 'URGENTE':
      return Icons.access_time_filled;
    default:
      return Icons.emoji_events_outlined;
  }
}
