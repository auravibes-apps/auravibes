// ignore_for_file: type=lint, type=warning
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies a transient assistant delta at its current sequence', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );

    final applied = state.apply(_event(sequence: 4, delta: 'R2'))!;
    final completed = applied.apply(_event(sequence: 4, delta: 'R3'))!;

    expect(completed.sequence, 4);
    expect(completed.activeAssistantContent, 'R1R2R3');
    expect(state.apply(_event(sequence: 6, delta: 'skipped')), isNull);
  });

  test('A2UI progress does not change projected assistant text', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    const payload =
        '{"assistantMessageId":"assistant-1","message":{"version":"v0.9"}}';
    final event = ConversationStreamEvent(
      workspaceId: 7,
      conversationId: 'conversation-1',
      sequence: 4,
      kind: ConversationEventType.a2uiMessage,
      actorUserId: 'system',
      payloadJson: payload,
      createdAt: DateTime.utc(2026),
    );

    final applied = state.apply(event)!;

    expect(applied.activeAssistantContent, isEmpty);
    expect(applied.messages.single.content, 'R1');
  });

  test('durable snapshot replaces active transient content', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    final streaming = state.apply(_event(sequence: 4, delta: 'R2'))!;
    final committed = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 5, assistantContent: 'R1R2'),
    );

    expect(streaming.activeAssistantContent, 'R1R2');
    expect(committed.activeAssistantContent, isEmpty);
    expect(committed.messages.single.content, 'R1R2');
  });

  test('ignores a duplicated transient event', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    final event = _event(sequence: 4, delta: 'R2', eventId: 'event-1');

    final applied = state.apply(event)!;
    final duplicate = applied.apply(event)!;

    expect(applied.activeAssistantContent, 'R1R2');
    expect(duplicate.activeAssistantContent, 'R1R2');
  });

  test('clears transient event keys after a durable event', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    final streaming = state.apply(
      _event(sequence: 4, delta: 'R2', eventId: 'event-1'),
    )!;
    final durable = streaming.apply(_event(sequence: 5))!;

    expect(streaming.appliedTransientEventKeys, {'event-1'});
    expect(durable.appliedTransientEventKeys, isEmpty);
  });

  test('projects active content by replacement, not append', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    ).apply(_event(sequence: 4, delta: 'R2'))!;

    final messages = readCloudConversationMessagesForTesting(state);

    expect(messages.single.content, 'R1R2');
  });

  test(
    'recovers its snapshot when a stream event has a sequence gap',
    () async {
      var snapshots = 0;
      final states = CloudConversationStream.watch(
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

  test('projects A2UI progress without advancing durable sequence', () {
    final state = CloudConversationState.fromSnapshot(_snapshot(sequence: 4));
    const payload =
        '{"assistantMessageId":"assistant-1","message":{"version":"v0.9"}}';
    final event = ConversationStreamEvent(
      workspaceId: 7,
      conversationId: 'conversation-1',
      sequence: 4,
      kind: ConversationEventType.a2uiMessage,
      actorUserId: 'system',
      payloadJson: payload,
      createdAt: DateTime.utc(2026),
    );

    final applied = state.apply(event);
    final duplicate = applied?.apply(event);

    expect(applied?.sequence, 4);
    expect(applied?.a2uiMessagesByAssistantMessageId['assistant-1'], [payload]);
    expect(duplicate?.a2uiMessagesByAssistantMessageId['assistant-1'], [
      payload,
    ]);
  });

  test('hides live A2UI progress while cloud execution is running', () {
    final state = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    const payload =
        '{"assistantMessageId":"assistant-1","message":{"version":"v0.9"}}';
    final event = ConversationStreamEvent(
      workspaceId: 7,
      conversationId: 'conversation-1',
      sequence: 4,
      kind: ConversationEventType.a2uiMessage,
      actorUserId: 'system',
      payloadJson: payload,
      createdAt: DateTime.utc(2026),
    );

    final applied = state.apply(event)!;

    expect(
      readCloudConversationMessagesForTesting(applied)
          .single
          .metadata
          ?.a2uiMessages,
      isEmpty,
    );
  });

  test('drops transient A2UI after a newer authoritative snapshot', () {
    final initial = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    const payload =
        '{"assistantMessageId":"assistant-1",'
        '"message":{"version":"v0.9","updateComponents":{'
        '"surfaceId":"main","components":[]}}}';
    final event = ConversationStreamEvent(
      workspaceId: 7,
      conversationId: 'conversation-1',
      sequence: 4,
      kind: ConversationEventType.a2uiMessage,
      actorUserId: 'system',
      payloadJson: payload,
      createdAt: DateTime.utc(2026),
    );
    final streaming = initial.apply(event)!;
    final completed = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 5, assistantContent: 'R1'),
    ).preserveTransientA2uiFrom(streaming);

    expect(completed.a2uiMessagesByAssistantMessageId['assistant-1'], isNull);
  });

  test('preserves create-before-update order across snapshots', () {
    final base = CloudConversationState.fromSnapshot(
      _snapshot(sequence: 4, assistantContent: 'R1'),
    );
    const create = '{"assistantMessageId":"assistant-1","create":true}';
    const update = '{"assistantMessageId":"assistant-1","update":true}';
    final previous = base.apply(_a2uiEvent(create))!;
    final current = base.apply(_a2uiEvent(update))!;

    final merged = current.preserveTransientA2uiFrom(previous);

    expect(merged.a2uiMessagesByAssistantMessageId['assistant-1'], [
      create,
      update,
    ]);
  });

  test('preserves transient A2UI when the stream reconnects', () async {
    var snapshotCount = 0;
    const payload = '{"assistantMessageId":"assistant-1","create":true}';
    final states = CloudConversationStream.watch(
      _gateway(
        snapshots: () {
          snapshotCount++;
          return _snapshot(sequence: 4, assistantContent: 'R1');
        },
        events: (_) => snapshotCount == 1
            ? Stream.value(_a2uiEvent(payload))
            : const Stream.empty(),
      ),
      (workspaceId: 'local', conversationId: 'conversation-1'),
      delay: (_) => Future<void>.value(),
    ).take(3);

    final values = await states.toList();

    expect(values.last.a2uiMessagesByAssistantMessageId['assistant-1'], [
      payload,
    ]);
  });
}

