import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/app/bootstrap.dart';

import 'test_config.dart';

abstract final class TestApp {
  static String? _hivePath;
  static bool _launched = false;

  /// Limpia tokens de sesiones previas (`flutter run`, etc.).
  static Future<void> clearStoredSession() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
  }

  /// Directorio Hive aislado para no chocar con `flutter run` ni otros tests.
  static void useIsolatedHive(Directory directory) {
    _hivePath = directory.path;
  }

  static void resetForNextTest() {
    _launched = false;
  }

  static Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;

    if (!_launched) {
      await bootstrapVoluntApp(hivePath: _hivePath);
      _launched = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  static bool _exists(Finder finder) => finder.evaluate().isNotEmpty;

  static Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = TestTimeouts.bootstrap,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(TestTimeouts.pumpStep);
      if (_exists(finder)) return;
    }
    fail('Timeout esperando $finder');
  }

  static Future<void> ensureLoginScreen(WidgetTester tester) async {
    await launch(tester);
    await _waitForBootstrap(tester);

    if (_exists(find.text('Iniciar sesión'))) return;

    if (_exists(find.text('Inicio')) || _exists(find.text('Panel Admin'))) {
      await logout(tester);
      await pumpUntilFound(tester, find.text('Iniciar sesión'));
      return;
    }

    await pumpUntilFound(tester, find.text('Iniciar sesión'));
  }

  static Future<void> _waitForBootstrap(WidgetTester tester) async {
    final deadline = DateTime.now().add(TestTimeouts.bootstrap);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(TestTimeouts.pumpStep);
      if (_exists(find.text('Iniciar sesión'))) return;
      if (_exists(find.text('Inicio'))) return;
      if (_exists(find.text('Panel Admin'))) return;
      if (!_exists(find.byType(CircularProgressIndicator))) {
        await tester.pump(const Duration(milliseconds: 500));
        if (_exists(find.text('Iniciar sesión'))) return;
        if (_exists(find.text('Inicio'))) return;
        if (_exists(find.text('Panel Admin'))) return;
      }
    }
    fail('Timeout esperando fin del bootstrap');
  }

  static Future<void> login(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await pumpUntilFound(tester, find.text('Iniciar sesión'));

    await tester.enterText(find.byKey(const Key('login_email')), email);
    await tester.enterText(find.byKey(const Key('login_password')), password);
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
  }

  static Future<void> logout(WidgetTester tester) async {
    final logoutButton = find.byTooltip('Cerrar sesión');
    await pumpUntilFound(tester, logoutButton);
    await tester.tap(logoutButton);
    await pumpUntilFound(tester, find.text('Iniciar sesión'),
        timeout: TestTimeouts.apiAction);
  }

  static Future<void> expectLoginScreen(WidgetTester tester) async {
    await pumpUntilFound(tester, find.text('Iniciar sesión'));
    expect(find.text('Ingresar'), findsOneWidget);
  }

  static Future<void> expectVoluntarioHome(WidgetTester tester) async {
    await pumpUntilFound(tester, find.text('Inicio'),
        timeout: TestTimeouts.apiAction);
    expect(find.text('Actividades'), findsWidgets);
  }

  static Future<void> expectFundacionHome(WidgetTester tester) async {
    await pumpUntilFound(tester, find.text('Inicio'),
        timeout: TestTimeouts.apiAction);
    expect(find.text('Convocatorias'), findsWidgets);
  }

  static Future<void> expectAdminHome(WidgetTester tester) async {
    await pumpUntilFound(tester, find.text('Panel Admin'),
        timeout: TestTimeouts.apiAction);
    expect(find.text('Fundaciones'), findsWidgets);
  }

  static Future<void> tapBottomNav(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}
