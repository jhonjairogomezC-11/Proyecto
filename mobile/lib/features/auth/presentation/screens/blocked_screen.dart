import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';

/// Screen S20 — Cuenta bloqueada / suspendida
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(authNotifierProvider).blockedMessage ??
        'No tienes acceso a esta aplicación.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: AppColors.danger, size: 72),
              const SizedBox(height: 24),
              const Text(
                'Acceso restringido',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).clearBlocked();
                  context.go(AppRoutes.login);
                },
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
