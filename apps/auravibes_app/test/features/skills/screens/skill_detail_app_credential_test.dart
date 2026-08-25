import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart'
    show appSkillRegistryProvider;
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Expected finder to appear: $finder');
  }

  testWidgets(
    'refreshes an app-skill credential after creation without error',
    (tester) async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          workspaceSessionForRouteProvider('workspace-1').overrideWith(
            (_) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
            ),
          ),
          cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
          cloudSkillStoreProvider('workspace-1').overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      final searxng = container
          .read(appSkillRegistryProvider)
          .getByIdentifier('searxng');
      if (searxng == null) fail('SearXNG must be registered for this test.');

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/skills/:id',
            builder: (_, _) => SkillDetailScreen(
              workspaceId: 'workspace-1',
              skillId: searxng.identifier,
            ),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/service-connections/new',
            builder: (context, _) => Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.pop(true);
                });

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
        initialLocation: '/skills/searxng',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        EasyLocalization(
          key: UniqueKey(),
          child: Builder(
            builder: (context) => UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            ),
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
      final _ = await tester.pump();
      final _ = await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.byType(Scrollable));
      final addCredential = find.text('Add Credential');
      await tester.scrollUntilVisible(
        addCredential,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(addCredential);
      final _ = await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
