import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
              builder: (context, child) =>
                  AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
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
      List<SkillEntity> skills,
      Set<String> failedDeleteIds,
      List<String> deleteAttempts,
    })
  >
  createFixture({
    bool includeAppSkill = false,
    String skillTitle = 'Write Summary',
    List<String> additionalUserSkillNames = const [],
    bool failDeletes = false,
  }) async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspaceRepository = WorkspaceRepository(database);
    final workspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final skillsRepository = SkillsRepository(database);
    final skill = await skillsRepository.createSkill(
      workspace.id,
      .new(
        kind: .template,
        title: skillTitle,
        description: 'Summarize selected content.',
        content: 'Summarize selected content.',
      ),
    );
    final userSkills = [skill];
    for (final title in additionalUserSkillNames) {
      userSkills.add(
        await skillsRepository.createSkill(
          workspace.id,
          .new(
            kind: .template,
            title: title,
            description: 'Test skill.',
            content: 'Test skill.',
          ),
        ),
      );
    }
    final failedDeleteIds = <String>{};
    final deleteAttempts = <String>[];
    Future<void> deleteSkill(String id) async {
      deleteAttempts.add(id);
      if (failDeletes || failedDeleteIds.contains(id)) {
        throw StateError('delete failed');
      }
      final _ = await skillsRepository.deleteSkill(id);
    }

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
        workspaceSkillsProvider.overrideWith(
          (_, _) async => [
            for (final userSkill in userSkills)
              WorkspaceSkill(
                source: SkillSource.user,
                id: userSkill.id,
                slug: userSkill.slug,
                title: userSkill.title,
                description: userSkill.description,
                kind: userSkill.kind,
                isEnabled: userSkill.isEnabled,
              ),
            if (includeAppSkill)
              const WorkspaceSkill(
                source: SkillSource.app,
                id: 'app-skill',
                slug: 'native_helper',
                title: 'Native Helper',
                description: 'Built-in helper skill.',
                kind: .native,
                isEnabled: false,
              ),
          ],
        ),
        deleteSkillProvider(workspace.id).overrideWithValue(deleteSkill),
      ],
    );
    addTearDown(container.dispose);

    return (
      database: database,
      container: container,
      workspace: workspace,
      skill: skill,
      skills: userSkills,
      failedDeleteIds: failedDeleteIds,
      deleteAttempts: deleteAttempts,
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
          builder: (context, state) =>
              SkillsScreen(workspaceId: state.pathParameters['workspaceId']!),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId',
          builder: (context, state) =>
              Text('Editing ${state.pathParameters['skillId']}'),
        ),
      ],
      initialLocation: '/',
    );
  }

  testWidgets('restores visible search after leaving the skills list', (
    tester,
  ) async {
    final fixture = await createFixture(
      additionalUserSkillNames: ['Translate'],
    );
    final router = createRouter();
    addTearDown(router.dispose);
    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Summary');
    final _ = await tester.pumpAndSettle();
    expect(find.text('Translate'), findsNothing);
    await tester.tap(find.text('Write Summary'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Editing ${fixture.skill.id}'), findsOneWidget);
    router.pop(true);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Summary',
    );
    expect(find.text('Translate'), findsNothing);
    router.go('/');
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Summary',
    );
    expect(find.text('Translate'), findsNothing);
    router.go('/workspaces/B/more/skills');
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '',
    );
    await tester.enterText(find.byType(EditableText), 'Translate');
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Summary',
    );
    expect(find.text('Translate'), findsNothing);
  });

  testWidgets('renders and manages user skills from the list', (tester) async {
    final fixture = await createFixture(includeAppSkill: true);
    final router = createRouter();
    addTearDown(router.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    expect(find.text('Workspace Skills'), findsOneWidget);
    await tester.ensureVisible(find.text('Write Summary'));
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
    await tester.ensureVisible(find.text('Write Summary'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Editing ${fixture.skill.id}'), findsOneWidget);

    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Write Summary'));
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

    final search = find.byType(EditableText);
    await tester.enterText(search, 'summary');
    final _ = await tester.pump();
    expect(find.text('Write Summary'), findsOneWidget);
    expect(find.text('Native Helper'), findsNothing);

    await tester.enterText(search, 'helper native');
    final _ = await tester.pump();
    expect(find.text('Native Helper'), findsOneWidget);
    expect(find.text('Write Summary'), findsNothing);

    await tester.enterText(search, 'summry');
    final _ = await tester.pump();
    expect(find.text('Write Summary'), findsOneWidget);
    expect(find.text('Native Helper'), findsNothing);

    await tester.enterText(search, 'native_helper');
    final _ = await tester.pump();
    expect(find.text('Native Helper'), findsOneWidget);
    expect(find.text('Write Summary'), findsNothing);

    await tester.enterText(search, 'app');
    final _ = await tester.pump();
    expect(find.text('Native Helper'), findsOneWidget);
    expect(find.text('Write Summary'), findsNothing);

    await tester.enterText(search, 'native');
    final _ = await tester.pump();
    expect(find.text('Native Helper'), findsOneWidget);
    expect(find.text('Write Summary'), findsNothing);

    await tester.enterText(search, '');
    final _ = await tester.pump();
    await tester.tap(find.byKey(const ValueKey('skills-source-filter')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('App').first);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Native Helper'), findsOneWidget);
    expect(find.text('Write Summary'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('skills-status-filter')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Disabled').last);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Native Helper'), findsOneWidget);
    expect(find.text('Write Summary'), findsNothing);

    await tester.enterText(search, 'missing');
    final _ = await tester.pump();
    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('No skills match these filters'), findsOneWidget);
    expect(find.text('Native Helper'), findsNothing);
  });

  testWidgets('sorts skills by localized name and enabled status', (
    tester,
  ) async {
    final fixture = await createFixture(includeAppSkill: true);
    final router = createRouter();
    addTearDown(router.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Native Helper')).dy,
      lessThan(tester.getTopLeft(find.text('Write Summary')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('skills-sort')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Enabled first').last);
    final _ = await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Write Summary')).dy,
      lessThan(tester.getTopLeft(find.text('Native Helper')).dy),
    );
  });

  testWidgets('aligns select-all with the sort field', (tester) async {
    final fixture = await createFixture();
    final router = createRouter();
    addTearDown(router.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('skills-select-all'))).bottom,
      tester.getRect(find.byKey(const ValueKey('skills-sort'))).bottom,
    );
  });

  testWidgets('selects filtered user skills and confirms bulk deletion', (
    tester,
  ) async {
    final fixture = await createFixture(includeAppSkill: true);
    final router = createRouter();
    addTearDown(router.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    final search = find.byType(EditableText);
    await tester.enterText(search, 'summary');
    final _ = await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(search).focusNode.hasFocus, isTrue);
    await tester.tap(find.byKey(const ValueKey('skills-select-all')));
    final _ = await tester.pumpAndSettle();

    expect(
      tester
          .widget<AuraCheckbox>(
            find.byKey(ValueKey('skill-selection-${fixture.skill.id}')),
          )
          .value,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('skill-selection-app-skill')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('skills-delete-selected')));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Delete selected skills?'), findsOneWidget);
    await tester.tap(find.widgetWithText(AuraButton, 'Cancel'));
    final _ = await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(search).focusNode.hasFocus, isFalse);
    expect(
      await SkillsRepository(fixture.database).getSkillById(fixture.skill.id),
      isA<SkillEntity>(),
    );

    await tester.tap(find.byKey(const ValueKey('skills-delete-selected')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AuraButton, 'Delete'));
    final _ = await tester.pumpAndSettle();

    expect(
      await SkillsRepository(fixture.database).getSkillById(fixture.skill.id),
      null,
    );
  });

  testWidgets('shows hidden skill selections in row and confirmation', (
    tester,
  ) async {
    final fixture = await createFixture(
      additionalUserSkillNames: ['Write Draft'],
    );
    final router = createRouter();
    addTearDown(router.dispose);
    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('skills-select-all')));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'summary');
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('2 selected'), findsOneWidget);
    expect(find.textContaining('1 hidden by filters'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('skills-delete-selected')));
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('2 selected'), findsWidgets);
    expect(find.textContaining('1 hidden by filters'), findsWidgets);
    await tester.tap(find.widgetWithText(AuraButton, 'Cancel'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton && widget.tooltip == 'Clear selection',
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('skills-delete-selected')), findsNothing);
    await tester.enterText(find.byType(EditableText), '');
    final _ = await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('skills-delete-selected')), findsNothing);
  });

  testWidgets('shows and retries only failed skill deletions', (tester) async {
    final fixture = await createFixture(
      skillTitle: 'Fail One',
      additionalUserSkillNames: ['Fail Two', 'Fail Three', 'Success Skill'],
    );
    final [failedOne, failedTwo, failedThree, success] = fixture.skills;
    fixture.failedDeleteIds.addAll([
      failedOne.id,
      failedTwo.id,
      failedThree.id,
    ]);
    final router = createRouter();
    addTearDown(router.dispose);
    final _ = await tester.runAsync(
      () => tester.pumpWidget(buildRouterScreen(fixture.container, router)),
    );
    final _ = await tester.pumpAndSettle();
    router.go('/workspaces/${fixture.workspace.id}/more/skills');
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('skills-select-all')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skills-delete-selected')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AuraButton, 'Delete'));
    final _ = await tester.pumpAndSettle();

    final failureDialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: failureDialog,
        matching: find.text('Some items could not be deleted'),
      ),
      findsOneWidget,
    );
    expect(find.text('Retry failed'), findsOneWidget);
    for (final name in ['Fail One', 'Fail Two', 'Fail Three']) {
      expect(
        find.descendant(of: failureDialog, matching: find.text(name)),
        findsOneWidget,
      );
    }
    expect(fixture.deleteAttempts.toSet(), {
      failedOne.id,
      failedTwo.id,
      failedThree.id,
      success.id,
    });

    final beforeFirstRetry = fixture.deleteAttempts.length;
    fixture.failedDeleteIds
      ..clear()
      ..add(failedTwo.id);
    await tester.tap(find.text('Retry failed'));
    final _ = await tester.pumpAndSettle();
    expect(fixture.deleteAttempts.skip(beforeFirstRetry).toSet(), {
      failedOne.id,
      failedTwo.id,
      failedThree.id,
    });
    expect(
      find.descendant(of: failureDialog, matching: find.text('Fail Two')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: failureDialog, matching: find.text('Fail One')),
      findsNothing,
    );
    expect(
      find.descendant(of: failureDialog, matching: find.text('Fail Three')),
      findsNothing,
    );

    fixture.failedDeleteIds.clear();
    final beforeSecondRetry = fixture.deleteAttempts.length;
    await tester.tap(find.text('Retry failed'));
    final _ = await tester.pumpAndSettle();
    expect(fixture.deleteAttempts.skip(beforeSecondRetry).toList(), [
      failedTwo.id,
    ]);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
