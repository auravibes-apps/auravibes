import 'package:auravibes_app/domain/enums/tool_grant_level.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_decision.dart';
import 'package:auravibes_app/features/chats/usecases/run_agent_iteration_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/approve_tool_call_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/run_allowed_tools_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/skip_tool_call_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/stop_all_pending_tool_calls_usecase.dart';
import 'package:riverpod/riverpod.dart';

class HandleToolApprovalIterationUsecase {
  const HandleToolApprovalIterationUsecase({
    required this.messageRepository,
    required this.conversationRepository,
    required this.approveToolCallUsecase,
    required this.skipToolCallUsecase,
    required this.stopAllPendingToolCallsUsecase,
    required this.runAllowedToolsUsecase,
    required this.runAgentIterationUsecase,
  });

  final MessageRepository messageRepository;
  final ConversationRepository conversationRepository;
  final ApproveToolCallUsecase approveToolCallUsecase;
  final SkipToolCallUsecase skipToolCallUsecase;
  final StopAllPendingToolCallsUsecase stopAllPendingToolCallsUsecase;
  final RunAllowedToolsUsecase runAllowedToolsUsecase;
  final RunAgentIterationUsecase runAgentIterationUsecase;

  Future<void> approveToolCall({
    required String toolCallId,
    required String messageId,
    required ToolGrantLevel level,
  }) async {
    await approveToolCallUsecase.call(
      toolCallId: toolCallId,
      messageId: messageId,
      level: level,
    );

    await _resumeConversationIfReady(messageId: messageId);
  }

  Future<void> skipToolCall({
    required String toolCallId,
    required String messageId,
  }) async {
    await skipToolCallUsecase.call(
      toolCallId: toolCallId,
      messageId: messageId,
    );

    await _resumeConversationIfReady(messageId: messageId);
  }

  Future<void> stopAllToolCalls({required String messageId}) {
    return stopAllPendingToolCallsUsecase.call(messageId: messageId);
  }

  Future<void> _resumeConversationIfReady({required String messageId}) async {
    final message = await messageRepository.getMessageById(messageId);
    if (message == null) return;

    final conversation = await conversationRepository.getConversationById(
      message.conversationId,
    );
    if (conversation == null) return;

    final decision = await runAllowedToolsUsecase.call(
      conversationId: conversation.id,
      workspaceId: conversation.workspaceId,
    );
    if (decision != AgentIterationDecision.continueIteration) return;

    await runAgentIterationUsecase.call(
      conversationId: conversation.id,
      context: const AgentIterationContext(
        origin: AgentIterationOrigin.toolResume,
      ),
    );
  }
}

final handleToolApprovalIterationUsecaseProvider =
    Provider<HandleToolApprovalIterationUsecase>((ref) {
      return HandleToolApprovalIterationUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
        conversationRepository: ref.watch(conversationRepositoryProvider),
        approveToolCallUsecase: ref.watch(approveToolCallUsecaseProvider),
        skipToolCallUsecase: ref.watch(skipToolCallUsecaseProvider),
        stopAllPendingToolCallsUsecase: ref.watch(
          stopAllPendingToolCallsUsecaseProvider,
        ),
        runAllowedToolsUsecase: ref.watch(runAllowedToolsUsecaseProvider),
        runAgentIterationUsecase: ref.watch(runAgentIterationUsecaseProvider),
      );
    });
