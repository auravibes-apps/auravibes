import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_provider_scope.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('confirms before discarding dirty create form', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) {
            return TestProviderScope(
              overrides: [
                cloudAccountsProvider.overrideWith(
                  (ref) async => const [
                    CloudAccountSession(
                      serverUrl: 'http://localhost:8080',
                      userId: 'account-1',
                      email: 'dev@example.com',
                    ),
                  ],
                ),
              ],
              child: MaterialApp(
                home: Builder(
                  builder: (context) => AuraButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const CreateWorkspaceScreen(workspaceId: 'ws-1'),
                      ),
                    ),
                    child: const Text('Open create'),
                  ),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            );
          },
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
    final _ = await tester.pumpAndSettle();

    final _ = await tester.tap(find.text('Open create'));
    final _ = await tester.pumpAndSettle();

    final _ = await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.text('Create New Workspace'), findsNothing);

    final _ = await tester.tap(find.text('Open create'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Workspace Draft');
    await tester.pump();

    final _ = await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);

    final _ = await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Workspace Draft'), findsOneWidget);

    final _ = await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.text('Discard'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.text('Create New Workspace'), findsNothing);

    final _ = await tester.tap(find.text('Open create'));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.text('Local workspace'));
    final _ = await tester.pump();
    final _ = await tester.tap(find.text('dev@example.com'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Workspace Draft');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    final _ = await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
  });
}
