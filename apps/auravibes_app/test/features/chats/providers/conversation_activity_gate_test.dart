import 'package:auravibes_app/features/chats/providers/conversation_activity_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationActivityGate', () {
    test('runActivity releases activity when action fails', () async {
      final gate = ConversationActivityGate();

      await expectLater(
        gate.runActivity<void>('conversation', () async {
          throw StateError('failed');
        }),
        throwsStateError,
      );

      expect(gate.tryBeginCheckpointRestore('conversation'), isTrue);
      gate.endCheckpointRestore('conversation');
    });

    test('runActivities holds and releases every conversation', () async {
      final gate = ConversationActivityGate();

      await gate.runActivities<void>(['root', 'child'], () {
        expect(gate.tryBeginCheckpointRestore('root'), isFalse);
        expect(gate.tryBeginCheckpointRestore('child'), isFalse);

        return .value();
      });

      expect(gate.tryBeginCheckpointRestore('root'), isTrue);
      gate.endCheckpointRestore('root');
      expect(gate.tryBeginCheckpointRestore('child'), isTrue);
      gate.endCheckpointRestore('child');
    });

    test(
      'runCheckpointRestore releases reservation when action fails',
      () async {
        final gate = ConversationActivityGate();

        await expectLater(
          gate.runCheckpointRestore<void>('conversation', () async {
            throw StateError('failed');
          }),
          throwsStateError,
        );

        expect(gate.tryBeginActivity('conversation'), isTrue);
        gate.endActivity('conversation');
      },
    );
  });
}
