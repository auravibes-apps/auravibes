import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/agent_harness/approve_tool_call_service.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('AppApproveToolCallDataProvider', () {
    var messageRepository = MockMessageRepository();
    var conversationRepository = MockConversationRepository();
    var conversationToolsRepository = MockConversationToolsRepository();
    var resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
    var agentToolResumeService = MockAgentToolResumeService();
    var provider = AppApproveToolCallDataProvider(
      messageRepository: messageRepository,
      conversationRepository: conversationRepository,
      conversationToolsRepository: conversationToolsRepository,
      resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
      toolResolverService: const ToolResolverService(),
      agentToolResumeService: agentToolResumeService,
      runResolvedToolUsecase: ResolvedToolService(
        agentCancellationRuntime: agent.AgentCancellationRuntime(),
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
            }) => Future.value(''),
      ),
      agentCancellationRuntime: agent.AgentCancellationRuntime(),
    );

    const messageId = 'message-1';
    const conversationId = 'conversation-1';
    const workspaceId = 'workspace-1';

    final tool = ResolvedTool.builtIn(
      tableId: 'calculator',
      toolIdentifier: 'calculator',
      tooltype: UserToolType.calculator,
    );
    final message = MessageEntity(
      id: messageId,
      conversationId: conversationId,
      content: 'assistant',
      messageType: MessageType.text,
      isUser: false,
      status: MessageStatus.sent,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      metadata: const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'tool-1',
            name: 'calculator',
            argumentsRaw: '{"input":"1+1"}',
          ),
        ],
      ),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      conversationRepository = MockConversationRepository();
      conversationToolsRepository = MockConversationToolsRepository();
      resolveToolApprovalDecision = MockResolveToolApprovalDecisionUsecase();
      agentToolResumeService = MockAgentToolResumeService();
      provider = AppApproveToolCallDataProvider(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        conversationToolsRepository: conversationToolsRepository,
        resolveToolApprovalDecisionUsecase: resolveToolApprovalDecision,
        toolResolverService: const ToolResolverService(),
        agentToolResumeService: agentToolResumeService,
        runResolvedToolUsecase: ResolvedToolService(
          agentCancellationRuntime: agent.AgentCancellationRuntime(),
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
              }) => Future.value(''),
        ),
        agentCancellationRuntime: agent.AgentCancellationRuntime(),
      );
    });

    test('loads approvable tool call from message metadata', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );

      final result = await provider.loadToolCall(
        messageId: messageId,
        toolCallId: 'tool-1',
      );

      expect(result?.conversationId, conversationId);
      expect(result?.name, 'calculator');
      expect(result?.argumentsRaw, '{"input":"1+1"}');
    });

    test('returns null when message or tool call is missing', () async {
      when(() => messageRepository.getMessageById('missing')).thenAnswer(
        (_) async => null,
      );
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );

      expect(
        await provider.loadToolCall(
          messageId: 'missing',
          toolCallId: 'tool-1',
        ),
        isNull,
      );
      expect(
        await provider.loadToolCall(
          messageId: messageId,
          toolCallId: 'missing-tool',
        ),
        isNull,
      );
    });

    test('grants resolved tool permission for the conversation', () async {
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer(
        (_) async => ConversationEntity(
          id: conversationId,
          title: 'Conversation',
          workspaceId: workspaceId,
          isPinned: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      when(
        () => resolveToolApprovalDecision.resolvePermissionTableId(
          conversationId: conversationId,
          workspaceId: workspaceId,
          resolvedTool: tool,
        ),
      ).thenAnswer((_) async => 'permission-table-1');
      when(
        () => conversationToolsRepository.setConversationToolPermission(
          conversationId,
          'permission-table-1',
          permissionMode: ToolPermissionMode.alwaysAllow,
        ),
      ).thenAnswer((_) async => true);

      await expectLater(
        provider.grantToolForConversation(
          conversationId: conversationId,
          tool: tool,
        ),
        completes,
      );

      verify(
        () => conversationToolsRepository.setConversationToolPermission(
          conversationId,
          'permission-table-1',
          permissionMode: ToolPermissionMode.alwaysAllow,
        ),
      ).called(1);
    });

    test('skips permission grant when conversation is missing', () async {
      when(
        () => conversationRepository.getConversationById(conversationId),
      ).thenAnswer((_) async => null);

      await expectLater(
        provider.grantToolForConversation(
          conversationId: conversationId,
          tool: tool,
        ),
        completes,
      );

      verifyNever(
        () => conversationToolsRepository.setConversationToolPermission(
          conversationId,
          'permission-table-1',
          permissionMode: ToolPermissionMode.alwaysAllow,
        ),
      ).called(0);
    });

    test('updates tool call result status in message metadata', () async {
      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(() => messageRepository.patchMessage(messageId, any())).thenAnswer(
        (_) async => message,
      );

      const cases = {
        agent.AgentToolResultStatus.success: ToolCallResultStatus.success,
        agent.AgentToolResultStatus.toolNotFound:
            ToolCallResultStatus.toolNotFound,
        agent.AgentToolResultStatus.executionError:
            ToolCallResultStatus.executionError,
        agent.AgentToolResultStatus.disabledInConversation:
            ToolCallResultStatus.disabledInConversation,
        agent.AgentToolResultStatus.disabledInWorkspace:
            ToolCallResultStatus.disabledInWorkspace,
        agent.AgentToolResultStatus.notConfigured:
            ToolCallResultStatus.notConfigured,
        agent.AgentToolResultStatus.stoppedByUser:
            ToolCallResultStatus.stoppedByUser,
      };

      for (final entry in cases.entries) {
        await provider.updateToolCallResult(
          messageId: messageId,
          toolCallId: 'tool-1',
          resultStatus: entry.key,
          responseRaw: 'response',
        );
      }

      final patches = verify(
        () => messageRepository.patchMessage(messageId, captureAny()),
      ).captured.whereType<MessagePatch>().toList();
      expect(
        patches.map((patch) => patch.metadata?.toolCalls.single.resultStatus),
        cases.values,
      );
      expect(
        patches.map((patch) => patch.metadata?.toolCalls.single.responseRaw),
        everyElement('response'),
      );
    });

    test('resumes conversation through resume service', () async {
      when(
        () => agentToolResumeService.call(messageId: messageId),
      ).thenAnswer((_) => Future<void>.value());

      await expectLater(
        provider.resumeConversationIfReady(messageId: messageId),
        completes,
      );

      verify(() => agentToolResumeService.call(messageId: messageId)).called(1);
    });
  });
}
