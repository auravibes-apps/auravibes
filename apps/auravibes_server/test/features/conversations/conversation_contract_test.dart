import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('legacy execution requests decode without capability fields', () {
    final base = {
      'workspaceId': 1,
      'requestId': 'request',
      'conversationId': 'conversation',
      'expectedConversationRevision': 1,
      'expectedProjectionRevision': 1,
      'clientMessageId': 'message',
      'content': 'Hello',
      'attachmentIds': <String>[],
      'turnId': 'turn',
      'toolCallId': 'tool',
      'argumentsDigest': 'digest',
      'expectedTurnRevision': 1,
      'decision': 'approve',
      'stopAll': false,
    };
    for (final components in <List<String>?>[
      null,
      ['Text', 'Badge'],
    ]) {
      final json = {
        ...base,
        'a2uiSupportedComponents': ?components,
      };
      final start = StartTurnRequest.fromJson(json);
      final turn = ContinueTurnRequest.fromJson(json);
      final conversation = ContinueConversationRequest.fromJson(json);
      final decision = SubmitToolDecisionRequest.fromJson(json);
      expect(
        StartTurnRequest.fromJson(start.toJson()).a2uiSupportedComponents,
        components,
      );
      expect(
        ContinueTurnRequest.fromJson(turn.toJson()).a2uiSupportedComponents,
        components,
      );
      expect(
        ContinueConversationRequest.fromJson(conversation.toJson())
            .a2uiSupportedComponents,
        components,
      );
      expect(
        SubmitToolDecisionRequest.fromJson(decision.toJson())
            .a2uiSupportedComponents,
        components,
      );
      if (components == null) {
        expect(start.toJson(), isNot(contains('a2uiSupportedComponents')));
      }
    }
  });

  test('turn job payload retains the initiating user', () {
    expect(
      conversationTurnJobPayload('user-1'),
      '{"actorUserId":"user-1"}',
    );
  });

  test('conversation wire contract uses stable ids and revisions', () {
    final request = StartTurnRequest(
      workspaceId: 1,
      requestId: 'turn-1',
      conversationId: 'conversation-1',
      expectedConversationRevision: 3,
      clientMessageId: 'message-1',
      content: 'hello',
      attachmentIds: ['42'],
    );
    final result = StartTurnResult(
      turnId: 'turn-1',
      userMessageId: 'message-1',
      assistantMessageId: 'turn-1:assistant',
      acceptedSequence: 4,
      turnRevision: 1,
      status: 'queued',
    );

    expect(request.conversationId, 'conversation-1');
    expect(request.attachmentIds, ['42']);
    expect(result.turnId, 'turn-1');
    expect(result.turnRevision, 1);
  });

  test('conversation summary carries all mutable metadata', () {
    final now = DateTime.utc(2026);
    final summary = ConversationSummary(
      id: 'conversation-1',
      title: 'Title',
      isPinned: true,
      modelId: 'model-1',
      agentId: 'agent-1',
      parentConversationId: 'parent-1',
      revision: 7,
      createdAt: now,
      updatedAt: now,
    );

    expect(summary.toJson()['revision'], 7);
    expect(summary.toJson()['parentConversationId'], 'parent-1');
  });

  test('conversation stream event retains sequence and actor attribution', () {
    final now = DateTime.utc(2026);
    final event = ConversationStreamEvent(
      workspaceId: 1,
      conversationId: 'conversation-1',
      sequence: 7,
      kind: ConversationEventType.messageQueued,
      actorUserId: 'member-1',
      payloadJson: '{"messageId":"message-1"}',
      createdAt: now,
    );

    final decoded = ConversationStreamEvent.fromJson(event.toJson());

    expect(decoded.sequence, 7);
    expect(decoded.actorUserId, 'member-1');
    expect(decoded.kind, ConversationEventType.messageQueued);
  });

  test('conversation page cursor keeps updatedAt and stableId tie break', () {
    final page = ConversationPage(
      conversations: const [],
      nextCursor: 'opaque-cursor',
    );
    final request = ListConversationsRequest(
      workspaceId: 1,
      limit: 20,
      cursor: page.nextCursor,
    );

    expect(request.cursor, 'opaque-cursor');
    expect(page.nextCursor, 'opaque-cursor');
  });

  test('mutation requests retain request IDs for idempotency', () {
    final create = CreateConversationRequest(
      workspaceId: 1,
      requestId: 'create-1',
      conversationId: 'conversation-1',
      title: 'Title',
      isPinned: false,
    );
    final update = UpdateConversationRequest(
      workspaceId: 1,
      requestId: 'update-1',
      conversationId: 'conversation-1',
      expectedRevision: 1,
      clearModel: false,
      clearAgent: false,
      clearParent: false,
    );
    final delete = DeleteConversationRequest(
      workspaceId: 1,
      requestId: 'delete-1',
      conversationId: 'conversation-1',
      expectedRevision: 2,
    );

    expect(create.toJson()['requestId'], 'create-1');
    expect(update.toJson()['requestId'], 'update-1');
    expect(delete.toJson()['requestId'], 'delete-1');
  });

  test('tool decision carries client-observed arguments digest', () {
    final request = SubmitToolDecisionRequest(
      workspaceId: 1,
      requestId: 'decision-1',
      turnId: 'turn-1',
      toolCallId: 'call-1',
      argumentsDigest: 'observed-digest',
      expectedTurnRevision: 2,
      decision: 'approve',
    );

    expect(request.toJson()['argumentsDigest'], 'observed-digest');
  });
}
