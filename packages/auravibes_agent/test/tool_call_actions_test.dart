import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/tool_call_actions.dart';
import 'package:test/test.dart';

void main() {
  group('ApproveToolCallService', () {
    test('marks unresolved tool as not found and resumes', () async {
      final provider = _FakeApproveToolCallProvider(resolvedTool: null);
      final usecase = ApproveToolCallService<String>(
        provider: provider,
      );

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        level: AgentToolGrantLevel.once,
      );

      expect(provider.updates, [AgentToolResultStatus.toolNotFound]);
      expect(provider.didResume, isTrue);
    });

    test('grants conversation permission before running tool', () async {
      final provider = _FakeApproveToolCallProvider(
        resolvedTool: 'calculator',
        runResult: '2',
      );
      final usecase = ApproveToolCallService<String>(
        provider: provider,
      );

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        level: AgentToolGrantLevel.conversation,
      );

      expect(provider.calls, [
        'grant:conversation-1:calculator',
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
      final usecase = ApproveToolCallService<String>(
        provider: provider,
      );

      await usecase.call(
        messageId: 'message-1',
        toolCallId: 'tool-1',
        level: AgentToolGrantLevel.once,
      );

      expect(provider.didResume, isFalse);
    });
  });

  group('SkipToolCallService', () {
    test('skips then resumes when mutation succeeds', () async {
      final provider = _FakeSkipToolCallProvider(shouldSkip: true);
      final usecase = SkipToolCallService(
        provider: provider,
      );

      await usecase.call(messageId: 'message-1', toolCallId: 'tool-1');

      expect(provider.calls, ['skip:message-1:tool-1', 'resume:message-1']);
    });

    test('does not resume when mutation is skipped', () async {
      final provider = _FakeSkipToolCallProvider(shouldSkip: false);
      final usecase = SkipToolCallService(
        provider: provider,
      );

      await usecase.call(messageId: 'message-1', toolCallId: 'tool-1');

      expect(provider.didResume, isFalse);
    });
  });
}

class _FakeApproveToolCallProvider implements ApproveToolCallProvider<String> {
  _FakeApproveToolCallProvider({
    required this.resolvedTool,
    this.runResult,
    this.isCancelled = false,
  });

  final String? resolvedTool;
  final Object? runResult;
  final bool isCancelled;
  final calls = <String>[];
  final updates = <AgentToolResultStatus>[];
  bool didResume = false;

  @override
  Future<AgentApprovableToolCall?> loadToolCall({
    required String messageId,
    required String toolCallId,
  }) async {
    return const AgentApprovableToolCall(
      conversationId: 'conversation-1',
      name: 'calculator',
      argumentsRaw: '{"input": "1+1"}',
    );
  }

  @override
  String? resolveTool(String toolName) => resolvedTool;

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

    return runResult;
  }

  @override
  Future<void> updateToolCallResult({
    required String messageId,
    required String toolCallId,
    required AgentToolResultStatus resultStatus,
    String? responseRaw,
  }) async {
    updates.add(resultStatus);
    calls.add('update:$resultStatus:$responseRaw');
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) async {
    didResume = true;
    calls.add('resume:$messageId');
  }

  @override
  bool isCancellationRequested(String conversationId) => isCancelled;

  @override
  void logToolExecutionError({
    required String conversationId,
    required String toolCallId,
    required String tool,
    required Object error,
    required StackTrace stackTrace,
  }) {}
}

class _FakeSkipToolCallProvider implements SkipToolCallProvider {
  _FakeSkipToolCallProvider({required this.shouldSkip});

  final bool shouldSkip;
  final calls = <String>[];
  bool didResume = false;

  @override
  Future<bool> skipToolCall({
    required String messageId,
    required String toolCallId,
  }) async {
    calls.add('skip:$messageId:$toolCallId');

    return shouldSkip;
  }

  @override
  Future<void> resumeConversationIfReady({required String messageId}) async {
    didResume = true;
    calls.add('resume:$messageId');
  }
}
