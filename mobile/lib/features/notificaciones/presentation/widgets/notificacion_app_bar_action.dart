import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/providers/notificaciones_badge_provider.dart';

class NotificacionAppBarAction extends ConsumerWidget {
  const NotificacionAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificacionesBadgeProvider);

    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () => context.push(AppRoutes.notificaciones),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
