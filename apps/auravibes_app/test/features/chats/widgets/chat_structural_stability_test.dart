import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/providers/batch_tool_approval_provider.dart';
import 'package:auravibes_app/features/chats/providers/chat_a2ui_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart' show StreamProvider;

import '../../../helpers/test_app.dart';

final _messageSnapshotsProvider = StreamProvider<Map<String, MessageEntity>>(
  (ref) => const Stream.empty(),
);
final _traceDate = DateTime(2025);

typedef _RenderedBranch = ({String typeName, Key? key});

@immutable
class const _StructureSignature({
  required final List<_RenderedBranch> branches,
  final List<String> diagnosticReasons = const [],
}) {
  @override
  int get hashCode => Object.hashAll(branches);

  @override
  bool operator ==(Object other) =>
      other is _StructureSignature && listEquals(branches, other.branches);
}

void _expectAcceptedTrace({
  required String traceName,
  required String acceptedTransitions,
  required List<_StructureSignature> observed,
  required List<_StructureSignature> accepted,
}) {
  expect(
    observed,
    equals(accepted),
    reason:
        '$traceName accepts only these structural transitions: '
        '$acceptedTransitions',
  );
}

_StructureSignature _captureStructure(
  WidgetTester tester, {
  Iterable<String> diagnosticReasons = const [],
}) {
  final renderedBranches = tester.widgetList<Widget>(
    find.byWidgetPredicate(
      (widget) =>
          widget.key != null ||
          widget is ListView ||
          widget is AuraMessageBubble ||
          widget is AuraSelectableText ||
          widget is AuraIconButton ||
          widget is ChatA2uiSurfaceHost ||
          widget is ChatA2uiWarning ||
          widget is ChatToolApprovalCard,
    ),
  );

  return _StructureSignature(
    branches: [
      for (final widget in renderedBranches)
        (typeName: widget.runtimeType.toString(), key: widget.key),
    ],
    diagnosticReasons: diagnosticReasons.toList(growable: false),
  );
}

Future<void> _pumpSubject(
  WidgetTester tester, {
  required _MessageSnapshotFeed feed,
  required List<String> messageIds,
  Map<String, MessageEntity>? restoredMessages,
  ChatA2uiRuntime? runtime,
  List<PendingToolCall> pendingCalls = const [],
  BatchToolApprovalActions? approvalActions,
}) async {
  final conversationRepository = _MockConversationRepository();
  when(() => conversationRepository.watchConversationById('conv-1'))
      .thenAnswer((_) => Stream.value(_createConversation()));
  when(() => conversationRepository.watchChildConversations('conv-1'))
      .thenAnswer((_) => Stream.value(const <ConversationEntity>[]));

  final overrides = [
    conversationSelectedProvider('conv-1').overrideWithValue('conv-1'),
    conversationRepositoryProvider.overrideWithValue(conversationRepository),
    _messageSnapshotsProvider.overrideWith((ref) => feed.stream),
    messageConversationByIdProvider.overrideWith(
      (ref, id) => ref.watch(_messageSnapshotsProvider).value?[id.messageId],
    ),
    isMessageStreamingProvider.overrideWith(
      (ref, id) =>
          ref.watch(_messageSnapshotsProvider).value?[id]?.status ==
          MessageStatus.unfinished,
    ),
    conversationBusyStateProvider.overrideWith(
      (ref, _) async => const ConversationBusyState(
        isStreaming: false,
        hasPendingTools: false,
      ),
    ),
    if (runtime != null)
      chatA2uiRuntimeProvider.overrideWith((ref, _) => runtime),
    if (approvalActions != null)
      batchToolApprovalUsecaseProvider.overrideWithValue(approvalActions),
  ];

  await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ChatPrimaryScrollController(
                  child: ChatMessagesWidget(
                    workspaceId: 'ws-1',
                    conversationId: 'conv-1',
                    messages: messageIds,
                    onOpenToolResult: (_) => fail('Unexpected tool result tab'),
                    messageEntitiesById: restoredMessages,
                  ),
                ),
              ),
              if (pendingCalls.isNotEmpty)
                ChatToolApprovalCard(
                  workspaceId: 'ws-1',
                  conversationId: 'conv-1',
                  pendingCalls: pendingCalls,
                ),
            ],
          ),
        ),
        overrides: overrides,
        workspaceId: 'ws-1',
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();
}

