import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  group('ConversationStreamingRuntime', () {
    test('holds function references', () {
      void start(String _) {
        final _ = Object();
      }

      bool isStreaming(String _) => false;
      void remove(String _) {
        final _ = Object();
      }

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
      void startSub(CompositeSubscription _, String _) {
        final _ = Object();
      }

      void updateResult(Object? _, String _) {
        final _ = Object();
      }

      Future<void> remove(String _) {
        return Future<void>.value();
      }

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
      void updateTitle(String _, String _) {
        final _ = Object();
      }

      void removeTitle(String _) {
        final _ = Object();
      }

      final runtime = TitlesStreamingRuntime(
        updateTitle: updateTitle,
        removeTitle: removeTitle,
      );

      expect(runtime.updateTitle, same(updateTitle));
      expect(runtime.removeTitle, same(removeTitle));
    });
  });

  group('ConversationRateLimitRetryRuntime', () {
    test('holds function references', () {
      void start(String _, DateTime _) {
        final _ = Object();
      }

      DateTime? retryAt(String _) => null;
      void clear(String _) {
        final _ = Object();
      }

      final runtime = ConversationRateLimitRetryRuntime(
        start: start,
        retryAt: retryAt,
        clear: clear,
      );

      expect(runtime.start, same(start));
      expect(runtime.retryAt, same(retryAt));
      expect(runtime.clear, same(clear));
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
      expect(() => runtime.removeTitle('conv-1'), returnsNormally);
    });
  });

  group('conversationRateLimitRetryRuntimeProvider', () {
    test('wires notifier methods to runtime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final runtime = container.read(conversationRateLimitRetryRuntimeProvider);
      final retryAt = DateTime(2026);

      runtime.start('conv-1', retryAt);
      expect(runtime.retryAt('conv-1'), retryAt);
      expect(runtime.retryAt('conv-2'), isNull);

      runtime.clear('conv-1');
      expect(runtime.retryAt('conv-1'), isNull);
    });
  });
}
