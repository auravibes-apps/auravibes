import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('keeps drafts isolated by workspace and conversation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = conversationDraftProvider('ws-1', 'chat-1');
    final second = conversationDraftProvider('ws-1', 'chat-2');
    final otherWorkspace = conversationDraftProvider('ws-2', 'chat-1');
    const original = ChatDraft(text: 'first');
    final staleDraft = ChatDraft(text: original.text);

    container.read(first.notifier).save(original);
    container.read(second.notifier).save(const ChatDraft(text: 'second'));
    container
        .read(otherWorkspace.notifier)
        .save(const ChatDraft(text: 'other workspace'));
    container.read(first.notifier).clearIfSame(staleDraft);

    expect(container.read(first), same(original));
    expect(container.read(second)?.text, 'second');
    expect(container.read(otherWorkspace)?.text, 'other workspace');

    container.read(first.notifier).clearIfSame(original);
    expect(container.read(first), isNull);
    expect(container.read(second)?.text, 'second');
  });
}