MessageEntity _createMessage({
  required String id,
  required String content,
  MessageStatus status = .sent,
  MessageType messageType = .text,
  MessageMetadataEntity? metadata,
}) => MessageEntity(
  id: id,
  conversationId: 'conv-1',
  content: content,
  messageType: messageType,
  isUser: false,
  status: status,
  createdAt: _traceDate,
  updatedAt: _traceDate,
  metadata: metadata,
);

ConversationEntity _createConversation() => ConversationEntity(
  id: 'conv-1',
  title: 'Trace',
  workspaceId: 'ws-1',
  isPinned: false,
  createdAt: _traceDate,
  updatedAt: _traceDate,
);

List<String> _formPayloads(String initialAnswer) => [
  for (final operation in [
    {
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': 'urn:auravibes:a2ui:chat:form:v1',
      },
    },
    {
      'updateComponents': {
        'surfaceId': 'main',
        'components': [
          {
            'id': 'root',
            'component': 'Text',
            'text': {'path': '/answer'},
          },
        ],
      },
    },
    {
      'updateDataModel': {
        'surfaceId': 'main',
        'path': '/',
        'value': {'answer': initialAnswer},
      },
    },
  ])
    jsonEncode({
      'protocolVersion': 'v1',
      'interactionMode': 'requiresUserAction',
      'message': {'version': 'v0.9', ...operation},
    }),
];

String _formAnswerUpdate(String answer) => jsonEncode({
  'protocolVersion': 'v1',
  'interactionMode': 'requiresUserAction',
  'message': {
    'version': 'v0.9',
    'updateDataModel': {
      'surfaceId': 'main',
      'path': '/',
      'value': {'answer': answer},
    },
  },
});

PendingToolCall _pendingCall(String id) => .new(
  toolCall: MessageToolCallEntity(
    id: id,
    name: 'built_in_1_read_file',
    argumentsRaw: '{"path":"trace.txt"}',
  ),
  messageId: 'assistant-1',
);

BatchToolApprovalResult _claimedApprovalResult(List<PendingToolCall> calls) =>
    .new(
      claimed: [
        for (final call in calls)
          .new(
            conversationId: 'conv-1',
            messageId: call.messageId,
            toolCallId: call.toolCall.id,
            argumentsDigest: call.toolCall.argumentsDigest,
            turnRevision: call.toolCall.turnRevision,
          ),
      ],
      alreadyHandled: const [],
      conflicted: const [],
    );

class _MessageSnapshotFeed {
  final StreamController<Map<String, MessageEntity>> _controller = .broadcast();

  Stream<Map<String, MessageEntity>> get stream => _controller.stream;

  void add(Map<String, MessageEntity> messages) => _controller.add(messages);

  Future<void> close() => _controller.close();
}

class _PendingApprovalActions implements BatchToolApprovalActions {
  final Completer<BatchToolApprovalResult> approveResult = .new();
  List<PendingToolCall>? approvedCalls;

