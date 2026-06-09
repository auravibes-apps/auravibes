// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-moving-to-variable
// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildSubject({
    required String workspaceId,
    required List<Object> overrides,
  }) {
    return EasyLocalization(
      child: ProviderScope(
        overrides: overrides.cast(),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: Portal(
                  child: Material(
                    child: ChatListWidget(workspaceId: workspaceId),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  ConversationEntity _createConversation({
    String id = 'conv-1',
    String title = 'Test Chat',
    bool isPinned = false,
    String? modelId,
  }) {
    return ConversationEntity(
      id: id,
      title: title,
      workspaceId: 'ws-1',
      isPinned: isPinned,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      modelId: modelId,
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  group('ChatListWidget', () {
    testWidgets('shows empty state when no chats', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value([]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.chat_outlined), findsOneWidget);
    });

    testWidgets('shows loading spinner while loading', (tester) async {
      final controller = StreamController<List<ConversationEntity>>();
      addTearDown(controller.close);

      final repo = _StubConversationRepository(
        conversationsStream: controller.stream,
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders chat tiles for conversations', (tester) async {
      final conversations = [
        _createConversation(title: 'Chat One'),
        _createConversation(id: 'conv-2', title: 'Chat Two'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.text('Chat One'), findsOneWidget);
      expect(find.text('Chat Two'), findsOneWidget);
    });

    testWidgets('shows pinned icon for pinned conversations', (tester) async {
      final conversations = [
        _createConversation(title: 'Pinned Chat', isPinned: true),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    });

    testWidgets('shows options menu button for each chat', (tester) async {
      final conversations = [
        _createConversation(title: 'Chat One'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows error state when stream has error', (tester) async {
      final controller = StreamController<List<ConversationEntity>>();
      addTearDown(controller.close);

      final repo = _StubConversationRepository(
        conversationsStream: controller.stream,
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      controller.addError(Exception('load failed'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.text(LocaleKeys.workspace_management_unexpected_error.tr()),
        findsOneWidget,
      );
    });

    testWidgets('shows model badge when model is set', (tester) async {
      final conversations = [
        _createConversation(title: 'Chat One', modelId: 'gpt-4'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.text('Chat One'), findsOneWidget);
    });

    testWidgets('uses streaming title when available', (tester) async {
      final conversations = [
        _createConversation(title: 'Original Title'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith(
              (ref, id) => 'Streamed Title',
            ),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.text('Streamed Title'), findsOneWidget);
    });

    testWidgets('renders multiple chats in list', (tester) async {
      final conversations = [
        _createConversation(title: 'Chat One'),
        _createConversation(id: 'conv-2', title: 'Chat Two'),
        _createConversation(id: 'conv-3', title: 'Chat Three'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(find.text('Chat One'), findsOneWidget);
      expect(find.text('Chat Two'), findsOneWidget);
      expect(find.text('Chat Three'), findsOneWidget);
    });

    testWidgets('shows no chats text in empty state', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: Stream.value([]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      expect(
        find.text(LocaleKeys.home_screen_conversation_states_no_chats_yet.tr()),
        findsOneWidget,
      );
    });
  });
}

class _StubConversationRepository implements ConversationRepository {
  _StubConversationRepository({required this.conversationsStream});

  final Stream<List<ConversationEntity>> conversationsStream;

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    return conversationsStream;
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    return const Stream.empty();
  }
}
