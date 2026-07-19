import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudChatGateway {}

class _Snapshot extends Mock implements TurnSnapshot {}

void main() {
  test('get delegates to cloud gateway', () async {
    final gateway = _Gateway();
    final snapshot = _Snapshot();
    when(
      () => gateway.getTurn(turnId: 'turn-1'),
    ).thenAnswer((_) async => snapshot);

    final result = await CloudTurnUsecase(gateway).get('turn-1');

    expect(result, same(snapshot));
    verify(
      () => gateway.getTurn(turnId: 'turn-1'),
    ).called(1);
  });

  test('continues with the latest cloud conversation revision', () async {
    final gateway = _Gateway();
    final result = MockConversationMutationResult();
    final now = DateTime(2026);
    when(
      () => gateway.getConversation('conversation-1'),
    ).thenAnswer(
      (_) async => ConversationSummary(
        id: 'conversation-1',
        title: 'Conversation',
        isPinned: false,
        revision: 3,
        createdAt: now,
        updatedAt: now,
      ),
    );
    when(
      () => gateway.continueTurn(
        requestId: any(named: 'requestId'),
        conversationId: 'conversation-1',
        expectedConversationRevision: 3,
      ),
    ).thenAnswer((_) async => result);

    final actual = await CloudTurnUsecase(gateway).continueConversation(
      'conversation-1',
    );

    expect(actual, same(result));
    verify(
      () => gateway.continueTurn(
        requestId: any(named: 'requestId'),
        conversationId: 'conversation-1',
        expectedConversationRevision: 3,
      ),
    ).called(1);
  });

  test('decide forwards client-observed arguments digest', () async {
    final gateway = _Gateway();
    final result = MockConversationMutationResult();
    when(
      () => gateway.submitToolDecision(
        requestId: any(named: 'requestId'),
        turnId: 'turn-1',
        toolCallId: 'call-1',
        argumentsDigest: 'observed-digest',
        expectedTurnRevision: 2,
        decision: 'approve',
        editedArgumentsJson: '{"value":2}',
      ),
    ).thenAnswer((_) async => result);

    final actual = await CloudTurnUsecase(gateway).decide(
      turnId: 'turn-1',
      toolCallId: 'call-1',
      argumentsDigest: 'observed-digest',
      revision: 2,
      approved: true,
      editedArgumentsJson: '{"value":2}',
    );

    expect(actual, same(result));
    verify(
      () => gateway.submitToolDecision(
        requestId: any(named: 'requestId'),
        turnId: 'turn-1',
        toolCallId: 'call-1',
        argumentsDigest: 'observed-digest',
        expectedTurnRevision: 2,
        decision: 'approve',
        editedArgumentsJson: '{"value":2}',
      ),
    ).called(1);
  });
}

class MockConversationMutationResult extends Mock
    implements ConversationMutationResult {}
