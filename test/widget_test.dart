import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swiftsave/main.dart';
import 'package:swiftsave/services/settings_service.dart';

void main() {
  testWidgets('MyApp renders injected home with required providers', (
    WidgetTester tester,
  ) async {
    const marker = 'test-home-marker';
    const testHome = Scaffold(body: Center(child: Text(marker)));

    ServiceInitializationState.initializationError = null;

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsService>.value(
        value: SettingsService.instance,
        child: const MyApp(home: testHome),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(marker), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
