import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
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
              builder: (context, child) => AuraSnackBarHost(
                child: child ?? const SizedBox.shrink(),
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
    final workspaceRepository = WorkspaceRepository(database);
    final workspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final skillsRepository = SkillsRepository(database);
    final skill = await skillsRepository.createSkill(
      workspace.id,
      const SkillToCreate(
        kind: SkillKind.template,
        title: 'Write Summary',
        description: 'Summarize selected content.',
        content: 'Summarize selected content.',
      ),
    );
    final appSkillSettings = AppSkillWorkspaceSettingsRepository(database);
    await appSkillSettings.setAppSkillEnabled(
      workspace.id,
      'skills_manager',
      isEnabled: false,
    );
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        workspaceSessionProvider(session).overrideWithValue(session),
        cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
        cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
        skillsRepositoryProvider.overrideWithValue(skillsRepository),
        appSkillWorkspaceSettingsRepositoryProvider.overrideWithValue(
          appSkillSettings,
        ),
        workspaceSkillsProvider(workspace.id).overrideWith(
          (_) async => [
            WorkspaceSkill(
              source: SkillSource.user,
              id: skill.id,
              slug: skill.slug,
              title: skill.title,
              description: skill.description,
              kind: skill.kind,
              isEnabled: skill.isEnabled,
            ),
          ],
        ),
        deleteSkillProvider(workspace.id).overrideWithValue(
          skillsRepository.deleteSkill,
        ),
      ],
    );
    addTearDown(container.dispose);

    return (
      database: database,
      container: container,
      workspace: workspace,
      skill: skill,
    );
  }

  GoRouter createRouter() {
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
    final router = createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      buildRouterScreen(fixture.container, router),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    expect(find.text('Workspace Skills'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Write Summary'), 200);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Write Summary'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Template'), findsOneWidget);
    expect(find.byType(AuraSwitch), findsWidgets);

    await tester.tap(find.text('Write Summary'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Editing ${fixture.skill.id}'), findsOneWidget);

    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Write Summary'), 200);
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Editing ${fixture.skill.id}'), findsOneWidget);

    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Write Summary'), 200);
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Delete skill'), findsOneWidget);
    expect(
      find.text(
        'Delete this skill? This also removes its conversation load state and '
        'template tools.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AuraButton, 'Delete'));
    final _ = await tester.pumpAndSettle();

    expect(
      await SkillsRepository(fixture.database).getSkillById(fixture.skill.id),
      null,
    );
  });
}
