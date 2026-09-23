// Required: Existing test and UI helpers keep compact return flow.

// Required: Provider unit tests read scoped providers directly.

import 'dart:async';
import 'dart:ui';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_state.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_effective_tool_approval_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/app_logging.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as hooks;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart' show Override;

ProviderContainer _pendingToolContainer({
  List<Override> overrides = const [],
  ConversationRepository? conversationRepository,
}) {
  return ProviderContainer(
    overrides: [
      workspaceSessionForRouteProvider.overrideWith(
        (_, workspaceId) =>
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: workspaceId)),
      ),
      loadConversationToolSpecsUsecaseProvider.overrideWith(
        (_, _) => const _FakeLoadConversationToolSpecsUsecase(),
      ),
      conversationRepositoryProvider.overrideWithValue(
        conversationRepository ?? _PendingConversationRepository(),
      ),
      ...overrides,
    ],
  );
}

class _PendingConversationRepository({
  final Map<String, List<ConversationEntity>> childrenByParent = const {},
}) implements ConversationRepository {
  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async => childrenByParent[parentConversationId] ?? const [];

  @override
  Null noSuchMethod(Invocation invocation) => null;
}

class const _FakeLoadConversationToolSpecsUsecase({
  final bool includeSkillCommand = false,
}) implements LoadConversationToolSpecsUsecase {
  @override
  ConversationRepository? get conversationRepository => null;

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
  }) async => includeSkillCommand
      ? _buildPendingToolCatalog(includeSkillCommand: true)
      : _pendingToolCatalog;
}

final ToolCatalog<ResolvedTool> _pendingToolCatalog =
    _buildPendingToolCatalog();
final String _calculatorToolName =
    _pendingToolCatalog.specs.firstOrNull?.name ??
    (throw RangeError.index(0, _pendingToolCatalog.specs));
final String _urlToolName = _pendingToolCatalog.specs[1].name;

ToolCatalog<ResolvedTool> _buildPendingToolCatalog({
  bool includeSkillCommand = false,
}) => buildToolCatalog<ResolvedTool>([
  if (includeSkillCommand)
    ToolCatalogCandidate.reserved(
      spec: .new(
        name: callSkillToolName,
        description: 'Call a loaded skill tool.',
        inputJsonSchema: const {'type': 'object'},
      ),
      target: ResolvedTool.skillCommand(commandName: callSkillToolName),
    ),
  ToolCatalogCandidate.external(
    spec: .new(
      name: 'built_in_calc_calculator',
      description: 'Calculator',
      inputJsonSchema: {},
    ),
    target: ResolvedTool.builtIn(
      tableId: 'calc',
      toolIdentifier: 'calculator',
      tooltype: .calculator,
    ),
    sourceId: 'calc',
  ),
  ToolCatalogCandidate.external(
    spec: .new(
      name: 'native_ws-tool-url_url',
      description: 'URL',
      inputJsonSchema: {},
    ),
    target: ResolvedTool.native(tableId: 'url', nativeToolType: .url),
    sourceId: 'url',
  ),
]);

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
    messageType: .text,
    isUser: false,
    status: .sent,
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
  ResolvedTool? lastResolvedTool;

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
    lastResolvedTool = resolvedTool;

    return _decisions[toolCallId] ??
        ToolApprovalDecision(
          toolCallId: toolCallId,
          permissionResult: .notConfigured,
        );
  }
}

class _FakeResolveEffectiveToolApprovalUsecase(
  final AgentResolvedToolName target,
) implements ResolveEffectiveToolApprovalUsecase {
  ResolvedTool? lastRequestedTool;
  String? lastArgumentsRaw;

  @override
  Future<ResolvedTool?> call({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool requestedTool,
    required String argumentsRaw,
  }) async {
    lastRequestedTool = requestedTool;
    lastArgumentsRaw = argumentsRaw;

    return ResolvedTool.skillCommand(
      commandName: callSkillToolName,
      target: target,
    );
  }

  @override
  Future<AgentResolvedToolName?> resolveTarget({
    required String conversationId,
    required String workspaceId,
    required SkillCommandTarget command,
  }) async => target;
}

