import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/grouped_tools_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/providers/tool_calling_manager_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'tool_calling_manager_provider_test.mocks.dart';

/// A fake MessagesManagerNotifier for testing that tracks calls
class FakeMessagesManagerNotifier extends MessagesManagerNotifier {
  final List<(List<ToolResponseItem>, String)> sendToolsResponseCalls = [];

  @override
  Future<void> sendToolsResponse(
    List<ToolResponseItem> responses,
    String responseMessageId,
  ) async {
    sendToolsResponseCalls.add((responses, responseMessageId));
  }
}

@GenerateMocks([
  MessageRepository,
  ConversationRepository,
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
])
void main() {
  late MockMessageRepository mockMessageRepository;
  late MockConversationRepository mockConversationRepository;
  late MockConversationToolsRepository mockConversationToolsRepository;
  late MockToolsGroupsRepository mockToolsGroupsRepository;
  late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;
  late FakeMessagesManagerNotifier fakeMessagesManagerNotifier;
  late ProviderContainer container;

  // Test data
  const testMessageId = 'test-message-id';
  const testConversationId = 'test-conversation-id';
  const testWorkspaceId = 'test-workspace-id';
  const testToolCallId = 'test-tool-call-id';
  // Composite ID format: built_in_<table_id>_<tool_identifier>
  const testToolTableId = 'tool-table-id';
  const testToolIdentifier = 'calculator';
  const testToolName = 'built_in_${testToolTableId}_$testToolIdentifier';

  MessageEntity createTestMessage({
    String? id,
    String? conversationId,
    MessageMetadataEntity? metadata,
  }) {
    return MessageEntity(
      id: id ?? testMessageId,
      conversationId: conversationId ?? testConversationId,
      content: 'test content',
      messageType: MessageType.text,
      isUser: false,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  ConversationEntity createTestConversation({
    String? id,
    String? workspaceId,
  }) {
    return ConversationEntity(
      id: id ?? testConversationId,
      workspaceId: workspaceId ?? testWorkspaceId,
      title: 'Test Conversation',
      modelId: 'test-model-id',
      isPinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  MessageToolCallEntity createTestToolCall({
    String? id,
    String? name,
    String? responseRaw,
    ToolCallResultStatus? resultStatus,
  }) {
    return MessageToolCallEntity(
      id: id ?? testToolCallId,
      name: name ?? testToolName,
      argumentsRaw: '{"input": "2+2"}',
      responseRaw: responseRaw,
      resultStatus: resultStatus,
    );
  }

  ToolToCall createTestToolToCall({
    String? id,
    String? tableId,
    String? toolIdentifier,
    UserToolType? toolType,
    String? argumentsRaw,
  }) {
    return ToolToCall(
      tool: ResolvedTool.builtIn(
        tableId: tableId ?? testToolTableId,
        toolIdentifier: toolIdentifier ?? testToolIdentifier,
        tooltype: toolType ?? UserToolType.calculator,
      ),
      id: id ?? testToolCallId,
      argumentsRaw: argumentsRaw ?? '{"input": "2+2"}',
    );
  }

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    mockConversationRepository = MockConversationRepository();
    mockConversationToolsRepository = MockConversationToolsRepository();
    mockToolsGroupsRepository = MockToolsGroupsRepository();
    mockWorkspaceToolsRepository = MockWorkspaceToolsRepository();
    fakeMessagesManagerNotifier = FakeMessagesManagerNotifier();

    container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(mockMessageRepository),
        conversationRepositoryProvider.overrideWithValue(
          mockConversationRepository,
        ),
        conversationToolsRepositoryProvider.overrideWithValue(
          mockConversationToolsRepository,
        ),
        toolsGroupsRepositoryProvider.overrideWithValue(
          mockToolsGroupsRepository,
        ),
        workspaceToolsRepositoryProvider.overrideWithValue(
          mockWorkspaceToolsRepository,
        ),
        messagesManagerProvider.overrideWith(() => fakeMessagesManagerNotifier),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ToolCallingManagerNotifier - State query methods', () {
    test('isToolRunning returns false when no tools are running', () {
      final notifier = container.read(toolCallingManagerProvider.notifier);

      expect(notifier.isToolRunning('any-id'), false);
    });

    test(
      'hasRunningToolsForMessage returns false when no tools are running',
      () {
        final notifier = container.read(toolCallingManagerProvider.notifier);

        expect(notifier.hasRunningToolsForMessage(testMessageId), false);
      },
    );

    test('getToolCallsForMessage returns empty list when no tools tracked', () {
      final notifier = container.read(toolCallingManagerProvider.notifier);

      expect(notifier.getToolCallsForMessage(testMessageId), isEmpty);
    });
  });

  group('ToolCallingManagerNotifier - runTask', () {
    test('returns early when message is not found', () async {
      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => null);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.runTask(
        [createTestToolToCall()],
        testMessageId,
      );

      verifyNever(mockConversationRepository.getConversationById(any));
    });

    test('returns early when conversation is not found', () async {
      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => createTestMessage());
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => null);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.runTask(
        [createTestToolToCall()],
        testMessageId,
      );

      verifyNever(
        mockConversationToolsRepository.checkToolPermission(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
          toolId: anyNamed('toolId'),
        ),
      );
    });

    test('skips disabled tools with appropriate response', () async {
      final toolToCall = createTestToolToCall();
      final toolCall = createTestToolCall();
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );
      final conversation = createTestConversation();

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockConversationToolsRepository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolTableId,
        ),
      ).thenAnswer((_) async => ToolPermissionResult.disabledInConversation);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => message);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.runTask([toolToCall], testMessageId);

      final captured = verify(
        mockMessageRepository.updateMessage(
          captureAny,
          captureAny,
        ),
      ).captured;
      final messageToUpdate = captured[1] as MessageToUpdate;
      expect(
        messageToUpdate.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.disabledInConversation,
      );
    });

    test('does not send AI response when tools need confirmation', () async {
      final toolToCall = createTestToolToCall();
      final toolCall = createTestToolCall();
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );
      final conversation = createTestConversation();

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockConversationToolsRepository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolTableId,
        ),
      ).thenAnswer((_) async => ToolPermissionResult.needsConfirmation);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => message);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.runTask([toolToCall], testMessageId);

      expect(fakeMessagesManagerNotifier.sendToolsResponseCalls, isEmpty);
    });

    test('processes mix of granted and skipped tools correctly', () async {
      final grantedToolToCall = createTestToolToCall(id: 'granted-tool-id');
      final skippedToolToCall = createTestToolToCall(id: 'skipped-tool-id');
      final grantedToolCall = createTestToolCall(id: 'granted-tool-id');
      final skippedToolCall = createTestToolCall(id: 'skipped-tool-id');
      final message = createTestMessage(
        metadata: MessageMetadataEntity(
          toolCalls: [grantedToolCall, skippedToolCall],
        ),
      );
      final conversation = createTestConversation();

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockConversationToolsRepository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: 'calculator',
        ),
      ).thenAnswer((_) async => ToolPermissionResult.granted);
      when(
        mockConversationToolsRepository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolTableId,
        ),
      ).thenAnswer((_) async => ToolPermissionResult.needsConfirmation);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => message);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.runTask(
        [grantedToolToCall, skippedToolToCall],
        testMessageId,
      );

      expect(fakeMessagesManagerNotifier.sendToolsResponseCalls, isEmpty);
    });
  });

  group('ToolCallingManagerNotifier - skipToolCall', () {
    test('marks tool as skipped with skippedByUser status', () async {
      final toolCall = createTestToolCall();
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => message);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.skipToolCall(
        toolCallId: testToolCallId,
        messageId: testMessageId,
      );

      final captured = verify(
        mockMessageRepository.updateMessage(
          captureAny,
          captureAny,
        ),
      ).captured;
      final messageToUpdate = captured[1] as MessageToUpdate;
      expect(
        messageToUpdate.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.skippedByUser,
      );
    });

    test('sends AI response when all tools are resolved after skip', () async {
      final toolCall = createTestToolCall();
      final messageAfterSkip = createTestMessage(
        metadata: MessageMetadataEntity(
          toolCalls: [
            toolCall.copyWith(
              resultStatus: ToolCallResultStatus.skippedByUser,
            ),
          ],
        ),
      );

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => messageAfterSkip);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => messageAfterSkip);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.skipToolCall(
        toolCallId: testToolCallId,
        messageId: testMessageId,
      );

      expect(fakeMessagesManagerNotifier.sendToolsResponseCalls.length, 1);
    });
  });

  group('ToolCallingManagerNotifier - stopAllToolCalls', () {
    test('marks all pending tools as stopped without sending to AI', () async {
      final toolCall1 = createTestToolCall(id: 'tool-1');
      final toolCall2 = createTestToolCall(id: 'tool-2');
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall1, toolCall2]),
      );
      final messageAfterStop = createTestMessage(
        metadata: MessageMetadataEntity(
          toolCalls: [
            toolCall1.copyWith(
              resultStatus: ToolCallResultStatus.stoppedByUser,
            ),
            toolCall2.copyWith(
              resultStatus: ToolCallResultStatus.stoppedByUser,
            ),
          ],
        ),
      );

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => messageAfterStop);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.stopAllToolCalls(messageId: testMessageId);

      final captured = verify(
        mockMessageRepository.updateMessage(
          captureAny,
          captureAny,
        ),
      ).captured;
      final messageToUpdate = captured[1] as MessageToUpdate;
      expect(
        messageToUpdate.metadata?.toolCalls.every(
          (t) => t.resultStatus == ToolCallResultStatus.stoppedByUser,
        ),
        true,
      );

      expect(fakeMessagesManagerNotifier.sendToolsResponseCalls.length, 0);
    });

    test('returns early when message is not found', () async {
      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => null);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.stopAllToolCalls(messageId: testMessageId);

      verifyNever(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      );
    });
  });

  group('ToolCallingManagerNotifier - grantToolCall', () {
    test('returns early when message context is not found', () async {
      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => null);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.grantToolCall(
        toolCallId: testToolCallId,
        messageId: testMessageId,
        level: ToolGrantLevel.once,
      );

      verifyNever(
        mockConversationToolsRepository.setConversationToolPermission(
          any,
          any,
          permissionMode: anyNamed('permissionMode'),
        ),
      );
    });

    test('returns early when tool call is not found in message', () async {
      final message = createTestMessage(
        metadata: const MessageMetadataEntity(),
      );
      final conversation = createTestConversation();

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.grantToolCall(
        toolCallId: 'non-existent-tool-id',
        messageId: testMessageId,
        level: ToolGrantLevel.once,
      );

      verifyNever(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      );
    });

    test('persists permission when level is conversation', () async {
      final toolCall = createTestToolCall();
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );
      final conversation = createTestConversation();
      final messageAfterGrant = createTestMessage(
        metadata: MessageMetadataEntity(
          toolCalls: [toolCall.copyWith(responseRaw: '4')],
        ),
      );

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockMessageRepository.getMessagesByConversation(testConversationId),
      ).thenAnswer((_) async => [message]);
      when(
        mockConversationToolsRepository.setConversationToolPermission(
          testConversationId,
          testToolTableId,
          permissionMode: ToolPermissionMode.alwaysAllow,
        ),
      ).thenAnswer((_) async => true);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => messageAfterGrant);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.grantToolCall(
        toolCallId: testToolCallId,
        messageId: testMessageId,
        level: ToolGrantLevel.conversation,
      );

      verify(
        mockConversationToolsRepository.setConversationToolPermission(
          testConversationId,
          testToolTableId,
          permissionMode: ToolPermissionMode.alwaysAllow,
        ),
      ).called(1);
    });

    test(
      'runs pending tools with same table ID when granting for conversation',
      () async {
        const otherMessageId = 'other-message-id';
        const otherToolCallId = 'other-tool-call-id';
        final toolCall = createTestToolCall();
        final otherToolCall = createTestToolCall(id: otherToolCallId);
        final message = createTestMessage(
          metadata: MessageMetadataEntity(toolCalls: [toolCall]),
        );
        final otherMessage = createTestMessage(
          id: otherMessageId,
          metadata: MessageMetadataEntity(toolCalls: [otherToolCall]),
        );
        final conversation = createTestConversation();

        when(
          mockMessageRepository.getMessageById(testMessageId),
        ).thenAnswer((_) async => message);
        when(
          mockMessageRepository.getMessageById(otherMessageId),
        ).thenAnswer((_) async => otherMessage);
        when(
          mockConversationRepository.getConversationById(testConversationId),
        ).thenAnswer((_) async => conversation);
        when(
          mockMessageRepository.getMessagesByConversation(testConversationId),
        ).thenAnswer((_) async => [message, otherMessage]);
        when(
          mockConversationToolsRepository.setConversationToolPermission(
            testConversationId,
            testToolTableId,
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).thenAnswer((_) async => true);
        when(
          mockConversationToolsRepository.checkToolPermission(
            conversationId: testConversationId,
            workspaceId: testWorkspaceId,
            toolId: testToolTableId,
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          mockMessageRepository.updateMessage(
            any,
            any,
          ),
        ).thenAnswer((_) async => message);

        final notifier = container.read(toolCallingManagerProvider.notifier);
        await notifier.grantToolCall(
          toolCallId: testToolCallId,
          messageId: testMessageId,
          level: ToolGrantLevel.conversation,
        );

        final verification = verify(
          mockMessageRepository.updateMessage(
            otherMessageId,
            captureAny,
          ),
        )..called(1);
        final capturedUpdate = verification.captured.single as MessageToUpdate;
        expect(
          capturedUpdate.metadata?.toolCalls.first.resultStatus,
          ToolCallResultStatus.success,
        );
      },
    );

    test('does not persist permission when level is once', () async {
      final toolCall = createTestToolCall();
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );
      final conversation = createTestConversation();
      final messageAfterGrant = createTestMessage(
        metadata: MessageMetadataEntity(
          toolCalls: [toolCall.copyWith(responseRaw: '4')],
        ),
      );

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => messageAfterGrant);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.grantToolCall(
        toolCallId: testToolCallId,
        messageId: testMessageId,
        level: ToolGrantLevel.once,
      );

      verifyNever(
        mockConversationToolsRepository.setConversationToolPermission(
          any,
          any,
          permissionMode: anyNamed('permissionMode'),
        ),
      );
    });

    test('handles unknown tool gracefully when granting', () async {
      final toolCall = createTestToolCall(name: 'unknown_tool_xyz');
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );
      final conversation = createTestConversation();
      final messageAfterUpdate = createTestMessage(
        metadata: MessageMetadataEntity(
          toolCalls: [
            toolCall.copyWith(
              resultStatus: ToolCallResultStatus.toolNotFound,
            ),
          ],
        ),
      );

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => messageAfterUpdate);

      final notifier = container.read(toolCallingManagerProvider.notifier);
      await notifier.grantToolCall(
        toolCallId: testToolCallId,
        messageId: testMessageId,
        level: ToolGrantLevel.once,
      );

      final captured = verify(
        mockMessageRepository.updateMessage(
          captureAny,
          captureAny,
        ),
      ).captured;
      final messageToUpdate = captured[1] as MessageToUpdate;
      expect(
        messageToUpdate.metadata?.toolCalls.first.resultStatus,
        ToolCallResultStatus.toolNotFound,
      );
    });
  });

  group('ToolCallingManagerNotifier - TrackedToolCall state', () {
    test('tracking state is updated during tool execution', () async {
      final toolToCall = createTestToolToCall();
      final toolCall = createTestToolCall();
      final message = createTestMessage(
        metadata: MessageMetadataEntity(toolCalls: [toolCall]),
      );
      final conversation = createTestConversation();

      when(
        mockMessageRepository.getMessageById(testMessageId),
      ).thenAnswer((_) async => message);
      when(
        mockConversationRepository.getConversationById(testConversationId),
      ).thenAnswer((_) async => conversation);
      when(
        mockConversationToolsRepository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolTableId,
        ),
      ).thenAnswer((_) async => ToolPermissionResult.granted);
      when(
        mockMessageRepository.updateMessage(
          any,
          any,
        ),
      ).thenAnswer((_) async => message);

      final notifier = container.read(toolCallingManagerProvider.notifier);

      expect(container.read(toolCallingManagerProvider), isEmpty);

      await notifier.runTask([toolToCall], testMessageId);

      expect(container.read(toolCallingManagerProvider), isEmpty);
      expect(notifier.isToolRunning(testToolCallId), false);
      expect(notifier.hasRunningToolsForMessage(testMessageId), false);
    });
  });
}
