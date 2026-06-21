import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/app/app.dart';

void main() {
  testWidgets('VoluntApp arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VoluntApp()));
    await tester.pump();

    expect(find.byType(VoluntApp), findsOneWidget);
  });
}
