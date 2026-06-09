// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: provider_dependencies
// Required: provider unit tests read scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as hooks;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:rxdart/rxdart.dart';

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

class _FakeResolveToolApprovalDecisionUsecase
    extends ResolveToolApprovalDecisionUsecase {
  _FakeResolveToolApprovalDecisionUsecase(this._decisions)
    : super(
        conversationToolsRepository: _NoOpConversationToolsRepository(),
        toolsGroupsRepository: _NoOpToolsGroupsRepository(),
        workspaceToolsRepository: _NoOpWorkspaceToolsRepository(),
      );
  final Map<String, ToolApprovalDecision> _decisions;

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
  Null noSuchMethod(Invocation invocation) => null;
}

@Dependencies([chatMessageIds, messageConversationById, pendingToolCalls])
void main() {
  testWidgets(
    'updates from real chatMessagesProvider without overlapping '
    'scheduler tasks',
    (tester) async {
      final repository = _StreamingMessageRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        hooks.ProviderScope(
          overrides: [
            conversationSelectedProvider.overrideWithValue('conv-1'),
            messageRepositoryProvider.overrideWithValue(repository),
          ],
          child: hooks.Consumer(
            builder: (context, ref, child) {
              final pendingCalls = ref.watch(pendingToolCallsProvider);

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
        ..emit([
          _assistantMessage(
            id: 'msg-1',
            conversationId: 'conv-1',
          ),
        ]);
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
    },
  );

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
            conversationSelectedProvider.overrideWithValue('conv-1'),
            messageRepositoryProvider.overrideWithValue(repository),
          ],
          child: hooks.Consumer(
            builder: (context, ref, child) {
              if (!widgetRefCompleter.isCompleted) {
                widgetRefCompleter.complete(ref);
              }
              final messageIds = ref.watch(chatMessageIdsProvider);
              final contents = [
                for (final messageId in messageIds)
                  ref
                      .watch(messageConversationByIdProvider(messageId))
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
    var container = ProviderContainer();

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

      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          chatMessagesProvider.overrideWithValue(
            AsyncValue<List<MessageEntity>>.data(messages),
          ),
          conversationByIdStreamProvider(
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
          resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
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

      final result = await container.read(pendingToolCallsProvider.future);

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

      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          chatMessagesProvider.overrideWithValue(
            AsyncValue<List<MessageEntity>>.data(messages),
          ),
          conversationByIdStreamProvider(
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
          resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
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

      final result = await container.read(pendingToolCallsProvider.future);

      expect(result.length, 2);
      expect(
        result.map((p) => p.toolCall.id),
        containsAll(['tc-needs-confirm-1', 'tc-needs-confirm-2']),
      );
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

      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          chatMessagesProvider.overrideWithValue(
            AsyncValue<List<MessageEntity>>.data(messages),
          ),
          conversationByIdStreamProvider(
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
          resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
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

      final result = await container.read(pendingToolCallsProvider.future);

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

      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          chatMessagesProvider.overrideWithValue(
            AsyncValue<List<MessageEntity>>.data(messages),
          ),
          conversationByIdStreamProvider(
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
          resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
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

      final result = await container.read(pendingToolCallsProvider.future);

      expect(result, isEmpty);
    });

    test(
      'T025: re-evaluates when decision use case changes '
      'from needsConfirmation to granted',
      () async {
        final messages = [
          _assistantMessage(
            id: 'msg-1',
            conversationId: 'conv-1',
            toolCalls: [
              _pendingToolCall(
                id: 'tc-1',
                name: 'native_ws-tool-url_url',
              ),
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

        container = ProviderContainer(
          overrides: [
            conversationSelectedProvider.overrideWithValue('conv-1'),
            chatMessagesProvider.overrideWithValue(
              AsyncValue<List<MessageEntity>>.data(messages),
            ),
            conversationByIdStreamProvider(
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
            resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
              needsConfirmUseCase,
            ),
          ],
        );

        final first = await container.read(pendingToolCallsProvider.future);
        expect(first.length, 1);
        expect(first.firstOrNull?.toolCall.id, 'tc-1');

        container.dispose();

        container = ProviderContainer(
          overrides: [
            conversationSelectedProvider.overrideWithValue('conv-1'),
            chatMessagesProvider.overrideWithValue(
              AsyncValue<List<MessageEntity>>.data(messages),
            ),
            conversationByIdStreamProvider(
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
            resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
              grantedUseCase,
            ),
          ],
        );

        final second = await container.read(pendingToolCallsProvider.future);
        expect(second, isEmpty);
      },
    );

    test(
      'T026: 20 consecutive approved-tool updates produce '
      'zero approval-card entries',
      () async {
        final toolCalls = List.generate(
          20,
          (i) => _pendingToolCall(
            id: 'tc-$i',
            name: 'built_in_calc_calculator',
          ),
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

        container = ProviderContainer(
          overrides: [
            conversationSelectedProvider.overrideWithValue('conv-1'),
            chatMessagesProvider.overrideWithValue(
              AsyncValue<List<MessageEntity>>.data(messages),
            ),
            conversationByIdStreamProvider(
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
            resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
              _FakeResolveToolApprovalDecisionUsecase(decisions),
            ),
          ],
        );

        final result = await container.read(pendingToolCallsProvider.future);
        expect(result, isEmpty);
      },
    );

    test(
      'T027: excludes completed, skipped, and disabled tools; '
      'includes only needsConfirmation',
      () async {
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

        container = ProviderContainer(
          overrides: [
            conversationSelectedProvider.overrideWithValue('conv-1'),
            chatMessagesProvider.overrideWithValue(
              AsyncValue<List<MessageEntity>>.data(messages),
            ),
            conversationByIdStreamProvider(
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
            resolveToolApprovalDecisionUsecaseProvider.overrideWithValue(
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

        final result = await container.read(pendingToolCallsProvider.future);
        expect(result.length, 1);
        expect(result.firstOrNull?.toolCall.id, 'tc-needs-confirm');
      },
    );
  });
}
