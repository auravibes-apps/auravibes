import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/chats/usecases/resume_conversation_if_ready_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/approve_tool_call_usecase.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'approve_tool_call_usecase_test.mocks.dart';

@GenerateMocks([
  MessageRepository,
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
  ToolResolverService,
  ResumeConversationIfReadyUsecase,
])
void main() {
  group('ApproveToolCallUsecase', () {
    late MockMessageRepository messageRepository;
    late MockConversationToolsRepository conversationToolsRepository;
    late MockToolsGroupsRepository toolsGroupsRepository;
    late MockWorkspaceToolsRepository workspaceToolsRepository;
    late MockToolResolverService toolResolverService;
    late MockResumeConversationIfReadyUsecase resumeConversationIfReadyUsecase;
    late ApproveToolCallUsecase usecase;

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
      conversationToolsRepository = MockConversationToolsRepository();
      toolsGroupsRepository = MockToolsGroupsRepository();
      workspaceToolsRepository = MockWorkspaceToolsRepository();
      toolResolverService = MockToolResolverService();
      resumeConversationIfReadyUsecase = MockResumeConversationIfReadyUsecase();

      usecase = ApproveToolCallUsecase(
        messageRepository: messageRepository,
        conversationToolsRepository: conversationToolsRepository,
        toolsGroupsRepository: toolsGroupsRepository,
        workspaceToolsRepository: workspaceToolsRepository,
        toolResolverService: toolResolverService,
        resumeConversationIfReadyUsecase: resumeConversationIfReadyUsecase,
      );

      when(messageRepository.getMessageById(messageId)).thenAnswer(
        (_) async => message,
      );
      when(messageRepository.updateMessage(messageId, any)).thenAnswer(
        (_) async => message,
      );
      when(
        resumeConversationIfReadyUsecase.call(messageId: anyNamed('messageId')),
      ).thenAnswer((_) async {});
    });

    test('marks tool as not found when resolution fails', () async {
      when(
        toolResolverService.resolveTool('built_in_calc_calculator'),
      ).thenReturn(null);

      await usecase.call(
        toolCallId: toolCallId,
        messageId: messageId,
        level: ToolGrantLevel.once,
      );

      final update =
          verify(
                messageRepository.updateMessage(messageId, captureAny),
              ).captured.single
              as MessageToUpdate;
      expect(
        update.metadata?.toolCalls.single.resultStatus,
        ToolCallResultStatus.toolNotFound,
      );

      verify(
        resumeConversationIfReadyUsecase.call(messageId: messageId),
      ).called(1);
    });

    test(
      'persists conversation allow and stores successful response',
      () async {
        final resolvedTool = ToolResolverService().resolveTool(
          'built_in_calc_calculator',
        )!;

        when(
          toolResolverService.resolveTool('built_in_calc_calculator'),
        ).thenReturn(resolvedTool);
        when(
          conversationToolsRepository.setConversationToolPermission(
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
          conversationToolsRepository.setConversationToolPermission(
            'conversation-1',
            'calc',
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).called(1);

        final update =
            verify(
                  messageRepository.updateMessage(messageId, captureAny),
                ).captured.single
                as MessageToUpdate;
        final updatedToolCall = update.metadata?.toolCalls.single;
        expect(updatedToolCall?.resultStatus, ToolCallResultStatus.success);
        expect(updatedToolCall?.responseRaw, '2.0');

        verify(
          resumeConversationIfReadyUsecase.call(messageId: messageId),
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
        final resolvedTool = ToolResolverService().resolveTool(
          'built_in_calc_calculator',
        )!;

        when(messageRepository.getMessageById(messageId)).thenAnswer(
          (_) async => badMessage,
        );
        when(
          toolResolverService.resolveTool('built_in_calc_calculator'),
        ).thenReturn(resolvedTool);

        await usecase.call(
          toolCallId: toolCallId,
          messageId: messageId,
          level: ToolGrantLevel.once,
        );

        final update =
            verify(
                  messageRepository.updateMessage(messageId, captureAny),
                ).captured.single
                as MessageToUpdate;
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
        final resolvedTool = ToolResolverService().resolveTool(
          'mcp_server-1_calc_sum',
        )!;
        final group = ToolsGroupEntity(
          id: 'group-1',
          workspaceId: 'workspace-1',
          name: 'Group',
          isEnabled: true,
          permissions: PermissionAccess.ask,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          mcpServerId: 'server-1',
        );
        final workspaceTool = WorkspaceToolEntity(
          id: 'workspace-tool-1',
          workspaceId: 'workspace-1',
          toolId: 'sum',
          isEnabled: true,
          permissionMode: ToolPermissionMode.alwaysAsk,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          workspaceToolsGroupId: 'group-1',
        );

        when(messageRepository.getMessageById(messageId)).thenAnswer(
          (_) async => mcpMessage,
        );
        when(
          toolResolverService.resolveTool('mcp_server-1_calc_sum'),
        ).thenReturn(
          resolvedTool,
        );
        when(
          toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
        ).thenAnswer((_) async => group);
        when(
          workspaceToolsRepository.getWorkspaceToolByToolName(
            toolGroupId: 'group-1',
            toolName: 'sum',
          ),
        ).thenAnswer((_) async => workspaceTool);
        when(
          conversationToolsRepository.setConversationToolPermission(
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
          conversationToolsRepository.setConversationToolPermission(
            'conversation-1',
            'workspace-tool-1',
            permissionMode: ToolPermissionMode.alwaysAllow,
          ),
        ).called(1);
      },
    );
  });
}
