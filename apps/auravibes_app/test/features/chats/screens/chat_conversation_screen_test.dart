// Required: widget tests override scoped providers directly.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_state_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_provider_scope.dart';

const _workspaceId = 'ws-1';
const _chatId = 'chat-1';

final _busyRefreshProvider = NotifierProvider<_BusyRefreshNotifier, int>(
  _BusyRefreshNotifier.new,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_ContinueConversationRequestFake());
  });

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

  test('maps the cloud tool-call status vocabulary intentionally', () {
    expect(CloudMessageTools.resultStatus('pending'), isNull);
    expect(CloudMessageTools.resultStatus('needsConfirmation'), isNull);
    expect(
      CloudMessageTools.resultStatus('approved'),
      ToolCallResultStatus.running,
    );
    expect(
      CloudMessageTools.resultStatus('running'),
      ToolCallResultStatus.running,
    );
    expect(
      CloudMessageTools.resultStatus('success'),
      ToolCallResultStatus.success,
    );
    expect(
      CloudMessageTools.resultStatus('denied'),
      ToolCallResultStatus.skippedByUser,
    );
    expect(
      CloudMessageTools.resultStatus('toolNotFound'),
      ToolCallResultStatus.toolNotFound,
    );
    expect(
      CloudMessageTools.resultStatus('disabledInWorkspace'),
      ToolCallResultStatus.disabledInWorkspace,
    );
    expect(
      CloudMessageTools.resultStatus('disabledInConversation'),
      ToolCallResultStatus.disabledInConversation,
    );
    expect(
      CloudMessageTools.resultStatus('disabledByAgent'),
      ToolCallResultStatus.disabledByAgent,
    );
    expect(
      CloudMessageTools.resultStatus('notConfigured'),
      ToolCallResultStatus.notConfigured,
    );
    expect(
      CloudMessageTools.resultStatus('executionError'),
      ToolCallResultStatus.executionError,
    );
    expect(
      CloudMessageTools.resultStatus('unknown'),
      ToolCallResultStatus.executionError,
    );
  });

  test('cloud pending tool calls become approval inputs', () {
    final now = DateTime.utc(2026);
    final pendingCalls = CloudMessageTools.pendingToolCalls(
      _cloudState(
        projectionRevision: 7,
        messages: [
          ConversationMessageView(
            id: 'message-1',
            conversationId: _chatId,
            turnId: 'turn-1',
            turnRevision: 11,
            role: 'assistant',
            kind: 'message',
            status: 'awaitingApproval',
            content: '',
            toolCalls: const [],
            revision: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        toolCalls: [
          ConversationToolCallView(
            id: 'tool-call-1',
            turnId: 'turn-1',
            messageId: 'message-1',
            name: 'load_skill',
            argumentsJson: '{"slug":"research"}',
            argumentsDigest: 'digest-1',
            status: 'pending',
            revision: 3,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );

    expect(pendingCalls, hasLength(1));
    expect(pendingCalls.single.toolCall.turnId, 'turn-1');
    expect(pendingCalls.single.toolCall.turnRevision, 11);
    expect(pendingCalls.single.toolCall.argumentsDigest, 'digest-1');
    expect(pendingCalls.single.messageId, 'message-1');
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

    final repo = _StubConversationRepository(watchStream: controller.stream);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          conversationRepositoryProvider.overrideWithValue(repo),
          conversationChatProvider(
            _workspaceId,
            _chatId,
          ).overrideWith(_ForeverLoadingChatNotifier.new),
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
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(
            _workspaceId,
            _chatId,
          ).overrideWith(_ErrorChatNotifier.new),
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

    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
  });

  testWidgets('shows error for ConversationNotFound result', (tester) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId, _chatId).overrideWith(
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

    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
  });

  testWidgets('shows error for ConversationWorkspaceMismatch result', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(_chatId),
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId, _chatId).overrideWith(
            () => _ResultChatNotifier(const ConversationWorkspaceMismatch()),
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

    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
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
          conversationRepositoryProvider.overrideWithValue(
            _StubConversationRepository(),
          ),
          conversationChatProvider(_workspaceId, _chatId).overrideWith(
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

    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
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

  testWidgets('renders ChatConversationScreen when ConversationFound', (
    tester,
  ) async {
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
                  workspaceSessionForRouteProvider(
                    _workspaceId,
                  ).overrideWithValue(
                    const AsyncData(
                      WorkspaceSession(
                        LocalWorkspaceRef(localWorkspaceId: _workspaceId),
                      ),
                    ),
                  ),
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  conversationRepositoryProvider.overrideWithValue(
                    _StubConversationRepository(),
                  ),
                  conversationChatProvider(_workspaceId, _chatId).overrideWith(
                    () => _ResultChatNotifier(ConversationFound(conversation)),
                  ),
                  conversationBusyStateProvider.overrideWith(
                    (ref, _) async => const ConversationBusyState(
                      isStreaming: false,
                      hasPendingTools: false,
                    ),
                  ),
                  chatMessagesProvider.overrideWith(
                    (ref, _) => Stream.value(const <MessageEntity>[]),
                  ),
                  chatMessageIdsProvider.overrideWith(
                    (ref, _) => const <String>[],
                  ),
                  contextUsageProvider.overrideWith(
                    (ref, _) => ContextUsageData.compute(
                      usedTokens: 0,
                      limitTokens: null,
                    ),
                  ),
                  pendingToolCallsProvider.overrideWith(
                    (ref, _) async => const <PendingToolCall>[],
                  ),
                  listModelsGroupedByProviderProvider(
                    workspaceId: _workspaceId,
                  ).overrideWith((ref) => Stream.value(const {})),
                  agentsProvider(
                    _workspaceId,
                  ).overrideWith((ref) => Stream.value(const [])),
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
  });

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
                  workspaceSessionForRouteProvider(
                    _workspaceId,
                  ).overrideWithValue(
                    const AsyncData(
                      WorkspaceSession(
                        LocalWorkspaceRef(localWorkspaceId: _workspaceId),
                      ),
                    ),
                  ),
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  conversationRepositoryProvider.overrideWithValue(
                    _StubConversationRepository(),
                  ),
                  conversationChatProvider(_workspaceId, _chatId).overrideWith(
                    () => _ResultChatNotifier(ConversationFound(conversation)),
                  ),
                  conversationBusyStateProvider.overrideWith(
                    (ref, _) async => const ConversationBusyState(
                      isStreaming: false,
                      hasPendingTools: false,
                    ),
                  ),
                  chatMessagesProvider.overrideWith(
                    (ref, _) => Stream.value(const <MessageEntity>[]),
                  ),
                  chatMessageIdsProvider.overrideWith(
                    (ref, _) => const <String>[],
                  ),
                  contextUsageProvider.overrideWith(
                    (ref, _) => ContextUsageData.compute(
                      usedTokens: 0,
                      limitTokens: null,
                    ),
                  ),
                  pendingToolCallsProvider.overrideWith(
                    (ref, _) async => const <PendingToolCall>[],
                  ),
                  listModelsGroupedByProviderProvider(
                    workspaceId: _workspaceId,
                  ).overrideWith((ref) => Stream.value(const {})),
                  agentsProvider(
                    _workspaceId,
                  ).overrideWith((ref) => Stream.value(const [])),
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

  testWidgets('keeps input busy while busy state refreshes', (tester) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final refreshCompleter = Completer<ConversationBusyState>();
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: _workspaceId),
          ),
        ).overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: _workspaceId),
          ),
        ),
        workspaceSessionForRouteProvider(_workspaceId).overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: _workspaceId)),
          ),
        ),
        conversationSelectedProvider.overrideWithValue(_chatId),
        conversationRepositoryProvider.overrideWithValue(
          _StubConversationRepository(),
        ),
        conversationChatProvider(_workspaceId, _chatId).overrideWith(
          () => _ResultChatNotifier(ConversationFound(conversation)),
        ),
        conversationBusyStateProvider.overrideWith((ref, _) {
          final refresh = ref.watch(_busyRefreshProvider);
          if (refresh == 0) {
            return Future.value(
              const ConversationBusyState(
                isStreaming: true,
                hasPendingTools: false,
              ),
            );
          }

          return refreshCompleter.future;
        }),
        chatMessagesProvider.overrideWith(
          (ref, _) => Stream.value(const <MessageEntity>[]),
        ),
        chatMessageIdsProvider.overrideWith((ref, _) => const <String>[]),
        contextUsageProvider.overrideWith(
          (ref, _) =>
              ContextUsageData.compute(usedTokens: 0, limitTokens: null),
        ),
        pendingToolCallsProvider.overrideWith(
          (ref, _) async => const <PendingToolCall>[],
        ),
        listModelsGroupedByProviderProvider(
          workspaceId: _workspaceId,
        ).overrideWith((ref) => Stream.value(const {})),
        agentsProvider(
          _workspaceId,
        ).overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return UncontrolledProviderScope(
                container: container,
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

    expect(
      tester.widget<ChatInputWidget>(find.byType(ChatInputWidget)).isBusy,
      isTrue,
    );

    container.read(_busyRefreshProvider.notifier).refresh();
    await tester.pump();

    expect(
      tester.widget<ChatInputWidget>(find.byType(ChatInputWidget)).isBusy,
      isTrue,
    );
  });

  testWidgets('shows rate-limit retry countdown and marks input busy', (
    tester,
  ) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final retryAt = DateTime.now().add(const Duration(seconds: 30));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return TestProviderScope(
                overrides: [
                  workspaceSessionForRouteProvider(
                    _workspaceId,
                  ).overrideWithValue(
                    const AsyncData(
                      WorkspaceSession(
                        LocalWorkspaceRef(localWorkspaceId: _workspaceId),
                      ),
                    ),
                  ),
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  conversationRepositoryProvider.overrideWithValue(
                    _StubConversationRepository(),
                  ),
                  conversationChatProvider(_workspaceId, _chatId).overrideWith(
                    () => _ResultChatNotifier(ConversationFound(conversation)),
                  ),
                  conversationBusyStateProvider.overrideWith(
                    (ref, _) async => const ConversationBusyState(
                      isStreaming: false,
                      hasPendingTools: false,
                    ),
                  ),
                  conversationRateLimitRetryProvider.overrideWith(
                    () => _StaticRateLimitRetryNotifier(retryAt),
                  ),
                  chatMessagesProvider.overrideWith(
                    (ref, _) => Stream.value(const <MessageEntity>[]),
                  ),
                  chatMessageIdsProvider.overrideWith(
                    (ref, _) => const <String>[],
                  ),
                  contextUsageProvider.overrideWith(
                    (ref, _) => ContextUsageData.compute(
                      usedTokens: 0,
                      limitTokens: null,
                    ),
                  ),
                  pendingToolCallsProvider.overrideWith(
                    (ref, _) async => const <PendingToolCall>[],
                  ),
                  listModelsGroupedByProviderProvider(
                    workspaceId: _workspaceId,
                  ).overrideWith((ref) => Stream.value(const {})),
                  agentsProvider(
                    _workspaceId,
                  ).overrideWith((ref) => Stream.value(const [])),
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

    expect(find.textContaining('Rate limit reached'), findsOneWidget);
    final input = tester.widget<ChatInputWidget>(find.byType(ChatInputWidget));
    expect(input.isBusy, isTrue);
  });

  testWidgets(
    'routes cloud Continue with the authoritative projection revision',
    (tester) async {
      final endpoint = _CloudConversationEndpoint();
      when(
        () => endpoint.continueConversation(any()),
      ).thenAnswer((_) async => _cloudSnapshot());
      final usecase = _cloudTurnUsecase(endpoint);

      await _pumpCloudConversationScreen(
        tester,
        initialState: _cloudState(projectionRevision: 42),
        updates: const Stream.empty(),
        usecase: usecase,
      );

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pump();
      await tester.pump();

      final request =
          verify(
                () => endpoint.continueConversation(captureAny()),
              ).captured.single
              as ContinueConversationRequest;
      expect(request.conversationId, _chatId);
      expect(request.expectedProjectionRevision, 42);
    },
  );

  testWidgets(
    'does not route cloud Continue after authoritative state becomes running',
    (tester) async {
      final endpoint =
          await _expectCloudContinueToBeIgnoredWhenStateBecomesBusy(
            tester,
            executionState: 'running',
          );

      expect(
        () => verifyNever(() => endpoint.continueConversation(any())),
        returnsNormally,
      );
    },
  );

  testWidgets(
    'does not route cloud Continue after authoritative state awaits approval',
    (tester) async {
      final endpoint =
          await _expectCloudContinueToBeIgnoredWhenStateBecomesBusy(
            tester,
            executionState: 'awaitingApproval',
          );

      expect(
        () => verifyNever(() => endpoint.continueConversation(any())),
        returnsNormally,
      );
    },
  );
}

