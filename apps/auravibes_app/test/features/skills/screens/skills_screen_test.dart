// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skills_repository_impl.dart';
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildRouterScreen(ProviderContainer container, GoRouter router) {
    return EasyLocalization(
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

  Future<
    ({
      AppDatabase database,
      ProviderContainer container,
      WorkspaceEntity workspace,
      SkillEntity skill,
    })
  >
  createFixture() async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final workspaceRepository = WorkspaceRepositoryImpl(database);
    final workspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final skillsRepository = SkillsRepositoryImpl(database);
    final skill = await skillsRepository.createSkill(
      workspace.id,
      const SkillToCreate(
        kind: SkillKind.template,
        title: 'Write Summary',
        description: 'Summarize selected content.',
        content: 'Summarize selected content.',
      ),
    );
    final appSkillSettings = AppSkillWorkspaceSettingsRepositoryImpl(database);
    await appSkillSettings.setAppSkillEnabled(
      workspace.id,
      'skills_manager',
      isEnabled: false,
    );

    return (
      database: database,
      container: container,
      workspace: workspace,
      skill: skill,
    );
  }

  GoRouter createRouter(String workspaceId) {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills',
          builder: (context, state) => SkillsScreen(
            workspaceId: state.pathParameters['workspaceId']!,
          ),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId',
          builder: (context, state) => Text(
            'Editing ${state.pathParameters['skillId']}',
          ),
        ),
      ],
      initialLocation: '/',
    );
  }

  testWidgets('renders and manages user skills from the list', (
    tester,
  ) async {
    final fixture = await createFixture();
    final router = createRouter(fixture.workspace.id);
    addTearDown(router.dispose);

    await tester.pumpWidget(buildRouterScreen(fixture.container, router));
    await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    await tester.pumpAndSettle();

    expect(find.text('Workspace Skills'), findsOneWidget);
    expect(find.text('Write Summary'), findsOneWidget);
    expect(find.text('Skills Manager'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Template'), findsOneWidget);
    expect(find.text('Native'), findsOneWidget);
    expect(find.byType(AuraSwitch), findsNWidgets(2));

    await tester.tap(find.text('Write Summary'));
    await tester.pumpAndSettle();

    expect(find.text('Editing ${fixture.skill.id}'), findsOneWidget);

    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Editing ${fixture.skill.id}'), findsOneWidget);

    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete skill'), findsOneWidget);
    expect(
      find.text(
        'Delete this skill? This also removes its conversation load state and '
        'template tools.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AuraButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Write Summary'), findsNothing);
  });
}
