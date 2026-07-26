import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Gateway extends Mock implements CloudChatGateway {}

class _Snapshot extends Mock implements TurnSnapshot {}

class _Turn extends Mock implements ConversationTurnView {}

class _ToolCall extends Mock implements ConversationToolCallView {}

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

  test(
    'retries a second pending decision from the same approval snapshot',
    () async {
      final gateway = _Gateway();
      final first = MockConversationMutationResult();
      final second = MockConversationMutationResult();
      final snapshot = _Snapshot();
      final turn = _Turn();
      final pendingCall = _ToolCall();
      when(() => snapshot.turn).thenReturn(turn);
      when(() => turn.revision).thenReturn(3);
      when(() => snapshot.toolCalls).thenReturn([pendingCall]);
      when(() => pendingCall.id).thenReturn('call-2');
      when(() => pendingCall.status).thenReturn('pending');
      when(() => pendingCall.argumentsDigest).thenReturn('digest-2');
      when(
        () => gateway.submitToolDecision(
          requestId: any(named: 'requestId'),
          turnId: 'turn-1',
          toolCallId: 'call-1',
          argumentsDigest: 'digest-1',
          expectedTurnRevision: 2,
          decision: 'approve',
        ),
      ).thenAnswer((_) async => first);
      when(
        () => gateway.submitToolDecision(
          requestId: any(named: 'requestId'),
          turnId: 'turn-1',
          toolCallId: 'call-2',
          argumentsDigest: 'digest-2',
          expectedTurnRevision: 2,
          decision: 'approve',
        ),
      ).thenThrow(
        const CloudAppException(
          localizationKey: 'unused',
          context: CloudOperationContext.conversation,
          code: 'staleRevision',
        ),
      );
      when(() => gateway.getTurn(turnId: 'turn-1')).thenAnswer(
        (_) async => snapshot,
      );
      when(
        () => gateway.submitToolDecision(
          requestId: any(named: 'requestId'),
          turnId: 'turn-1',
          toolCallId: 'call-2',
          argumentsDigest: 'digest-2',
          expectedTurnRevision: 3,
          decision: 'approve',
        ),
      ).thenAnswer((_) async => second);

      final usecase = CloudTurnUsecase(gateway);
      expect(
        await usecase.decide(
          turnId: 'turn-1',
          toolCallId: 'call-1',
          argumentsDigest: 'digest-1',
          revision: 2,
          approved: true,
        ),
        same(first),
      );
      expect(
        await usecase.decide(
          turnId: 'turn-1',
          toolCallId: 'call-2',
          argumentsDigest: 'digest-2',
          revision: 2,
          approved: true,
        ),
        same(second),
      );

      verify(() => gateway.getTurn(turnId: 'turn-1')).called(1);
      verify(
        () => gateway.submitToolDecision(
          requestId: any(named: 'requestId'),
          turnId: 'turn-1',
          toolCallId: 'call-2',
          argumentsDigest: 'digest-2',
          expectedTurnRevision: 3,
          decision: 'approve',
        ),
      ).called(1);
    },
  );

  test('reuses a decision request ID when stale revision retries', () async {
    final gateway = _Gateway();
    final snapshot = _Snapshot();
    final turn = _Turn();
    final pendingCall = _ToolCall();
    final result = MockConversationMutationResult();
    final requestIds = <String>[];
    var attempts = 0;
    when(() => snapshot.turn).thenReturn(turn);
    when(() => turn.revision).thenReturn(3);
    when(() => snapshot.toolCalls).thenReturn([pendingCall]);
    when(() => pendingCall.id).thenReturn('call-1');
    when(() => pendingCall.status).thenReturn('pending');
    when(() => pendingCall.argumentsDigest).thenReturn('digest-1');
    when(() => gateway.getTurn(turnId: 'turn-1')).thenAnswer(
      (_) async => snapshot,
    );
    when(
      () => gateway.submitToolDecision(
        requestId: any(named: 'requestId'),
        turnId: 'turn-1',
        toolCallId: 'call-1',
        argumentsDigest: 'digest-1',
        expectedTurnRevision: any(named: 'expectedTurnRevision'),
        decision: 'approve',
      ),
    ).thenAnswer((invocation) async {
      requestIds.add(invocation.namedArguments[#requestId]! as String);
      if (attempts++ == 0) {
        throw const CloudAppException(
          localizationKey: 'unused',
          context: CloudOperationContext.conversation,
          code: 'staleRevision',
        );
      }

      return result;
    });

    expect(
      await CloudTurnUsecase(gateway).decide(
        turnId: 'turn-1',
        toolCallId: 'call-1',
        argumentsDigest: 'digest-1',
        revision: 2,
        approved: true,
      ),
      same(result),
    );

    expect(requestIds, hasLength(2));
    expect(requestIds.toSet(), hasLength(1));
  });

  test('stop-all denial reaches the cloud decision gateway', () async {
    final gateway = _Gateway();
    final result = MockConversationMutationResult();
    when(
      () => gateway.submitToolDecision(
        requestId: any(named: 'requestId'),
        turnId: 'turn-1',
        toolCallId: 'call-1',
        argumentsDigest: 'observed-digest',
        expectedTurnRevision: 2,
        decision: 'deny',
        stopAll: true,
      ),
    ).thenAnswer((_) async => result);

    final actual = await CloudTurnUsecase(gateway).decide(
      turnId: 'turn-1',
      toolCallId: 'call-1',
      argumentsDigest: 'observed-digest',
      revision: 2,
      approved: false,
      stopAll: true,
    );

    expect(actual, same(result));
    verify(
      () => gateway.submitToolDecision(
        requestId: any(named: 'requestId'),
        turnId: 'turn-1',
        toolCallId: 'call-1',
        argumentsDigest: 'observed-digest',
        expectedTurnRevision: 2,
        decision: 'deny',
        stopAll: true,
      ),
    ).called(1);
  });
}

class MockConversationMutationResult extends Mock
    implements ConversationMutationResult {}
