import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart'
    show CloudAccountHealth;
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_health_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  const account = (serverUrl: 'https://example.test', accountId: 'account');

  for (final scenario in [
    (locale: const Locale('en'), label: 'Access verified:', month: 'Sep'),
    (locale: const Locale('es'), label: 'Acceso verificado:', month: 'sept'),
  ]) {
    testWidgets('formats access verification in ${scenario.locale}', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: const Scaffold(
              body: CloudAccountHealthStatus(
                account: account,
                workspaceId: 'local',
                returnPath: '/workspaces/local',
              ),
            ),
            overrides: [
              cloudAccountHealthProvider.overrideWith(
                (ref, key) async => CloudAccountHealth(
                  status: .verified,
                  checkedAt: .new(2026, 9, 30, 13, 5),
                ),
              ),
            ],
            startLocale: scenario.locale,
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      final label = tester.widget<Text>(find.textContaining(scenario.label));
      expect(label.data, contains(scenario.month));
      expect(label.data, isNot(contains('.000')));
      expect(label.data, isNot(contains('2026-09-30')));
    });
  }

  testWidgets('verified access without a timestamp has a complete label', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const Scaffold(
            body: CloudAccountHealthStatus(
              account: account,
              workspaceId: 'local',
              returnPath: '/workspaces/local',
            ),
          ),
          overrides: [
            cloudAccountHealthProvider.overrideWith(
              (ref, key) async => const CloudAccountHealth(status: .verified),
            ),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Access verified'), findsOneWidget);
  });
}
