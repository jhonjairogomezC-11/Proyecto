import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/app/router/app_router.dart';
import 'package:voluntapp_mobile/app/theme/app_theme.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';

class VoluntApp extends ConsumerWidget {
  const VoluntApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: config.isDev,
      theme: AppTheme.light,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
