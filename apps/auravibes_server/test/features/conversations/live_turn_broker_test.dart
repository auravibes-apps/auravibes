import 'package:auravibes_server/src/features/conversations/live_turn_broker.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('uses a workspace-turn scoped channel', () {
    expect(LiveTurnBroker.channel(7, 'turn-1'), 'auravibes.live-turn.7.turn-1');
  });

  test('enables cross-instance fanout only with Redis', () {
    expect(LiveTurnBroker.usesGlobalFanout(redisEnabled: false), isFalse);
    expect(LiveTurnBroker.usesGlobalFanout(redisEnabled: true), isTrue);
  });

  test('serializes typed ephemeral event states', () {
    final event = LiveTurnEvent(
      workspaceId: 7,
      turnId: 'turn-1',
      sequence: 2,
      kind: LiveTurnEventKind.text,
      text: 'Hello',
    );

    expect(LiveTurnEvent.fromJson(event.toJson()).toJson(), event.toJson());
    expect(
      LiveTurnEventKind.values,
      contains(LiveTurnEventKind.awaitingApproval),
    );
    expect(LiveTurnEventKind.values, contains(LiveTurnEventKind.cancelled));
  });
}