Future<void> _pumpCloudConversationScreen(
  WidgetTester tester, {
  required CloudConversationState initialState,
  required Stream<CloudConversationState> updates,
  CloudTurnUsecase? usecase,
  Future<CloudTurnUsecase?>? usecaseFuture,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final conversation = ConversationEntity(
    id: _chatId,
    title: 'Chat',
    workspaceId: _workspaceId,
    isPinned: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final cloudUsecase = usecaseFuture ?? Future.value(usecase);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) {
            return TestProviderScope(
              overrides: [
                workspaceSessionForRouteProvider(
                  _workspaceId,
                ).overrideWithValue(
                  const AsyncData(
                    WorkspaceSession(
                      CloudWorkspaceRef(
                        localWorkspaceId: _workspaceId,
                        serverUrl: 'https://example.com',
                        accountId: 'account',
                        cloudWorkspaceId: 7,
                      ),
                    ),
                  ),
                ),
                conversationSelectedProvider.overrideWithValue(_chatId),
                conversationRepositoryProvider.overrideWithValue(
                  _StubConversationRepository(),
                ),
                conversationChatProvider(_workspaceId, _chatId).overrideWith(
                  () => _ResultChatNotifier(ConversationFound(conversation)),
                ),
                conversationBusyStateProvider.overrideWith(
                  (ref, _) async => const ConversationBusyState(
                    isStreaming: false,
                    hasPendingTools: false,
                  ),
                ),
                cloudConversationStateProvider.overrideWith((ref, _) async* {
                  yield initialState;
                  yield* updates;
                }),
                cloudTurnUsecaseProvider(
                  _workspaceId,
                ).overrideWith((ref) => cloudUsecase),
                chatMessagesProvider.overrideWith(
                  (ref, _) => Stream.value(const <MessageEntity>[]),
                ),
                chatMessageIdsProvider.overrideWith(
                  (ref, _) => const <String>[],
                ),
                contextUsageProvider.overrideWith(
                  (ref, _) => ContextUsageData.compute(
                    usedTokens: 0,
                    limitTokens: null,
                  ),
                ),
                listModelsGroupedByProviderProvider(
                  workspaceId: _workspaceId,
                ).overrideWith((ref) => Stream.value(const {})),
                agentsProvider(
                  _workspaceId,
                ).overrideWith((ref) => Stream.value(const [])),
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
}

Future<_CloudConversationEndpoint>
_expectCloudContinueToBeIgnoredWhenStateBecomesBusy(
  WidgetTester tester, {
  required String executionState,
}) async {
  final endpoint = _CloudConversationEndpoint();
  when(
    () => endpoint.continueConversation(any()),
  ).thenAnswer((_) async => _cloudSnapshot());
  final usecaseCompleter = Completer<CloudTurnUsecase?>();
  final updates = StreamController<CloudConversationState>();
  addTearDown(updates.close);

  await _pumpCloudConversationScreen(
    tester,
    initialState: _cloudState(projectionRevision: 42),
    updates: updates.stream,
    usecaseFuture: usecaseCompleter.future,
  );

  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pump();
  await tester.tap(find.byIcon(Icons.play_circle_outline));
  await tester.pump();

  updates.add(
    _cloudState(projectionRevision: 43, executionState: executionState),
  );
  await tester.pump();
  final _ = usecaseCompleter.complete(_cloudTurnUsecase(endpoint));
  await tester.pump();
  await tester.pump();

  return endpoint;
}

CloudTurnUsecase _cloudTurnUsecase(_CloudConversationEndpoint endpoint) {
  final gateway = _CloudWorkspaceGateway();
  final client = _CloudClient();
  when(() => gateway.workspace).thenReturn(
    const CloudWorkspaceRef(
      localWorkspaceId: _workspaceId,
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    ),
  );
  when(() => gateway.client).thenReturn(client);
  when(() => client.conversation).thenReturn(endpoint);

  return CloudTurnUsecase(CloudChatGateway(gateway));
}

CloudConversationState _cloudState({
  required int projectionRevision,
  String executionState = 'idle',
  List<ConversationMessageView> messages = const [],
  List<ConversationToolCallView> toolCalls = const [],
}) => CloudConversationState(
  conversation: ConversationProjectionView(
    id: _chatId,
    workspaceId: 7,
    executionState: executionState,
    projectionRevision: projectionRevision,
    sequence: projectionRevision,
    updatedAt: DateTime.utc(2026),
  ),
  messages: messages,
  pendingMessages: const [],
  activeExecution: null,
  toolCalls: toolCalls,
  sequence: projectionRevision,
);

ConversationSnapshot _cloudSnapshot() => ConversationSnapshot(
  conversation: ConversationProjectionView(
    id: _chatId,
    workspaceId: 7,
    executionState: 'running',
    projectionRevision: 43,
    sequence: 43,
    updatedAt: DateTime.utc(2026),
  ),
  messages: const [],
  pendingMessages: const [],
  toolCalls: const [],
  sequence: 43,
);

class _CloudWorkspaceGateway extends Mock
    implements CloudWorkspaceStateGateway {}

class _CloudClient extends Mock implements Client {}

class _CloudConversationEndpoint extends Mock implements EndpointConversation {}

class _ContinueConversationRequestFake extends Fake
    implements ContinueConversationRequest {}

class _ForeverLoadingChatNotifier extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(String workspaceId, String conversationId) {
    return Completer<ConversationResult>().future;
  }
}

class _ErrorChatNotifier extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(
    String workspaceId,
    String conversationId,
  ) async {
    throw Exception('test error');
  }
}

class _ResultChatNotifier extends ConversationChatNotifier {
  _ResultChatNotifier(this.result);
  final ConversationResult result;

  @override
  Future<ConversationResult> build(
    String workspaceId,
    String conversationId,
  ) async => result;
}

class _StaticRateLimitRetryNotifier extends ConversationRateLimitRetryNotifier {
  _StaticRateLimitRetryNotifier(this.retryDeadline);

  final DateTime retryDeadline;

  @override
  Map<String, DateTime> build() => {_chatId: retryDeadline};
}

class _BusyRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() {
    state = state + 1;
  }
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
}
