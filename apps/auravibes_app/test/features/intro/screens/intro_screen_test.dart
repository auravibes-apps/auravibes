import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
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

  testWidgets('creates workspace and skips AI setup to new chat', (
    tester,
  ) async {
    final fixture = _IntroFixture();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.buildApp());
    await _pumpUntilFound(tester, find.byKey(_continueKey));

    expect(find.text('Welcome to AuraVibes'), findsOneWidget);

    await tester.tap(find.byKey(_continueKey));
    await _pumpUntilFound(tester, find.byKey(_continueKey));
    await tester.tap(find.byKey(_continueKey));
    await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(
      tester,
      find.text('Workspace name must be at least 3 characters'),
    );

    await tester.enterText(find.byType(TextField), 'a' * 21);
    await tester.tap(find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(
      tester,
      find.text('Workspace name must be at most 20 characters'),
    );

    await tester.enterText(find.byType(TextField), 'Project');
    await tester.tap(find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(tester, find.text('Ready to start'));

    final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
    expect(workspaces.single.name, 'Project');

    await tester.tap(find.byKey(_skipAiKey));
    await _pumpUntilFound(tester, find.textContaining('new chat:'));
  });
}

const _continueKey = Key('intro_continue_button');
const _createWorkspaceKey = Key('intro_create_workspace_button');
const _skipAiKey = Key('intro_skip_ai_button');

Future<void> _pumpFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await _pumpFrame(tester);
    if (finder.evaluate().isNotEmpty) return;
  }

  expect(finder, findsOneWidget);
}

class _IntroFixture {
  _IntroFixture()
    : this._(
        AppDatabase(connection: NativeDatabase.memory()),
      );

  _IntroFixture._(this.database)
    : container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      ),
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/intro',
            builder: (context, state) => const IntroScreen(),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/chat/new',
            builder: (context, state) {
              return Text('new chat: ${state.pathParameters['workspaceId']}');
            },
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/service-connections/new',
            builder: (context, state) {
              return Text(
                'service connection: ${state.uri.queryParameters['type']}',
              );
            },
          ),
        ],
        initialLocation: '/intro',
      );

  final AppDatabase database;
  final ProviderContainer container;
  final GoRouter router;

  Widget buildApp() {
    return EasyLocalization(
      key: UniqueKey(),
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
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

  Future<void> dispose() async {
    router.dispose();
    container.dispose();
    await database.close();
  }
}
