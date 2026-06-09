// ignore_for_file: provider_dependencies
// Required: provider unit tests read scoped providers directly.

import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([conversationSelected])
void main() {
  group('conversationSelectedProvider', () {
    test(
      'throws ProviderException containing NoConversationSelectedException '
      'when read without override',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(conversationSelectedProvider),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('NoConversationSelectedException'),
            ),
          ),
        );
      },
    );

    test('returns overridden value when provided', () {
      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-123'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(conversationSelectedProvider), 'conv-123');
    });

    test('can be overridden with different values', () {
      final container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-456'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(conversationSelectedProvider), 'conv-456');
    });
  });
}
