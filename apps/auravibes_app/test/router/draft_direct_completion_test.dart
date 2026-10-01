import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final action in [
    'agent-save',
    'type-save',
    'type-delete',
    'connection-save',
  ]) {
    testWidgets('$action from a direct editor persists and safely returns', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await WorkspaceRepository(database)
          .createWorkspace(const .new(name: 'Direct workspace', type: .local));
      final agents = AgentsRepository(database);
      final agent = await agents.createAgent(
        workspace.id,
        const .new(
          name: 'Saved agent',
          description: 'Saved description',
          content: 'Saved instructions',
        ),
      );
      final definitions = SkillCredentialDefinitionsRepository(database);
      final definition = await definitions.createDefinition(
        workspace.id,
        const .new(
          title: 'Saved type',
          attributesJson: '{"key":{"description":"Key"}}',
        ),
      );
      final connection = await database
          .into(database.serviceConnections)
          .insertReturning(
            ServiceConnectionsCompanion(
              name: const .new('Saved connection'),
              serviceId: const .new('custom'),
              kind: const .new(ServiceConnectionKindTable.appSkillCredential),
              authenticationType: const .new(
                ServiceAuthenticationTypeTable.none,
              ),
              workspaceId: .new(workspace.id),
            ),
          );
      final route = switch (action) {
        'agent-save' => AgentDetailRoute(
          workspaceId: workspace.id,
          agentId: agent.id,
        ),
        'connection-save' => ServiceConnectionEditRoute(
          workspaceId: workspace.id,
          connectionId: connection.id,
        ),
        _ => SkillCredentialDefinitionEditRoute(
          workspaceId: workspace.id,
          definitionId: definition.id,
        ),
      };
      final destination = switch (action) {
        'agent-save' => AgentsRoute(workspaceId: workspace.id).location,
        'connection-save' => ServiceConnectionsRoute(
          workspaceId: workspace.id,
        ).location,
        _ => SkillCredentialDefinitionsRoute(
          workspaceId: workspace.id,
        ).location,
      };
      final router = GoRouter(
        routes: [
          GoRoute(path: '/direct', builder: route.build, onExit: route.onExit),
          GoRoute(
            path: destination,
            builder: (_, _) => const Text('Saved destination'),
          ),
        ],
        initialLocation: '/direct',
      );
      addTearDown(router.dispose);
      final session = WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: workspace.id),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          workspaceSessionProvider(session).overrideWithValue(session),
          workspaceSessionForRouteProvider(workspace.id)
              .overrideWith((_) async => session),
          cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
          cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      final sessionSubscription = container.listen(
        workspaceSessionForRouteProvider(workspace.id),
        (_, next) => expect(next.hasError, isFalse),
      );
      addTearDown(sessionSubscription.close);
      final _ = await container.read(
        workspaceSessionForRouteProvider(workspace.id).future,
      );
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
      await tester.enterText(
        find.descendant(
          of: find.byType(AuraInput).first,
          matching: find.byType(EditableText),
        ),
        'Saved revision',
      );
      if (action == 'type-delete') {
        await tester.tap(find.byTooltip('Delete credential type'));
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Delete').last);
      } else if (action == 'type-save') {
        await tester.tap(find.byIcon(Icons.save_outlined));
      } else {
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
      }
      final _ = await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Saved destination'), findsOneWidget);
      expect(router.state.uri.path, destination);
      expect(find.text('Keep editing'), findsNothing);
      switch (action) {
        case 'agent-save':
          final saved = await agents.getAgentById(agent.id);
          expect(saved?.name, 'Saved revision');
          expect(saved?.content, 'Saved instructions');
        case 'connection-save':
          final query = database.select(database.serviceConnections)
            ..where((table) => table.id.equals(connection.id));
          final saved = await query.getSingle();
          expect(saved.name, 'Saved revision');
          expect(saved.encryptedAuthValue, connection.encryptedAuthValue);
        case 'type-save':
          final saved = await definitions.getDefinitionById(definition.id);
          expect(saved?.title, 'Saved revision');
          expect(
            (jsonDecode(saved?.attributesJson ?? '{}') as Map)['key'],
            containsPair('description', 'Key'),
          );
        case 'type-delete':
          expect(await definitions.getDefinitionById(definition.id), isNull);
      }
    });
  }
}
