import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildSubject({
    required List<String> messages,
    required List<Object> overrides,
    String conversationId = 'conv-1',
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue(conversationId),
          ...overrides.cast(),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: Material(
                  child: ChatMessagesWidget(
                    messages: messages,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  MessageEntity _createMessage({
    String id = 'msg-1',
    String content = 'Hello',
    bool isUser = true,
    MessageStatus status = MessageStatus.sent,
    MessageMetadataEntity? metadata,
    MessageType messageType = MessageType.text,
  }) {
    return MessageEntity(
      id: id,
      conversationId: 'conv-1',
      content: content,
      messageType: messageType,
      isUser: isUser,
      status: status,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      metadata: metadata,
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  group('ChatMessagesWidget', () {
    testWidgets('renders empty list when no messages', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: [],
          overrides: [
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(ChatMessagesWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders user message with text content', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Hello AI',
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Hello AI'), findsOneWidget);
    });

    testWidgets('renders AI message content', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Hello user',
                isUser: false,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Hello user'), findsOneWidget);
    });

    testWidgets('renders AI reasoning summary separately', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Final answer',
                isUser: false,
                metadata: const MessageMetadataEntity(
                  thinking: 'Reasoned before answering',
                ),
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Reasoning summary'), findsOneWidget);
      expect(find.text('Reasoned before answering'), findsOneWidget);
      expect(find.text('Final answer'), findsOneWidget);
    });

    testWidgets('handles null message gracefully', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['missing-msg'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => null),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(ChatMessagesWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders tool calls from message metadata', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"input": "test.txt"}',
        responseRaw: 'file content',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders reasoning summary when tool calls hide empty answer', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_read_file',
        argumentsRaw: '{"input": "test.txt"}',
        resultStatus: ToolCallResultStatus.success,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(
          thinking: 'Need to inspect the file first',
          toolCalls: [toolCall],
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Reasoning summary'), findsOneWidget);
      expect(find.text('Need to inspect the file first'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders multiple messages', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1', 'msg-2'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                id: id,
                content: 'Message $id',
                isUser: id == 'msg-1',
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Message msg-1'), findsOneWidget);
      expect(find.text('Message msg-2'), findsOneWidget);
    });

    testWidgets('renders AI message without content but with tool calls', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.executionError,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('renders tool call with skipped status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.skippedByUser,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('renders tool call with stopped status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    });

    testWidgets('renders tool call with tool not found status', (tester) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.toolNotFound,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders tool call with not configured status', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.notConfigured,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders message with sending status', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Sending...',
                status: MessageStatus.sending,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Sending...'), findsOneWidget);
    });

    testWidgets('renders message with error status', (tester) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(
                content: 'Error msg',
                isUser: false,
                status: MessageStatus.error,
              ),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.text('Error msg'), findsOneWidget);
    });

    testWidgets('renders tool call with disabled in workspace status', (
      tester,
    ) async {
      const toolCall = MessageToolCallEntity(
        id: 'tc-1',
        name: 'built_in_1_calculator',
        argumentsRaw: '{}',
        resultStatus: ToolCallResultStatus.disabledInWorkspace,
      );
      final message = _createMessage(
        content: '',
        isUser: false,
        metadata: const MessageMetadataEntity(toolCalls: [toolCall]),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('renders compacting indicator when compaction is running', (
      tester,
    ) async {
      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            conversationCompactionExecutionStateProvider.overrideWithValue(
              CompactionExecutionState(
                conversationId: 'conv-1',
                trigger: CompactionTrigger.auto,
                startedAt: DateTime(2025),
                status: CompactionExecutionStatus.running,
              ),
            ),
            messageConversationByIdProvider.overrideWith(
              (ref, id) => _createMessage(),
            ),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
      expect(find.text('Compacting...'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders compacted message widget for compaction summary', (
      tester,
    ) async {
      final message = _createMessage(
        content: 'Summary of older messages',
        isUser: false,
        metadata: const MessageMetadataEntity(
          isCompactionSummary: true,
          compactionKind: CompactionKind.auto,
          compactedMessageIds: ['old-1', 'old-2'],
          compactedFromMessageId: 'old-1',
          compactedThroughMessageId: 'old-2',
        ),
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.compress_outlined), findsOneWidget);
      expect(find.text('Automatic'), findsOneWidget);
      expect(find.text('Summary of older messages'), findsOneWidget);
    });

    testWidgets('renders error widget for non-user system error message', (
      tester,
    ) async {
      final message = _createMessage(
        content: 'compaction.errors.compaction_failed',
        isUser: false,
        status: MessageStatus.error,
        messageType: MessageType.system,
      );

      await pumpAndInit(
        tester,
        buildSubject(
          messages: ['msg-1'],
          overrides: [
            messageConversationByIdProvider.overrideWith((ref, id) => message),
            isMessageStreamingProvider.overrideWith((ref, id) => false),
            conversationBusyStateProvider.overrideWith(
              (ref) async => const ConversationBusyState(
                isStreaming: false,
                hasPendingTools: false,
              ),
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
