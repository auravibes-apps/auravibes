// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.

import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

const _workspaceId = 'ws-1';
const _chatId = 'chat-1';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async {
            if (methodCall.method == 'getTemporaryDirectory') {
              return '.';
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });
  test('ChatConversationScreen stores workspaceId and chatId', () {
    const screen = ChatConversationScreen(
      workspaceId: _workspaceId,
      chatId: _chatId,
    );
    expect(screen.workspaceId, _workspaceId);
    expect(screen.chatId, _chatId);
  });

  test('ConversationResult subclasses have correct types', () {
    const notFound = ConversationNotFound();
    const mismatch = ConversationWorkspaceMismatch();
    final found = ConversationFound(
      ConversationEntity(
        id: 'c1',
        title: 'Test',
        workspaceId: 'ws1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    expect(notFound, isA<ConversationResult>());
    expect(mismatch, isA<ConversationResult>());
    expect(found, isA<ConversationResult>());
    expect(found.conversation.id, 'c1');
  });

  testWidgets('shows spinner when conversationChatProvider is loading', (
    tester,
  ) async {
    final controller = StreamController<ConversationEntity?>.broadcast();
    addTearDown(controller.close);

    final repo = _StubConversationRepository(
      watchStream: controller.stream,
    );

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          routerPathSegmentsProvider.overrideWithValue(const []),
          conversationRepositoryProvider.overrideWithValue(repo),
          conversationChatProvider(_workspaceId).overrideWith(
            _ForeverLoadingChatNotifier.new,
          ),
        ],
        child: const MaterialApp(
          home: ChatConversationScreen(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('shows error when conversationChatProvider has error', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          routerPathSegmentsProvider.overrideWithValue(const []),
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId).overrideWith(
            _ErrorChatNotifier.new,
          ),
        ],
        child: const MaterialApp(
          home: ChatConversationScreen(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('shows error for ConversationNotFound result', (tester) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          routerPathSegmentsProvider.overrideWithValue(const []),
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId).overrideWith(
            () => _ResultChatNotifier(const ConversationNotFound()),
          ),
        ],
        child: const MaterialApp(
          home: ChatConversationScreen(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('shows error for ConversationWorkspaceMismatch result', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          routerPathSegmentsProvider.overrideWithValue(const []),
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId).overrideWith(
            () => _ResultChatNotifier(
              const ConversationWorkspaceMismatch(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ChatConversationScreen(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  test('ConversationFound stores conversation', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final found = ConversationFound(entity);
    expect(found.conversation, same(entity));
    expect(found.conversation.id, 'c1');
    expect(found.conversation.title, 'Test');
  });

  test('ConversationFound is a ConversationResult', () {
    const notFound = ConversationNotFound();
    const mismatch = ConversationWorkspaceMismatch();
    final found = ConversationFound(
      ConversationEntity(
        id: 'c1',
        title: 'Test',
        workspaceId: 'ws1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    expect(notFound, isA<ConversationResult>());
    expect(mismatch, isA<ConversationResult>());
    expect(found, isA<ConversationResult>());
  });

  test('ConversationNotFound is const', () {
    const result = ConversationNotFound();
    expect(result, isA<ConversationNotFound>());
  });

  test('ConversationWorkspaceMismatch is const', () {
    const result = ConversationWorkspaceMismatch();
    expect(result, isA<ConversationWorkspaceMismatch>());
  });

  testWidgets('shows error for null conversation result', (tester) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          routerPathSegmentsProvider.overrideWithValue(const []),
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId).overrideWith(
            () => _ResultChatNotifier(const ConversationNotFound()),
          ),
        ],
        child: const MaterialApp(
          home: ChatConversationScreen(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  test('ConversationEntity hasValidTitle returns true for non-empty title', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(entity.hasValidTitle, isTrue);
  });

  test('ConversationEntity hasValidTitle returns false for empty title', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: '',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(entity.hasValidTitle, isFalse);
  });

  test('ConversationEntity isValid returns true for valid data', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(entity.isValid, isTrue);
  });

  test('ConversationEntity isValid returns false for empty workspaceId', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: '',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(entity.isValid, isFalse);
  });

  test('ConversationEntity modelId can be null', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(entity.modelId, isNull);
  });

  test('ConversationEntity modelId can be set', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelId: 'gpt-4',
    );
    expect(entity.modelId, 'gpt-4');
  });

  test('ConversationEntity copyWith preserves id', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final copy = entity.copyWith(title: 'Updated');
    expect(copy.id, 'c1');
    expect(copy.title, 'Updated');
    expect(copy.workspaceId, 'ws1');
  });

  test('ConversationEntity isPinned can be true', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(entity.isPinned, isTrue);
  });

  testWidgets(
    'renders ChatConversationScreen when ConversationFound',
    (tester) async {
      final conversation = ConversationEntity(
        id: _chatId,
        title: 'Chat',
        workspaceId: _workspaceId,
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          EasyLocalization(
            child: Builder(
              builder: (context) {
                return TestProviderScope(
                  overrides: [
                    conversationSelectedProvider.overrideWithValue(_chatId),
                    routerPathSegmentsProvider.overrideWithValue(const []),
                    conversationRepositoryProvider.overrideWithValue(
                      _StubConversationRepository(),
                    ),
                    conversationChatProvider(_workspaceId).overrideWith(
                      () => _ResultChatNotifier(
                        ConversationFound(conversation),
                      ),
                    ),
                    conversationBusyStateProvider.overrideWith(
                      (ref) async => const ConversationBusyState(
                        isStreaming: false,
                        hasPendingTools: false,
                      ),
                    ),
                    chatMessagesProvider.overrideWith(
                      (ref) async => const <MessageEntity>[],
                    ),
                    chatMessageIdsProvider.overrideWith(
                      (ref) => MessageIdList.empty,
                    ),
                    contextUsageProvider.overrideWith(
                      (ref) => ContextUsageData.compute(
                        usedTokens: 0,
                        limitTokens: null,
                      ),
                    ),
                    pendingToolCallsProvider.overrideWith(
                      (ref) async => const <PendingToolCall>[],
                    ),
                    listModelsGroupedByProviderProvider(
                      workspaceId: _workspaceId,
                    ).overrideWith(
                      (ref) => Stream.value(const {}),
                    ),
                  ],
                  child: MaterialApp(
                    home: const ChatConversationScreen(
                      workspaceId: _workspaceId,
                      chatId: _chatId,
                    ),
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  ),
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
        await tester.pump();
        await tester.pump();
      });
      await tester.pump();
      await tester.pump();

      expect(find.text('Chat'), findsOneWidget);
    },
  );

  testWidgets('passes running compaction state to chat input', (tester) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return TestProviderScope(
                overrides: [
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  routerPathSegmentsProvider.overrideWithValue(const []),
                  conversationRepositoryProvider.overrideWithValue(
                    _StubConversationRepository(),
                  ),
                  conversationChatProvider(_workspaceId).overrideWith(
                    () => _ResultChatNotifier(
                      ConversationFound(conversation),
                    ),
                  ),
                  conversationBusyStateProvider.overrideWith(
                    (ref) async => const ConversationBusyState(
                      isStreaming: false,
                      hasPendingTools: false,
                    ),
                  ),
                  chatMessagesProvider.overrideWith(
                    (ref) async => const <MessageEntity>[],
                  ),
                  chatMessageIdsProvider.overrideWith(
                    (ref) => MessageIdList.empty,
                  ),
                  contextUsageProvider.overrideWith(
                    (ref) => ContextUsageData.compute(
                      usedTokens: 0,
                      limitTokens: null,
                    ),
                  ),
                  pendingToolCallsProvider.overrideWith(
                    (ref) async => const <PendingToolCall>[],
                  ),
                  listModelsGroupedByProviderProvider(
                    workspaceId: _workspaceId,
                  ).overrideWith(
                    (ref) => Stream.value(const {}),
                  ),
                  compactionExecutionStateProvider(_chatId).overrideWithValue(
                    CompactionExecutionState(
                      conversationId: _chatId,
                      trigger: CompactionTrigger.manual,
                      startedAt: DateTime(2026),
                      status: CompactionExecutionStatus.running,
                    ),
                  ),
                ],
                child: MaterialApp(
                  home: const ChatConversationScreen(
                    workspaceId: _workspaceId,
                    chatId: _chatId,
                  ),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                ),
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
      await tester.pump();
      await tester.pump();
    });
    await tester.pump();
    await tester.pump();

    final input = tester.widget<ChatInputWidget>(find.byType(ChatInputWidget));
    expect(input.isCompacting, isTrue);
  });
}

class _ForeverLoadingChatNotifier extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(String workspaceId) {
    return Completer<ConversationResult>().future;
  }
}

class _ErrorChatNotifier extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(String workspaceId) async {
    throw Exception('test error');
  }
}

class _ResultChatNotifier extends ConversationChatNotifier {
  _ResultChatNotifier(this.result);
  final ConversationResult result;

  @override
  Future<ConversationResult> build(String workspaceId) async => result;
}

class _StubConversationRepository implements ConversationRepository {
  _StubConversationRepository({this.watchStream});
  final Stream<ConversationEntity?>? watchStream;

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    return watchStream ?? const Stream.empty();
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) async => null;

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    throw UnimplementedError();
  }
}
