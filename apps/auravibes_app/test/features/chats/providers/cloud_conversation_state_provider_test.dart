import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_state_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies a transient assistant delta at its current sequence', () {
    final state = CloudConversationState.fromSnapshot(_snapshot(sequence: 4));

    final applied = state.apply(_event(sequence: 4, delta: 'hello'));

    expect(applied?.sequence, 4);
    expect(applied?.activeAssistantContent, 'hello');
    expect(state.apply(_event(sequence: 6, delta: 'skipped')), isNull);
  });

  test(
    'recovers its snapshot when a stream event has a sequence gap',
    () async {
      var snapshots = 0;
      final states = watchCloudConversation(
        _gateway(
          snapshots: () => _snapshot(sequence: snapshots++ == 0 ? 4 : 8),
          events: (_) => Stream.value(_event(sequence: 7)),
        ),
        (workspaceId: 'local', conversationId: 'conversation-1'),
        delay: (_) => Future<void>.value(),
      ).take(2);

      expect(await states.map((state) => state.sequence).toList(), [4, 8]);
    },
  );
}

CloudChatGateway _gateway({
  required ConversationSnapshot Function() snapshots,
  required Stream<ConversationStreamEvent> Function(
    ConversationSubscribeRequest request,
  )
  events,
}) {
  final stateGateway = CloudWorkspaceStateGateway.forTesting(
    workspace: _workspace,
    readState: (_) => throw UnimplementedError(),
    subscribe: (_) => const Stream.empty(),
  );

  return CloudChatGateway.forConversationTesting(
    stateGateway: stateGateway,
    subscribeConversation: events,
    getConversationSnapshot: (_) async => snapshots(),
  );
}

const _workspace = CloudWorkspaceRef(
  localWorkspaceId: 'local',
  serverUrl: 'https://example.com',
  accountId: 'account',
  cloudWorkspaceId: 7,
);

ConversationSnapshot _snapshot({required int sequence}) {
  final now = DateTime.utc(2026);

  return ConversationSnapshot(
    conversation: ConversationProjectionView(
      id: 'conversation-1',
      workspaceId: 7,
      executionState: 'idle',
      projectionRevision: sequence,
      sequence: sequence,
      updatedAt: now,
    ),
    messages: const [],
    pendingMessages: const [],
    toolCalls: const [],
    sequence: sequence,
  );
}

ConversationStreamEvent _event({required int sequence, String? delta}) =>
    ConversationStreamEvent(
      workspaceId: 7,
      conversationId: 'conversation-1',
      sequence: sequence,
      kind: ConversationEventType.executionStateChanged,
      actorUserId: 'user-1',
      payloadJson: '{}',
      transientTextDelta: delta,
      createdAt: DateTime.utc(2026),
    );
