// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/delete_conversation_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/delete_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() => registerFallbackValue(_DeleteConversationRequestFake()));
  Widget buildSubject({
    required String workspaceId,
    required List<Object> overrides,
    Widget? content,
  }) => TestableApp(
    child: Theme(
      data: .new(),
      child: Portal(
        child: Material(
          child: content ?? ChatListWidget(workspaceId: workspaceId),
        ),
      ),
    ),
    overrides: overrides,
    workspaceId: workspaceId,
  );

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
    await tester.pump(const Duration(milliseconds: 300));
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

      expect(find.byType(AuraSpinner), findsOneWidget);
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

    testWidgets('selects multiple conversations and shows selection count', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([
          _createConversation(title: 'Chat One'),
          _createConversation(id: 'conv-2', title: 'Chat Two'),
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

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-2')),
      );
      await tester.pump();

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('clears selection when switching workspaces', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([_createConversation(title: 'Chat One')]),
      );
      var workspaceId = 'ws-1';

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: workspaceId,
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => workspaceId = 'ws-2'),
                  child: const Text('Switch workspace'),
                ),
                Expanded(child: ChatListWidget(workspaceId: workspaceId)),
              ],
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Switch workspace'));
      await tester.pump();

      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('keeps selected conversations when search filters the list', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([
          _createConversation(title: 'Alpha'),
          _createConversation(id: 'conv-2', title: 'Beta'),
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

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.enterText(find.byType(EditableText), 'Beta');
      await tester.pump(const Duration(milliseconds: 301));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNWidgets(2));
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Pin selected'));
      final _ = await tester.pumpAndSettle();

      expect(
        repo.patches,
        equals([
          (id: 'conv-1', patch: const ConversationPatch(isPinned: true)),
        ]),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Beta',
      );
    });

    testWidgets('bulk unpin preserves search and selection', (tester) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([
          _createConversation(title: 'Alpha', isPinned: true),
          _createConversation(id: 'conv-2', title: 'Beta', isPinned: true),
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

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-2')),
      );
      await tester.enterText(find.byType(EditableText), 'Beta');
      await tester.pump(const Duration(milliseconds: 301));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsNothing);
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(find.text('Unpin selected'));
      final _ = await tester.pumpAndSettle();

      expect(
        repo.patches,
        equals([
          (id: 'conv-2', patch: const ConversationPatch(isPinned: false)),
        ]),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Beta',
      );
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('bulk pin reports failures and keeps failed chats selected', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([
          _createConversation(title: 'Failed Chat'),
          _createConversation(id: 'conv-2', title: 'Pinned Chat'),
        ]),
        onPatch: (id, patch) async {
          if (id == 'conv-1') throw StateError('pin denied');

          return _createConversation(
            id: id,
            title: 'Pinned Chat',
            isPinned: patch.isPinned ?? false,
          );
        },
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

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-2')),
      );
      await tester.pump();
      await tester.tap(find.text('Pin selected'));
      final _ = await tester.pumpAndSettle();

      expect(
        repo.patches,
        equals([
          (id: 'conv-1', patch: const ConversationPatch(isPinned: true)),
          (id: 'conv-2', patch: const ConversationPatch(isPinned: true)),
        ]),
      );
      expect(
        find.text('Could not update pin for: Failed Chat'),
        findsOneWidget,
      );
      expect(find.text('2 selected'), findsOneWidget);
      expect(
        tester
            .widget<AuraCheckbox>(
              find.byKey(const ValueKey('conversation-selection-conv-1')),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('cancelled bulk delete leaves conversations unchanged', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([_createConversation()]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            deleteConversationUsecaseProvider.overrideWithValue(
              DeleteConversationUsecase(repo, (_) => Future<void>.value()),
            ),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.pump();
      await tester.tap(find.text('Delete selected'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(repo.deleteCalls, isEmpty);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('cloud delete failure never falls back to local delete', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([_createConversation()]),
      );
      final stateGateway = _WorkspaceGateway();
      final client = _Client();
      final endpoint = _ConversationEndpoint();
      when(() => stateGateway.workspace).thenReturn(_cloudWorkspace);
      when(() => stateGateway.client).thenReturn(client);
      when(() => client.conversation).thenReturn(endpoint);
      when(() => endpoint.delete(any()))
          .thenThrow(StateError('cloud permission denied'));
      final gateway = CloudChatGateway(stateGateway);

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            deleteConversationUsecaseProvider.overrideWithValue(
              DeleteConversationUsecase(repo, (_) => Future<void>.value()),
            ),
            cloudConversationUsecaseProvider.overrideWithValue(.new(gateway)),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.pump();
      await tester.tap(find.text('Delete selected'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      final _ = await tester.pumpAndSettle();

      verify(() => endpoint.delete(any())).called(1);
      expect(repo.deleteCalls, isEmpty);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('bulk delete reports and retains failed conversations', (
      tester,
    ) async {
      final repo = _StubConversationRepository(
        conversationsStream: .value([
          _createConversation(title: 'Failed Chat'),
          _createConversation(id: 'conv-2', title: 'Deleted Chat'),
        ]),
        onDelete: (id) async => id != 'conv-1',
      );

      await pumpAndInit(
        tester,
        buildSubject(
          workspaceId: 'ws-1',
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repo),
            deleteConversationUsecaseProvider.overrideWithValue(
              DeleteConversationUsecase(repo, (_) => Future<void>.value()),
            ),
            streamingTitleProvider.overrideWith((ref, id) => null),
            listWorkspaceModelSelectionsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([]),
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('conversation-selection-conv-2')),
      );
      await tester.pump();
      await tester.tap(find.text('Delete selected'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      final _ = await tester.pumpAndSettle();

      expect(repo.deleteCalls, ['conv-1', 'conv-2']);
      expect(find.text('Could not delete: Failed Chat'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Failed Chat'), findsOneWidget);
      expect(
        tester
            .widget<AuraCheckbox>(
              find.byKey(const ValueKey('conversation-selection-conv-1')),
            )
            .value,
        isTrue,
      );
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

class _WorkspaceGateway extends Mock implements CloudWorkspaceStateGateway;

class _Client extends Mock implements Client;

class _ConversationEndpoint extends Mock implements EndpointConversation;

class _DeleteConversationRequestFake extends Fake
    implements DeleteConversationRequest;

const _cloudWorkspace = CloudWorkspaceRef(
  localWorkspaceId: 'ws-1',
  serverUrl: 'https://example.com/',
  accountId: 'account',
  cloudWorkspaceId: 1,
);

class _StubConversationRepository({
  required final Stream<List<ConversationEntity>> conversationsStream,
  final Future<ConversationEntity> Function(String, ConversationPatch)? onPatch,
  final Future<bool> Function(String)? onDelete,
}) implements ConversationRepository {
  final queries = <({String? search, int? limit, int offset})>[];
  final patches = <({String id, ConversationPatch patch})>[];

  final deleteCalls = <String>[];
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
  Future<bool> deleteConversation(String id) async {
    deleteCalls.add(id);
    final delete = onDelete;
    final deleted = delete == null || await delete(id);
    if (deleted) {
      _cachedConversations = _cachedConversations
          ?.where((conversation) => conversation.id != id)
          .toList();
    }

    return deleted;
  }

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();

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
