import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_resources_provider.dart';
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

void main() {
  for (final editor in [
    'skill',
    'resource',
    'agent',
    'type',
    'connection',
    'workspace',
  ]) {
    testWidgets('$editor replacement retains draft on cancel', (tester) async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await WorkspaceRepository(database).createWorkspace(
        const WorkspaceToCreate(name: 'Draft test', type: .local),
      );
      final skill = await SkillsRepository(database).createSkill(
        workspace.id,
        const SkillToCreate(
          kind: .template,
          title: 'Parent',
          description: 'Parent description',
          content: 'Persisted instructions',
        ),
      );
      final definition = await SkillCredentialDefinitionsRepository(database)
          .createDefinition(
            workspace.id,
            const SkillCredentialDefinitionToCreate(
              title: 'Test type',
              attributesJson: '{"apiKey":{"description":"API key"}}',
            ),
          );
      final session = WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: workspace.id),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          cloudAccountsProvider.overrideWith((_) async => const []),
          workspaceSessionProvider(session).overrideWithValue(session),
          cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
          cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
          skillDetailProvider(
            workspace.id,
            skill.id,
          ).overrideWith((_) async => SkillDetail.fromUserSkill(skill)),
        ],
      );
      addTearDown(container.dispose);
      final route = switch (editor) {
        'resource' => SkillResourceCreateRoute(
          workspaceId: workspace.id,
          skillId: skill.id,
        ),
        'agent' => AgentCreateRoute(workspaceId: workspace.id),
        'type' => SkillCredentialDefinitionCreateRoute(
          workspaceId: workspace.id,
        ),
        'connection' => ServiceConnectionCreateRoute(
          workspaceId: workspace.id,
          type: 'skillCredential',
          credentialDefinitionId: definition.id,
        ),
        'workspace' => WorkspaceCreateRoute(workspaceId: workspace.id),
        _ => SkillCreateRoute(workspaceId: workspace.id),
      };
      final keepLabel = editor == 'skill' ? 'Continue' : 'Keep editing';
      final discardLabel = ['skill', 'agent', 'workspace'].contains(editor)
          ? 'Discard'
          : 'Discard changes';
      final router = GoRouter(
        routes: [
          GoRoute(path: '/draft', builder: route.build, onExit: route.onExit),
          GoRoute(
            path: '/workspaces/:workspaceId/more/agents',
            builder: (_, _) => const Text('Workspace agents destination'),
          ),
          GoRoute(
            path: '/destination',
            builder: (_, _) => const Text('Destination'),
          ),
        ],
        initialLocation: '/draft',
      );
      addTearDown(router.dispose);
      final _ = await tester.runAsync(
        () => tester.pumpWidget(
          EasyLocalization(
            child: Builder(
              builder: (context) => UncontrolledProviderScope(
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
              ),
            ),
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            startLocale: const Locale('en'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final field = find.byType(AuraInput).first;
      await tester.enterText(field, 'Exact unsaved draft');
      if (editor == 'skill') {
        FocusManager.instance.primaryFocus?.unfocus();
        final _ = await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Open workspace agents'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Open workspace agents'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Workspace agents destination'), findsOneWidget);
        expect(find.text(keepLabel), findsNothing);
        router.pop();
        final _ = await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(AuraInput).first,
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Exact unsaved draft'), findsOneWidget);
      }
      router.go('/destination');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Destination'), findsNothing);
      expect(find.text(keepLabel), findsOneWidget);
      await tester.tap(find.text(keepLabel));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Exact unsaved draft'), findsOneWidget);
      expect(
        (await SkillsRepository(database).getSkillById(skill.id))?.content,
        'Persisted instructions',
      );
      expect(
        await container.read(
          skillResourcesProvider(workspace.id, skill.id).future,
        ),
        isEmpty,
      );
      router.go('/destination');
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text(discardLabel));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
    });
  }
}
