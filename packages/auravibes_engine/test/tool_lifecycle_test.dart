import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/tool_execution_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  test('lifecycle exposes pending, resolved, stop, and valid transitions', () {
    expect(AgentToolCallLifecycle.pending.isPending, isTrue);
    expect(AgentToolCallLifecycle.pending.isResolved, isFalse);
    expect(
      AgentToolCallLifecycle.pending.canTransitionTo(
        AgentToolCallLifecycle.success,
      ),
      isTrue,
    );
    expect(
      AgentToolCallLifecycle.success.canTransitionTo(
        AgentToolCallLifecycle.failed,
      ),
      isFalse,
    );
    expect(AgentToolCallLifecycle.stoppedByUser.stopsAgentLoop, isTrue);
  });

  test('result statuses preserve lifecycle and model fallback semantics', () {
    const expectedFallbacks = {
      AgentToolResultStatus.success: '',
      AgentToolResultStatus.toolNotFound: 'Tool not found.',
      AgentToolResultStatus.executionError: 'Tool execution failed.',
      AgentToolResultStatus.disabledInConversation:
          'Tool is disabled for this conversation.',
      AgentToolResultStatus.disabledByAgent:
          'Tool is denied by the selected agent.',
      AgentToolResultStatus.disabledInWorkspace:
          'Tool is disabled in workspace.',
      AgentToolResultStatus.notConfigured: 'Tool is not configured.',
      AgentToolResultStatus.stoppedByUser:
          'Tool execution was stopped by the user.',
    };

    for (final MapEntry(key: status, value: fallback)
        in expectedFallbacks.entries) {
      expect(status.modelFallback, fallback);
    }
    expect(
      AgentToolResultStatus.stoppedByUser.lifecycle,
      AgentToolCallLifecycle.stoppedByUser,
    );
    expect(
      AgentToolResultStatus.disabledByAgent.lifecycle,
      AgentToolCallLifecycle.failed,
    );
  });
}
