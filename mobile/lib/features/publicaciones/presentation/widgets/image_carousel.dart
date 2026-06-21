import 'package:flutter/material.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/core/utils/media_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageCarousel extends ConsumerStatefulWidget {
  const ImageCarousel({
    super.key,
    required this.urls,
    this.height = 180,
  });

  final List<String> urls;
  final double height;

  @override
  ConsumerState<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends ConsumerState<ImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final apiBase = ref.watch(appConfigProvider).apiBaseUrl;
    final resolved = widget.urls
        .map((u) => resolveMediaUrl(u, apiBase))
        .where((u) => u.isNotEmpty)
        .toList();

    if (resolved.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 48, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              itemCount: resolved.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Image.network(
                resolved[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.background,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
        ),
        if (resolved.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              resolved.length,
              (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      i == _index ? AppColors.primary : const Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