ConversationStreamEvent _a2uiEvent(String payload) => ConversationStreamEvent(
  workspaceId: 7,
  conversationId: 'conversation-1',
  sequence: 4,
  kind: ConversationEventType.a2uiMessage,
  actorUserId: 'system',
  payloadJson: payload,
  createdAt: DateTime.utc(2026),
);

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

ConversationSnapshot _snapshot({
  required int sequence,
  String? assistantContent,
}) {
  final now = DateTime.utc(2026);
  const assistantMessageId = 'assistant-1';
  final hasAssistant = assistantContent != null;

  return ConversationSnapshot(
    conversation: ConversationProjectionView(
      id: 'conversation-1',
      workspaceId: 7,
      executionState: hasAssistant ? 'running' : 'idle',
      projectionRevision: sequence,
      sequence: sequence,
      updatedAt: now,
    ),
    messages: hasAssistant
        ? [
            ConversationMessageView(
              id: assistantMessageId,
              conversationId: 'conversation-1',
              role: 'assistant',
              kind: 'text',
              status: 'running',
              content: assistantContent,
              toolCalls: const [],
              revision: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ]
        : const [],
    pendingMessages: const [],
    toolCalls: const [],
    sequence: sequence,
    activeExecution: hasAssistant
        ? ConversationExecutionView(
            id: 'execution-1',
            status: 'running',
            attempt: 1,
            claimedMessageIds: const [],
            assistantMessageId: assistantMessageId,
            createdByUserId: 'user-1',
            createdAt: now,
            updatedAt: now,
          )
        : null,
  );
}

ConversationStreamEvent _event({
  required int sequence,
  String? delta,
  String? eventId,
}) => ConversationStreamEvent(
  workspaceId: 7,
  conversationId: 'conversation-1',
  sequence: sequence,
  eventId: eventId,
  kind: ConversationEventType.executionStateChanged,
  actorUserId: 'user-1',
  payloadJson: '{}',
  transientTextDelta: delta,
  createdAt: DateTime.utc(2026),
);
