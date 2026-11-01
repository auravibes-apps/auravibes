// Required: Widget tests override scoped providers directly.
// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/model_usage_aggregation.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/models/background_work_continuation_preview.dart';
import 'package:auravibes_app/features/chats/models/cloud_conversation_state.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/background_work_continuation_provider.dart';
import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/features/chats/providers/conversation_archive_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/providers/model_usage_provider.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/active_sub_agent_status_widget.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_continuation_status.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_detach_controls.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_thinking_indicator.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_provider_scope.dart';

const _workspaceId = 'ws-1';
const _chatId = 'chat-1';

final _busyRefreshProvider = NotifierProvider<_BusyRefreshNotifier, int>(
  _BusyRefreshNotifier.new,
);

Override _incompleteAgentContextOverride() =>
    conversationArchiveIncompleteContextProvider((
      workspaceId: _workspaceId,
      conversationId: _chatId,
    )).overrideWith((ref) => Stream.value(false));

void main() {
  setUpAll(() {
    registerFallbackValue(_ContinueConversationRequestFake());
  });

  test('agent stop notifier queues only user-visible stop decisions', () {
    final provider = conversationAgentStopDecisionProvider(_chatId);
    final uncappedContainer = ProviderContainer();
    addTearDown(uncappedContainer.dispose);
    uncappedContainer.read(provider.notifier).markIfAgentStopDecision(.done);
    expect(uncappedContainer.read(provider), isNull);

    final cappedContainer = ProviderContainer();
    addTearDown(cappedContainer.dispose);
    cappedContainer
        .read(provider.notifier)
        .markIfAgentStopDecision(.iterationLimitReached);
    expect(
      cappedContainer.read(provider),
      AgentIterationDecision.iterationLimitReached,
    );
    expect(
      cappedContainer.read(provider.notifier).consume(),
      AgentIterationDecision.iterationLimitReached,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
      CloudMessageTools.resultStatus('runningInBackground'),
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
            name: 'activate_skill',
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

  test(
    'cloud pending calls from inherited messages stay read-only history',
    () {
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
              status: 'sent',
              content: '',
              isForkReference: true,
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
              name: 'activate_skill',
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

      expect(pendingCalls, isEmpty);
    },
  );

  test('ConversationResult subclasses have correct types', () {
    const notFound = ConversationNotFound();
    const mismatch = ConversationWorkspaceMismatch();
    final found = ConversationFound(
      .new(
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
          ..._emptyBackgroundWorkOverrides(),
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
          ..._emptyBackgroundWorkOverrides(),
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
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
  });

  testWidgets('shows error for ConversationNotFound result', (tester) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          ..._emptyBackgroundWorkOverrides(),
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
          ..._emptyBackgroundWorkOverrides(),
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
      createdAt: .new(2026),
      updatedAt: .new(2026),
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
      .new(
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
          ..._emptyBackgroundWorkOverrides(),
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
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    expect(entity.hasValidTitle, isTrue);
  });

  test('ConversationEntity hasValidTitle returns false for empty title', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: '',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    expect(entity.hasValidTitle, isFalse);
  });

  test('ConversationEntity isValid returns true for valid data', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    expect(entity.isValid, isTrue);
  });

  test('ConversationEntity isValid returns false for empty workspaceId', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: '',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    expect(entity.isValid, isFalse);
  });

  test('ConversationEntity modelId can be null', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    expect(entity.modelId, isNull);
  });

  test('ConversationEntity modelId can be set', () {
    final entity = ConversationEntity(
      id: 'c1',
      title: 'Test',
      workspaceId: 'ws1',
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
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
      createdAt: .new(2026),
      updatedAt: .new(2026),
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
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    expect(entity.isPinned, isTrue);
  });

  testWidgets('opens usage details for the loaded conversation', (
    tester,
  ) async {
    final modelUsageRepository = _ModelUsageRepositoryMock();
    final usageRecords = [
      ModelUsageRecord(
        id: 'generation',
        conversationId: _chatId,
        providerId: 'anthropic',
        modelId: 'claude-sonnet-5-5',
        requestKind: .generation,
        outcome: .succeeded,
        usage: const .new(
          promptTokens: 12,
          responseTokens: 4,
          totalTokens: 16,
          cacheReadInputTokens: 2,
          cacheCreationInputTokens: 1,
        ),
        costStatus: .known,
        costUsd: 0.005,
        createdAt: .utc(2026),
      ),
      ModelUsageRecord(
        id: 'compaction',
        conversationId: _chatId,
        providerId: 'anthropic',
        modelId: 'claude-sonnet-5-5',
        requestKind: .compaction,
        outcome: .failed,
        usage: null,
        costStatus: .unknown,
        costUsd: null,
        createdAt: .utc(2026, 1, 2),
      ),
    ];
    when(() => modelUsageRepository.getRecordsForConversation(_chatId))
        .thenAnswer((_) async => usageRecords);
    when(() => modelUsageRepository.getTotalsForConversation(_chatId))
        .thenAnswer((_) async => ModelUsageAggregation.aggregate(usageRecords));

    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return TestProviderScope(
                overrides: [
                  ..._emptyBackgroundWorkOverrides(),
                  conversationSkillSelectorProvider(
                    _workspaceId,
                    _chatId,
                  ).overrideWith(
                    (ref) async => const ConversationSkillSelectorState(
                      loaded: [],
                      loadable: [],
                    ),
                  ),
                  workspaceSessionForRouteProvider(_workspaceId)
                      .overrideWithValue(
                        const AsyncData(
                          WorkspaceSession(
                            LocalWorkspaceRef(localWorkspaceId: _workspaceId),
                          ),
                        ),
                      ),
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  _incompleteAgentContextOverride(),
                  conversationRepositoryProvider.overrideWithValue(
                    _StubConversationRepository(),
                  ),
                  modelUsageRepositoryProvider.overrideWithValue(
                    modelUsageRepository,
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
                  listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
                      .overrideWith((ref) => Stream.value(const {})),
                  agentsProvider(_workspaceId)
                      .overrideWith((ref) => Stream.value(const [])),
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
    final usageButton = find.byKey(
      const ValueKey<String>('model-usage-button'),
    );
    expect(usageButton, findsOneWidget);
    await tester.tap(usageButton);
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(find.text('Model usage'), findsOneWidget);
    expect(find.text('Generation'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Compaction'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Compaction'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Unknown'), findsWidgets);
    final aggregateCostRow = find
        .ancestor(
          of: find.text('Estimated cost (USD)').first,
          matching: find.byType(Row),
        )
        .first;
    expect(
      find.descendant(of: aggregateCostRow, matching: find.text('Unknown')),
      findsOneWidget,
    );
    verify(() => modelUsageRepository.getRecordsForConversation(_chatId))
        .called(1);
    verify(() => modelUsageRepository.getTotalsForConversation(_chatId))
        .called(1);
  });

  testWidgets('opens saved messages scoped to the loaded conversation', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/conversation',
          builder: (_, _) => const ChatConversationScreen(
            workspaceId: _workspaceId,
            chatId: _chatId,
          ),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/bookmarks',
          builder: (_, state) => Text(
            'Bookmarks ${state.pathParameters['workspaceId']} '
            '${state.uri.queryParameters['conversation-id']}',
          ),
        ),
      ],
      initialLocation: '/conversation',
    );
    addTearDown(router.dispose);

    await _pumpCloudConversationScreen(
      tester,
      initialState: _cloudState(projectionRevision: 42),
      updates: const Stream.empty(),
      router: router,
    );

    final bookmarksButton = find.byTooltip('Saved messages');
    expect(bookmarksButton, findsOneWidget);
    await tester.tap(bookmarksButton);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Bookmarks ws-1 chat-1'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/workspaces/ws-1/bookmarks?conversation-id=chat-1',
    );
  });

  testWidgets('passes compaction and tool access state to chat input', (
    tester,
  ) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      toolAccessMode: .allowAll,
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return TestProviderScope(
                overrides: [
                  ..._emptyBackgroundWorkOverrides(),
                  conversationSkillSelectorProvider(
                    _workspaceId,
                    _chatId,
                  ).overrideWith(
                    (ref) async => const ConversationSkillSelectorState(
                      loaded: [],
                      loadable: [],
                    ),
                  ),
                  workspaceSessionForRouteProvider(_workspaceId)
                      .overrideWithValue(
                        const AsyncData(
                          WorkspaceSession(
                            LocalWorkspaceRef(localWorkspaceId: _workspaceId),
                          ),
                        ),
                      ),
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  _incompleteAgentContextOverride(),
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
                  listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
                      .overrideWith((ref) => Stream.value(const {})),
                  agentsProvider(_workspaceId)
                      .overrideWith((ref) => Stream.value(const [])),
                  compactionExecutionStateProvider(_chatId).overrideWithValue(
                    .new(
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
    expect(input.toolAccessMode, ConversationToolAccessMode.allowAll);
    expect(input.onToolAccessModeChanged, isNotNull);
    final control = find.byKey(const ValueKey<String>('chat_tool_access_mode'));
    await tester.tap(control);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Default'));
    await tester.pump();
    expect(
      tester
          .widget<ChatInputWidget>(find.byType(ChatInputWidget))
          .toolAccessMode,
      ConversationToolAccessMode.defaultMode,
    );
    await tester.tap(control);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Allow all'));
    await tester.pump();
    expect(
      tester
          .widget<ChatInputWidget>(find.byType(ChatInputWidget))
          .toolAccessMode,
      ConversationToolAccessMode.allowAll,
    );
  });

  testWidgets('shows and updates active sub-agent status in chat controls', (
    tester,
  ) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    final container = ProviderContainer(
      overrides: [
        ..._emptyBackgroundWorkOverrides(),
        conversationSkillSelectorProvider(_workspaceId, _chatId).overrideWith(
          (ref) async =>
              const ConversationSkillSelectorState(loaded: [], loadable: []),
        ),
        workspaceSessionForRouteProvider(_workspaceId).overrideWithValue(
          const AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: _workspaceId)),
          ),
        ),
        conversationSelectedProvider.overrideWithValue(_chatId),
        _incompleteAgentContextOverride(),
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
        chatMessageIdsProvider.overrideWith((ref, _) => const <String>[]),
        contextUsageProvider.overrideWith(
          (ref, _) =>
              ContextUsageData.compute(usedTokens: 0, limitTokens: null),
        ),
        pendingToolCallsProvider.overrideWith(
          (ref, _) async => const <PendingToolCall>[],
        ),
        listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
            .overrideWith((ref) => Stream.value(const {})),
        agentsProvider(_workspaceId)
            .overrideWith((ref) => Stream.value(const [])),
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
                  home: const AuraLegacyMaterialBridge(
                    child: ChatConversationScreen(
                      workspaceId: _workspaceId,
                      chatId: _chatId,
                    ),
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

    final status = find.byKey(const ValueKey<String>('chat_active_sub_agents'));
    expect(status, findsNothing);

    final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
    final firstRequest = runtime.start(parentId: _chatId, childId: 'child-1');
    await tester.pump();
    expect(status, findsOneWidget);
    expect(
      find.descendant(of: status, matching: find.text('1')),
      findsOneWidget,
    );

    final secondRequest = runtime.start(parentId: _chatId, childId: 'child-2');
    await tester.pump();
    expect(
      find.descendant(of: status, matching: find.text('2')),
      findsOneWidget,
    );

    firstRequest.finish();
    await tester.pump();
    expect(
      find.descendant(of: status, matching: find.text('1')),
      findsOneWidget,
    );

    secondRequest.finish();
    await tester.pump();
    expect(status, findsNothing);
  });

  testWidgets('resizes active sub-agent action with Aura target updates', (
    tester,
  ) async {
    final theme = ValueNotifier(AuraTheme.light);
    addTearDown(theme.dispose);
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: [_childConversation('child-1', 'Research')],
      themeListenable: theme,
    );
    final request = container
        .read(activeSubAgentRuntimeProvider.notifier)
        .start(parentId: _chatId, childId: 'child-1');
    await tester.pump();

    final status = find.byKey(const ValueKey<String>('chat_active_sub_agents'));
    final badge = find.descendant(
      of: status,
      matching: find.byType(AuraContainer),
    );
    expect(status, findsOneWidget);
    final initialTargetSize = tester.getSize(status);
    expect(initialTargetSize.width, greaterThanOrEqualTo(48));
    expect(initialTargetSize.height, greaterThanOrEqualTo(48));
    final compactBadgeSize = tester.getSize(badge);

    theme.value = AuraTheme.light.copyWith(
      interactionSizes: const AuraInteractionSizeScale(minimumTargetSize: 72),
    );
    final _ = await tester.pumpAndSettle();

    final updatedTargetSize = tester.getSize(status);
    expect(updatedTargetSize.width, greaterThanOrEqualTo(72));
    expect(updatedTargetSize.height, greaterThanOrEqualTo(72));
    expect(tester.getSize(badge), compactBadgeSize);
    final _ = request.finish();
  });

  testWidgets('keeps input busy while busy state refreshes', (tester) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    final refreshCompleter = Completer<ConversationBusyState>();
    final container = ProviderContainer(
      overrides: [
        ..._emptyBackgroundWorkOverrides(),
        conversationSkillSelectorProvider(_workspaceId, _chatId).overrideWith(
          (ref) async =>
              const ConversationSkillSelectorState(loaded: [], loadable: []),
        ),
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
        _incompleteAgentContextOverride(),
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
                isStreaming: false,
                hasPendingTools: false,
                isAgentWorking: true,
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
        listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
            .overrideWith((ref) => Stream.value(const {})),
        agentsProvider(_workspaceId)
            .overrideWith((ref) => Stream.value(const [])),
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
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    expect(find.byType(ChatThinkingIndicator), findsOneWidget);

    container.read(_busyRefreshProvider.notifier).refresh();
    await tester.pump();

    expect(
      tester.widget<ChatInputWidget>(find.byType(ChatInputWidget)).isBusy,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    expect(find.byType(ChatThinkingIndicator), findsOneWidget);
  });

  testWidgets('shows retry and iteration-limit notices and marks input busy', (
    tester,
  ) async {
    final conversation = ConversationEntity(
      id: _chatId,
      title: 'Chat',
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    final retryAt = DateTime.now().add(const Duration(seconds: 30));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return TestProviderScope(
                overrides: [
                  ..._emptyBackgroundWorkOverrides(),
                  conversationSkillSelectorProvider(
                    _workspaceId,
                    _chatId,
                  ).overrideWith(
                    (ref) async => const ConversationSkillSelectorState(
                      loaded: [],
                      loadable: [],
                    ),
                  ),
                  workspaceSessionForRouteProvider(_workspaceId)
                      .overrideWithValue(
                        const AsyncData(
                          WorkspaceSession(
                            LocalWorkspaceRef(localWorkspaceId: _workspaceId),
                          ),
                        ),
                      ),
                  conversationSelectedProvider.overrideWithValue(_chatId),
                  _incompleteAgentContextOverride(),
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
                      isAgentWorking: true,
                    ),
                  ),
                  conversationRateLimitRetryProvider.overrideWith(
                    () => _StaticRateLimitRetryNotifier(retryAt),
                  ),
                  conversationAgentStopDecisionProvider(_chatId).overrideWith(
                    () => _StaticAgentStopDecisionNotifier(
                      .iterationLimitReached,
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
                  listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
                      .overrideWith((ref) => Stream.value(const {})),
                  agentsProvider(_workspaceId)
                      .overrideWith((ref) => Stream.value(const [])),
                ],
                child: MaterialApp(
                  home: const ChatConversationScreen(
                    workspaceId: _workspaceId,
                    chatId: _chatId,
                  ),
                  builder: (_, child) =>
                      AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
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
    expect(
      find.text(
        'The agent reached its iteration limit. Partial output and completed '
        'tool results are available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue agent'), findsOneWidget);
    expect(find.text('Waiting to retry'), findsOneWidget);
    final retryText = tester.widget<Text>(
      find.textContaining('Rate limit reached'),
    );
    expect(
      retryText.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    final input = tester.widget<ChatInputWidget>(find.byType(ChatInputWidget));
    expect(input.isBusy, isTrue);
    expect(
      find.byKey(const ValueKey<String>('chat_stop_generation')),
      findsOneWidget,
    );
    expect(find.byType(ChatThinkingIndicator), findsNothing);

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacement<void, void>(
          MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Continue agent'), findsOneWidget);
    _activateSnackBarAction(tester, 'Continue agent');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('stops continuation if route unmounts during cloud lookup', (
    tester,
  ) async {
    final usecaseCompleter = Completer<CloudTurnUsecase?>();
    await _pumpCloudConversationScreen(
      tester,
      initialState: _cloudState(projectionRevision: 42),
      updates: const Stream.empty(),
      usecaseFuture: usecaseCompleter.future,
      iterationLimitReached: true,
    );

    expect(find.text('Continue agent'), findsOneWidget);
    _activateSnackBarAction(tester, 'Continue agent');
    await tester.pump();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacement<void, void>(
          MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        );
    final _ = await tester.pumpAndSettle();
    usecaseCompleter.complete(null);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a distinct notice when a repeated tool loop stops', (
    tester,
  ) async {
    await _pumpCloudConversationScreen(
      tester,
      initialState: _cloudState(projectionRevision: 42),
      updates: const Stream.empty(),
      repeatedToolLoopDetected: true,
    );

    expect(
      find.text(
        'The agent stopped because the same tool calls kept returning the '
        'same results. Partial output and completed tool results are '
        'available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue agent'), findsOneWidget);
  });

  testWidgets('stops retry if route unmounts during cloud lookup', (
    tester,
  ) async {
    final usecaseCompleter = Completer<CloudTurnUsecase?>();
    final retryableMessage = MessageEntity(
      id: 'retry-user-message',
      conversationId: _chatId,
      content: 'Original prompt',
      messageType: .text,
      isUser: true,
      status: .unfinished,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );
    await _pumpCloudConversationScreen(
      tester,
      initialState: _cloudState(projectionRevision: 42),
      updates: const Stream.empty(),
      chatMessages: [retryableMessage],
      usecaseFuture: usecaseCompleter.future,
    );

    final retryButton = find.byKey(
      const ValueKey('retry_message_retry-user-message'),
    );
    expect(retryButton, findsOneWidget);
    await tester.tap(retryButton);
    await tester.pump();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacement<void, void>(
          MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        );
    final _ = await tester.pumpAndSettle();
    usecaseCompleter.complete(null);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'does not mount background status widgets when no work is available',
    (tester) async {
      await _pumpCloudConversationScreen(
        tester,
        initialState: _cloudState(projectionRevision: 42),
        updates: const Stream.empty(),
      );

      expect(find.byType(BackgroundWorkDetachControls), findsNothing);
      expect(find.byType(BackgroundWorkContinuationStatus), findsNothing);
    },
  );

  testWidgets(
    'shows saved background results without another conversation status',
    (tester) async {
      const result = 'Background work finished.';
      final work = BackgroundWorkView(
        id: 'work-1',
        workspaceId: 7,
        conversationId: _chatId,
        toolCallId: 'tool-call-1',
        toolKind: 'skillNative',
        status: 'completed',
        statusPreview: BackgroundWorkContinuationPreview.queued,
        resultContent: result,
        resultByteLength: result.length,
        createdAt: .utc(2026),
        updatedAt: .utc(2026),
      );

      await _pumpCloudConversationScreen(
        tester,
        initialState: _cloudState(projectionRevision: 42),
        updates: const Stream.empty(),
        backgroundWorks: [work],
      );

      expect(find.text('View result'), findsOneWidget);
      await tester.tap(find.text('View result'));
      final settledDuration = await tester.pumpAndSettle();
      expect(
        find.text(result),
        findsOneWidget,
        reason:
            'Background result dialog did not settle after $settledDuration.',
      );
    },
  );

  testWidgets('shows recovery when cloud conversation stream fails', (
    tester,
  ) async {
    var streamSubscriptions = 0;
    final updates = Stream<CloudConversationState>.multi((controller) {
      if (streamSubscriptions++ == 0) {
        controller.addError(
          const CloudConversationStreamFailure(
            localizationKey: LocaleKeys.cloud_errors_unavailable,
          ),
        );
      } else {
        controller.add(_cloudState(projectionRevision: 43));
      }
      unawaited(controller.close());
    });
    await _pumpCloudConversationScreen(
      tester,
      initialState: _cloudState(projectionRevision: 42),
      updates: updates,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('The cloud service is unavailable. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(streamSubscriptions, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('The cloud service is unavailable. Try again.'),
      findsNothing,
    );
    expect(streamSubscriptions, 2);
  });

  testWidgets(
    'routes cloud Continue with the authoritative projection revision',
    (tester) async {
      final endpoint = _CloudConversationEndpoint();
      when(() => endpoint.continueConversation(any()))
          .thenAnswer((_) async => _cloudSnapshot());
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
          verify(() => endpoint.continueConversation(captureAny()))
                  .captured
                  .single
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
    'does not route cloud Continue after a non-retryable provider failure',
    (tester) async {
      final endpoint = _CloudConversationEndpoint();
      when(() => endpoint.continueConversation(any()))
          .thenAnswer((_) async => _cloudSnapshot());
      final failedMessage = ConversationMessageView(
        id: 'failed-user-message',
        conversationId: _chatId,
        role: 'user',
        kind: 'message',
        status: 'error',
        content: 'Original prompt',
        metadataJson: jsonEncode(
          const MessageMetadataEntity(
            modelMetadata: {
              'providerError': true,
              'providerRecovery': {
                'classification': 'authentication',
                'retryable': false,
              },
            },
          ).toJson(),
        ),
        toolCalls: const [],
        revision: 1,
        createdAt: .utc(2026),
        updatedAt: .utc(2026),
      );

      await _pumpCloudConversationScreen(
        tester,
        initialState: _cloudState(
          projectionRevision: 42,
          executionState: 'failed',
          messages: [failedMessage],
        ),
        updates: const Stream.empty(),
        usecase: _cloudTurnUsecase(endpoint),
      );

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pump();
      await tester.pump();

      expect(
        () => verifyNever(() => endpoint.continueConversation(any())),
        returnsNormally,
      );
    },
  );

  testWidgets(
    'routes cloud Continue when a newer user turn follows a provider failure',
    (tester) async {
      final endpoint = _CloudConversationEndpoint();
      when(() => endpoint.continueConversation(any()))
          .thenAnswer((_) async => _cloudSnapshot());
      final failedMessage = ConversationMessageView(
        id: 'failed-user-message',
        conversationId: _chatId,
        role: 'user',
        kind: 'message',
        status: 'error',
        content: 'Original prompt',
        metadataJson: jsonEncode(
          const MessageMetadataEntity(
            modelMetadata: {
              'providerError': true,
              'providerRecovery': {
                'classification': 'authentication',
                'retryable': false,
              },
            },
          ).toJson(),
        ),
        toolCalls: const [],
        revision: 1,
        createdAt: .utc(2026),
        updatedAt: .utc(2026),
      );
      final latestUserMessage = failedMessage.copyWith(
        id: 'latest-user-message',
        status: 'sent',
        createdAt: .utc(2026, 2),
        updatedAt: .utc(2026, 2),
      );

      await _pumpCloudConversationScreen(
        tester,
        initialState: _cloudState(
          projectionRevision: 42,
          executionState: 'failed',
          messages: [latestUserMessage, failedMessage],
        ),
        updates: const Stream.empty(),
        usecase: _cloudTurnUsecase(endpoint),
      );

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pump();
      await tester.pump();

      verify(() => endpoint.continueConversation(any())).called(1);
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

  testWidgets('delegated chat names its parent and remains read-only', (
    tester,
  ) async {
    await _pumpCloudConversationScreen(
      tester,
      initialState: _cloudState(projectionRevision: 42),
      updates: const Stream.empty(),
      parentId: 'parent',
    );
    expect(find.text('Delegated task from Original task'), findsOneWidget);
    expect(
      find.text(
        'This delegated conversation is read-only. '
        'Continue the task in the parent chat.',
      ),
      findsOneWidget,
    );
    expect(find.text('Return to parent conversation'), findsOneWidget);
    expect(find.byType(ChatInputWidget), findsNothing);
    expect(find.text('No active response'), findsOneWidget);
  });

  testWidgets('hides active sub-agent action when no children are live', (
    tester,
  ) async {
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: const [],
    );
    expect(container.read(activeSubAgentRuntimeProvider), isEmpty);

    expect(
      find.byKey(const ValueKey<String>('chat_active_sub_agents')),
      findsNothing,
    );
  });

  testWidgets('routes one live child directly with localized semantics', (
    tester,
  ) async {
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: [_childConversation('child-1', 'Research')],
    );
    final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
    final request = runtime.start(parentId: _chatId, childId: 'child-1');
    await tester.pump();

    final status = find.byKey(const ValueKey<String>('chat_active_sub_agents'));
    final semantics = tester.ensureSemantics();
    final node = tester.getSemantics(status);
    expect(node.label, contains('1 sub-agent running'));
    expect(node.label, contains('View active sub-agents'));
    expect(node, matchesSemantics(isButton: true, hasTapAction: true));

    await tester.tap(status, kind: .mouse);
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(find.text('Opened child-1'), findsOneWidget);
    request.finish();

    semantics.dispose();
  });

  testWidgets('opens one live child with keyboard activation', (tester) async {
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: [_childConversation('child-1', 'Research')],
    );
    final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
    final request = runtime.start(parentId: _chatId, childId: 'child-1');
    await tester.pump();

    expect(await tester.sendKeyEvent(.tab), isTrue);
    expect(await tester.sendKeyEvent(.enter), isTrue);
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(find.text('Opened child-1'), findsOneWidget);
    request.finish();
  });

  testWidgets('offers persisted child titles in multi-child chooser', (
    tester,
  ) async {
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: [
        _childConversation('child-1', 'Research notes'),
        _childConversation('child-2', 'Write summary'),
      ],
    );
    final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
    final firstRequest = runtime.start(parentId: _chatId, childId: 'child-1');
    final secondRequest = runtime.start(parentId: _chatId, childId: 'child-2');
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('chat_active_sub_agents')),
    );
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(find.text('Active sub-agents'), findsOneWidget);
    expect(find.text('Research notes'), findsOneWidget);
    expect(find.text('Write summary'), findsOneWidget);

    await tester.tap(find.text('Write summary'));
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(find.text('Opened child-2'), findsOneWidget);
    firstRequest.finish();
    secondRequest.finish();
  });

  testWidgets('shows partial child status in the active-child chooser', (
    tester,
  ) async {
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: [
        _childConversation('partial', 'Partial child'),
        _childConversation('running', 'Running child'),
      ],
    );
    final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
    final partialRequest = runtime.start(parentId: _chatId, childId: 'partial');
    final runningRequest = runtime.start(parentId: _chatId, childId: 'running');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_active_sub_agents')),
    );
    final _ = await tester.pumpAndSettle();

    partialRequest.finish(status: .partial);
    await tester.pump();

    expect(find.text('Partial'), findsOneWidget);
    runningRequest.finish();
  });

  testWidgets('keeps live and terminal status details safe in chooser', (
    tester,
  ) async {
    final container = await _pumpActiveSubAgentStatusWidget(
      tester,
      childConversations: [
        _childConversation('running', 'Running child'),
        _childConversation('approval', 'Approval child'),
        _childConversation('failed', 'Failed child'),
        _childConversation('stopped', 'Stopped child'),
      ],
    );
    final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
    final requests = [
      for (final childId in ['running', 'approval', 'failed', 'stopped'])
        runtime.start(parentId: _chatId, childId: childId),
    ];
    runtime.markAwaitingApproval('approval');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('chat_active_sub_agents')),
    );
    expect(await tester.pumpAndSettle(), greaterThan(0));

    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('active_sub_agent_running')),
        matching: find.text('Running'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('active_sub_agent_approval')),
        matching: find.text('Awaiting approval'),
      ),
      findsOneWidget,
    );

    runtime
      ..finish((
        parentId: _chatId,
        childId: 'failed',
        status: .error,
        error: 'api_key=top-secret',
        stackTrace: StackTrace.fromString('stack-secret'),
      ))
      ..finish((
        parentId: _chatId,
        childId: 'stopped',
        status: .stopped,
        error: null,
        stackTrace: null,
      ));
    await tester.pump();

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Stopped'), findsOneWidget);
    expect(find.text('Error: api_key=[REDACTED]'), findsOneWidget);
    expect(find.textContaining('top-secret'), findsNothing);
    expect(find.textContaining('stack-secret'), findsNothing);

    for (final request in requests) {
      request.finish();
    }
  });
}

Future<ProviderContainer> _pumpActiveSubAgentStatusWidget(
  WidgetTester tester, {
  required List<ConversationEntity> childConversations,
  ValueListenable<AuraTheme>? themeListenable,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, state) => NoTransitionPage(
          child: const Scaffold(
            body: ActiveSubAgentStatusWidget(
              workspaceId: _workspaceId,
              conversationId: _chatId,
            ),
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/workspaces/:workspaceId/chats/:chatId/sub-agents/:subAgentConversationId',
        pageBuilder: (_, state) => NoTransitionPage(
          child: Scaffold(
            body: Text(
              'Opened ${state.pathParameters['subAgentConversationId']}',
            ),
          ),
          key: state.pageKey,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      childConversationsStreamProvider(
        _workspaceId,
        parentConversationId: _chatId,
      ).overrideWith((ref) => Stream.value(childConversations)),
    ],
  );
  addTearDown(container.dispose);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) {
              final listenable = themeListenable;
              if (listenable == null) {
                return MaterialApp.router(
                  routerConfig: router,
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                );
              }

              Widget appForTheme(AuraTheme theme) => MaterialApp.router(
                routerConfig: router,
                builder: (context, child) => AuraThemeScope(
                  theme: theme,
                  child: child ?? const SizedBox.shrink(),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              );

              return ValueListenableBuilder<AuraTheme>(
                valueListenable: listenable,
                builder: (context, theme, _) => appForTheme(theme),
              );
            },
          ),
        ),
        supportedLocales: const [Locale('en'), Locale('es')],
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
  expect(await tester.pumpAndSettle(), greaterThan(0));

  return container;
}

ConversationEntity _childConversation(String id, String title) =>
    ConversationEntity(
      id: id,
      title: title,
      workspaceId: _workspaceId,
      isPinned: false,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      parentConversationId: _chatId,
    );

Future<void> _pumpCloudConversationScreen(
  WidgetTester tester, {
  required CloudConversationState initialState,
  required Stream<CloudConversationState> updates,
  List<MessageEntity> chatMessages = const [],
  List<BackgroundWorkView> backgroundWorks = const [],
  CloudTurnUsecase? usecase,
  Future<CloudTurnUsecase?>? usecaseFuture,
  bool iterationLimitReached = false,
  bool repeatedToolLoopDetected = false,
  String? parentId,
  GoRouter? router,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final conversation = ConversationEntity(
    id: _chatId,
    title: 'Chat',
    workspaceId: _workspaceId,
    isPinned: false,
    createdAt: .new(2026),
    updatedAt: .new(2026),
    modelId: 'model-1',
    parentConversationId: parentId,
  );
  final cloudUsecase = usecaseFuture ?? Future.value(usecase);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) {
            final agentStopDecision = switch ((
              repeatedToolLoopDetected: repeatedToolLoopDetected,
              iterationLimitReached: iterationLimitReached,
            )) {
              (repeatedToolLoopDetected: true, iterationLimitReached: _) =>
                AgentIterationDecision.repeatedToolLoopDetected,
              (repeatedToolLoopDetected: false, iterationLimitReached: true) =>
                AgentIterationDecision.iterationLimitReached,
              _ => null,
            };
            Widget appBuilder(BuildContext _, Widget? child) =>
                AuraSnackBarHost(child: child ?? const SizedBox.shrink());
            final appBuilderOrNull = agentStopDecision != null
                ? appBuilder
                : null;
            final app = router == null
                ? MaterialApp(
                    home: ChatConversationScreen(
                      workspaceId: _workspaceId,
                      chatId: _chatId,
                      showInputComposer: parentId == null,
                    ),
                    builder: appBuilderOrNull,
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  )
                : MaterialApp.router(
                    routerConfig: router,
                    builder: appBuilderOrNull,
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  );

            return TestProviderScope(
              overrides: [
                ..._emptyBackgroundWorkOverrides(),
                backgroundWorkContinuationsProvider((
                  workspaceId: _workspaceId,
                  conversationId: _chatId,
                )).overrideWith((ref) async => backgroundWorks),
                if (parentId != null)
                  conversationByIdStreamProvider(
                    _workspaceId,
                    conversationId: parentId,
                  ).overrideWith(
                    (ref) => Stream.value(
                      conversation.copyWith(
                        id: parentId,
                        title: 'Original task',
                      ),
                    ),
                  ),
                conversationSkillSelectorProvider(
                  _workspaceId,
                  _chatId,
                ).overrideWith(
                  (ref) async => const ConversationSkillSelectorState(
                    loaded: [],
                    loadable: [],
                  ),
                ),
                workspaceSessionForRouteProvider(_workspaceId)
                    .overrideWithValue(
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
                if (agentStopDecision case final decision?)
                  conversationAgentStopDecisionProvider(_chatId).overrideWith(
                    () => _StaticAgentStopDecisionNotifier(decision),
                  ),
                cloudConversationStateProvider.overrideWith((ref, _) async* {
                  yield initialState;
                  yield* updates;
                }),
                cloudTurnUsecaseProvider(_workspaceId)
                    .overrideWith((ref) => cloudUsecase),
                workspaceModelSelectionByIdProvider(
                  _workspaceId,
                  'model-1',
                ).overrideWithValue(AsyncData(_cloudModelSelection())),
                chatMessagesProvider.overrideWith(
                  (ref, _) => Stream.value(chatMessages),
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
                listModelsGroupedByProviderProvider(workspaceId: _workspaceId)
                    .overrideWith((ref) => Stream.value(const {})),
                agentsProvider(_workspaceId)
                    .overrideWith((ref) => Stream.value(const [])),
              ],
              child: app,
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

List<Override> _emptyBackgroundWorkOverrides() => [
  conversationBackgroundWorksProvider(_chatId)
      .overrideWith((ref) => Stream.value(const [])),
  cloudConversationBackgroundWorksProvider((
    workspaceId: _workspaceId,
    conversationId: _chatId,
  )).overrideWith((ref) async => const []),
];

Future<_CloudConversationEndpoint>
_expectCloudContinueToBeIgnoredWhenStateBecomesBusy(
  WidgetTester tester, {
  required String executionState,
}) async {
  final endpoint = _CloudConversationEndpoint();
  when(() => endpoint.continueConversation(any()))
      .thenAnswer((_) async => _cloudSnapshot());
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

  return CloudTurnUsecase(.new(gateway));
}

CloudConversationState _cloudState({
  required int projectionRevision,
  String executionState = 'idle',
  List<ConversationMessageView> messages = const [],
  List<ConversationToolCallView> toolCalls = const [],
}) => CloudConversationState(
  conversation: .new(
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

WorkspaceModelSelectionWithConnectionEntity _cloudModelSelection() => .new(
  workspaceModelSelection: .new(
    id: 'model-1',
    modelId: 'gpt-5.5',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    modelConnectionId: 'connection-1',
  ),
  modelConnection: .new(
    id: 'connection-1',
    name: 'OpenAI',
    modelId: 'openai',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    workspaceId: _workspaceId,
    hasKey: true,
  ),
  modelsProvider: const ApiModelProviderEntity(
    id: 'openai',
    name: 'OpenAI',
    type: null,
  ),
);

ConversationSnapshot _cloudSnapshot() => ConversationSnapshot(
  conversation: .new(
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

class _CloudWorkspaceGateway extends Mock implements CloudWorkspaceStateGateway;

class _CloudClient extends Mock implements Client;

class _CloudConversationEndpoint extends Mock implements EndpointConversation;

class _ModelUsageRepositoryMock extends Mock implements ModelUsageRepository;

class _ContinueConversationRequestFake extends Fake
    implements ContinueConversationRequest;

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

class _ResultChatNotifier(final ConversationResult result)
    extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(
    String workspaceId,
    String conversationId,
  ) async => result;

  @override
  Future<void> setToolAccessMode(ConversationToolAccessMode mode) async {
    final current = state.requireValue as ConversationFound;
    state = AsyncData(
      ConversationFound(current.conversation.copyWith(toolAccessMode: mode)),
    );
  }
}

class _StaticRateLimitRetryNotifier(final DateTime retryDeadline)
    extends ConversationRateLimitRetryNotifier {
  @override
  Map<String, DateTime> build() => {_chatId: retryDeadline};
}

void _activateSnackBarAction(WidgetTester tester, String label) {
  final action = tester.widget<GestureDetector>(
    find
        .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
        .first,
  );
  final onTap = action.onTap;
  if (onTap == null) fail('Expected snackbar action to have a tap handler');
  onTap();
}

class _StaticAgentStopDecisionNotifier(final AgentIterationDecision decision)
    extends ConversationAgentStopDecisionNotifier {
  @override
  AgentIterationDecision? build() => decision;
}

class _BusyRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() {
    state = state + 1;
  }
}

class _StubConversationRepository({
  final Stream<ConversationEntity?>? watchStream,
}) implements ConversationRepository {
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
    String? search,
    int? limit,
    int offset = 0,
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

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();
}
