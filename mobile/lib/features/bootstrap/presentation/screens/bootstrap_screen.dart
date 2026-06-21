import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_colors.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';

/// Screen S19 — Splash / bootstrap de sesión (Fase 1).
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await ref.read(sharedPreferencesProvider.future);
    await ref.read(authNotifierProvider.notifier).bootstrap();

    if (!mounted) return;

    final status = ref.read(authNotifierProvider).status;
    if (status == AuthStatus.blocked) {
      context.go(AppRoutes.blocked);
    } else if (status == AuthStatus.authenticated) {
      context.go(AppRoutes.homeForUser(ref.read(authNotifierProvider).usuario));
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤝', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              config.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ambiente: ${config.env.toUpperCase()}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
