import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/tool_call_actions.dart';
import 'package:test/test.dart';

void main() {
  group('ApproveToolCallService', () {
    test('marks unresolved tool as not found and resumes', () async {
      final provider = _FakeApproveToolCallProvider(resolvedTool: null);
      final usecase = ApproveToolCallService<String>(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        conversationId: 'conversation-1',
        level: .once,
      );

      expect(provider.updates, [AgentToolResultStatus.toolNotFound]);
      expect(provider.didResume, isTrue);
    });

    test('marks unresolved nested skill command as not configured', () async {
      final provider = _FakeApproveToolCallProvider(
        resolvedTool: null,
        toolName: callSkillToolName,
      );
      final usecase = ApproveToolCallService<String>(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        level: .once,
      );

      expect(provider.updates, [AgentToolResultStatus.notConfigured]);
      expect(provider.didResume, isTrue);
    });

    test('grants conversation permission before running tool', () async {
      final provider = _FakeApproveToolCallProvider(
        resolvedTool: 'calculator',
        runResult: '2',
      );
      final usecase = ApproveToolCallService<String>(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        conversationId: 'conversation-1',
        level: .conversation,
      );

      expect(provider.calls, [
        'resolve:conversation-1:calculator:{"input": "1+1"}',
        'grant:conversation-1:calculator',
        'running:message-1:tool-1',
        'run:1+1',
        'update:AgentToolResultStatus.success:2',
        'resume:message-1',
      ]);
    });

    test('does not resume after cancelled execution', () async {
      final provider = _FakeApproveToolCallProvider(
        resolvedTool: 'calculator',
        runResult: '2',
        isCancelled: true,
      );
      final usecase = ApproveToolCallService<String>(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        conversationId: 'conversation-1',
        level: .once,
      );

      expect(provider.didResume, isFalse);
    });

    test('resumes after execution error', () async {
      final provider = _FakeApproveToolCallProvider(
        resolvedTool: 'calculator',
        runError: StateError('blocked'),
      );
      final usecase = ApproveToolCallService<String>(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        conversationId: 'conversation-1',
        level: .once,
      );

      expect(provider.updates, [AgentToolResultStatus.executionError]);
      expect(provider.didResume, isTrue);
    });
  });

  group('SkipToolCallService', () {
    test('skips then resumes when mutation succeeds', () async {
      final provider = _FakeSkipToolCallProvider(shouldSkip: true);
      final usecase = SkipToolCallService(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        conversationId: 'conversation-1',
      );

      expect(provider.calls, ['skip:message-1:tool-1', 'resume:message-1']);
    });

    test('does not resume when mutation is skipped', () async {
      final provider = _FakeSkipToolCallProvider(shouldSkip: false);
      final usecase = SkipToolCallService(provider: provider);

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        conversationId: 'conversation-1',
      );

      expect(provider.didResume, isFalse);
    });
  });
}

class _FakeApproveToolCallProvider({
  required final String? resolvedTool,
  final Object? runResult,
  final Object? runError,
  final bool isCancelled = false,
  final String toolName = 'calculator',
}) implements ApproveToolCallProvider<String> {
  final calls = <String>[];
  final updates = <AgentToolResultStatus>[];
  bool didResume = false;

  @override
  Future<AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) async {
    return AgentApprovableToolCall(
      conversationId: 'conversation-1',
      name: toolName,
      argumentsRaw: '{"input": "1+1"}',
    );
  }

  @override
  Future<String?> resolveTool({
    required String conversationId,
    required String toolName,
    required String argumentsRaw,
  }) async {
    calls.add('resolve:$conversationId:$toolName:$argumentsRaw');

    return resolvedTool;
  }

  @override
  Future<void> grantToolForConversation({
    required String conversationId,
    required String tool,
  }) async {
    calls.add('grant:$conversationId:$tool');
  }

  @override
  Future<Object?> runResolvedTool({
    required String conversationId,
    required String tool,
    required Map<String, dynamic> arguments,
  }) async {
    calls.add('run:${arguments['input']}');
    final error = runError;
    if (error is Exception) throw error;
    if (error is Error) throw error;

    return runResult;
  }

  @override
  Future<void> markToolCallRunning({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) async {
    calls.add('running:$messageId:$toolCallId');
  }

  @override
  Future<void> updateToolCallResult(
    AgentToolCallResultUpdateRequest request,
  ) async {
    updates.add(request.resultStatus);
    calls.add('update:${request.resultStatus}:${request.responseRaw}');
  }

  @override
  Future<void> resumeConversationIfReady({
    required String messageId,
    required String conversationId,
  }) async {
    didResume = true;
    calls.add('resume:$messageId');
  }

  @override
  bool isCancellationRequested(String conversationId) => isCancelled;

  @override
  void logToolExecutionError(AgentToolExecutionErrorRequest<String> request) {}
}

class _FakeSkipToolCallProvider({required final bool shouldSkip})
    implements SkipToolCallProvider {
  final calls = <String>[];
  bool didResume = false;

  @override
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
    required String conversationId,
  }) async {
    calls.add('skip:$messageId:$toolCallId');

    return shouldSkip;
  }

  @override
  Future<void> resumeConversationIfReady({
    required String messageId,
    required String conversationId,
  }) async {
    didResume = true;
    calls.add('resume:$messageId');
  }
}
