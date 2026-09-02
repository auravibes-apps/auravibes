// Required: Existing test and UI helpers keep compact return flow.

// Required: provider unit tests read scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as hooks;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:rxdart/rxdart.dart';

ProviderContainer _pendingToolContainer({List<Override> overrides = const []}) {
  return ProviderContainer(
    overrides: [
      workspaceSessionForRouteProvider.overrideWith(
        (_, workspaceId) =>
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: workspaceId)),
      ),
      loadConversationToolSpecsUsecaseProvider.overrideWith(
        (_, _) => const _FakeLoadConversationToolSpecsUsecase(),
      ),
      ...overrides,
    ],
  );
}

class const _FakeLoadConversationToolSpecsUsecase()
    implements LoadConversationToolSpecsUsecase {
  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async => (await buildCatalog(
    conversationId: conversationId,
    workspaceId: workspaceId,
  )).specs;

  @override
  Future<ToolCatalog<ResolvedTool>> buildCatalog({
    required String conversationId,
    required String workspaceId,
  }) async {
    return buildToolCatalog([
      ToolCatalogCandidate.external(
        spec: ToolSpec(
          name: 'built_in_calc_calculator',
          description: 'Calculator',
          inputJsonSchema: {},
        ),
        target: ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        ),
        sourceId: 'calc',
      ),
      ToolCatalogCandidate.external(
        spec: ToolSpec(
          name: 'native_ws-tool-url_url',
          description: 'URL',
          inputJsonSchema: {},
        ),
        target: ResolvedTool.native(
          tableId: 'url',
          nativeToolType: NativeToolType.url,
        ),
        sourceId: 'url',
      ),
    ]);
  }
}

MessageToolCallEntity _pendingToolCall({
  required String id,
  required String name,
}) {
  return MessageToolCallEntity(id: id, name: name, argumentsRaw: '{}');
}

MessageEntity _assistantMessage({
  required String id,
  required String conversationId,
  List<MessageToolCallEntity>? toolCalls,
}) {
  final now = DateTime(2026);

  return MessageEntity(
    id: id,
    conversationId: conversationId,
    content: 'assistant',
    messageType: MessageType.text,
    isUser: false,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: toolCalls != null
        ? MessageMetadataEntity(toolCalls: toolCalls)
        : null,
  );
}

class _FakeResolveToolApprovalDecisionUsecase(
  final Map<String, ToolApprovalDecision> _decisions,
) extends ResolveToolApprovalDecisionUsecase {
  this
    : super(
        conversationToolsRepository: _NoOpConversationToolsRepository(),
        toolsGroupsRepository: _NoOpToolsGroupsRepository(),
        workspaceToolsRepository: _NoOpWorkspaceToolsRepository(),
      );

  @override
  Future<ToolApprovalDecision> call({
    required String conversationId,
    required String workspaceId,
    required String toolCallId,
    required ResolvedTool resolvedTool,
  }) async {
    return _decisions[toolCallId] ??
        ToolApprovalDecision(
          toolCallId: toolCallId,
          permissionResult: ToolPermissionResult.notConfigured,
        );
  }
}

class _NoOpConversationToolsRepository implements ConversationToolsRepository {
  @override
  Null noSuchMethod(Invocation invocation) => null;
}

class _NoOpToolsGroupsRepository implements ToolsGroupsRepository {
  @override
  Null noSuchMethod(Invocation invocation) => null;
}

class _NoOpWorkspaceToolsRepository implements WorkspaceToolsRepository {
  @override
  Null noSuchMethod(Invocation invocation) => null;
}

class _StreamingMessageRepository implements MessageRepository {
  final StreamController<List<MessageEntity>> _controller =
      StreamController<List<MessageEntity>>.broadcast();

  void emit(List<MessageEntity> messages) => _controller.add(messages);

  Future<void> dispose() => _controller.close();

  @override
  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) => _controller.stream;

  @override
  Stream<MessageEntity?> watchLatestAssistantMessageByConversation(
    String conversationId,
  ) {
    return _controller.stream.map((messages) {
      for (final message in messages.reversed) {
        if (!message.isUser) {
          return message;
        }
      }

      return null;
    });
  }

  @override
  Null noSuchMethod(Invocation invocation) => null;
}

