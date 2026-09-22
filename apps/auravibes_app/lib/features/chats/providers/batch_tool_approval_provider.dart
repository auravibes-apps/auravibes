import 'package:auravibes_app/features/chats/agent_adapters/agent_tool_resume_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/cloud_turn_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_effective_tool_approval_usecase.dart';
import 'package:auravibes_app/services/tools/tool_resolver_service.dart';
import 'package:riverpod/riverpod.dart';

final batchToolApprovalUsecaseProvider = Provider<BatchToolApprovalActions>(
  (ref) => BatchToolApprovalUsecase(
    messageRepository: ref.watch(messageRepositoryProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    agentToolResumeService: ref.watch(agentToolResumeServiceProvider),
    runResolvedTool: ref.watch(resolvedToolServiceProvider),
    cancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    toolResolver: const ToolResolverService(),
    loadToolSpecs: (workspaceId) =>
        ref.read(loadConversationToolSpecsUsecaseProvider(workspaceId)),
    effectiveToolApproval: ref.watch(
      resolveEffectiveToolApprovalUsecaseProvider,
    ),
    resolveCloudTurn: (workspaceId) =>
        ref.read(cloudTurnUsecaseProvider(workspaceId).future),
    onToolCallChanged: () => ref.invalidate(pendingToolCallsProvider),
  ),
  dependencies: [agentToolResumeServiceProvider],
);
