// Required: Tests use numeric fixtures.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/database/drift/database_test_utils.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);

  for (final completion in ['primary', 'keyboard', 'configure']) {
    final configure = completion == 'configure';
    testWidgets('creating a skill continues according to $completion', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final workspace = await WorkspaceRepository(database).createWorkspace(
        const WorkspaceToCreate(name: 'Test Workspace', type: .local),
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
        ],
      );
      addTearDown(container.dispose);
      final _ = await SkillCredentialDefinitionsRepository(database)
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Example Service',
              attributesJson: '{"api_key":{"description":"API key"}}',
            ),
          );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/more/skills/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SkillCreateRoute(
                workspaceId: state.pathParameters['workspaceId']!,
              ).build(context, state),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/skills/:skillId/resources/new',
            pageBuilder: (_, state) => NoTransitionPage(
              child: SkillResourceEditScreen(
                workspaceId: state.pathParameters['workspaceId']!,
                skillId: state.pathParameters['skillId']!,
              ),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/skills/:skillId',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SkillDetailRoute(
                workspaceId: state.pathParameters['workspaceId']!,
                skillId: state.pathParameters['skillId']!,
              ).build(context, state),
              key: state.pageKey,
            ),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/skills',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SkillsScreen(
                workspaceId: state.pathParameters['workspaceId']!,
              ),
              key: state.pageKey,
            ),
          ),
        ],
        initialLocation: '/workspaces/${workspace.id}/more/skills',
      );
      addTearDown(router.dispose);

      final _ = await tester.runAsync(
        () => tester.pumpWidget(
          EasyLocalization(
            child: Builder(
              builder: (context) {
                return UncontrolledProviderScope(
                  container: container,
                  child: MaterialApp.router(
                    routerConfig: router,
                    builder: (_, child) => AuraLegacyMaterialBridge(
                      child: AuraSnackBarHost(
                        child: child ?? const SizedBox.shrink(),
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
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      final _ = await tester.pumpAndSettle();
      final _ = await tester.pump();
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(AuraInput).at(0), 'Write Summary');
      await tester.tap(find.text('Edit description'));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'a' * 1025);
      final _ = await tester.pumpAndSettle();
      expect(find.text('1025/1024'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.save_outlined).last);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Edit skill description'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        '# Summary\n\n**Bold**',
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('19/1024'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.save_outlined).last);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Edit content'));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'Summarize text.',
      );
      await tester.tap(find.byIcon(Icons.save_outlined).last);
      final _ = await tester.pumpAndSettle();
      expect(
        await SkillsRepository(database).getWorkspaceSkills(workspace.id),
        isEmpty,
      );
      if (configure) {
        await tester.enterText(find.byType(AuraInput).first, 'Invalid!');
        await tester.ensureVisible(find.text('Create and configure'));
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Create and configure'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Unable to save skill'), findsOneWidget);
        expect(
          router.state.uri.path,
          '/workspaces/${workspace.id}/more/skills/new',
        );
        expect(
          await SkillsRepository(database).getWorkspaceSkills(workspace.id),
          isEmpty,
        );
        await tester.enterText(find.byType(AuraInput).first, 'Write Summary');
        await tester.ensureVisible(find.text('Create and configure'));
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Create and configure'));
      } else if (completion == 'keyboard') {
        await tester.tap(find.byType(AuraInput).first);
        await tester.testTextInput.receiveAction(.done);
      } else {
        await tester.tap(find.byIcon(Icons.save_outlined));
      }
      final _ = await tester.pumpAndSettle();

      if (!configure) expect(find.text('Unable to save skill'), findsNothing);
      final skill = await SkillsRepository(database)
          .getSkillByTitle(workspace.id, 'Write Summary');
      final _ = skill ?? fail('skill missing');
      expect(skill.description, '# Summary\n\n**Bold**');
      expect(skill.content, 'Summarize text.');
      expect(skill.credentialDefinitionId, null);
      final savedSkills = await SkillsRepository(database)
          .getWorkspaceSkills(workspace.id);
      expect(savedSkills, hasLength(1));
      expect(
        router.state.uri.path,
        configure
            ? '/workspaces/${workspace.id}/more/skills/${skill.id}'
            : '/workspaces/${workspace.id}/more/skills',
      );
      if (configure) {
        await tester.enterText(
          find.byType(AuraInput).first,
          'Unsaved parent name',
        );
        await tester.scrollUntilVisible(
          find.byTooltip('New skill resource'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('New skill resource'));
        final _ = await tester.pumpAndSettle();
        expect(find.byType(SkillResourceEditScreen), findsOneWidget);
        expect(
          router.state.uri.path,
          '/workspaces/${workspace.id}/more/skills/${skill.id}/resources/new',
        );
        await tester.enterText(find.byType(AuraInput).first, 'Reference');
        await tester.tap(find.text('Edit content'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Edit resource content'), findsOneWidget);
        expect(
          find.text('Applies to this draft. Save the resource to finish.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(EditableText).last,
          'Exact resource content',
        );
        await tester.tap(find.byTooltip('Apply changes'));
        final _ = await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save resource'));
        await tester.tap(find.text('Save resource'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Resource changes saved'), findsOneWidget);
        expect(find.text('Reference'), findsOneWidget);
        expect(
          tester
              .widget<AuraInput>(find.byType(AuraInput).first)
              .controller
              ?.text,
          'Unsaved parent name',
        );
        expect(
          (await SkillsRepository(database).getSkillById(skill.id))?.title,
          'Write Summary',
        );
      } else {
        expect(find.text('Workspace Skills'), findsOneWidget);
      }
    });
  }
}
