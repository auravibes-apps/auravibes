import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/models/cloud_live_turn_state.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cloud send does not require local repository or agent runtime',
    () async {
      String? sentConversationId;
      final usecase = SendMessageUsecase.cloud((conversationId, draft) {
        sentConversationId = conversationId;
        expect(draft.text, 'hello');

        return Future.value(_turn);
      });

      await usecase.call(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'hello'),
      );

      expect(sentConversationId, 'conversation-1');
    },
  );

  test('cloud first send does not require local repository', () async {
    var called = false;
    final usecase = SendMessageUsecase.cloud((conversationId, draft) {
      called = true;

      return Future.value(_turn);
    });

    await usecase.sendFirstMessage(
      conversationId: 'conversation-1',
      draft: const ChatDraft(text: 'hello'),
      onContinueError: (error, stackTrace) => fail('$error'),
    );

    expect(called, isTrue);
  });
}

const _turn = CloudLiveTurnState(
  turnId: 'turn-1',
  revision: 1,
  sequence: 1,
  state: CloudLiveTurnLifecycle.queued,
);
