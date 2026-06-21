import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';

class TagMultiSelect extends StatelessWidget {
  const TagMultiSelect({
    super.key,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<({int id, String nombre})> options;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option.nombre),
            selected: selectedIds.contains(option.id),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            onSelected: (selected) {
              final next = List<int>.from(selectedIds);
              if (selected) {
                next.add(option.id);
              } else {
                next.remove(option.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
