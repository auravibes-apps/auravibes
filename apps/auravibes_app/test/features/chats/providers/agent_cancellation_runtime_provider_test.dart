import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentCancellationRuntime', () {
    test(
      'does not create a cancellation entry when stopping inactive runs',
      () {
        final runtime = AgentCancellationRuntime();

        runtime.requestStop('conversation-1');

        expect(runtime.isCancellationRequested('conversation-1'), isFalse);
      },
    );

    test('keeps existing cleanups when start is called twice', () {
      final runtime = AgentCancellationRuntime();
      var cleanupCount = 0;

      runtime
        ..start('conversation-1')
        ..registerCleanup('conversation-1', () {
          cleanupCount += 1;
        })
        ..start('conversation-1')
        ..requestStop('conversation-1');

      expect(cleanupCount, 1);
      expect(runtime.isCancellationRequested('conversation-1'), isTrue);
    });
  });
}
