import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:test/test.dart';

void main() {
  group('AgentContinuationPreparer', () {
    test('loads model, prompt context, and tools', () async {
      final usecase = _usecase();

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.model.id, 'model-1');
      expect(result.chatHistory.map((message) => message.content), [
        'skill context',
        'hello',
      ]);
      expect(result.enabledTools, ['calculator']);
      expect(result.messagesCount, 1);
    });

    test('disables tools when selected model cannot use them', () async {
      final usecase = _usecase(
        loadSelectedModel: (_) async =>
            const _Model('model-1', supportsToolCalls: false),
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.enabledTools, isEmpty);
    });

    test('throws when conversation has no model id', () async {
      final usecase = _usecase(
        loadConversation: (_) async => const AgentConversationReference(
          workspaceId: 'workspace-1',
          modelId: null,
        ),
      );

      await expectLater(
        usecase.call(conversationId: 'conversation-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

AgentContinuationPreparer<_Model, String, _Chat, String> _usecase({
  Future<AgentConversationReference?> Function(String conversationId)?
  loadConversation,
  Future<_Model?> Function(String modelId)? loadSelectedModel,
}) {
  return AgentContinuationPreparer<_Model, String, _Chat, String>(
    provider: _FakeAgentContinuationProvider(
      loadConversation ??
          (_) async => const AgentConversationReference(
            workspaceId: 'workspace-1',
            modelId: 'model-1',
          ),
      loadSelectedModel ??
          (_) async => const _Model('model-1', supportsToolCalls: true),
    ),
  );
}

class _FakeAgentContinuationProvider
    implements AgentContinuationProvider<_Model, String, _Chat, String> {
  const _FakeAgentContinuationProvider(
    this._loadConversation,
    this._loadSelectedModel,
  );

  final Future<AgentConversationReference?> Function(String conversationId)
  _loadConversation;
  final Future<_Model?> Function(String modelId) _loadSelectedModel;

  @override
  Future<AgentConversationReference?> loadConversation(String conversationId) {
    return _loadConversation(conversationId);
  }

  @override
  Future<_Model?> loadSelectedModel(String modelId) {
    return _loadSelectedModel(modelId);
  }

  @override
  Future<_Model> projectSelectedModel(_Model model) async => model;

  @override
  Future<List<String>> selectPromptMessages(String conversationId) async {
    return ['hello'];
  }

  @override
  Future<List<_Chat>> buildSkillContextMessages({
    required String conversationId,
    required String workspaceId,
  }) async {
    return [const _Chat('skill context', isSkillContext: true)];
  }

  @override
  Future<List<String>> loadTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    return ['calculator'];
  }

  @override
  List<_Chat> buildChatHistory({
    required List<String> messages,
    required List<_Chat> skillContextMessages,
  }) {
    return [...skillContextMessages, ...messages.map(_Chat.new)];
  }

  @override
  bool shouldDisableTools(_Model model) => !model.supportsToolCalls;

  @override
  bool isSystemMessage(_Chat message) => message.isSystem;

  @override
  bool isSkillContextMessage(_Chat message) => message.isSkillContext;

  @override
  bool isUserMessage(_Chat message) {
    return !message.isSystem && !message.isSkillContext;
  }
}

class _Model {
  const _Model(this.id, {required this.supportsToolCalls});

  final String id;
  final bool supportsToolCalls;
}

class _Chat {
  const _Chat(
    this.content, {
    this.isSystem = false,
    this.isSkillContext = false,
  });

  final String content;
  final bool isSystem;
  final bool isSkillContext;
}
