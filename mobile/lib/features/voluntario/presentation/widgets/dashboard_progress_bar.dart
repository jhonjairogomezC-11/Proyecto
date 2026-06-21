import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';

class DashboardProgressBar extends StatelessWidget {
  const DashboardProgressBar({
    super.key,
    required this.label,
    required this.progressText,
    required this.percentage,
    required this.gradientColors,
    this.hint,
  });

  final String label;
  final String progressText;
  final int percentage;
  final List<Color> gradientColors;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(progressText, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(gradientColors.last),
          ),
        ),
        if (hint != null && hint!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}