class _ThrowingToolApprovalUsecase()
    extends ResolveToolApprovalDecisionUsecase {
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
    throw const FormatException('access_token=decision-secret');
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
              textDirection: .ltr,
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
                        messageConversationByIdProvider((
                          workspaceId: 'ws-1',
                          conversationId: 'conv-1',
                          messageId: messageId,
                        )),
                      )
                      ?.content,
              ].nonNulls.join('|');

              return Directionality(textDirection: .ltr, child: Text(contents));
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
        ..startSubscription(.new(), 'msg-1')
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
            _pendingToolCall(id: 'tc-granted', name: _calculatorToolName),
            _pendingToolCall(id: 'tc-needs-confirm', name: _urlToolName),
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-granted': const ToolApprovalDecision(
                toolCallId: 'tc-granted',
                permissionResult: .granted,
                permissionTableId: 'calculator',
              ),
              'tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm',
                permissionResult: .needsConfirmation,
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
            _pendingToolCall(id: 'tc-needs-confirm-1', name: _urlToolName),
            _pendingToolCall(
              id: 'tc-needs-confirm-2',
              name: _calculatorToolName,
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-needs-confirm-1': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm-1',
                permissionResult: .needsConfirmation,
                permissionTableId: 'url',
              ),
              'tc-needs-confirm-2': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm-2',
                permissionResult: .needsConfirmation,
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

    test('shows valid nested list_agents approval by exact target', () async {
      const argumentsRaw =
          '{"skill":"agents","tool":"list_agents","args":{},'
          '"revision":"rev-1"}';
      final effectiveUsecase = _FakeResolveEffectiveToolApprovalUsecase(
        .skillNative(
          tableId: listAgentsToolName,
          skillSlug: agentsSkillSlug,
          toolIdentifier: listAgentsToolName,
        ),
      );
      final decisionUsecase = _FakeResolveToolApprovalDecisionUsecase({
        'tc-list-agents': const ToolApprovalDecision(
          toolCallId: 'tc-list-agents',
          permissionResult: .needsConfirmation,
          permissionTableId: 'list-agents-permission',
        ),
      });
      final messages = [
        _assistantMessage(
          id: 'msg-list-agents',
          conversationId: 'conv-1',
          toolCalls: [
            const MessageToolCallEntity(
              id: 'tc-list-agents',
              name: callSkillToolName,
              argumentsRaw: argumentsRaw,
            ),
          ],
        ),
      ];

      container = _pendingToolContainer(
        overrides: [
          loadConversationToolSpecsUsecaseProvider('ws-1').overrideWithValue(
            const _FakeLoadConversationToolSpecsUsecase(
              includeSkillCommand: true,
            ),
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveEffectiveToolApprovalUsecaseProvider.overrideWithValue(
            effectiveUsecase,
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1')
              .overrideWithValue(decisionUsecase),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result, hasLength(1));
      expect(result.single.toolCall.name, callSkillToolName);
      expect(
        effectiveUsecase.lastRequestedTool?.toolIdentifier,
        callSkillToolName,
      );
      expect(effectiveUsecase.lastArgumentsRaw, argumentsRaw);
      expect(
        decisionUsecase.lastResolvedTool?.fullName,
        'skill__app_native__agents__list_agents',
      );
    });

    test('includes child conversation pending tool calls', () async {
      final childMessages = [
        _assistantMessage(
          id: 'child-msg-1',
          conversationId: 'child-1',
          toolCalls: [
            _pendingToolCall(id: 'child-tc-needs-confirm', name: _urlToolName),
          ],
        ),
      ];
      final childConversation = ConversationEntity(
        id: 'child-1',
        title: 'Child agent',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
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
          ).overrideWithValue(.data([childConversation])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(const AsyncValue<List<MessageEntity>>.data([])),
          chatMessagesByConversationProvider(
            'ws-1',
            'child-1',
          ).overrideWithValue(.data(childMessages)),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'child-1',
          ).overrideWithValue(.data(childConversation)),
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
                permissionResult: .needsConfirmation,
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

    test('includes nested child conversation pending tool calls', () async {
      final nestedMessages = [
        _assistantMessage(
          id: 'nested-msg-1',
          conversationId: 'nested-child-1',
          toolCalls: [
            _pendingToolCall(id: 'nested-tc-needs-confirm', name: _urlToolName),
          ],
        ),
      ];
      final childConversation = ConversationEntity(
        id: 'child-1',
        title: 'Child agent',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        parentConversationId: 'conv-1',
      );
      final nestedConversation = ConversationEntity(
        id: 'nested-child-1',
        title: 'Nested agent',
        workspaceId: 'ws-1',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        parentConversationId: 'child-1',
      );

      container = _pendingToolContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
          childConversationsStreamProvider(
            'ws-1',
            parentConversationId: 'conv-1',
          ).overrideWithValue(.data([childConversation])),
          chatMessagesProvider(
            'ws-1',
            'conv-1',
          ).overrideWithValue(const AsyncValue.data([])),
          conversationByIdStreamProvider(
            'ws-1',
            conversationId: 'conv-1',
          ).overrideWithValue(
            .data(
              ConversationEntity(
                id: 'conv-1',
                title: 'Root',
                workspaceId: 'ws-1',
                isPinned: false,
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          messageRepositoryProvider.overrideWithValue(
            _StaticMessageRepository({'nested-child-1': nestedMessages}),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'nested-tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'nested-tc-needs-confirm',
                permissionResult: .needsConfirmation,
                permissionTableId: 'url',
              ),
            }),
          ),
        ],
        conversationRepository: _PendingConversationRepository(
          childrenByParent: {
            'conv-1': [childConversation],
            'child-1': [nestedConversation],
          },
        ),
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );

      expect(result, hasLength(1));
      expect(result.single.toolCall.id, 'nested-tc-needs-confirm');
      expect(result.single.sourceConversationId, 'nested-child-1');
      expect(result.single.sourceLabel, 'Nested agent');
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
              resultStatus: .skippedByUser,
            ),
            _pendingToolCall(id: 'tc-needs-confirm', name: _urlToolName),
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm',
                permissionResult: .needsConfirmation,
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
            _pendingToolCall(id: 'tc-1', name: _calculatorToolName),
            _pendingToolCall(id: 'tc-2', name: _urlToolName),
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-1': const ToolApprovalDecision(
                toolCallId: 'tc-1',
                permissionResult: .granted,
                permissionTableId: 'calculator',
              ),
              'tc-2': const ToolApprovalDecision(
                toolCallId: 'tc-2',
                permissionResult: .granted,
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
          toolCalls: [_pendingToolCall(id: 'tc-1', name: _urlToolName)],
        ),
      ];

      final needsConfirmUseCase = _FakeResolveToolApprovalDecisionUsecase({
        'tc-1': const ToolApprovalDecision(
          toolCallId: 'tc-1',
          permissionResult: .needsConfirmation,
          permissionTableId: 'url',
        ),
      });

      final grantedUseCase = _FakeResolveToolApprovalDecisionUsecase({
        'tc-1': const ToolApprovalDecision(
          toolCallId: 'tc-1',
          permissionResult: .granted,
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
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
        (i) => _pendingToolCall(id: 'tc-$i', name: _calculatorToolName),
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
              permissionResult: .granted,
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
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
              resultStatus: .success,
            ),
            const MessageToolCallEntity(
              id: 'tc-skipped',
              name: 'built_in_calc_calculator',
              argumentsRaw: '{}',
              resultStatus: .skippedByUser,
            ),
            const MessageToolCallEntity(
              id: 'tc-stopped',
              name: 'built_in_calc_calculator',
              argumentsRaw: '{}',
              resultStatus: .stoppedByUser,
            ),
            _pendingToolCall(id: 'tc-needs-confirm', name: _urlToolName),
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1').overrideWithValue(
            _FakeResolveToolApprovalDecisionUsecase({
              'tc-needs-confirm': const ToolApprovalDecision(
                toolCallId: 'tc-needs-confirm',
                permissionResult: .needsConfirmation,
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

    test('redacts approval resolution errors from logs', () async {
      final previousDebugPrint = debugPrint;
      final previousFlutterError = FlutterError.onError;
      final previousPlatformError = PlatformDispatcher.instance.onError;
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      AppLogging.resetForTesting();
      AppLogging.configure(enabled: true);

      addTearDown(() {
        debugPrint = previousDebugPrint;
        FlutterError.onError = previousFlutterError;
        PlatformDispatcher.instance.onError = previousPlatformError;
        AppLogging.resetForTesting();
      });

      const rawArguments = '{"access_token":"argument-secret"}';
      final messages = [
        _assistantMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          toolCalls: [
            MessageToolCallEntity(
              id: 'tc-secret',
              name: _urlToolName,
              argumentsRaw: rawArguments,
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
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ),
          ),
          resolveToolApprovalDecisionUsecaseProvider('ws-1')
              .overrideWithValue(_ThrowingToolApprovalUsecase()),
        ],
      );

      final result = await container.read(
        pendingToolCallsProvider('ws-1', 'conv-1').future,
      );
      await Future<void>.delayed(.zero);

      final joinedLogs = logs.join('\n');
      expect(result, hasLength(1));
      expect(joinedLogs, contains('[WARNING] message_id_list:'));
      expect(joinedLogs, isNot(contains('decision-secret')));
      expect(joinedLogs, isNot(contains('argument-secret')));
    });
  });
}