  @override
  Future<BatchToolApprovalResult> approveOnce({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) {
    approvedCalls = pendingCalls;

    return approveResult.future;
  }

  @override
  Future<BatchToolApprovalResult> skip({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) async => const BatchToolApprovalResult(
    claimed: [],
    alreadyHandled: [],
    conflicted: [],
  );
}

class _MockConversationRepository extends Mock
    implements ConversationRepository;

Future<void> _settle(WidgetTester tester) async {
  final _ = await tester.pumpAndSettle();
}

Future<void> _conversationTokenTrace(WidgetTester tester) async {
  final feed = _MessageSnapshotFeed();
  addTearDown(feed.close);
  const messageId = 'assistant-1';
  await _pumpSubject(tester, feed: feed, messageIds: const [messageId]);
  final emptyTimeline = _captureStructure(tester);

  final firstPartial = _createMessage(
    id: messageId,
    content: 'Draft answer',
    status: .unfinished,
  );
  feed.add({messageId: firstPartial});
  await _settle(tester);
  expect(find.text('Draft answer'), findsOneWidget);
  final firstMessage = _captureStructure(tester);

  final updatedPartial = firstPartial.copyWith(
    content: 'Draft answer with another token',
  );
  feed.add({messageId: updatedPartial});
  await _settle(tester);
  expect(find.text('Draft answer with another token'), findsOneWidget);
  expect(find.text('Draft answer'), findsNothing);
  final updatedMessage = _captureStructure(tester);

  final finalMessage = updatedPartial.copyWith(
    content: 'Draft answer complete',
    status: .sent,
  );
  feed.add({messageId: finalMessage});
  await _settle(tester);
  expect(find.text('Draft answer complete'), findsOneWidget);
  expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
  final completedMessage = _captureStructure(tester);

  _expectAcceptedTrace(
    traceName: 'conversation token updates',
    acceptedTransitions:
        'empty timeline -> one keyed assistant row; token updates retain '
        'that row; completion adds response actions once',
    observed: [emptyTimeline, firstMessage, updatedMessage, completedMessage],
    accepted: [emptyTimeline, firstMessage, firstMessage, completedMessage],
  );
  expect(tester.takeException(), isNull);
}

Future<void> _a2uiAnswerTrace(WidgetTester tester) async {
  final feed = _MessageSnapshotFeed();
  addTearDown(feed.close);
  final runtime = ChatA2uiRuntime(conversationId: 'conv-1');
  addTearDown(runtime.dispose);
  final message = _createMessage(
    id: 'assistant-form',
    content: '',
    status: .unfinished,
    metadata: .new(a2uiMessages: _formPayloads('Approval pending')),
  );
  await _pumpSubject(
    tester,
    feed: feed,
    messageIds: const ['assistant-form'],
    restoredMessages: {message.id: message},
    runtime: runtime,
  );
  feed.add({message.id: message});
  await _settle(tester);

  expect(find.text('Approval pending'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('a2ui_submit_assistant-form:main')),
    findsOneWidget,
  );
  final initialSurface = _captureStructure(tester);

  runtime
    ..addMessageJson(_formAnswerUpdate('Approval ready'))
    ..commitCurrentMessage();
  await _settle(tester);

  expect(find.text('Approval ready'), findsOneWidget);
  expect(find.text('Approval pending'), findsNothing);
  expect(find.byKey(const ValueKey('a2ui_assistant-form')), findsOneWidget);
  final updatedSurface = _captureStructure(tester);

  _expectAcceptedTrace(
    traceName: 'A2UI answer updates',
    acceptedTransitions:
        'the ready form surface and submit action appear once; data-model '
        'text changes preserve the rendered surface key and branch types',
    observed: [initialSurface, updatedSurface],
    accepted: [initialSurface, initialSurface],
  );
  expect(tester.takeException(), isNull);
}

void main() {
  test('structural equality ignores changing A2UI diagnostic reasons', () {
    const warningBranch = (
      typeName: 'ChatA2uiWarning',
      key: ValueKey<String>('a2ui-message:main'),
    );
    const malformedPayload = _StructureSignature(
      branches: [warningBranch],
      diagnosticReasons: ['malformedPayload'],
    );
    const unsupportedComponent = _StructureSignature(
      branches: [warningBranch],
      diagnosticReasons: ['unsupportedComponent'],
    );

    expect(malformedPayload, unsupportedComponent);
    expect(malformedPayload.hashCode, unsupportedComponent.hashCode);
  });

  test('negative control rejects a repeated A-B-A-B layout oscillation', () {
    const textBubble = _StructureSignature(
      branches: [
        (typeName: 'AuraMessageBubble', key: ValueKey<String>('assistant-1')),
      ],
    );
    const providerError = _StructureSignature(
      branches: [
        (typeName: 'AuraSelectableText', key: ValueKey<String>('assistant-1')),
      ],
    );

    expect(
      () => _expectAcceptedTrace(
        traceName: 'conversation token updates',
        acceptedTransitions: 'the keyed assistant bubble stays mounted',
        observed: [textBubble, providerError, textBubble, providerError],
        accepted: [textBubble, textBubble, textBubble, textBubble],
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets(
    'conversation trace accepts message arrival and final actions; '
    'token updates keep the keyed row stable',
    _conversationTokenTrace,
  );

  testWidgets(
    'A2UI trace accepts one live surface and keeps its branch stable '
    'across answer updates',
    _a2uiAnswerTrace,
  );

  testWidgets(
    'provider error details and copy response update while the error row '
    'stays stable',
    (tester) async {
      final feed = _MessageSnapshotFeed();
      addTearDown(feed.close);
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      const messageId = 'provider-error';
      await _pumpSubject(tester, feed: feed, messageIds: const [messageId]);
      final emptyTimeline = _captureStructure(tester);

      final initialError = _createMessage(
        id: messageId,
        content: 'Quota exceeded for model atlas',
        status: .error,
        messageType: .system,
        metadata: const MessageMetadataEntity(
          modelMetadata: {'providerError': true},
        ),
      );
      feed.add({messageId: initialError});
      await _settle(tester);
      expect(find.text('Quota exceeded for model atlas'), findsOneWidget);
      final firstError = _captureStructure(
        tester,
        diagnosticReasons: [initialError.content],
      );

      final updatedError = initialError.copyWith(
        content: 'Context length exceeded for model atlas',
      );
      feed.add({messageId: updatedError});
      await _settle(tester);
      expect(
        find.text('Context length exceeded for model atlas'),
        findsOneWidget,
      );
      expect(find.text('Quota exceeded for model atlas'), findsNothing);
      final latestError = _captureStructure(
        tester,
        diagnosticReasons: [updatedError.content],
      );
      expect(latestError, firstError);

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await _settle(tester);
      expect(copiedText, updatedError.content);
      final copiedError = _captureStructure(
        tester,
        diagnosticReasons: [updatedError.content],
      );

      _expectAcceptedTrace(
        traceName: 'provider error detail updates',
        acceptedTransitions:
            'the provider-error row appears once; detail text and copy state '
            'change inside the same keyed row',
        observed: [emptyTimeline, firstError, latestError, copiedError],
        accepted: [emptyTimeline, firstError, firstError, firstError],
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'approval response is immediate while the conversation trace keeps '
    'updating',
    (tester) async {
      final feed = _MessageSnapshotFeed();
      addTearDown(feed.close);
      final actions = _PendingApprovalActions();
      final pendingCalls = [_pendingCall('tc-1'), _pendingCall('tc-2')];
      await _pumpSubject(
        tester,
        feed: feed,
        messageIds: const ['assistant-1'],
        pendingCalls: pendingCalls,
        approvalActions: actions,
      );
      feed.add({
        'assistant-1': _createMessage(
          id: 'assistant-1',
          content: 'Waiting for approval',
          status: .unfinished,
        ),
      });
      await _settle(tester);

      expect(find.text('Waiting for approval'), findsOneWidget);
      final pendingLayout = _captureStructure(tester);
      final approveAll = find.byKey(
        const ValueKey<String>('tool_approval_allow_all'),
      );
      expect(approveAll, findsOneWidget);

      await tester.tap(approveAll);
      await tester.pump();

      expect(actions.approvedCalls?.map((call) => call.toolCall.id), [
        'tc-1',
        'tc-2',
      ]);
      expect(
        find.byKey(const ValueKey<String>('tool_approval_allow_all')),
        findsNothing,
      );
      final approvalStarted = _captureStructure(tester);
      expect(approvalStarted, isNot(pendingLayout));

      feed.add({
        'assistant-1': _createMessage(
          id: 'assistant-1',
          content: 'Approval request sent',
          status: .unfinished,
        ),
      });
      await _settle(tester);
      expect(find.text('Approval request sent'), findsOneWidget);
      final messageUpdated = _captureStructure(tester);
      expect(messageUpdated, approvalStarted);

      actions.approveResult.complete(_claimedApprovalResult(pendingCalls));
      await _settle(tester);
      final approvalCompleted = _captureStructure(tester);

      _expectAcceptedTrace(
        traceName: 'pending approval alongside conversation updates',
        acceptedTransitions:
            'the pending approval card appears once; allow-all removes its '
            'controls immediately; streaming text and the claimed result keep '
            'the dismissed card branch stable',
        observed: [
          pendingLayout,
          approvalStarted,
          messageUpdated,
          approvalCompleted,
        ],
        accepted: [
          pendingLayout,
          approvalStarted,
          approvalStarted,
          approvalStarted,
        ],
      );
      expect(tester.takeException(), isNull);
    },
  );
}
