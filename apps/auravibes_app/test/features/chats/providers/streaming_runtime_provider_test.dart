import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  group('ConversationStreamingRuntime', () {
    test('holds function references', () {
      void start(String _) {}
      bool isStreaming(String _) => false;
      void remove(String _) {}

      final runtime = ConversationStreamingRuntime(
        start: start,
        isStreaming: isStreaming,
        remove: remove,
      );

      expect(runtime.start, same(start));
      expect(runtime.isStreaming, same(isStreaming));
      expect(runtime.remove, same(remove));
    });
  });

  group('MessagesStreamingRuntime', () {
    test('holds function references', () {
      void startSub(CompositeSubscription _, String _) {}
      void updateResult(Object? _, String _) {}
      Future<void> remove(String _) async {}

      final runtime = MessagesStreamingRuntime(
        startSubscription: startSub,
        updateResult: updateResult,
        remove: remove,
      );

      expect(runtime.startSubscription, same(startSub));
      expect(runtime.updateResult, same(updateResult));
      expect(runtime.remove, same(remove));
    });
  });

  group('TitlesStreamingRuntime', () {
    test('holds function references', () {
      void updateTitle(String _, String _) {}
      void removeTitle(String _) {}

      final runtime = TitlesStreamingRuntime(
        updateTitle: updateTitle,
        removeTitle: removeTitle,
      );

      expect(runtime.updateTitle, same(updateTitle));
      expect(runtime.removeTitle, same(removeTitle));
    });
  });

  group('conversationStreamingRuntimeProvider', () {
    test('wires notifier methods to runtime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final runtime = container.read(conversationStreamingRuntimeProvider);

      runtime.start('conv-1');
      expect(runtime.isStreaming('conv-1'), isTrue);
      expect(runtime.isStreaming('conv-2'), isFalse);

      runtime.remove('conv-1');
      expect(runtime.isStreaming('conv-1'), isFalse);
    });
  });

  group('messagesStreamingRuntimeProvider', () {
    test('wires notifier methods to runtime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final runtime = container.read(messagesStreamingRuntimeProvider);
      final sub = CompositeSubscription();

      runtime.startSubscription(sub, 'msg-1');
      expect(() => runtime.remove('msg-1'), returnsNormally);
    });
  });

  group('titlesStreamingRuntimeProvider', () {
    test('wires notifier methods to runtime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final runtime = container.read(titlesStreamingRuntimeProvider);

      runtime.updateTitle('conv-1', 'New Title');
      runtime.removeTitle('conv-1');
    });
  });
}
