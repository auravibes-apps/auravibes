import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/app_sub_agent_catalog.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const AgentListQuery(workspaceId: 'fallback'));
  });

  group('AppSubAgentCatalog', () {
    test('lists all enabled agents with types', () async {
      final repository = _MockAgentsRepository();
      when(() => repository.listAgents(any())).thenAnswer(
        (_) async => const AgentListPage(
          agents: [
            AgentListItem(
              id: 'main',
              name: 'Main',
              description: 'Main',
              isEnabled: true,
              visibility: .chatSelector,
              skillCount: 0,
            ),
            AgentListItem(
              id: 'sub',
              name: 'Sub',
              description: 'Sub',
              isEnabled: true,
              visibility: .subAgentList,
              skillCount: 0,
            ),
            AgentListItem(
              id: 'both',
              name: 'Both',
              description: 'Both',
              isEnabled: true,
              visibility: .both,
              skillCount: 0,
            ),
          ],
          nextCursor: 'next',
        ),
      );

      final page = await AppSubAgentCatalog(repository).listSubAgents(
        const agent.SubAgentCatalogQuery(workspaceId: 'workspace-1'),
      );

      expect(page.agents.map((agent) => agent.id), ['main', 'sub', 'both']);
      expect(page.agents.map((agent) => agent.types), [
        ['main'],
        ['sub_agent'],
        ['main', 'sub_agent'],
      ]);
      expect(page.nextCursor, 'next');
      final query =
          verify(() => repository.listAgents(captureAny())).captured.single
              as AgentListQuery;
      expect(query.workspaceId, 'workspace-1');
      expect(query.status, AgentListStatus.enabled);
    });

    test('gets only enabled sub-agent-list agents', () async {
      final repository = _MockAgentsRepository();
      final now = DateTime(2026);
      when(() => repository.getAgentById('sub')).thenAnswer(
        (_) async => _agent(id: 'sub', now: now, visibility: .subAgentList),
      );
      when(() => repository.getAgentById('main')).thenAnswer(
        (_) async => _agent(id: 'main', now: now, visibility: .chatSelector),
      );
      when(() => repository.getAgentById('missing'))
          .thenAnswer((_) async => null);

      final catalog = AppSubAgentCatalog(repository);

      final subAgent = await catalog.getSubAgent('sub');

      expect(subAgent?.id, 'sub');
      expect(subAgent?.types, ['sub_agent']);
      expect(await catalog.getSubAgent('main'), isNull);
      expect(await catalog.getSubAgent('missing'), isNull);
    });
  });

  group('AppSubAgentConversationStore', () {
    test('creates and reads sub-agent conversation records', () async {
      final repository = _MockConversationRepository();
      final now = DateTime(2026);
      final created = _conversation(
        id: 'child',
        now: now,
        parentConversationId: 'parent',
      );
      const input = ConversationToCreate(
        title: 'Task',
        workspaceId: 'workspace-1',
        modelId: 'model-1',
        agentId: 'agent-1',
        parentConversationId: 'parent',
      );
      when(() => repository.createConversation(input))
          .thenAnswer((_) async => created);
      when(() => repository.getConversationById('child'))
          .thenAnswer((_) async => created);
      when(() => repository.getConversationById('missing'))
          .thenAnswer((_) async => null);

      final store = AppSubAgentConversationStore(repository);

      final child = await store.createChildConversation((
        parentConversationId: 'parent',
        workspaceId: 'workspace-1',
        modelId: 'model-1',
        agentId: 'agent-1',
        title: 'Task',
      ));

      expect(child.id, 'child');
      expect(child.workspaceId, 'workspace-1');
      expect(child.modelId, 'model-1');
      expect(child.parentConversationId, 'parent');
      expect((await store.getConversation('child'))?.id, 'child');
      expect(await store.getConversation('missing'), isNull);
    });
  });

  group('AppSubAgentMessageStore', () {
    test('creates prompt and reads latest assistant content', () async {
      final repository = _MockMessageRepository();
      final now = DateTime(2026);
      const input = MessageToCreate(
        conversationId: 'child',
        content: 'Do it',
        messageType: .text,
        isUser: true,
        status: .sent,
      );
      when(() => repository.createMessage(input)).thenAnswer(
        (_) async => _message(
          id: 'message-1',
          conversationId: 'child',
          content: 'Do it',
          isUser: true,
          now: now,
        ),
      );
      when(
        () => repository.getLatestAssistantMessagesByConversations(['child']),
      ).thenAnswer(
        (_) async => [
          _message(
            id: 'assistant-1',
            conversationId: 'child',
            content: 'Done',
            isUser: false,
            now: now,
          ),
        ],
      );
      when(
        () => repository.getLatestAssistantMessagesByConversations(['empty']),
      ).thenAnswer((_) async => []);

      final store = AppSubAgentMessageStore(repository);

      final prompt = await store.createUserPrompt(
        conversationId: 'child',
        prompt: 'Do it',
      );

      expect(prompt.id, 'message-1');
      expect(await store.latestAssistantContent('child'), 'Done');
      expect(await store.latestAssistantContent('empty'), '');
    });
  });
}

AgentEntity _agent({
  required String id,
  required DateTime now,
  required AgentVisibility visibility,
  bool isEnabled = true,
}) {
  return AgentEntity(
    id: id,
    workspaceId: 'workspace-1',
    name: id,
    content: 'content',
    skills: const [],
    createdAt: now,
    updatedAt: now,
    description: '$id description',
    isEnabled: isEnabled,
    visibility: visibility,
  );
}

class _MockAgentsRepository extends Mock implements AgentsRepository;

ConversationEntity _conversation({
  required String id,
  required DateTime now,
  String? parentConversationId,
}) {
  return ConversationEntity(
    id: id,
    title: id,
    workspaceId: 'workspace-1',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    modelId: 'model-1',
    agentId: 'agent-1',
    parentConversationId: parentConversationId,
  );
}

MessageEntity _message({
  required String id,
  required String conversationId,
  required String content,
  required bool isUser,
  required DateTime now,
}) {
  return MessageEntity(
    id: id,
    conversationId: conversationId,
    content: content,
    messageType: .text,
    isUser: isUser,
    status: .sent,
    createdAt: now,
    updatedAt: now,
  );
}

class _MockConversationRepository extends Mock
    implements ConversationRepository;

class _MockMessageRepository extends Mock implements MessageRepository;
