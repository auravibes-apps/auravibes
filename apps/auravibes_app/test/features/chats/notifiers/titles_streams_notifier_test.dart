// ignore_for_file: cascade_invocations
import 'package:auravibes_app/features/chats/notifiers/titles_streams_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('TitlesStreamsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty map', () {
      final state = container.read(titlesStreamsProvider);
      expect(state, isEmpty);
    });

    test('updateTitle adds entry to map', () {
      final notifier = container.read(titlesStreamsProvider.notifier);

      notifier.updateTitle('conv-1', 'My Title');

      final state = container.read(titlesStreamsProvider);
      expect(state, {'conv-1': 'My Title'});
    });

    test('updateTitle overwrites existing title', () {
      final notifier = container.read(titlesStreamsProvider.notifier);

      notifier
        ..updateTitle('conv-1', 'First Title')
        ..updateTitle('conv-1', 'Updated Title');

      final state = container.read(titlesStreamsProvider);
      expect(state, {'conv-1': 'Updated Title'});
    });

    test('updateTitle handles multiple conversations', () {
      final notifier = container.read(titlesStreamsProvider.notifier);

      notifier
        ..updateTitle('conv-1', 'Title 1')
        ..updateTitle('conv-2', 'Title 2');

      final state = container.read(titlesStreamsProvider);
      expect(state, {'conv-1': 'Title 1', 'conv-2': 'Title 2'});
    });

    test('removeTitle removes entry from map', () {
      final notifier = container.read(titlesStreamsProvider.notifier);

      notifier
        ..updateTitle('conv-1', 'Title 1')
        ..updateTitle('conv-2', 'Title 2')
        ..removeTitle('conv-1');

      final state = container.read(titlesStreamsProvider);
      expect(state, {'conv-2': 'Title 2'});
    });

    test('removeTitle with unknown id is no-op', () {
      final notifier = container.read(titlesStreamsProvider.notifier);

      notifier
        ..updateTitle('conv-1', 'Title 1')
        ..removeTitle('unknown');

      final state = container.read(titlesStreamsProvider);
      expect(state, {'conv-1': 'Title 1'});
    });
  });
}
