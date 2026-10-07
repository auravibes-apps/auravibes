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
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/drift/database_test_utils.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      final _ = await rootBundle.loadString('assets/i18n/en.json');
      final _ = await rootBundle.loadString('assets/i18n/es.json');
    });
  });
  for (final action in ['agent', 'type', 'connection']) {
    final testName =
        '$action identity replacement keeps A on cancel '
        'and saves only B after discard';
    testWidgets(testName, (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      final second = await agents.createAgent(
        workspace.id,
        const .new(
          name: 'Second agent',
          description: 'Second description',
          content: 'Second instructions',
        ),
      );
      final definitions = SkillCredentialDefinitionsRepository(database);
      final definition = await definitions.createDefinition(
        workspace.id,
        const .new(
          title: 'Saved type',
          attributesJson: '{"key":{"description":"Original key"}}',
        ),
      );
      final secondDefinition = await definitions.createDefinition(
        workspace.id,
        const .new(
          title: 'Second type',
          attributesJson: '{"other":{"description":"Second key"}}',
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
                ServiceAuthenticationTypeTable.apiKey,
              ),
              encryptedAuthValue: const .new('retained-ciphertext-A'),
              workspaceId: .new(workspace.id),
            ),
          );
      final secondConnection = await database
          .into(database.serviceConnections)
          .insertReturning(
            ServiceConnectionsCompanion(
              name: const .new('Second connection'),
              serviceId: const .new('custom'),
              kind: const .new(ServiceConnectionKindTable.appSkillCredential),
              authenticationType: const .new(
                ServiceAuthenticationTypeTable.apiKey,
              ),
              encryptedAuthValue: const .new('retained-ciphertext-B'),
              workspaceId: .new(workspace.id),
            ),
          );
      final firstId = switch (action) {
        'agent' => agent.id,
        'type' => definition.id,
        _ => connection.id,
      };
      final secondId = switch (action) {
        'agent' => second.id,
        'type' => secondDefinition.id,
        _ => secondConnection.id,
      };
      final secondTitle = switch (action) {
        'agent' => 'Second agent',
        'type' => 'Second type',
        _ => 'Second connection',
      };
      GoRouteData routeFor(String id) => switch (action) {
        'agent' => AgentDetailRoute(workspaceId: workspace.id, agentId: id),
        'type' => SkillCredentialDefinitionEditRoute(
          workspaceId: workspace.id,
          definitionId: id,
        ),
        _ => ServiceConnectionEditRoute(
          workspaceId: workspace.id,
          connectionId: id,
        ),
      };
      final route = routeFor(firstId);
      final destination = switch (action) {
        'agent' => AgentsRoute(workspaceId: workspace.id).location,
        'type' => SkillCredentialDefinitionsRoute(
          workspaceId: workspace.id,
        ).location,
        _ => ServiceConnectionsRoute(workspaceId: workspace.id).location,
      };
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/direct/:id',
            builder: (context, state) =>
                routeFor(state.pathParameters['id']!).build(context, state),
            onExit: route.onExit,
          ),
          GoRoute(
            path: destination,
            builder: (_, _) => const Text('Saved destination'),
          ),
        ],
        initialLocation: '/direct/$firstId',
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
      router.go('/direct/$secondId');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing', skipOffstage: false), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.path, '/direct/$firstId');
      expect(find.text('Saved revision'), findsOneWidget);
      router.go('/direct/$secondId');
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.text(action == 'agent' ? 'Discard' : 'Discard changes'),
      );
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.path, '/direct/$secondId');
      expect(find.text(secondTitle), findsOneWidget);
      expect(find.text('Saved revision'), findsNothing);
      await tester.enterText(
        find.descendant(
          of: find.byType(AuraInput).first,
          matching: find.byType(EditableText),
        ),
        'Second revision',
      );
      if (action == 'type') {
        await tester.tap(find.byIcon(Icons.save_outlined));
      } else {
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
      }
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.path, destination);
      switch (action) {
        case 'agent':
          final original = await agents.getAgentById(agent.id);
          final saved = await agents.getAgentById(second.id);
          expect(original?.name, 'Saved agent');
          expect(original?.description, 'Saved description');
          expect(original?.content, 'Saved instructions');
          expect(saved?.name, 'Second revision');
          expect(saved?.description, 'Second description');
          expect(saved?.content, 'Second instructions');
        case 'type':
          final original = await definitions.getDefinitionById(definition.id);
          final saved = await definitions.getDefinitionById(
            secondDefinition.id,
          );
          expect(original?.title, 'Saved type');
          expect(
            jsonDecode(original?.attributesJson ?? '{}'),
            containsPair('key', containsPair('description', 'Original key')),
          );
          expect(saved?.title, 'Second revision');
          expect(
            jsonDecode(saved?.attributesJson ?? '{}'),
            containsPair('other', containsPair('description', 'Second key')),
          );
        case 'connection':
          final firstQuery = database.select(database.serviceConnections)
            ..where((table) => table.id.equals(connection.id));
          final secondQuery = database.select(database.serviceConnections)
            ..where((table) => table.id.equals(secondConnection.id));
          final original = await firstQuery.getSingle();
          final saved = await secondQuery.getSingle();
          expect(original.name, 'Saved connection');
          expect(original.encryptedAuthValue, connection.encryptedAuthValue);
          expect(saved.name, 'Second revision');
          expect(saved.encryptedAuthValue, secondConnection.encryptedAuthValue);
      }
    });
  }
}
