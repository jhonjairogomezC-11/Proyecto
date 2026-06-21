import 'package:flutter/material.dart';

Color colorFromHex(String hex, {Color fallback = const Color(0xFF6366F1)}) {
  try {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return fallback;
  }
}

String formatShortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String formatRelativeDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final diff = DateTime.now().difference(date).inDays;
  if (diff < 1) return 'Hoy';
  if (diff == 1) return 'Ayer';
  if (diff < 7) return 'Hace $diff días';
  if (diff < 30) return 'Hace ${diff ~/ 7} semanas';
  return formatShortDate(iso);
}
