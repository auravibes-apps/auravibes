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

  test('disposes empty providers after their last listener closes', () async {
    final observer = _DisposedProviderObserver();
    final container = ProviderContainer(observers: [observer]);
    addTearDown(container.dispose);
    final provider = conversationDraftProvider('ws-1', 'chat-1');
    final observedDrafts = <ChatDraft?>[];
    container.listen(provider, (_, draft) => observedDrafts.add(draft)).close();

    await container.pump();

    expect(observer.disposedProviders, contains(provider.toString()));
    expect(observedDrafts, isEmpty);
  });

  test('retains saved drafts until they are cleared', () async {
    final observer = _DisposedProviderObserver();
    final container = ProviderContainer(observers: [observer]);
    addTearDown(container.dispose);
    final provider = conversationDraftProvider('ws-1', 'chat-1');
    final observedDrafts = <ChatDraft?>[];
    final subscription = container.listen(
      provider,
      (_, draft) => observedDrafts.add(draft),
    );
    const draft = ChatDraft(text: 'draft');

    container.read(provider.notifier).save(draft);
    subscription.close();
    await container.pump();

    expect(observer.disposedProviders, isNot(contains(provider.toString())));
    expect(container.read(provider), same(draft));
    expect(observedDrafts, [draft]);

    final retainedSubscription = container.listen(
      provider,
      (_, currentDraft) => observedDrafts.add(currentDraft),
    );
    container.read(provider.notifier).clear();
    retainedSubscription.close();
    await container.pump();

    expect(observer.disposedProviders, contains(provider.toString()));
    expect(observedDrafts, [draft, null]);
  });
}

final class _DisposedProviderObserver extends ProviderObserver {
  final disposedProviders = <String>[];

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposedProviders.add(context.provider.toString());
  }
}
