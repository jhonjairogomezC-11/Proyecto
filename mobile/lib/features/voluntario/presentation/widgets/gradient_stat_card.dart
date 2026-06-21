import 'package:flutter/material.dart';

enum StatCardVariant { blue, purple, green, orange }

class GradientStatCard extends StatelessWidget {
  const GradientStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.variant = StatCardVariant.blue,
    this.onTap,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final StatCardVariant variant;
  final VoidCallback? onTap;

  (Color, Color) get _gradient {
    switch (variant) {
      case StatCardVariant.purple:
        return (const Color(0xFF8B5CF6), const Color(0xFF6366F1));
      case StatCardVariant.green:
        return (const Color(0xFF10B981), const Color(0xFF059669));
      case StatCardVariant.orange:
        return (const Color(0xFFF59E0B), const Color(0xFFEA580C));
      case StatCardVariant.blue:
        return (const Color(0xFF3B82F6), const Color(0xFF6366F1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _gradient;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: start.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
