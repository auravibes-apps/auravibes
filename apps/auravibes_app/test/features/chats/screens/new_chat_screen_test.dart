import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('constructor sets workspaceId', () {
    const screen = NewChatScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  test('constructor accepts different workspaceIds', () {
    const screen = NewChatScreen(workspaceId: 'other-id');
    expect(screen.workspaceId, 'other-id');
  });

  group('NewChatState', () {
    test('default values', () {
      const state = NewChatState();
      expect(state.modelId, isNull);
      expect(state.providerId, isNull);
      expect(state.isLoading, isFalse);
    });

    test('copyWith preserves values', () {
      const state = NewChatState(modelId: 'm1', providerId: 'p1');
      final copied = state.copyWith(isLoading: true);
      expect(copied.modelId, 'm1');
      expect(copied.providerId, 'p1');
      expect(copied.isLoading, isTrue);
    });

    test('copyWith allows nulling modelId', () {
      const state = NewChatState(modelId: 'm1');
      final copied = state.copyWith(modelId: null);
      expect(copied.modelId, isNull);
      expect(copied.providerId, isNull);
    });

    test('equality works', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm1');
      expect(a, equals(b));
    });

    test('inequality works', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm1');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes fields', () {
      const state = NewChatState(modelId: 'm1', isLoading: true);
      final str = state.toString();
      expect(str, contains('m1'));
      expect(str, contains('true'));
    });
  });

  group('render', () {
    testWidgets('renders NewChatScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableApp(
            child: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const NewChatScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              newChatProvider('test-ws').overrideWithValue(
                const NewChatState(),
              ),
              listModelsGroupedByProviderProvider.overrideWith(
                (ref, workspaceId) => Stream.value({}),
              ),
            ],
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(find.byType(NewChatScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
      expect(find.byType(ChatInputWidget), findsOneWidget);
    });
  });
}
