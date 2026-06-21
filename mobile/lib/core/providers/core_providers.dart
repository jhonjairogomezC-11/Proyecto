import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voluntapp_mobile/core/config/app_config.dart';
import 'package:voluntapp_mobile/core/network/auth_interceptor.dart';
import 'package:voluntapp_mobile/core/network/refresh_interceptor.dart';
import 'package:voluntapp_mobile/core/storage/secure_token_storage.dart';
import 'package:voluntapp_mobile/core/storage/session_storage.dart';
import 'package:voluntapp_mobile/features/auth/presentation/providers/auth_notifier.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final sessionStorageProvider = FutureProvider<SessionStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SessionStorage(prefs);
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  final authNotifier = ref.read(authNotifierProvider.notifier);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final refreshInterceptor = RefreshInterceptor(
    dio: dio,
    tokenStorage: tokenStorage,
    onSessionExpired: () => authNotifier.clearSession(),
  );

  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage),
    refreshInterceptor,
    if (kDebugMode)
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ),
  ]);

  return dio;
});
