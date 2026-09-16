// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget buildSubject({
    required String workspaceId,
    required List<Object> overrides,
  }) {
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspaceId),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(session).overrideWithValue(session),
        workspaceSessionForRouteProvider.overrideWith((_, _) async => session),
        ...overrides.cast(),
      ],
    );
    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Theme(
                data: .new(extensions: [AuraTheme.light]),
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
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
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
      createdAt: .new(2025),
      updatedAt: .new(2025),
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
      final repo = _StubConversationRepository(conversationsStream: .value([]));

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
        conversationsStream: .value(conversations),
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

    testWidgets('filters chats by title and restores all chats when cleared', (
      tester,
    ) async {
      final conversations = [
        _createConversation(title: 'Release Plan'),
        _createConversation(id: 'conv-2', title: 'Design Brief'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: .value(conversations),
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

      expect(find.byType(AuraInput), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'RELEASE');
      await tester.pump(const Duration(milliseconds: 301));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Release Plan'), findsOneWidget);
      expect(find.text('Design Brief'), findsNothing);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pump(const Duration(milliseconds: 301));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Release Plan'), findsOneWidget);
      expect(find.text('Design Brief'), findsOneWidget);
    });

    testWidgets('keeps search focused while query reloads', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([_createConversation(title: 'Release')]),
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

      final searchField = find.byType(EditableText);
      await tester.tap(searchField);
      final focusNode = tester.widget<EditableText>(searchField).focusNode;
      expect(focusNode.hasFocus, isTrue);
      expect(repo.queries, hasLength(1));

      await tester.enterText(searchField, 'R');
      await tester.pump();

      expect(repo.queries, hasLength(1));
      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(focusNode.hasFocus, isTrue);

      await tester.pump(const Duration(milliseconds: 301));
      await tester.pump();

      expect(repo.queries.last.search, 'R');
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('shows a no-results state for an unmatched title', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([
          _createConversation(title: 'Release Plan'),
        ]),
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

      await tester.enterText(find.byType(EditableText), 'missing');
      await tester.pump(const Duration(milliseconds: 301));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Release Plan'), findsNothing);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No conversations match your search'), findsOneWidget);
    });

    testWidgets('shows pinned icon for pinned conversations', (tester) async {
      final conversations = [
        _createConversation(title: 'Pinned Chat', isPinned: true),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: .value(conversations),
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
      final conversations = [_createConversation(title: 'Chat One')];
      final repo = _StubConversationRepository(
        conversationsStream: .value(conversations),
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

    testWidgets('pins a conversation from its options menu', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([_createConversation()]),
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
      await tester.tap(find.byIcon(Icons.more_vert));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Pin conversation'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Pin conversation'));
      final _ = await tester.pumpAndSettle();

      expect(
        repo.patches,
        equals([
          (id: 'conv-1', patch: const ConversationPatch(isPinned: true)),
        ]),
      );
    });

    testWidgets('unpins a conversation from its options menu', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([_createConversation(isPinned: true)]),
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
      await tester.tap(find.byIcon(Icons.more_vert));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Unpin conversation'), findsOneWidget);

      await tester.tap(find.text('Unpin conversation'));
      final _ = await tester.pumpAndSettle();

      expect(
        repo.patches,
        equals([
          (id: 'conv-1', patch: const ConversationPatch(isPinned: false)),
        ]),
      );
    });

    testWidgets('renames a chat from its menu', (tester) async {
      final initial = _createConversation(title: 'Original');
      final renamed = _createConversation(title: 'Renamed');
      final controller = StreamController<List<ConversationEntity>>.broadcast();
      final patched = <ConversationPatch>[];
      addTearDown(controller.close);
      final repo = _StubConversationRepository(
        conversationsStream: controller.stream,
        onPatch: (id, patch) async {
          patched.add(patch);
          controller.add([renamed]);

          return renamed;
        },
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            conversationByIdStreamProvider.overrideWith(
              (ref, conversationId) => Stream.value(initial),
            ),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );
      controller.add([initial]);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);

      await tester.tap(find.text('Rename'));
      final _ = await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller?.text,
        'Original',
      );

      await tester.enterText(find.byType(TextField).last, 'Renamed');
      await tester.tap(find.text('Save'));
      final _ = await tester.pumpAndSettle();

      expect(patched, hasLength(1));
      expect(patched.single.title, 'Renamed');
      expect(find.text('Renamed'), findsOneWidget);
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
        conversationsStream: .value(conversations),
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
      final conversations = [_createConversation(title: 'Original Title')];
      final repo = _StubConversationRepository(
        conversationsStream: .value(conversations),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => 'Streamed Title'),
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
        conversationsStream: .value(conversations),
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
      final repo = _StubConversationRepository(conversationsStream: .value([]));

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
      expect(find.byType(AuraInput), findsNothing);
    });

    testWidgets('loads the next page from the repository', (tester) async {
      final conversations = [
        for (var index = 1; index <= 21; index++)
          _createConversation(id: 'conv-$index', title: 'Chat $index'),
      ];
      final repo = _StubConversationRepository(
        conversationsStream: .value(conversations),
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

      expect(find.text('Show more'), findsOneWidget);
      expect(repo.queries.single.offset, 0);

      await tester.tap(find.text('Show more'));
      final _ = await tester.pumpAndSettle();

      expect(repo.queries.last.offset, 20);
      expect(find.text('Show more'), findsNothing);
    });
  });
}

class _StubConversationRepository({
  required final Stream<List<ConversationEntity>> conversationsStream,
  final Future<ConversationEntity> Function(String, ConversationPatch)? onPatch,
}) implements ConversationRepository {
  final queries = <({String? search, int? limit, int offset})>[];
  final patches = <({String id, ConversationPatch patch})>[];
  List<ConversationEntity>? _cachedConversations;

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) {
    queries.add((search: search, limit: limit, offset: offset));
    final cachedConversations = _cachedConversations;
    if (cachedConversations != null) {
      return Stream.value(
        _page(
          cachedConversations,
          search: search,
          limit: limit,
          offset: offset,
        ),
      );
    }

    return conversationsStream.map((conversations) {
      _cachedConversations = conversations;

      return _page(conversations, search: search, limit: limit, offset: offset);
    });
  }

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) {
    return const Stream.empty();
  }

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async {
    return const [];
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
  ) async {
    patches.add((id: id, patch: conversation));

    if (onPatch case final callback?) {
      return await callback(id, conversation);
    }

    return ConversationEntity(
      id: id,
      title: 'Updated chat',
      workspaceId: 'ws-1',
      isPinned: conversation.isPinned ?? false,
      createdAt: .new(2025),
      updatedAt: .new(2025),
    );
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    return const Stream.empty();
  }

  List<ConversationEntity> _page(
    List<ConversationEntity> conversations, {
    required String? search,
    required int? limit,
    required int offset,
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final matching = normalizedSearch.isEmpty
        ? conversations
        : conversations
              .where(
                (conversation) =>
                    conversation.title.toLowerCase().contains(normalizedSearch),
              )
              .toList();

    return matching.skip(offset).take(limit ?? matching.length).toList();
  }
}
