import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/tool_resume_service.dart';
import 'package:test/test.dart';

void main() {
  test('returns when no resume reference exists', () async {
    final provider = _FakeResumeProvider(reference: null);
    final service = AgentToolResumeService(provider: provider);

    await service.call(messageId: 'm1');

    expect(provider.calls, ['reference:m1']);
  });

  test('runs allowed tools without continuing when decision is done', () async {
    final provider = _FakeResumeProvider();
    final service = AgentToolResumeService(provider: provider);

    await service.call(messageId: 'm1');

    expect(provider.calls, ['reference:m1', 'tools:c1:w1']);
  });

  test('continues agent when allowed tools request another turn', () async {
    final provider = _FakeResumeProvider(
      decision: AgentIterationDecision.continueIteration,
    );
    final service = AgentToolResumeService(provider: provider);

    await service.call(messageId: 'm1');

    expect(provider.calls, ['reference:m1', 'tools:c1:w1', 'continue:c1']);
    expect(provider.contexts.single.origin, AgentIterationOrigin.toolResume);
  });
}

class _FakeResumeProvider implements AgentToolResumeProvider {
  _FakeResumeProvider({
    this.reference = const AgentToolResumeReference(
      conversationId: 'c1',
      workspaceId: 'w1',
    ),
    this.decision = AgentIterationDecision.done,
  });

  final AgentToolResumeReference? reference;
  final AgentIterationDecision decision;
  final calls = <String>[];
  final contexts = <AgentIterationContext>[];

  @override
  Future<AgentToolResumeReference?> getResumeReference(String messageId) async {
    calls.add('reference:$messageId');

    return reference;
  }

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    calls.add('tools:$conversationId:$workspaceId');

    return decision;
  }

  @override
  Future<void> continueAgent({
    required String conversationId,
    required AgentIterationContext context,
  }) async {
    calls.add('continue:$conversationId');
    contexts.add(context);
  }
}
