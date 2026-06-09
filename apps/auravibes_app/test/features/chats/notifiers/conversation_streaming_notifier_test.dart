// ignore_for_file: cascade_invocations
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ConversationStreamingNotifier', () {
    var container = ProviderContainer();

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty set', () {
      final state = container.read(conversationStreamingProvider);
      expect(state, isEmpty);
    });

    test('start adds conversationId to set', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier.start('conv-1');

      expect(container.read(conversationStreamingProvider), {'conv-1'});
    });

    test('start adds multiple conversationIds', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier
        ..start('conv-1')
        ..start('conv-2');

      expect(
        container.read(conversationStreamingProvider),
        {'conv-1', 'conv-2'},
      );
    });

    test('isStreaming returns true for active conversation', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier.start('conv-1');

      expect(notifier.isStreaming('conv-1'), isTrue);
    });

    test('isStreaming returns false for unknown conversation', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier.start('conv-1');

      expect(notifier.isStreaming('conv-999'), isFalse);
    });

    test('remove removes conversationId from set', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier
        ..start('conv-1')
        ..start('conv-2')
        ..remove('conv-1');

      expect(
        container.read(conversationStreamingProvider),
        {'conv-2'},
      );
    });

    test('remove with unknown id is no-op', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier
        ..start('conv-1')
        ..remove('unknown');

      expect(container.read(conversationStreamingProvider), {'conv-1'});
    });

    test('start with duplicate id does not duplicate', () {
      final notifier = container.read(
        conversationStreamingProvider.notifier,
      );

      notifier
        ..start('conv-1')
        ..start('conv-1');

      expect(container.read(conversationStreamingProvider), {'conv-1'});
    });
  });
}
