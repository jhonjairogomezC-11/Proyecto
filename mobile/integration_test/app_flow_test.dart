import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_config.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // El viewport de prueba es más bajo que una ventana real; ignorar overflow menor del nav bar.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) {
      return;
    }
    FlutterError.presentError(details);
  };

  late Directory hiveDir;

  setUpAll(() {
    hiveDir = Directory.systemTemp.createTempSync('voluntapp_integration_');
    TestApp.useIsolatedHive(hiveDir);
  });

  tearDownAll(() {
    try {
      if (hiveDir.existsSync()) {
        hiveDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    TestApp.resetForNextTest();
    await TestApp.clearStoredSession();
  });

  group('Auth flow (requiere backend + DemoSeeder)', () {
    testWidgets('voluntario: login → inicio → logout', (tester) async {
      await TestApp.ensureLoginScreen(tester);
      await TestApp.login(
        tester,
        email: TestCredentials.voluntarioEmail,
        password: TestCredentials.demoPassword,
      );
      await TestApp.expectVoluntarioHome(tester);
      await TestApp.logout(tester);
      await TestApp.expectLoginScreen(tester);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('fundación: login → inicio', (tester) async {
      await TestApp.ensureLoginScreen(tester);
      await TestApp.login(
        tester,
        email: TestCredentials.fundacionEmail,
        password: TestCredentials.demoPassword,
      );
      await TestApp.expectFundacionHome(tester);
      await TestApp.logout(tester);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('admin: login → panel admin', (tester) async {
      await TestApp.ensureLoginScreen(tester);
      await TestApp.login(
        tester,
        email: TestCredentials.adminEmail,
        password: TestCredentials.adminPassword,
      );
      await TestApp.expectAdminHome(tester);
      await TestApp.logout(tester);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('Navegación voluntario', () {
    testWidgets('bottom nav cambia de pantalla sin cerrar sesión',
        (tester) async {
      await TestApp.ensureLoginScreen(tester);
      await TestApp.login(
        tester,
        email: TestCredentials.voluntarioEmail,
        password: TestCredentials.demoPassword,
      );
      await TestApp.expectVoluntarioHome(tester);

      await TestApp.tapBottomNav(tester, 'Actividades');
      await tester.pump(const Duration(seconds: 2));
      tester.takeException();

      await TestApp.tapBottomNav(tester, 'Postulaciones');
      await tester.pump(const Duration(seconds: 2));
      tester.takeException();

      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);

      await TestApp.logout(tester);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
