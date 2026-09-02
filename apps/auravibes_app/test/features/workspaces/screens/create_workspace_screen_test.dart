import 'dart:ui';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/services/app_logging.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(AppLogging.resetForTesting);

  testWidgets('logs unexpected create failures without sensitive details', (
    tester,
  ) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    final previousFlutterError = FlutterError.onError;
    final previousPlatformError = PlatformDispatcher.instance.onError;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };

    try {
      AppLogging.configure(enabled: true);
      final container = ProviderContainer(
        overrides: [
          cloudAccountsProvider.overrideWith((ref) async => const []),
          workspaceRepositoryProvider.overrideWithValue(
            _ThrowingWorkspaceRepository(
              StateError('Authorization: Bearer secret-token'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildForm(container: container),
      );
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Project');
      await tester.tap(find.byKey(const Key('intro_create_workspace_button')));
      final _ = await tester.pumpAndSettle();

      final output = logs.join('\n');
      expect(output, contains('[WARNING] create_workspace_screen'));
      expect(output, contains('Create workspace failed'));
      expect(output, isNot(contains('secret-token')));
      expect(output, contains('Error: StateError'));
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    } finally {
      AppLogging.resetForTesting();
      debugPrint = previousDebugPrint;
      FlutterError.onError = previousFlutterError;
      PlatformDispatcher.instance.onError = previousPlatformError;
    }
  });
}

Widget _buildForm({required ProviderContainer container}) {
  return EasyLocalization(
    child: Builder(
      builder: (context) {
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AuraScreen(
              child: CreateWorkspaceForm(
                onCreated: (_) => fail('Unexpected workspace created.'),
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
  );
}

class _ThrowingWorkspaceRepository implements WorkspaceRepository {
  const _ThrowingWorkspaceRepository(this.error);

  final StateError error;

  @override
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    throw error;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
