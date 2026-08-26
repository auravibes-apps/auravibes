// Required: provider unit tests read scoped providers directly.

import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('conversationSelectedProvider', () {
    test('returns the route workspace ID when read without override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(conversationSelectedProvider('ws-1')), 'ws-1');
    });

    test('returns overridden value when provided', () {
      final container = ProviderContainer(
        overrides: [conversationSelectedProvider.overrideWithValue('conv-123')],
      );
      addTearDown(container.dispose);

      expect(container.read(conversationSelectedProvider('ws-1')), 'conv-123');
    });

    test('can be overridden with different values', () {
      final container = ProviderContainer(
        overrides: [conversationSelectedProvider.overrideWithValue('conv-456')],
      );
      addTearDown(container.dispose);

      expect(container.read(conversationSelectedProvider('ws-1')), 'conv-456');
    });
  });
}