class const _StaticMessageRepository(
  final Map<String, List<MessageEntity>> _messagesByConversationId,
) implements MessageRepository {
  @override
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async {
    return _messagesByConversationId[conversationId] ?? const [];
  }

  @override
  Future<List<MessageEntity>> getLatestAssistantMessagesByConversations(
    List<String> conversationIds,
  ) async {
    return [
      for (final conversationId in conversationIds)
        ...(_messagesByConversationId[conversationId] ?? const []),
    ];
  }

  @override
  Stream<MessageEntity?> watchLatestAssistantMessageByConversation(
    String conversationId,
  ) {
    final messages = _messagesByConversationId[conversationId] ?? const [];
    for (final message in messages.reversed) {
      if (!message.isUser) {
        return Stream.value(message);
      }
    }

    return Stream.value(null);
  }

  @override
  Null noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('updates pending calls from chat provider', (tester) async {
    final repository = _StreamingMessageRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      hooks.ProviderScope(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
            ),
          ).overrideWithValue(
            const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
            ),
          ),
          workspaceSessionForRouteProvider('ws-1').overrideWith(
            (_) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws-1'),
            ),
          ),
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data(null)),
          messageRepositoryProvider.overrideWithValue(repository),
        ],
        child: hooks.Consumer(
          builder: (context, ref, child) {
            final pendingCalls = ref.watch(
              pendingToolCallsProvider('ws-1', 'conv-1'),
            );

            return Directionality(
              textDirection: TextDirection.ltr,
              child: Text('${pendingCalls.value?.length ?? 0}'),
            );
          },
        ),
      ),
    );

    repository
      ..emit(const <MessageEntity>[])
      ..emit([_assistantMessage(id: 'msg-1', conversationId: 'conv-1')]);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets(
    'streams assistant response through real message providers without '
    'overlapping scheduler tasks',
    (tester) async {
      final repository = _StreamingMessageRepository();
      addTearDown(repository.dispose);
      final widgetRefCompleter = Completer<hooks.WidgetRef>();

      await tester.pumpWidget(
        hooks.ProviderScope(
          overrides: [
            workspaceSessionProvider(
              const WorkspaceSession(
                LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
              ),
            ).overrideWithValue(
              const WorkspaceSession(
                LocalWorkspaceRef(localWorkspaceId: 'workspace-1'),
              ),
            ),
            workspaceSessionForRouteProvider('ws-1').overrideWith(
              (_) async => const WorkspaceSession(
                LocalWorkspaceRef(localWorkspaceId: 'ws-1'),
              ),
            ),
            conversationSelectedProvider.overrideWithValue('conv-1'),
            messageRepositoryProvider.overrideWithValue(repository),
          ],
          child: hooks.Consumer(
            builder: (context, ref, child) {
              if (!widgetRefCompleter.isCompleted) {
                widgetRefCompleter.complete(ref);
              }
              final messageIds = ref.watch(
                chatMessageIdsProvider('ws-1', 'conv-1'),
              );
              final contents = [
                for (final messageId in messageIds)
                  ref
                      .watch(
                        messageConversationByIdProvider(
                          'ws-1',
                          'conv-1',
                          messageId,
                        ),
                      )
                      ?.content,
              ].nonNulls.join('|');

              return Directionality(
                textDirection: TextDirection.ltr,
                child: Text(contents),
              );
            },
          ),
        ),
      );
      await tester.pump();

      repository.emit([
        _assistantMessage(id: 'msg-1', conversationId: 'conv-1'),
      ]);
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('assistant'), findsOneWidget);

      final widgetRef = await widgetRefCompleter.future;
      widgetRef.read(messagesStreamingProvider.notifier)
        ..startSubscription(CompositeSubscription(), 'msg-1')
        ..updateResult(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('streaming response'),
            usage: const LanguageModelUsage(),
          ),
          'msg-1',
        );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('streaming response'), findsOneWidget);
    },
  );

  group('pendingToolCallsProvider', () {
    var container = _pendingToolContainer();

    tearDown(() {
      container.dispose();
    });

    test('excludes already-granted tool calls from approval UI', () async {
      final messages = [
        _assistantMessage(
          id: 'msg-2',
          conversationId: 'conv-1',
          toolCalls: [
            _pendingToolCall(
              id: 'tc-granted',
              name: 'built_in_calc_calculator',
            ),
            _pendingToolCall(
              id: 'tc-needs-confirm',
              name: 'native_ws-tool-url_url',
            ),
          ],
        ),
      ];

      container = _pendingToolContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ),
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-granted': const ToolApprovalDecision(
                toolCallId: 'tc-granted',
                permissionResult: ToolPermissionResult.granted,
                permissionTableId: 'calculator',
              ),
              'tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm',
                permissionResult: ToolPermissionResult.needsConfirmation,
                permissionTableId: 'url',
              ),
            }),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result.length, 1);
      expect(result.firstOrNull?.toolCall.id, 'tc-needs-confirm');
    });

    test('includes needsConfirmation tool calls in approval UI', () async {
      final messages = [
        _assistantMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          toolCalls: [
            _pendingToolCall(
              id: 'tc-needs-confirm-1',
              name: 'native_ws-tool-url_url',
            ),
            _pendingToolCall(
              id: 'tc-needs-confirm-2',
              name: 'built_in_calc_calculator',
            ),
          ],
        ),
      ];

      container = _pendingToolContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ),
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-needs-confirm-1': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm-1',
                permissionResult: ToolPermissionResult.needsConfirmation,
                permissionTableId: 'url',
              ),
              'tc-needs-confirm-2': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm-2',
                permissionResult: ToolPermissionResult.needsConfirmation,
                permissionTableId: 'calculator',
              ),
            }),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result.length, 2);
      expect(
        result.map((p) => p.toolCall.id),
        containsAll(['tc-needs-confirm-1', 'tc-needs-confirm-2']),
      );
    });

    test('includes child conversation pending tool calls', () async {
      final childMessages = [
        _assistantMessage(
          id: 'child-msg-1',
          conversationId: 'child-1',
          toolCalls: [
            _pendingToolCall(
              id: 'child-tc-needs-confirm',
              name: 'native_ws-tool-url_url',
            ),
          ],
        ),
      ];
      final childConversation = ConversationEntity(
        id: 'child-1',
        title: 'Child agent',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        parentConversationId: 'conv-1',
      );

      container = _pendingToolContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
          ),
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(AsyncValue.data([childConversation])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(const AsyncValue<List<MessageEntity>>.data([])),
          chatMessagesByConversationProvider(
            'ws-1',
            'child-1',
          ).overrideWithValue(AsyncValue.data(childMessages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'child-1',
          ).overrideWithValue(AsyncValue.data(childConversation)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data(null)),
          messageRepositoryProvider.overrideWithValue(
            _StaticMessageRepository({'child-1': childMessages}),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'child-tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'child-tc-needs-confirm',
                permissionResult: ToolPermissionResult.needsConfirmation,
                permissionTableId: 'url',
              ),
            }),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result, hasLength(1));
      expect(result.single.toolCall.id, 'child-tc-needs-confirm');
      expect(result.single.sourceConversationId, 'child-1');
      expect(result.single.sourceLabel, 'Child agent');
    });

    test('excludes skipped tools from approval UI', () async {
      final messages = [
        _assistantMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          toolCalls: [
            const MessageToolCallEntity(
              id: 'tc-skipped',
              name: 'built_in_calc_calculator',
              argumentsRaw: '{}',
              resultStatus: ToolCallResultStatus.skippedByUser,
            ),
            _pendingToolCall(
              id: 'tc-needs-confirm',
              name: 'native_ws-tool-url_url',
            ),
          ],
        ),
      ];

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm',
                permissionResult: ToolPermissionResult.needsConfirmation,
                permissionTableId: 'url',
              ),
            }),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result.length, 1);
      expect(result.firstOrNull?.toolCall.id, 'tc-needs-confirm');
    });

    test('returns empty when all pending tools are granted', () async {
      final messages = [
        _assistantMessage(
          id: 'msg-2',
          conversationId: 'conv-1',
          toolCalls: [
            _pendingToolCall(id: 'tc-1', name: 'built_in_calc_calculator'),
            _pendingToolCall(id: 'tc-2', name: 'native_ws-tool-url_url'),
          ],
        ),
      ];

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-1': const ToolApprovalDecision(
                toolCallId: 'tc-1',
                permissionResult: ToolPermissionResult.granted,
                permissionTableId: 'calculator',
              ),
              'tc-2': const ToolApprovalDecision(
                toolCallId: 'tc-2',
                permissionResult: ToolPermissionResult.granted,
                permissionTableId: 'url',
              ),
            }),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result, isEmpty);
    });

    test('T025: reevaluates when decision use case changes', () async {
      final messages = [
        _assistantMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          toolCalls: [
            _pendingToolCall(id: 'tc-1', name: 'native_ws-tool-url_url'),
          ],
        ),
      ];

      final needsConfirmUseCase = _FakeResolveToolApprovalDecisionUsecase({
        'tc-1': const ToolApprovalDecision(
          toolCallId: 'tc-1',
          permissionResult: ToolPermissionResult.needsConfirmation,
          permissionTableId: 'url',
        ),
      });

      final grantedUseCase = _FakeResolveToolApprovalDecisionUsecase({
        'tc-1': const ToolApprovalDecision(
          toolCallId: 'tc-1',
          permissionResult: ToolPermissionResult.granted,
          permissionTableId: 'url',
        ),
      });

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1')
              .overrideWithValue(needsConfirmUseCase),
        ],
      );

      final first = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );
      expect(first.length, 1);
      expect(first.firstOrNull?.toolCall.id, 'tc-1');

      container.dispose();

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1')
              .overrideWithValue(grantedUseCase),
        ],
      );

      final second = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );
      expect(second, isEmpty);
    });

    test('T026: handles 20 approved-tool updates', () async {
      final toolCalls = List.generate(
        20,
        (i) => _pendingToolCall(id: 'tc-$i', name: 'built_in_calc_calculator'),
      );

      final messages = [
        _assistantMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          toolCalls: toolCalls,
        ),
      ];

      final decisions = Map.fromEntries(
        List.generate(
          20,
          (i) => MapEntry(
            'tc-$i',
            ToolApprovalDecision(
              toolCallId: 'tc-$i',
              permissionResult: ToolPermissionResult.granted,
              permissionTableId: 'calculator',
            ),
          ),
        ),
      );

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase(decisions),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );
      expect(result, isEmpty);
    });

    test('T027: filters completed and disabled tools', () async {
      final messages = [
        _assistantMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          toolCalls: [
            const MessageToolCallEntity(
              id: 'tc-completed',
              name: 'built_in_calc_calculator',
              argumentsRaw: '{}',
              resultStatus: ToolCallResultStatus.success,
            ),
            const MessageToolCallEntity(
              id: 'tc-skipped',
              name: 'built_in_calc_calculator',
              argumentsRaw: '{}',
              resultStatus: ToolCallResultStatus.skippedByUser,
            ),
            const MessageToolCallEntity(
              id: 'tc-stopped',
              name: 'built_in_calc_calculator',
              argumentsRaw: '{}',
              resultStatus: ToolCallResultStatus.stoppedByUser,
            ),
            _pendingToolCall(
              id: 'tc-needs-confirm',
              name: 'native_ws-tool-url_url',
            ),
          ],
        ),
      ];

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(AsyncValue<List<MessageEntity>>.data(messages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            AsyncValue<ConversationEntity?>.data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Test',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm',
                permissionResult: ToolPermissionResult.needsConfirmation,
                permissionTableId: 'url',
              ),
            }),
          ),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );
      expect(result.length, 1);
      expect(result.firstOrNull?.toolCall.id, 'tc-needs-confirm');
    });
  });
}
