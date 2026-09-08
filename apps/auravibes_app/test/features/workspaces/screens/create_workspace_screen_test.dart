import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_provider_scope.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('logs unexpected create failures through the logger', (
    tester,
  ) async {
    final repository = _MockWorkspaceRepository();
    when(
      () => repository.createWorkspace(
        const WorkspaceToCreate(name: 'Project', type: WorkspaceType.local),
      ),
    ).thenThrow(StateError('token=workspace-secret'));

    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    final previousLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    addTearDown(() => Logger.root.level = previousLevel);

    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) {
            return TestProviderScope(
              overrides: [
                cloudAccountsProvider.overrideWith((ref) async => const []),
                workspaceRepositoryProvider.overrideWithValue(repository),
              ],
              child: MaterialApp(
                home: AuraScreen(
                  child: CreateWorkspaceForm(
                    onCreated: (workspace) => expect(workspace.id, isNotEmpty),
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

    await tester.enterText(find.byType(TextField), 'Project');
    await tester.tap(find.byKey(const Key('intro_create_workspace_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final record = records.firstWhere(
      (record) => record.message == 'Create workspace failed',
    );
    expect(record.error, StateError);
    expect(record.error.toString(), isNot(contains('workspace-secret')));
    expect(record.stackTrace, isNotNull);
    expect(
      find.text('An unexpected error occurred. Please try again.'),
      findsOneWidget,
    );
  });
}

class _MockWorkspaceRepository extends Mock implements WorkspaceRepository;
