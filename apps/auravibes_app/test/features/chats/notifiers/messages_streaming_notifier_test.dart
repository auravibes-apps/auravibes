// ignore_for_file: cascade_invocations
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../test_mocks.dart';

void main() {
  group('MessagesStreamingNotifier', () {
    var container = ProviderContainer();

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty map', () {
      final state = container.read(messagesStreamingProvider);
      expect(state, isEmpty);
    });

    test('startSubscription adds entry to map', () {
      final notifier = container.read(messagesStreamingProvider.notifier);
      final subscription = CompositeSubscription();

      notifier.startSubscription(subscription, 'msg-1');

      final state = container.read(messagesStreamingProvider);
      expect(state, contains('msg-1'));
      expect(state['msg-1']!.streamSubscription, subscription);
      expect(state['msg-1']!.lastResult, isNull);
    });

    test('updateResult throws when no subscription exists', () {
      final notifier = container.read(messagesStreamingProvider.notifier);
      final mockResult = MockChatResult();

      expect(
        () => notifier.updateResult(mockResult, 'nonexistent'),
        throwsA(isA<Exception>()),
      );
    });

    test('remove cancels subscription and removes entry', () async {
      final notifier = container.read(messagesStreamingProvider.notifier);
      final subscription = CompositeSubscription();

      notifier.startSubscription(subscription, 'msg-1');
      await notifier.remove('msg-1');

      expect(
        container.read(messagesStreamingProvider),
        isNot(contains('msg-1')),
      );
    });

    test('remove with unknown id is no-op', () async {
      final notifier = container.read(messagesStreamingProvider.notifier);
      final subscription = CompositeSubscription();

      notifier.startSubscription(subscription, 'msg-1');
      await notifier.remove('unknown');

      expect(container.read(messagesStreamingProvider), contains('msg-1'));
    });

    test('startSubscription for multiple messages', () {
      final notifier = container.read(messagesStreamingProvider.notifier);

      notifier
        ..startSubscription(CompositeSubscription(), 'msg-1')
        ..startSubscription(CompositeSubscription(), 'msg-2');

      final state = container.read(messagesStreamingProvider);
      expect(state, contains('msg-1'));
      expect(state, contains('msg-2'));
    });
  });
}
