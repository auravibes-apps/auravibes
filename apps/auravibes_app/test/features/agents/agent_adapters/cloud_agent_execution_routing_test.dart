import 'dart:convert';

import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _Gateway extends Mock implements CloudWorkspaceStateGateway {}

class _Client extends Mock implements Client {}

class _Conversation extends Mock implements EndpointConversation {}

void main() {
  test(
    'cloud agent execution lookup never constructs local repositories',
    () async {
      final gateway = _Gateway();
      final client = _Client();
      final conversation = _Conversation();
      final now = DateTime.utc(2026);
      when(() => gateway.read(pages: any(named: 'pages'))).thenAnswer(
        (_) async => ReadWorkspaceStateResponse(
          pages: [
            WorkspaceResourcePage(
              resourceKind: WorkspaceResourceKind.agent,
              resources: [
                WorkspaceResource(
                  workspaceId: 1,
                  resourceKind: WorkspaceResourceKind.agent,
                  resourceId: 'agent-1',
                  data: jsonEncode({
                    'name': 'Agent',
                    'content': 'Cloud prompt',
                    'visibility': 'both',
                  }),
                  revision: 1,
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            ),
            WorkspaceResourcePage(
              resourceKind: WorkspaceResourceKind.agentAssociation,
              resources: const [],
            ),
          ],
          currentSequence: 1,
          events: const [],
          requiresSnapshot: false,
        ),
      );
      when(() => gateway.workspace).thenReturn(
        const CloudWorkspaceRef(
          localWorkspaceId: 'local',
          serverUrl: 'https://example.com',
          accountId: 'account',
          cloudWorkspaceId: 1,
        ),
      );
      when(() => gateway.client).thenReturn(client);
      when(() => client.conversation).thenReturn(conversation);
      when(() => conversation.get(any())).thenAnswer(
        (_) async => ConversationSummary(
          id: 'conversation-1',
          title: 'Conversation',
          isPinned: false,
          agentId: 'agent-1',
          revision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          workspaceSessionProvider.overrideWithValue(
            const WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: 'local',
                serverUrl: 'https://example.com',
                accountId: 'account',
                cloudWorkspaceId: 1,
              ),
            ),
          ),
          cloudWorkspaceStateGatewayProvider.overrideWith((_) async => gateway),
          agentsRepositoryProvider.overrideWith(
            (_) => throw StateError('local agents touched'),
          ),
          conversationRepositoryProvider.overrideWith(
            (_) => throw StateError('local conversations touched'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final usecase = container.read(
        listConversationAgentSkillsUsecaseProvider,
      );
      expect(
        (await usecase.loadSelectedAgent(
          conversationId: 'conversation-1',
          workspaceId: 'local',
        ))?.content,
        'Cloud prompt',
      );
      expect(
        container.read(resolvedToolServiceProvider),
        isA<ResolvedToolService>(),
      );
    },
  );
}
