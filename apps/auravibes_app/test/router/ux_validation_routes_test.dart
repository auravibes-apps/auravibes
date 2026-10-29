import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:auravibes_app/features/agents/screens/agents_screen.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connections_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/features/tools/widgets/tools_search_input.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_app/widgets/feature_destination_master.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import '../helpers/ux_validation_fixture.dart';

void main() {
  tearDownAll(UxValidationFixture.closeDatabase);
  testWidgets('connections master stays behind a Services swipe', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final toolsLocation = ToolsRoute(workspaceId: f.workspaceId).location;
    await _expectMasterPreviewDuringBack(
      tester,
      f,
      masterLocation: FeatureDestinations.masterLocation(toolsLocation),
      targetLocation: FeatureDestinations.connectionLocation(
        f.workspaceId,
        .services,
      ),
      masterTitle: 'Connections',
      detailScreen: find.byType(ServiceConnectionsScreen),
      absentDuringPreview: find.byType(ToolsSearchInput, skipOffstage: false),
    );
  });

  testWidgets(
    'same-path connection master selects the remembered destination',
    (tester) async {
      final f = await UxValidationFixture.create();
      final servicesLocation = FeatureDestinations.connectionLocation(
        f.workspaceId,
        .services,
      );
      await _expectMasterPreviewDuringBack(
        tester,
        f,
        masterLocation: FeatureDestinations.masterLocation(servicesLocation),
        targetLocation: servicesLocation,
        masterTitle: 'Connections',
        detailScreen: find.byType(ServiceConnectionsScreen),
      );
    },
  );

  testWidgets('Agents and Skills master stays behind an Agents swipe', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final skillsLocation = SkillsRoute(workspaceId: f.workspaceId).location;
    await _expectMasterPreviewDuringBack(
      tester,
      f,
      masterLocation: FeatureDestinations.masterLocation(skillsLocation),
      targetLocation: AgentsRoute(workspaceId: f.workspaceId).location,
      masterTitle: 'Agents & skills',
      detailScreen: find.byType(AgentsScreen),
    );
  });

  testWidgets('clean production iOS detail route supports edge back', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = .iOS;
    try {
      final f = await UxValidationFixture.create();
      final skillList = SkillsRoute(workspaceId: f.workspaceId).location;
      final router = await f.pump(
        tester,
        skillList,
        size: const Size(466, 678),
      );
      final _ = router.push<void>(
        SkillDetailRoute(
          workspaceId: f.workspaceId,
          skillId: f.skillId,
        ).location,
      );
      await f.settle(tester);
      expect(find.byType(SkillDetailScreen), findsOneWidget);
      final route = ModalRoute.of(
        tester.element(find.byType(SkillDetailScreen)),
      );
      expect(route?.popGestureEnabled, isTrue);

      await tester.dragFrom(const Offset(12, 350), const Offset(280, 0));
      await f.settle(tester);

      expect(router.routeInformationProvider.value.uri.path, skillList);
      await f.close(tester);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
  testWidgets('compact production feature route supports iOS edge back', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = .iOS;
    try {
      final f = await UxValidationFixture.create();
      final agentsLocation = AgentsRoute(workspaceId: f.workspaceId).location;
      final masterLocation = FeatureDestinations.masterLocation(agentsLocation);
      final router = await f.pump(
        tester,
        NewChatRoute(workspaceId: f.workspaceId).location,
        size: const Size(466, 678),
      );
      final _ = await tester.tap(find.byKey(const ValueKey('app_drawer_menu')));
      await f.settle(tester);
      final _ = await tester.tap(find.text('Agents & skills'));
      await f.settle(tester);
      expect(router.state.uri.toString(), masterLocation);
      expect(find.byType(FeatureDestinationMaster), findsOneWidget);

      final skillsLocation = SkillsRoute(workspaceId: f.workspaceId).location;
      final _ = await tester.tap(
        find.byKey(ValueKey('feature-destination-$skillsLocation')),
      );
      await f.settle(tester);
      expect(find.byType(SkillsScreen), findsOneWidget);
      final route = ModalRoute.of(tester.element(find.byType(SkillsScreen)));
      expect(route?.isCurrent, isTrue);
      expect(router.canPop(), isTrue);
      expect(route?.popGestureEnabled, isTrue);
      expect(
        Theme.of(tester.element(find.byType(SkillsScreen))).platform,
        TargetPlatform.iOS,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString().contains(
            'CupertinoBackGestureDetector',
          ),
        ),
        findsWidgets,
      );

      final gesture = await tester.startGesture(const Offset(1, 350));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(route?.popGestureInProgress, isTrue);
      await gesture.moveBy(const Offset(300, 0));
      await gesture.up();
      await f.settle(tester);

      expect(find.byType(SkillsScreen), findsNothing);
      expect(find.byType(FeatureDestinationMaster), findsOneWidget);
      expect(router.state.uri.toString(), masterLocation);

      final _ = await tester.tap(
        find.byKey(ValueKey('feature-destination-$skillsLocation')),
      );
      await f.settle(tester);
      expect(find.byType(SkillsScreen), findsOneWidget);
      final _ = await tester.tap(
        find.byKey(const ValueKey('app_navigation_back')),
      );
      await f.settle(tester);
      expect(find.byType(SkillsScreen), findsNothing);
      expect(find.byType(FeatureDestinationMaster), findsOneWidget);
      expect(router.state.uri.toString(), masterLocation);
      await f.close(tester);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
  testWidgets(
    'two agents retain a shared skill when one saved agent is disabled',
    (tester) async {
      final f = await UxValidationFixture.create();
      final repository = AgentsRepository(f.database);
      final before = await repository.getAgentsByWorkspace(f.workspaceId);
      final sibling = before.singleWhere((agent) => agent.id != f.agentId);
      final _ = await f.pump(
        tester,
        AgentDetailRoute(
          workspaceId: f.workspaceId,
          agentId: f.agentId,
        ).location,
        size: const Size(1280, 1600),
      );
      expect(find.text('Available in chats'), findsOneWidget);
      expect(find.text('Available for delegation'), findsOneWidget);
      final toggle = find.byType(AuraSwitch).first;
      await Scrollable.ensureVisible(tester.element(toggle), alignment: 0.5);
      final _ = await tester.pumpAndSettle();
      await tester.tap(toggle);
      final _ = await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save').last);
      await tester.tap(find.text('Save').last);
      await f.settle(tester);
      expect(find.byType(AgentsScreen), findsOneWidget);
      final changed = await repository.getAgentById(f.agentId);
      final untouched = await repository.getAgentById(sibling.id);
      expect(changed?.isEnabled, isFalse);
      expect(
        changed?.visibility,
        before.singleWhere((agent) => agent.id == f.agentId).visibility,
      );
      expect(
        changed?.skills,
        before.singleWhere((agent) => agent.id == f.agentId).skills,
      );
      expect(untouched, sibling);
      expect(changed?.skills, sibling.skills);
      expect(
        (await SkillsRepository(f.database).getSkillById(f.skillId))?.isEnabled,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets(
    'create second agent reuses actual shared skill without changing first',
    (tester) async {
      final f = await UxValidationFixture.create();
      final repository = AgentsRepository(f.database);
      final original = await repository.getAgentById(f.agentId);
      final before = await repository.getAgentsByWorkspace(f.workspaceId);
      for (final agent in before.where((agent) => agent.id != f.agentId)) {
        final _ = await repository.deleteAgent(agent.id);
      }
      final skillsBefore = await f.database.select(f.database.skills).get();
      final _ = await f.pump(
        tester,
        AgentsRoute(workspaceId: f.workspaceId).location,
        size: const Size(1280, 1800),
      );
      await tester.tap(find.byTooltip('Create agent'));
      await f.settle(tester);
      await tester.enterText(find.byType(AuraInput).at(0), 'Second researcher');
      await tester.enterText(
        find.byType(AuraInput).at(1),
        'Research with shared notes.',
      );
      await tester.ensureVisible(find.text('Add system prompt'));
      await tester.tap(find.text('Add system prompt'));
      await f.settle(tester);
      await tester.enterText(
        find.byType(TextFormField),
        'Use the shared research notes.',
      );
      await tester.tap(find.byIcon(Icons.save_outlined));
      await f.settle(tester);
      await tester.ensureVisible(find.text('Advanced settings'));
      await tester.tap(find.text('Advanced settings'));
      await f.settle(tester);
      await tester.ensureVisible(find.text('Manage skills'));
      await tester.tap(find.text('Manage skills'));
      await f.settle(tester);
      await tester.tap(find.text('Research notes').last);
      await f.settle(tester);
      await tester.tap(find.bySemanticsLabel('Close dialog'));
      await f.settle(tester);
      expect(
        tester
            .widget<AuraButton>(find.widgetWithText(AuraButton, 'Create agent'))
            .disabled,
        isFalse,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      await tester.ensureVisible(
        find.widgetWithText(AuraButton, 'Create agent'),
      );
      await tester.tap(find.widgetWithText(AuraButton, 'Create agent'));
      await f.settle(tester);
      for (
        var i = 0;
        i < 20 && find.byType(AgentsScreen).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(find.byType(AgentsScreen), findsOneWidget);
      final agents = await repository.getAgentsByWorkspace(f.workspaceId);
      expect(agents, hasLength(2));
      final created = agents.singleWhere((agent) => agent.id != f.agentId);
      expect(created.name, 'Second researcher');
      expect(created.description, 'Research with shared notes.');
      expect(created.content, 'Use the shared research notes.');
      expect(created.skills, original?.skills);
      expect(await repository.getAgentById(f.agentId), original);
      expect(await f.database.select(f.database.skills).get(), skillsBefore);
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets(
    'zero accounts Intro authenticates and creates intended cloud workspace',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final f = await UxValidationFixture.create(empty: true);
      final store = ServerpodAuthStore();
      final accounts = <CloudAccountSession>[];
      final protocol = _Protocol();
      final client = _Client();
      final endpoint = _CloudEndpoint();
      when(() => client.cloudWorkspace).thenReturn(endpoint);
      final origin = CloudAccountIdentity.canonicalServerOrigin(
        AppEnvConfig.auravibesServerUrl,
      );
      final account = CloudAccountSession(
        serverUrl: origin,
        userId: '11111111-1111-4111-8111-111111111111',
        email: 'new@example.com',
      );
      when(() => protocol.login('new@example.com', 'fixture-password'))
          .thenAnswer(
            (_) async => (
              session: account,
              auth: AuthSuccess(
                authStrategy: 'jwt',
                token: 'fixture-token',
                authUserId: .fromString(account.userId),
                scopeNames: {},
              ),
            ),
          );
      registerFallbackValue(
        CreateCloudWorkspaceRequest(name: 'Fresh cloud', requestId: 'request'),
      );
      when(() => endpoint.createWorkspace(any())).thenAnswer((call) async {
        expect(
          (call.positionalArguments.single as CreateCloudWorkspaceRequest).name,
          'Fresh cloud',
        );

        return CloudWorkspaceSummary(
          id: 23,
          name: 'Fresh cloud',
          role: 'owner',
          revision: 1,
          sequence: 1,
          createdAt: .new(2026),
          updatedAt: .new(2026),
        );
      });
      final _ = await f.pump(
        tester,
        const IntroRoute().location,
        accounts: accounts,
        overrides: [
          cloudAccountUseCasesProvider.overrideWithValue(
            CloudAccountUseCases(
              store: store,
              workspaceRepository: .new(f.database),
              deleteRemoteAccount: ({required serverUrl, required userId}) =>
                  Future<void>.error(StateError('Unexpected remote delete')),
              invalidateAccount: (server, user) {
                expect(server, origin);
                expect(user, account.userId);
                accounts.add(account);
              },
              createAuthProtocol: (server) {
                expect(server, origin);

                return protocol;
              },
            ),
          ),
          cloudWorkspaceUseCasesProvider.overrideWith(
            (ref, key) async => CloudWorkspaceUseCases(
              cloudRepository: .new(client),
              workspaceRepository: .new(f.database),
              cloudAccountId: key.accountId,
              serverUrl: key.serverUrl,
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('intro_welcome_skip_button')));
      await f.settle(tester);
      await tester.tap(find.byKey(const Key('intro_route_cloud_button')));
      await f.settle(tester);
      await tester.enterText(find.byType(AuraInput), 'Fresh cloud');
      await tester.tap(
        find.byKey(const Key('intro_sign_in_to_continue_button')),
      );
      await f.settle(tester);
      expect(find.byType(CloudAccountAuthContent), findsOneWidget);
      expect(await f.database.workspaceDao.getAllWorkspaces(), isEmpty);
      await _enter(tester, 'Email', 'new@example.com');
      await _enter(tester, 'Password', 'fixture-password');
      await tester.tap(find.widgetWithText(AuraButton, 'Log in').first);
      await f.settle(tester);
      expect(find.text('Fresh cloud'), findsOneWidget);
      expect(await f.database.workspaceDao.getAllWorkspaces(), isEmpty);
      await tester.tap(find.byKey(const Key('intro_create_workspace_button')));
      for (
        var i = 0;
        i < 20 &&
            find.byKey(const Key('intro_skip_ai_button')).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(find.text('Workspace created'), findsOneWidget);
      final workspace =
          (await f.database.workspaceDao.getAllWorkspaces()).single;
      expect(workspace.cloudWorkspaceId, '23');
      expect(workspace.cloudAccountId, account.userId);
      expect(workspace.url, origin);
      expect(workspace.name, 'Fresh cloud');
      expect((await store.listAccounts()).single.key, account.key);
      verify(() => endpoint.createWorkspace(any())).called(1);
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
    skip: AppEnvConfig.auravibesServerUrl.isEmpty,
  );

  testWidgets(
    'tool source opens actual connection and returns with persisted repair',
    (tester) async {
      final f = await UxValidationFixture.create();
      final repository = McpServersRepository(f.database);
      final server = await repository.addMcpServerWithTools(
        workspaceId: f.workspaceId,
        serverToCreate: const .new(
          name: 'Research source',
          url: 'https://old.example.test/mcp',
          transport: McpTransportTypeSSE(),
          authenticationType: .none(),
        ),
        tools: [
          const .new(
            toolName: 'lookup',
            description: 'Read reference details',
            inputSchema: {},
          ),
        ],
      );
      final group = await f.database.toolsGroupsDao.getToolsGroupByMcpServerId(
        server.id,
      );
      final originalTools = await f.database.workspaceToolsDao
          .getWorkspaceTools(f.workspaceId);
      final parent = ToolsRoute(workspaceId: f.workspaceId).location;
      final router = await f.pump(
        tester,
        parent,
        overrides: [
          mcpConnectionProvider.overrideWith(_DisconnectedMcp.new),
          mcpServersRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.tap(
        find.byKey(ValueKey('tools-open-connection-${server.id}')),
      );
      await f.settle(tester);
      expect(find.byType(ServiceConnectionEditScreen), findsOneWidget);
      await tester.enterText(
        find.byType(AuraInput).at(0),
        'Repaired research source',
      );
      await tester.enterText(
        find.byType(AuraInput).at(1),
        'https://new.example.test/mcp',
      );
      await tester.tap(find.text('Save').last);
      for (
        var i = 0;
        i < 20 && find.byType(ToolsScreen).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(router.routeInformationProvider.value.uri.path, parent);
      expect(find.byType(ToolsScreen), findsOneWidget);
      expect(find.text('Repaired research source'), findsOneWidget);
      final persisted = await repository.getMcpServerById(server.id);
      expect(persisted?.url, 'https://new.example.test/mcp');
      expect(persisted?.name, 'Repaired research source');
      final updatedGroup = await f.database.toolsGroupsDao
          .getToolsGroupByMcpServerId(server.id);
      expect(updatedGroup?.id, group?.id);
      expect(updatedGroup?.permissions, group?.permissions);
      final updatedTools = await f.database.workspaceToolsDao.getWorkspaceTools(
        f.workspaceId,
      );
      expect(
        updatedTools
            .where((t) => t.workspaceToolsGroupId == group?.id)
            .map((t) => (id: t.id, permissions: t.permissions))
            .toList(),
        originalTools
            .where((t) => t.workspaceToolsGroupId == group?.id)
            .map((t) => (id: t.id, permissions: t.permissions))
            .toList(),
      );
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets(
    'Intro reconnect authenticates then attaches the intended cloud workspace',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final f = await UxValidationFixture.create(empty: true);
      const account = CloudAccountSession(
        serverUrl: 'https://cloud.example',
        userId: '11111111-1111-4111-8111-111111111111',
        email: 'person@example.com',
      );
      final store = ServerpodAuthStore();
      final protocol = _Protocol();
      final summary = CloudWorkspaceSummary(
        id: 11,
        name: 'Shared research',
        role: 'owner',
        revision: 1,
        sequence: 1,
        createdAt: .new(2026),
        updatedAt: .new(2026),
      );
      var signedIn = false;
      when(() => protocol.login('person@example.com', 'fixture-password'))
          .thenAnswer(
            (_) async => (
              session: account,
              auth: AuthSuccess(
                authStrategy: 'jwt',
                token: 'fixture-token',
                authUserId: .fromString(account.userId),
                scopeNames: {},
              ),
            ),
          );
      final router = await f.pump(
        tester,
        const IntroRoute().location,
        accounts: [account],
        overrides: [
          cloudAccountUseCasesProvider.overrideWith(
            (ref) => CloudAccountUseCases(
              store: store,
              workspaceRepository: .new(f.database),
              deleteRemoteAccount: ({required serverUrl, required userId}) =>
                  Future<void>.error(StateError('Unexpected remote delete')),
              invalidateAccount: (server, user) {
                expect(server, account.serverUrl);
                expect(user, account.userId);
                signedIn = true;
                ref.invalidate(cloudWorkspaceStateProvider(account.key));
              },
              createAuthProtocol: (origin) {
                expect(origin, account.serverUrl);

                return protocol;
              },
            ),
          ),
          cloudWorkspaceStateProvider(account.key).overrideWith(
            (ref) async => signedIn
                ? CloudWorkspaceViewState(
                    workspaces: [summary],
                    pendingInvites: [],
                  )
                : const CloudWorkspaceViewState.authenticationRequired(),
          ),
          cloudWorkspaceUseCasesProvider(account.key).overrideWith(
            (ref) async => CloudWorkspaceUseCases(
              cloudRepository: .new(_Client()),
              workspaceRepository: .new(f.database),
              cloudAccountId: account.userId,
              serverUrl: account.serverUrl,
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('intro_welcome_skip_button')));
      await f.settle(tester);
      await tester.tap(find.byKey(const Key('intro_connect_existing_button')));
      await f.settle(tester);
      await tester.tap(find.text('Session expired. Sign in again.'));
      await f.settle(tester);
      expect(find.byType(CloudAccountAuthContent), findsOneWidget);
      await _enter(tester, 'Password', 'fixture-password');
      await tester.tap(find.widgetWithText(AuraButton, 'Log in').first);
      await f.settle(tester);
      expect(find.byType(CloudAccountAuthContent), findsNothing);
      expect(signedIn, isTrue);
      expect((await store.listAccounts()).single.key, account.key);
      expect(await f.database.workspaceDao.getAllWorkspaces(), isEmpty);
      await tester.tap(
        find.byKey(
          ValueKey(
            'cloud_workspace_connect_${account.serverUrl}_'
            '${account.userId}_11',
          ),
        ),
      );
      for (
        var i = 0;
        i < 20 &&
            find.byKey(const Key('intro_skip_ai_button')).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(find.text('Workspace connected'), findsOneWidget);
      final workspace =
          (await f.database.workspaceDao.getAllWorkspaces()).single;
      expect(workspace.cloudWorkspaceId, '11');
      expect(workspace.cloudAccountId, account.userId);
      expect(workspace.url, account.serverUrl);
      expect(workspace.name, 'Shared research');
      expect(
        router.routeInformationProvider.value.uri.path,
        const IntroRoute().location,
      );
      verify(() => protocol.login('person@example.com', 'fixture-password'))
          .called(1);
      verify(protocol.close).called(1);
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets(
    'first local use creates workspace provider model and persisted message',
    (tester) async {
      svg.cache.clear();
      addTearDown(svg.cache.clear);
      await tester.runAsync(_cacheModelLogos);
      final f = await UxValidationFixture.create(empty: true);
      final _ = await f.database.apiModelProvidersDao.upsertProvider(
        .insert(id: 'openai', name: 'OpenAI', type: const Value(.openai)),
      );
      final providerServices = _ProviderServices();
      final repository = ModelConnectionRepository(
        database: f.database,
        encryptionService: .new(_SecretKeyManager()),
        modelProviderServices: providerServices,
      );
      final messages = MessageRepository(f.database);
      String? continued;
      final _ = await f.pump(
        tester,
        const IntroRoute().location,
        emptyModels: false,
        realSessions: true,
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(repository),
          generateTitleUsecaseProvider.overrideWithValue(_Title()),
          sendMessageUsecaseProvider.overrideWith(
            (ref, workspaceId) => SendMessageUsecase(
              continueAgentTurn:
                  ({
                    required conversationId,
                    required context,
                    languageCode,
                  }) async {
                    continued = conversationId;
                    expect(context.ackMessageIds, hasLength(1));
                    expect(
                      (await messages.getMessageById(
                        context.ackMessageIds.single,
                      ))?.content,
                      'First saved question',
                    );
                    final _ = await messages.patchMessage(
                      context.ackMessageIds.single,
                      const .new(status: .sent),
                    );

                    return .done;
                  },
              messageRepository: messages,
              getConversationBusyStateUsecase: ref.watch(
                getConversationBusyStateUsecaseProvider,
              ),
              sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
              conversationActivityGate: .new(),
            ),
          ),
        ],
      );
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(await f.database.select(f.database.workspaces).get(), isEmpty);
      await tester.tap(find.byKey(const Key('intro_welcome_skip_button')));
      await f.settle(tester);
      await tester.tap(find.byKey(const Key('intro_route_local_button')));
      await f.settle(tester);
      await tester.enterText(find.byType(AuraInput), 'First local');
      await tester.tap(find.byKey(const Key('intro_create_workspace_button')));
      await f.settle(tester);
      final workspace =
          (await f.database.select(f.database.workspaces).get()).single;
      final workspaceId = workspace.id;
      expect(workspace.name, 'First local');
      await tester.tap(find.byKey(const Key('intro_skip_ai_button')));
      await f.settle(tester);
      expect(find.byType(NewChatScreen), findsOneWidget);
      await tester.tap(find.text('Add provider'));
      await f.settle(tester);
      expect(find.byType(ServiceConnectionCreateScreen), findsOneWidget);
      await tester.tap(find.text('OpenAI').last);
      await f.settle(tester);
      await tester.enterText(
        find.byWidgetPredicate((widget) => widget is AuraInput).at(0),
        'First provider',
      );
      await tester.enterText(
        find.byWidgetPredicate((widget) => widget is AuraInput).at(1),
        'controlled-fixture-key',
      );
      await f.settle(tester);
      await tester.ensureVisible(find.text('Verify connection'));
      await tester.tap(find.text('Verify connection'));
      await f.settle(tester);
      expect(providerServices.calls, 1);
      await tester.ensureVisible(find.text('Add provider').last);
      await tester.tap(find.text('Add provider').last);
      await f.settle(tester);
      expect(find.text('Connection saved'), findsWidgets);
      final connections = await f.database
          .select(f.database.serviceConnections)
          .get();
      expect(connections.single.workspaceId, workspaceId);
      expect(connections.single.name, 'First provider');
      final selection =
          (await f.database.select(f.database.workspaceModelSelections).get())
              .single;
      expect(selection.modelId, 'fixture-model');
      expect(selection.modelConnectionId, connections.single.id);
      await tester.tap(find.text('Continue to chat'));
      await f.settle(tester);
      expect(find.byType(NewChatScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await f.settle(tester);
      await tester.tap(find.text('Model').last);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('fixture-model').last);
      final _ = await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(ChatInputWidget),
              matching: find.byType(EditableText),
            )
            .first,
        'First saved question',
      );
      for (
        var i = 0;
        i < 20 &&
            tester
                .widget<ChatInputWidget>(find.byType(ChatInputWidget))
                .disabled;
        i++
      ) {
        await f.settle(tester);
      }
      final _ = await tester.pumpAndSettle();
      expect(
        tester.widget<ChatInputWidget>(find.byType(ChatInputWidget)).disabled,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey<String>('chat_send_button')));
      await f.settle(tester);
      for (
        var i = 0;
        i < 20 && find.byType(ChatConversationScreen).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(find.byType(ChatConversationScreen), findsOneWidget);
      final screen = tester.widget<ChatConversationScreen>(
        find.byType(ChatConversationScreen),
      );
      expect(screen.workspaceId, workspaceId);
      expect(
        GoRouterState.of(tester.element(find.byType(ChatConversationScreen)))
            .uri
            .path,
        ConversationRoute(
          workspaceId: workspaceId,
          chatId: screen.chatId,
        ).location,
      );
      final persisted = await ConversationRepository(f.database)
          .getConversationById(screen.chatId);
      expect(persisted?.modelId, selection.id);
      expect(persisted?.workspaceId, workspaceId);
      expect(
        (await messages.getMessagesByConversation(screen.chatId))
            .single
            .content,
        'First saved question',
      );
      expect(continued, screen.chatId);
      expect(find.text('First saved question'), findsWidgets);
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets('staged skill creates resource and links Connector tool', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final _ = await f.pump(
      tester,
      SkillCreateRoute(workspaceId: f.workspaceId).location,
      size: const Size(1280, 1600),
      overrides: [
        connectorToolCatalogProvider.overrideWith(
          (_) => const [
            ConnectorToolCatalogItem(
              toolId: 'connector/test/search',
              connectorName: 'Research',
              title: 'Search sources',
              description: 'Search public sources.',
            ),
          ],
        ),
      ],
    );
    await tester.enterText(find.byType(AuraInput).first, 'Complete authoring');
    for (final field in ['Edit description', 'Edit content']) {
      await tester.ensureVisible(find.text(field));
      await tester.tap(find.text(field));
      await f.settle(tester);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Shared research instructions.',
      );
      await tester.tap(find.byTooltip('Apply changes'));
      await f.settle(tester);
    }
    await tester.ensureVisible(find.text('Create and configure'));
    await tester.tap(find.text('Create and configure'));
    await f.settle(tester);
    final skill = await SkillsRepository(f.database)
        .getSkillByTitle(f.workspaceId, 'Complete authoring');
    final skillId = skill?.id ?? (throw StateError('Missing configured skill'));
    final parent = SkillDetailRoute(
      workspaceId: f.workspaceId,
      skillId: skillId,
    ).location;
    expect(
      GoRouterState.of(tester.element(find.byType(SkillDetailScreen))).uri.path,
      parent,
    );
    await tester.enterText(
      find.byType(AuraInput).first,
      'Unpersisted parent title',
    );
    await tester.scrollUntilVisible(
      find.byTooltip('New skill resource'),
      350,
      scrollable: find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byTooltip('New skill resource'));
    await f.settle(tester);
    expect(find.byType(SkillResourceEditScreen), findsOneWidget);
    await tester.enterText(find.byType(AuraInput).first, 'Saved reference');
    await tester.tap(find.text('Edit content'));
    await f.settle(tester);
    await tester.enterText(
      find.byType(EditableText).last,
      'Exact saved reference content.',
    );
    await tester.tap(find.byTooltip('Apply changes'));
    await f.settle(tester);
    await tester.ensureVisible(find.text('Save resource'));
    await tester.tap(find.text('Save resource'));
    await f.settle(tester);
    expect(find.byType(SkillDetailScreen), findsOneWidget);
    final resources = await SkillResourcesRepository(f.database)
        .getSkillResources(skillId);
    expect(resources, hasLength(1));
    expect(resources.single.title, 'Saved reference');
    expect(resources.single.content, 'Exact saved reference content.');
    expect(
      tester.widget<AuraInput>(find.byType(AuraInput).first).controller?.text,
      'Unpersisted parent title',
    );
    expect(
      (await SkillsRepository(f.database).getSkillById(skillId))?.title,
      'Complete authoring',
    );
    const connectorToolId = 'connector/test/search';
    await tester.scrollUntilVisible(
      find.text('Connector tools'),
      350,
      scrollable: find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Choose tools'));
    final _ = await tester.pumpAndSettle();
    final connectorToolOption = find.byType(AuraCheckboxListTile);
    expect(connectorToolOption, findsOneWidget);
    expect(
      tester.widget<AuraCheckboxListTile>(connectorToolOption).value,
      isFalse,
    );
    await tester.tap(connectorToolOption);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<AuraCheckboxListTile>(connectorToolOption).value,
      isTrue,
    );
    await tester.tap(find.text('Apply'));
    await f.settle(tester);
    expect(find.text('Research: Search sources'), findsOneWidget);
    await tester.tap(find.byTooltip('Save skill'));
    await f.settle(tester);

    final updatedSkill = await SkillsRepository(f.database)
        .getSkillById(skillId);
    expect(updatedSkill?.connectorToolIds, [connectorToolId]);
    expect(updatedSkill?.title, 'Unpersisted parent title');
    expect(
      await SkillResourcesRepository(f.database).getSkillResources(skillId),
      resources,
    );
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  testWidgets('delegated child returns to the loaded production parent', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final router = await f.pump(
      tester,
      SubAgentConversationRoute(
        workspaceId: f.workspaceId,
        chatId: f.chatId,
        subAgentConversationId: f.childId,
      ).location,
    );
    expect(
      tester
          .widget<ChatConversationScreen>(find.byType(ChatConversationScreen))
          .chatId,
      f.childId,
    );
    await tester.tap(find.text('Return to parent conversation'));
    final _ = await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChatConversationScreen>(find.byType(ChatConversationScreen))
          .chatId,
      f.chatId,
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      ConversationRoute(workspaceId: f.workspaceId, chatId: f.chatId).location,
    );
    expect(find.text('Project research'), findsWidgets);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });
}

Future<void> _expectMasterPreviewDuringBack(
  WidgetTester tester,
  UxValidationFixture fixture, {
  required String masterLocation,
  required String targetLocation,
  required String masterTitle,
  required Finder detailScreen,
  Finder? absentDuringPreview,
}) async {
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = .iOS;
  try {
    final router = await fixture.pump(
      tester,
      masterLocation,
      size: const Size(466, 678),
    );
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('feature-destination-$targetLocation')),
    );
    await fixture.settle(tester);
    expect(router.state.uri.toString(), targetLocation);
    final route = ModalRoute.of(tester.element(detailScreen));
    expect(route?.popGestureEnabled, isTrue);
    final gesture = await tester.startGesture(const Offset(1, 350));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(route?.popGestureInProgress, isTrue);
    expect(
      find.byType(FeatureDestinationMaster, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text(masterTitle, skipOffstage: false), findsWidgets);
    if (absentDuringPreview != null) {
      expect(
        absentDuringPreview,
        findsNothing,
        reason: 'The previous page must render its master list.',
      );
    }

    await gesture.moveBy(const Offset(300, 0));
    await gesture.up();
    await fixture.settle(tester);
    expect(router.state.uri.toString(), masterLocation);
    expect(find.byType(FeatureDestinationMaster), findsOneWidget);
    expect(find.text(masterTitle), findsWidgets);
    await fixture.close(tester);
  } finally {
    debugDefaultTargetPlatformOverride = previousPlatform;
  }
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final input = find.byWidgetPredicate(
    (widget) =>
        widget is AuraInput &&
        switch (widget.label) {
          Text(:final data) => data == label,
          _ => false,
        },
  );
  await tester.ensureVisible(input.first);
  await tester.enterText(
    find.descendant(of: input.first, matching: find.byType(EditableText)),
    value,
  );
  final _ = await tester.pumpAndSettle();
}

class _ProviderServices extends ModelProviderServices {
  int calls = 0;

  @override
  Future<List<WorkspaceModelSelectionToCreate>> getWorkspaceModelSelections(
    ModelProvider provider,
  ) async {
    calls++;
    expect(provider.type, CredentialsModelType.openai);
    expect(provider.key, 'controlled-fixture-key');

    return const [.new(modelId: 'fixture-model', modelConnectionId: '')];
  }
}

class _Title extends Mock implements GenerateTitleUsecase;

class _SecretKeyManager extends SecretKeyManager {
  @override
  Future<SecretKey> getOrCreateSecretKey() async =>
      SecretKey(List<int>.filled(32, 7));
}

class _Protocol extends Mock implements CloudAuthProtocol;

class _Client extends Mock implements Client;

class _DisconnectedMcp extends McpConnectionNotifier {
  @override
  List<McpConnectionState> build() => [];
}

class _CloudEndpoint extends Mock implements EndpointCloudWorkspace;

Future<void> _cacheModelLogos() async {
  final bytes = await const SvgStringLoader(
    '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20">'
    ' <circle cx="10" cy="10" r="8"/></svg>',
  ).loadBytes(null);
  for (final id in ['openai', 'openai-codex']) {
    final loader = SvgNetworkLoader('https://models.dev/logos/$id.svg');
    final _ = await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () async => bytes,
    );
  }
}
