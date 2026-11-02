import 'dart:async';

import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_cancellation.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancelling one concurrent invocation preserves its sibling and conversation', () async {
    final runtime = AgentCancellationRuntime();
    addTearDown(runtime.dispose);
    final adapter = ScopedVerificationCancellation(runtime);
    final first = Completer<ScopedVerificationResult>();
    final second = Completer<ScopedVerificationResult>();
    final scopes = <AgentCancellationScope>[];
    final a = adapter.run(_invocation('one'), (scope) {
      scopes.add(scope);
      final _ = scope.registerCleanup(() => first.complete(ScopedVerificationResult(outcome: .cancelled, reason: 'cancelled')));
      return first.future;
    });
    final b = adapter.run(_invocation('two'), (scope) { scopes.add(scope); return second.future; });
    final handle = runtime.toolCancellationHandle(conversationId: 'chat', toolCallId: 'one');
    expect(await handle?.requestCancellation(), isTrue);
    expect((await a).outcome, ScopedVerificationOutcome.cancelled);
    expect(scopes[1].isCancellationRequested, isFalse);
    expect(runtime.current('chat')?.isCancellationRequested, isFalse);
    expect(second.isCompleted, isFalse);
    second.complete(ScopedVerificationResult(outcome: .pass, reason: 'zero_exit'));
    expect((await b).outcome, ScopedVerificationOutcome.pass);
    expect(runtime.current('chat'), isNull);
  });

  test('conversation stop fans out without releasing a foreground-owned scope', () async {
    final runtime = AgentCancellationRuntime();
    addTearDown(runtime.dispose);
    final foreground = runtime.start('chat');
    final adapter = ScopedVerificationCancellation(runtime);
    final scopes = <AgentCancellationScope>[];
    Future<ScopedVerificationResult> execute(AgentCancellationScope scope) {
      scopes.add(scope);
      final completion = Completer<ScopedVerificationResult>();
      final _ = scope.registerCleanup(() => completion.complete(ScopedVerificationResult(outcome: .cancelled, reason: 'cancelled')));
      return completion.future;
    }
    final a = adapter.run(_invocation('one'), execute);
    final b = adapter.run(_invocation('two'), execute);
    runtime.requestStop('chat');
    expect((await a).outcome, ScopedVerificationOutcome.cancelled);
    expect((await b).outcome, ScopedVerificationOutcome.cancelled);
    expect(scopes.every((scope) => scope.isCancellationRequested), isTrue);
    expect(runtime.current('chat'), same(foreground));
    runtime.clear('chat', foreground);
  });
}

({String conversationId, String toolCallId, ResolvedTool tool}) _invocation(String id) => (conversationId: 'chat', toolCallId: id, tool: ResolvedTool.mcp(tableId: 'edit', toolIdentifier: 'edit_file', mcp: (mcpServerId: 'server', mcpSlug: 'server', outputSchemaJson: null)));
