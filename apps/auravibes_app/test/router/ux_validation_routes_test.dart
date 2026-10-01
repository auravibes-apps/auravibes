import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
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
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_edit_screen.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_tool_edit_screen.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/screens/tools_screen.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import '../helpers/ux_validation_fixture.dart';

void main() {
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
      await tester.enterText(find.byType(AuraInput), 'Fresh cloud');
      await tester.tap(find.byKey(const ValueKey('workspace_intent_cloud')));
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
      await tester.enterText(find.byType(AuraInput), 'Preserved intent');
      await tester.tap(find.byKey(const ValueKey('workspace_intent_connect')));
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
      await tester.tap(find.byType(AuraPopupMenuButton).last);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Connect to this app').last);
      for (
        var i = 0;
        i < 20 &&
            find.byKey(const Key('intro_skip_ai_button')).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(find.text('Workspace created'), findsOneWidget);
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
    'schema creation returns selected type and encrypted credential saves',
    (tester) async {
      final f = await UxValidationFixture.create();
      final repository = SkillCredentialsRepository(
        database: f.database,
        encryptionService: .new(_SecretKeyManager()),
      );
      final _ = await SkillsRepository(f.database).deleteSkill(f.skillId);
      final _ = await f.database
          .delete(f.database.skillCredentialDefinitions)
          .go();
      final parent = ServiceConnectionCreateRoute(
        workspaceId: f.workspaceId,
        type: 'skillCredential',
      ).location;
      final _ = await f.pump(
        tester,
        parent,
        size: const Size(1280, 1600),
        overrides: [
          skillCredentialsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.enterText(find.byType(AuraInput).first, 'Project access');
      await tester.tap(find.text('Create credential type'));
      await f.settle(tester);
      expect(find.byType(SkillCredentialDefinitionEditScreen), findsOneWidget);
      await tester.enterText(find.byType(AuraInput).at(0), 'Project schema');
      await tester.enterText(find.byType(AuraInput).at(1), 'api_key');
      await tester.enterText(find.byType(AuraInput).at(2), 'API key');
      await tester.testTextInput.receiveAction(.done);
      await f.settle(tester);
      expect(find.byType(ServiceConnectionCreateScreen), findsOneWidget);
      expect(find.text('Project schema'), findsOneWidget);
      expect(find.text('Project access'), findsOneWidget);
      await tester.enterText(find.byType(AuraInput).last, 'fixture-secret');
      await tester.tap(find.text('Save').last);
      for (
        var i = 0;
        i < 20 &&
            find.byType(ServiceConnectionCreateScreen).evaluate().isNotEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      final definition = await SkillCredentialDefinitionsRepository(f.database)
          .getDefinitionBySlug(f.workspaceId, 'project_schema');
      expect(definition, isNotNull);
      final credentials = await repository.getCredentialsForDefinition(
        workspaceId: f.workspaceId,
        credentialDefinitionId:
            definition?.id ?? (throw StateError('Missing saved definition')),
      );
      expect(credentials.single.name, 'Project access');
      expect(
        (await repository.getCredentialForEdit(credentials.single.id))
            ?.secretAttributes['api_key']
            ?.hasValue,
        isTrue,
      );
      final row = await f.database.skillCredentialsDao.getCredentialById(
        credentials.single.id,
      );
      expect(row?.encryptedAuthValue, isNot(contains('fixture-secret')));
      expect(
        await EncryptionService(_SecretKeyManager()).decrypt(
          row?.encryptedAuthValue ??
              (throw StateError('Missing encrypted credential')),
        ),
        contains('fixture-secret'),
      );
      expect(credentials.single.attributes, isNot(contains('api_key')));
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets(
    'owning skill credential action persists and refreshes retained parent',
    (tester) async {
      final f = await UxValidationFixture.create();
      final repository = SkillCredentialsRepository(
        database: f.database,
        encryptionService: .new(_SecretKeyManager()),
      );
      final parent = SkillDetailRoute(
        workspaceId: f.workspaceId,
        skillId: f.skillId,
      ).location;
      final router = await f.pump(
        tester,
        parent,
        size: const Size(1280, 1800),
        overrides: [
          skillCredentialsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.enterText(
        find.byType(AuraInput).first,
        'Unpersisted owner title',
      );
      final create = find.text('Add Credential').first;
      await Scrollable.ensureVisible(tester.element(create), alignment: 0.5);
      final _ = await tester.pumpAndSettle();
      await tester.tap(create);
      await f.settle(tester);
      expect(find.byType(ServiceConnectionCreateScreen), findsOneWidget);
      expect(find.text('Research access'), findsOneWidget);
      await tester.enterText(find.byType(AuraInput).first, 'Owner access');
      await tester.enterText(find.byType(AuraInput).last, 'owner-secret');
      await tester.tap(find.text('Save').last);
      for (
        var i = 0;
        i < 20 && find.byType(SkillDetailScreen).evaluate().isEmpty;
        i++
      ) {
        await f.settle(tester);
      }
      expect(router.routeInformationProvider.value.uri.path, parent);
      expect(
        tester.widget<AuraInput>(find.byType(AuraInput).first).controller?.text,
        'Unpersisted owner title',
      );
      expect(
        (await repository.getCredentialsForDefinition(
          workspaceId: f.workspaceId,
          credentialDefinitionId: f.definitionId,
        )).single.name,
        'Owner access',
      );
      expect(
        (await SkillsRepository(f.database).getSkillById(f.skillId))?.title,
        'Research notes',
      );
      expect(find.text('1 credential configured'), findsOneWidget);
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
                  ({required conversationId, required context}) async {
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

  testWidgets(
    'credential dependency opens actual skill and refreshes after repair',
    (tester) async {
      final f = await UxValidationFixture.create();
      final parent = SkillCredentialDefinitionEditRoute(
        workspaceId: f.workspaceId,
        definitionId: f.definitionId,
      ).location;
      final router = await f.pump(tester, parent, size: const Size(1280, 1800));
      await tester.enterText(
        find.byType(AuraInput).first,
        'Unpersisted schema title',
      );
      await tester.tap(find.text('Research notes').last);
      await f.settle(tester);
      expect(find.byType(SkillDetailScreen), findsOneWidget);
      final selected = find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.text('Research access'),
          )
          .first;
      await Scrollable.ensureVisible(tester.element(selected), alignment: 0.5);
      final _ = await tester.pumpAndSettle();
      await tester.tap(selected);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('No credential type').last);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save skill'));
      await f.settle(tester);
      expect(find.byType(SkillCredentialDefinitionEditScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, parent);
      expect(
        tester.widget<AuraInput>(find.byType(AuraInput).first).controller?.text,
        'Unpersisted schema title',
      );
      expect(
        (await SkillsRepository(f.database).getSkillById(f.skillId))
            ?.credentialDefinitionId,
        isNull,
      );
      expect(find.text('Research notes'), findsNothing);
      expect(
        (await SkillCredentialDefinitionsRepository(f.database)
                .getDefinitionById(f.definitionId))
            ?.title,
        'Research access',
      );
      expect(tester.takeException(), isNull);
      await f.close(tester);
    },
  );

  testWidgets('staged skill creates resource and tool with retained parent', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final _ = await f.pump(
      tester,
      SkillCreateRoute(workspaceId: f.workspaceId).location,
      size: const Size(1280, 1600),
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
    await tester.scrollUntilVisible(
      find.byTooltip('New template tool'),
      350,
      scrollable: find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byTooltip('New template tool'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(SkillToolEditScreen), findsOneWidget);
    await _enter(tester, 'Title', 'New reference lookup');
    await _enter(tester, 'URL', 'https://example.test/reference');
    await Scrollable.ensureVisible(
      tester.element(find.text('Edit description')),
      alignment: 0.5,
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Edit description'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).last,
      'Find a public reference.',
    );
    await tester.tap(find.byTooltip('Apply changes'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save skill'));
    await f.settle(tester);

    expect(find.byType(SkillDetailScreen), findsOneWidget);
    expect(
      tester.widget<AuraInput>(find.byType(AuraInput).first).controller?.text,
      'Unpersisted parent title',
    );
    final tools = await SkillTemplateToolsRepository(f.database)
        .getSkillTools(skillId);
    final created = tools.singleWhere(
      (tool) => tool.title == 'New reference lookup',
    );
    expect(tools, hasLength(1));
    expect(
      (await SkillsRepository(f.database).getSkillById(skillId))?.title,
      'Complete authoring',
    );
    await tester.scrollUntilVisible(
      find.text('New reference lookup'),
      350,
      scrollable: find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('New reference lookup'));
    final _ = await tester.pumpAndSettle();
    expect(
      tester
          .widget<SkillToolEditScreen>(find.byType(SkillToolEditScreen))
          .toolId,
      created.id,
    );
    await _enter(tester, 'Title', 'Updated reference lookup');
    await tester.tap(find.byTooltip('Save skill'));
    await f.settle(tester);

    expect(
      GoRouterState.of(tester.element(find.byType(SkillDetailScreen))).uri.path,
      parent,
    );
    expect(
      tester.widget<AuraInput>(find.byType(AuraInput).first).controller?.text,
      'Unpersisted parent title',
    );
    final updated = await SkillTemplateToolsRepository(f.database)
        .getSkillTools(skillId);
    expect(
      updated.singleWhere((tool) => tool.id == created.id).title,
      'Updated reference lookup',
    );
    expect(updated, hasLength(1));
    expect(
      await SkillResourcesRepository(f.database).getSkillResources(skillId),
      resources,
    );
    await tester.scrollUntilVisible(
      find.text('Updated reference lookup'),
      400,
      scrollable: find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Updated reference lookup'), findsOneWidget);
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
