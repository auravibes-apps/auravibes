import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/mcp_servers_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_tools_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_chat_attachment_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/models/data/cloud_model_stores.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/tools/data/cloud_tools_repository.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway {}

class _Client extends Mock implements Client {}

class _Conversation extends Mock implements EndpointConversation {}

Never _local(String dependency) =>
    throw StateError('Cloud composition touched local $dependency');

void main() {
  const cloud = WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: 'mirror-a',
      serverUrl: 'https://server-a.example',
      accountId: 'account-a',
      cloudWorkspaceId: 11,
    ),
  );
  const local = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: 'local-a'),
  );

  setUpAll(() {
    registerFallbackValue(
      ListConversationsRequest(workspaceId: 0, limit: 0),
    );
    registerFallbackValue(
      ListConversationMessagesRequest(
        workspaceId: 0,
        conversationId: '',
        limit: 0,
      ),
    );
  });

  test('cloud production composition avoids every local dependency', () async {
    final now = DateTime.utc(2026);
    final gateway = _Gateway();
    final client = _Client();
    final conversation = _Conversation();
    when(() => gateway.workspace).thenReturn(
      const CloudWorkspaceRef(
        localWorkspaceId: 'mirror-a',
        serverUrl: 'https://server-a.example',
        accountId: 'account-a',
        cloudWorkspaceId: 11,
      ),
    );
    when(() => gateway.client).thenReturn(client);
    when(() => client.conversation).thenReturn(conversation);
    when(() => conversation.list(any())).thenAnswer(
      (_) async => [
        ConversationSummary(
          id: 'conversation-a',
          title: 'Cloud',
          isPinned: false,
          revision: 3,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    when(
      () => conversation.listMessages(any()),
    ).thenAnswer((_) async => const []);
    when(() => gateway.watchResources(any())).thenAnswer(
      (_) => Stream.value(const <WorkspaceResource>[]),
    );

    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(cloud).overrideWithValue(cloud),
        workspaceSessionForRouteProvider.overrideWith((_, _) async => cloud),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
        cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => gateway,
        ),
        cloudConversationStateProvider.overrideWith(
          (_, _) async* {
            yield CloudConversationState(
              conversation: ConversationProjectionView(
                id: 'conversation-a',
                workspaceId: 11,
                executionState: 'idle',
                projectionRevision: 3,
                sequence: 0,
                updatedAt: now,
              ),
              messages: const [],
              pendingMessages: const [],
              activeExecution: null,
              toolCalls: const [],
              sequence: 0,
            );
          },
        ),
        toolsGroupsRepositoryProvider(cloud).overrideWithValue(
          CloudToolsRepository(Future.value(gateway)),
        ),
        workspaceSkillsProvider('mirror-a').overrideWith((_) async => const []),
        appDatabaseProvider.overrideWith((_) => _local('Drift database')),
        conversationRepositoryProvider.overrideWith(
          (_) => _local('conversation repository'),
        ),
        messageRepositoryProvider.overrideWith(
          (_) => _local('message repository'),
        ),
        modelConnectionRepositoryProvider.overrideWith(
          (_) => _local('model connection repository'),
        ),
        workspaceModelSelectionRepositoryProvider.overrideWith(
          (_) => _local('model selection repository'),
        ),
        serviceConnectionRepositoryProvider.overrideWith(
          (_) => _local('credential repository'),
        ),
        skillsRepositoryProvider.overrideWith(
          (_) => _local('skills repository'),
        ),
        skillTemplateToolsRepositoryProvider.overrideWith(
          (_) => _local('skill tools repository'),
        ),
        skillCredentialDefinitionsRepositoryProvider.overrideWith(
          (_) => _local('credential definitions repository'),
        ),
        skillCredentialsRepositoryProvider.overrideWith(
          (_) => _local('skill credential store'),
        ),
        conversationSkillsRepositoryProvider.overrideWith(
          (_) => _local('conversation skills repository'),
        ),
        appSkillWorkspaceSettingsRepositoryProvider.overrideWith(
          (_) => _local('skill settings repository'),
        ),
        workspaceCompactionSettingsRepositoryProvider.overrideWith(
          (_) => _local('compaction settings repository'),
        ),
        encryptionServiceProvider.overrideWith(
          (_) => _local('credential encryption'),
        ),
        oauthCredentialServiceProvider.overrideWith(
          (_) => _local('OAuth credential service'),
        ),
        mcpManagerServiceProvider.overrideWith(
          (_) => _local('MCP manager'),
        ),
        chatbotServiceProvider.overrideWith(
          (_) => _local('provider transport'),
        ),
        auraAgentServiceProvider.overrideWith(
          (_) => _local('agent runtime'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final conversations = conversationsStreamProvider(workspaceId: 'mirror-a');
    final messages = chatMessagesByConversationProvider(
      'mirror-a',
      'conversation-a',
    );
    final compaction = compactionSettingsProvider('mirror-a');
    final conversationsSubscription = container.listen(
      conversations,
      (_, _) => 0,
    );
    final messagesSubscription = container.listen(messages, (_, _) => 0);
    final compactionSubscription = container.listen(compaction, (_, _) => 0);
    addTearDown(conversationsSubscription.close);
    addTearDown(messagesSubscription.close);
    addTearDown(compactionSubscription.close);

    expect(
      await container.read(conversations.future),
      hasLength(1),
    );
    expect(
      await container.read(messages.future),
      isEmpty,
    );
    expect(
      await container.read(cloudConversationUsecaseProvider('mirror-a').future),
      isNotNull,
    );
    expect(
      await container.read(cloudTurnUsecaseProvider('mirror-a').future),
      isNotNull,
    );
    expect(
      await container.read(
        cloudChatAttachmentUsecaseProvider('mirror-a').future,
      ),
      isNotNull,
    );
    expect(
      container.read(sendMessageUsecaseProvider('mirror-a')),
      isA<SendMessageUsecase>(),
    );
    expect(
      await container.read(modelConnectionStoreProvider('mirror-a').future),
      isA<CloudModelStore>(),
    );
    expect(
      await container.read(modelSelectionStoreProvider('mirror-a').future),
      isA<CloudModelStore>(),
    );
    expect(
      await container.read(
        serviceConnectionOperationsProvider('mirror-a').future,
      ),
      isA<ServiceConnectionOperations>(),
    );
    expect(
      container.read(mcpServersRepositoryProvider(cloud)),
      isA<CloudToolsRepository>(),
    );
    expect(
      container.read(toolsGroupsRepositoryProvider(cloud)),
      isA<CloudToolsRepository>(),
    );
    expect(
      container.read(workspaceToolsRepositoryProvider(cloud)),
      isA<CloudToolsRepository>(),
    );
    expect(
      container.read(agentRepositoryProvider('mirror-a')),
      isA<CloudAgentRepository>(),
    );
    expect(
      container.read(agentToolsRepositoryProvider('mirror-a')),
      isA<CloudAgentToolsRepository>(),
    );
    expect(
      container.read(skillCredentialOperationsProvider('mirror-a')),
      isNotNull,
    );
    expect(
      await container.read(workspaceSkillsProvider('mirror-a').future),
      isEmpty,
    );
    expect(
      await container.read(compaction.future),
      isNotNull,
    );
  });

  test('local production composition avoids every server dependency', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(local).overrideWithValue(local),
        workspaceSessionForRouteProvider.overrideWith((_, _) async => local),
        appDatabaseProvider.overrideWithValue(database),
        toolsGroupsRepositoryProvider(local).overrideWithValue(
          ToolsGroupsRepository(database),
        ),
        serverpodClientForWorkspaceProvider.overrideWith(
          (_, _) => _local('workspace server client'),
        ),
        serverpodClientForAccountProvider.overrideWith(
          (_, _) => _local('account server client'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final conversations = conversationsStreamProvider(workspaceId: 'local-a');
    final messages = chatMessagesByConversationProvider(
      'local-a',
      'conversation-a',
    );
    final conversationsSubscription = container.listen(
      conversations,
      (_, _) => 0,
    );
    final messagesSubscription = container.listen(messages, (_, _) => 0);
    addTearDown(conversationsSubscription.close);
    addTearDown(messagesSubscription.close);

    expect(await container.read(conversations.future), isEmpty);
    expect(await container.read(messages.future), isEmpty);

    expect(
      await container.read(cloudWorkspaceStateGatewayProvider(local).future),
      isNull,
    );
    expect(
      await container.read(cloudConversationUsecaseProvider('local-a').future),
      isNull,
    );
    expect(
      await container.read(cloudTurnUsecaseProvider('local-a').future),
      isNull,
    );
    expect(
      await container.read(
        cloudChatAttachmentUsecaseProvider('local-a').future,
      ),
      isNull,
    );
    expect(
      await container.read(modelConnectionStoreProvider('local-a').future),
      isNot(isA<CloudModelStore>()),
    );
    expect(
      await container.read(modelSelectionStoreProvider('local-a').future),
      isNot(isA<CloudModelStore>()),
    );
    expect(
      container.read(mcpServersRepositoryProvider(local)),
      isA<McpServersRepository>(),
    );
    expect(
      container.read(toolsGroupsRepositoryProvider(local)),
      isA<ToolsGroupsRepository>(),
    );
    expect(
      container.read(workspaceToolsRepositoryProvider(local)),
      isA<WorkspaceToolsRepository>(),
    );
    expect(
      container.read(agentRepositoryProvider('local-a')),
      isA<AgentsRepository>(),
    );
    expect(
      container.read(agentToolsRepositoryProvider('local-a')),
      isA<AgentToolsRepository>(),
    );
    expect(
      container.read(skillCredentialOperationsProvider('local-a')),
      isNotNull,
    );
    expect(
      container.read(workspaceCompactionSettingsRepositoryProvider),
      isNotNull,
    );
  });
}
