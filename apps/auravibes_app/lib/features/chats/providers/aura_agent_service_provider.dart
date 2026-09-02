import 'package:auravibes_app/features/chats/agent_adapters/app_agent_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_execution_service.dart';
import 'package:auravibes_app/services/agent_harness/agent_tool_resume_service.dart';
import 'package:auravibes_app/services/agent_harness/approve_tool_call_service.dart';
import 'package:auravibes_app/services/agent_harness/resolved_tool_service.dart';
import 'package:auravibes_app/services/agent_harness/skip_tool_call_service.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

final auraAgentServiceProvider = Provider<agent.AuraAgentService<ResolvedTool>>(
  (ref) {
    final agentToolResumeService = ref.watch(agentToolResumeServiceProvider);
    final agentToolExecutionService = ref.watch(
      agentToolExecutionServiceProvider,
    );
    final toolCallActions = AppToolCallActionsDataProvider(
      messageRepository: ref.watch(messageRepositoryProvider),
      agentToolResumeService: agentToolResumeService,
      onToolCallChanged: () => ref.invalidate(pendingToolCallsProvider),
      activeSubAgents: ref.watch(activeSubAgentRuntimeProvider.notifier),
    );

    return agent.AuraAgentService<ResolvedTool>(
      data: ref.watch(appAgentDataProvider),
      models: ref.watch(appAgentModelProvider),
      loopTools: AppAgentLoopToolProvider(agentToolExecutionService),
      approvals: AppApproveToolCallDataProvider(
        messageRepository: ref.watch(messageRepositoryProvider),
        conversationRepository: ref.watch(conversationRepositoryProvider),
        conversationToolsRepositoryForWorkspace: (workspaceId) =>
            ref.read(conversationToolsRepositoryProvider(workspaceId)),
        resolveToolApprovalDecisionUsecaseForWorkspace: (workspaceId) =>
            ref.read(resolveToolApprovalDecisionUsecaseProvider(workspaceId)),
        loadConversationToolSpecsUsecaseForWorkspace: (workspaceId) =>
            ref.read(loadConversationToolSpecsUsecaseProvider(workspaceId)),
        toolResolverService: const ToolResolverService(),
        agentToolResumeService: agentToolResumeService,
        runResolvedToolUsecase: ref.watch(resolvedToolServiceProvider),
        agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
        onToolCallChanged: () => ref.invalidate(pendingToolCallsProvider),
      ),
      skips: toolCallActions,
      stopPending: toolCallActions,
      resume: agentToolResumeService.provider,
      sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
      cancellationEffects: ref.watch(agentCancellationRuntimeProvider),
      rateLimitRetryRuntime: agent.AgentRateLimitRetryRuntime(
        start: ref.watch(conversationRateLimitRetryRuntimeProvider).start,
        clear: ref.watch(conversationRateLimitRetryRuntimeProvider).clear,
      ),
    );
  },
  dependencies: [
    agentToolResumeServiceProvider,
    appAgentDataProvider,
    appAgentModelProvider,
  ],
);
