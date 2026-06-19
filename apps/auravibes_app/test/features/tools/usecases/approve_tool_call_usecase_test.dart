// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/approve_tool_call_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_resolved_tool_usecase.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ApproveToolCallUsecase', () {
    var messageRepository = MockMessageRepository();
    var conversationRepository = MockConversationRepository();
    var conversationToolsRepository = MockConversationToolsRepository();
    var resolveToolApprovalDecisionUsecase =
        MockResolveToolApprovalDecisionUsecase();
    var toolResolverService = MockToolResolverService();
    var resumeConversationIfReadyUsecase =
        MockResumeConversationIfReadyUsecase();
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    String? calledMcpServerId;
    String? calledMcpToolIdentifier;
    Map<String, dynamic>? calledMcpArguments;
    var usecase = ApproveToolCallUsecase(
      messageRepository: messageRepository,
      conversationRepository: conversationRepository,
      conversationToolsRepository: conversationToolsRepository,
      toolResolverService: toolResolverService,
      resolveToolApprovalDecisionUsecase: resolveToolApprovalDecisionUsecase,
      resumeConversationIfReadyUsecase: resumeConversationIfReadyUsecase,
      runResolvedToolUsecase: RunResolvedToolUsecase(
        agentCancellationRuntime: agentCancellationRuntime,
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
            }) async {
              calledMcpServerId = mcpServerId;
              calledMcpToolIdentifier = toolIdentifier;
              calledMcpArguments = arguments;

              return 'mcp result';
            },
      ),
      agentCancellationRuntime: agentCancellationRuntime,
    );

    const toolCallId = 'tool-1';
    const messageId = 'message-1';
    final message = MessageEntity(
      id: messageId,
      conversationId: 'conversation-1',
      content: 'assistant',
      messageType: MessageType.text,
      isUser: false,
      status: MessageStatus.sent,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      metadata: const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: toolCallId,
            name: 'built_in_calc_calculator',
            argumentsRaw: '{"input": "1+1"}',
          ),
        ],
      ),
    );

    setUp(() {
      messageRepository = MockMessageRepository();
      conversationRepository = MockConversationRepository();
      conversationToolsRepository = MockConversationToolsRepository();
      resolveToolApprovalDecisionUsecase =
          MockResolveToolApprovalDecisionUsecase();
      toolResolverService = MockToolResolverService();
      resumeConversationIfReadyUsecase = MockResumeConversationIfReadyUsecase();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');
      calledMcpServerId = null;
      calledMcpToolIdentifier = null;
      calledMcpArguments = null;

      usecase = ApproveToolCallUsecase(
        messageRepository: messageRepository,
        conversationRepository: conversationRepository,
        conversationToolsRepository: conversationToolsRepository,
        toolResolverService: toolResolverService,
        resolveToolApprovalDecisionUsecase: resolveToolApprovalDecisionUsecase,
        resumeConversationIfReadyUsecase: resumeConversationIfReadyUsecase,
        runResolvedToolUsecase: RunResolvedToolUsecase(
          agentCancellationRuntime: agentCancellationRuntime,
          mcpToolCaller:
              ({
                required mcpServerId,
                required toolIdentifier,
                required arguments,
              }) async {
                calledMcpServerId = mcpServerId;
                calledMcpToolIdentifier = toolIdentifier;
                calledMcpArguments = arguments;

                return 'mcp result';
              },
        ),
        agentCancellationRuntime: agentCancellationRuntime,
      );

      when(() => messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(() => messageRepository.patchMessage(messageId, any())).thenAnswer(
        (_) async => message,
      );
      when(
        () => resumeConversationIfReadyUsecase.call(
          messageId: any(named: 'messageId'),
        ),
      ).thenAnswer((_) {
        return Future<void>.value();
      });
    });

    test('marks tool as not found when resolution fails', () async {
      when(
        () => toolResolverService.resolveTool('built_in_calc_calculator'),
      ).thenReturn(null);

      await usecase.call(
        toolCallId: toolCallId,
        messageId: messageId,
        level: ToolGrantLevel.once,
      );

      final update =
          verify(
                () => messageRepository.patchMessage(messageId, captureAny()),
              ).captured.single
              as MessagePatch;
      expect(
        update.metadata?.toolCalls.single.resultStatus,
        ToolCallResultStatus.toolNotFound,
      );

      verify(
        () => resumeConversationIfReadyUsecase.call(messageId: messageId),
      ).called(1);
    });

    test(
      'executes MCP tools with raw arguments',
      () async {
        final mcpMessage = message.copyWith(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: toolCallId,
                name: 'mcp_server-1_calc_sum',
                argumentsRaw: '{"a": 1, "b": 2}',
              ),
            ],
          ),
        );
        final resolvedTool =
            ToolResolverService().resolveTool(
              'mcp_server-1_calc_sum',
            ) ??
            fail('Expected tool to resolve');

        when(() => messageRepository.getMessageById(messageId)).thenAnswer(
          (_) async => mcpMessage,
        );
        when(
          () => toolResolverService.resolveTool('mcp_server-1_calc_sum'),
        ).thenReturn(resolvedTool);

        await usecase.call(
          toolCallId: toolCallId,
          messageId: messageId,
          level: ToolGrantLevel.once,
        );

        expect(calledMcpServerId, 'server-1');
        expect(calledMcpToolIdentifier, 'sum');
        expect(calledMcpArguments, {'a': 1, 'b': 2});

        final update =
            verify(
                  () => messageRepository.patchMessage(messageId, captureAny()),
                ).captured.single
                as MessagePatch;
        expect(update.metadata?.toolCalls.single.responseRaw, 'mcp result');
      },
    );

    test(
      'persists conversation allow and stores successful response',
      () async {
        final resolvedTool =
            ToolResolverService().resolveTool(
              'built_in_calc_calculator',
            ) ??
            fail('Expected tool to resolve');

        when(
          () => toolResolverService.resolveTool('built_in_calc_calculator'),
        ).thenReturn(resolvedTool);
        when(
          () => conversationRepository.getConversationById('conversation-1'),
        ).thenAnswer((_) async => _conversation);
        when(
          () => resolveToolApprovalDecisionUsecase.resolvePermissionTableId(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            resolvedTool: resolvedTool,
          ),
        ).thenAnswer((_) async => 'calc');
        when(
          () => conversationToolsRepository.setConversationToolPermission(
            'conversation-1',
            'calc',
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).thenAnswer((_) async => true);

        await usecase.call(
          toolCallId: toolCallId,
          messageId: messageId,
          level: ToolGrantLevel.conversation,
        );

        verify(
          () => conversationToolsRepository.setConversationToolPermission(
            'conversation-1',
            'calc',
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).called(1);

        final update =
            verify(
                  () => messageRepository.patchMessage(messageId, captureAny()),
                ).captured.single
                as MessagePatch;
        final updatedToolCall = update.metadata?.toolCalls.single;
        expect(updatedToolCall?.resultStatus, ToolCallResultStatus.success);
        expect(updatedToolCall?.responseRaw, '2.0');

        verify(
          () => resumeConversationIfReadyUsecase.call(messageId: messageId),
        ).called(1);
      },
    );

    test(
      'marks tool as executionError when built-in input is missing',
      () async {
        final badMessage = message.copyWith(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: toolCallId,
                name: 'built_in_calc_calculator',
                argumentsRaw: '{}',
              ),
            ],
          ),
        );
        final resolvedTool =
            ToolResolverService().resolveTool(
              'built_in_calc_calculator',
            ) ??
            fail('Expected tool to resolve');

        when(() => messageRepository.getMessageById(messageId)).thenAnswer(
          (_) async => badMessage,
        );
        when(
          () => toolResolverService.resolveTool('built_in_calc_calculator'),
        ).thenReturn(resolvedTool);

        await usecase.call(
          toolCallId: toolCallId,
          messageId: messageId,
          level: ToolGrantLevel.once,
        );

        final update =
            verify(
                  () => messageRepository.patchMessage(messageId, captureAny()),
                ).captured.single
                as MessagePatch;
        expect(
          update.metadata?.toolCalls.single.resultStatus,
          ToolCallResultStatus.executionError,
        );
      },
    );

    test(
      'resolves MCP permission table before persisting conversation allow',
      () async {
        final mcpMessage = message.copyWith(
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: toolCallId,
                name: 'mcp_server-1_calc_sum',
                argumentsRaw: '{}',
              ),
            ],
          ),
        );
        final resolvedTool =
            ToolResolverService().resolveTool(
              'mcp_server-1_calc_sum',
            ) ??
            fail('Expected tool to resolve');

        when(() => messageRepository.getMessageById(messageId)).thenAnswer(
          (_) async => mcpMessage,
        );
        when(
          () => toolResolverService.resolveTool('mcp_server-1_calc_sum'),
        ).thenReturn(
          resolvedTool,
        );
        when(
          () => conversationRepository.getConversationById('conversation-1'),
        ).thenAnswer((_) async => _conversation);
        when(
          () => resolveToolApprovalDecisionUsecase.resolvePermissionTableId(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            resolvedTool: resolvedTool,
          ),
        ).thenAnswer((_) async => 'workspace-tool-1');
        when(
          () => conversationToolsRepository.setConversationToolPermission(
            'conversation-1',
            'workspace-tool-1',
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).thenAnswer((_) async => true);

        await usecase.call(
          toolCallId: toolCallId,
          messageId: messageId,
          level: ToolGrantLevel.conversation,
        );

        verify(
          () => conversationToolsRepository.setConversationToolPermission(
            'conversation-1',
            'workspace-tool-1',
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).called(1);
      },
    );
  });
}

final _conversation = ConversationEntity(
  id: 'conversation-1',
  title: 'Conversation',
  workspaceId: 'workspace-1',
  isPinned: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
