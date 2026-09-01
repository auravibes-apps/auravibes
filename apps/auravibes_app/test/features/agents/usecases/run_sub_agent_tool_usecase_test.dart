import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/agents/usecases/run_sub_agent_tool_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('AppSubAgentCatalog', () {
    test('lists all enabled agents with types', () async {
      final repository = _MockAgentsRepository();
      final now = DateTime(2026);
      when(() => repository.getAgentsByWorkspace('workspace-1')).thenAnswer(
        (_) async => [
          _agent(
            id: 'main',
            now: now,
            visibility: AgentVisibility.chatSelector,
          ),
          _agent(id: 'sub', now: now, visibility: AgentVisibility.subAgentList),
          _agent(id: 'both', now: now, visibility: AgentVisibility.both),
          _agent(
            id: 'off',
            now: now,
            visibility: AgentVisibility.both,
            isEnabled: false,
          ),
        ],
      );

      final agents = await AppSubAgentCatalog(repository)
          .listSubAgents('workspace-1');

      expect(agents.map((agent) => agent.id), ['main', 'sub', 'both']);
      expect(agents.map((agent) => agent.types), [
        ['main'],
        ['sub_agent'],
        ['main', 'sub_agent'],
      ]);
    });

    test('gets only enabled sub-agent-list agents', () async {
      final repository = _MockAgentsRepository();
      final now = DateTime(2026);
      when(() => repository.getAgentById('sub')).thenAnswer(
        (_) async => _agent(
          id: 'sub',
          now: now,
          visibility: AgentVisibility.subAgentList,
        ),
      );
      when(() => repository.getAgentById('main')).thenAnswer(
        (_) async => _agent(
          id: 'main',
          now: now,
          visibility: AgentVisibility.chatSelector,
        ),
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

      final child = await store.createChildConversation(
        parentConversationId: 'parent',
        workspaceId: 'workspace-1',
        modelId: 'model-1',
        agentId: 'agent-1',
        title: 'Task',
      );

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
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
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
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
  );
}

class _MockConversationRepository extends Mock
    implements ConversationRepository;

class _MockMessageRepository extends Mock implements MessageRepository;
