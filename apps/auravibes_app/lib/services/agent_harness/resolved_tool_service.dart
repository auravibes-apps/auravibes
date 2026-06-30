// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:async/async.dart';
import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_agent/auravibes_agent_internal.dart'
    as agent_resolved;
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:riverpod/riverpod.dart';

const _conversationRepositoryNotConfigured =
    'ConversationRepository is not configured.';

typedef McpToolCaller =
    Future<String> Function({
      required String mcpServerId,
      required String toolIdentifier,
      required Map<String, dynamic> arguments,
    });

typedef SkillsManagerToolSuccessHandler =
    void Function({
      required String workspaceId,
      required String toolSlug,
      required Object result,
    });

class ResolvedToolService {
  // Null disables mutation side-effects for tests and non-skills callers.
  // ignore: unnecessary-nullable
  ResolvedToolService({
    required agent.AgentCancellationRuntime agentCancellationRuntime,
    required McpToolCaller mcpToolCaller,
    ConversationRepository? conversationRepository,
    LoadConversationSkillUsecase? loadConversationSkillUsecase,
    UnloadConversationSkillUsecase? unloadConversationSkillUsecase,
    RunSkillTemplateToolUsecase? runSkillTemplateToolUsecase,
    RunSkillsManagerToolUsecase? runSkillsManagerToolUsecase,
    ListAvailableSkillsUsecase? listAvailableSkillsUsecase,
    SkillCredentialsRepository? skillCredentialsRepository,
    SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess,
  }) : _delegate = agent_resolved.ResolvedToolService<ResolvedTool>(
         provider: AppResolvedToolProvider(
           agentCancellationRuntime: agentCancellationRuntime,
           mcpToolCaller: mcpToolCaller,
           conversationRepository: conversationRepository,
           loadConversationSkillUsecase: loadConversationSkillUsecase,
           unloadConversationSkillUsecase: unloadConversationSkillUsecase,
           runSkillTemplateToolUsecase: runSkillTemplateToolUsecase,
           runSkillsManagerToolUsecase: runSkillsManagerToolUsecase,
           listAvailableSkillsUsecase: listAvailableSkillsUsecase,
           skillCredentialsRepository: skillCredentialsRepository,
           onSkillsManagerToolSuccess: onSkillsManagerToolSuccess,
         ),
       );

  final agent_resolved.ResolvedToolService<ResolvedTool> _delegate;

  Future<Object?> call({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) {
    return _delegate.call(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }
}

class AppResolvedToolProvider
    implements agent.ResolvedToolProvider<ResolvedTool> {
  const AppResolvedToolProvider({
    required this.agentCancellationRuntime,
    required this.mcpToolCaller,
    this.conversationRepository,
    this.loadConversationSkillUsecase,
    this.unloadConversationSkillUsecase,
    this.runSkillTemplateToolUsecase,
    this.runSkillsManagerToolUsecase,
    this.listAvailableSkillsUsecase,
    this.skillCredentialsRepository,
    this.onSkillsManagerToolSuccess,
  });

  final agent.AgentCancellationRuntime agentCancellationRuntime;
  final McpToolCaller mcpToolCaller;
  final ConversationRepository? conversationRepository;
  final LoadConversationSkillUsecase? loadConversationSkillUsecase;
  final UnloadConversationSkillUsecase? unloadConversationSkillUsecase;
  final RunSkillTemplateToolUsecase? runSkillTemplateToolUsecase;
  final RunSkillsManagerToolUsecase? runSkillsManagerToolUsecase;
  final ListAvailableSkillsUsecase? listAvailableSkillsUsecase;
  final SkillCredentialsRepository? skillCredentialsRepository;
  final SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess;

  @override
  agent.AgentResolvedToolExecution<ResolvedTool> toExecution(
    ResolvedTool tool,
  ) {
    return _toExecution(tool);
  }

  @override
  Future<Object?> runBuiltInTool({
    required String conversationId,
    required ResolvedTool tool,
    required Object input,
  }) {
    return _runCancelableInputTool(
      conversationId: conversationId,
      input: input,
      toolIdentifier: tool.toolIdentifier,
      operation: _builtInOperation(tool, input),
      agentCancellationRuntime: agentCancellationRuntime,
    );
  }

  @override
  Future<Object?> runNativeTool({
    required String conversationId,
    required ResolvedTool tool,
    required Object input,
  }) {
    return _runCancelableInputTool(
      conversationId: conversationId,
      input: input,
      toolIdentifier: tool.toolIdentifier,
      operation: _nativeOperation(tool, input),
      agentCancellationRuntime: agentCancellationRuntime,
    );
  }

  @override
  Future<Object?> runMcpTool({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) {
    return mcpToolCaller(
      mcpServerId: mcpServerId,
      toolIdentifier: toolIdentifier,
      arguments: arguments,
    );
  }

  @override
  Future<String> getConversationWorkspaceId(String conversationId) {
    return _workspaceIdFor(
      conversationRepository: conversationRepository,
      conversationId: conversationId,
    );
  }

  @override
  Future<Object?> runSkillControlTool({
    required String conversationId,
    required String workspaceId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) {
    return _runSkillControlTool(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolIdentifier: toolIdentifier,
      arguments: arguments,
      loadConversationSkillUsecase: loadConversationSkillUsecase,
      unloadConversationSkillUsecase: unloadConversationSkillUsecase,
      listAvailableSkillsUsecase: listAvailableSkillsUsecase,
      skillCredentialsRepository: skillCredentialsRepository,
    );
  }

  @override
  Future<Object?> runSkillTemplateTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) {
    final usecase = runSkillTemplateToolUsecase;
    if (usecase == null) {
      throw StateError('RunSkillTemplateToolUsecase is not configured.');
    }

    return usecase.call(
      workspaceId: workspaceId,
      skillSlug: skillSlug,
      toolSlug: toolSlug,
      arguments: arguments,
    );
  }

  @override
  Future<Object?> runSkillNativeTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    final usecase = runSkillsManagerToolUsecase;
    if (usecase == null) {
      throw StateError('RunSkillsManagerToolUsecase is not configured.');
    }
    final result = await usecase.call(
      workspaceId: workspaceId,
      toolSlug: toolSlug,
      arguments: arguments,
    );
    onSkillsManagerToolSuccess?.call(
      workspaceId: workspaceId,
      toolSlug: toolSlug,
      result: result,
    );

    return result;
  }
}

agent.AgentResolvedToolExecution<ResolvedTool> _toExecution(
  ResolvedTool tool,
) {
  return agent.AgentResolvedToolExecution(
    descriptor: _toAgentDescriptor(tool),
    tool: tool,
  );
}

agent.AgentResolvedToolName _toAgentDescriptor(ResolvedTool tool) {
  return switch (tool.type) {
    ResolvedToolType.builtIn => agent.AgentResolvedToolName.builtIn(
      tableId: tool.tableId,
      toolIdentifier: tool.toolIdentifier,
    ),
    ResolvedToolType.mcp => agent.AgentResolvedToolName.mcp(
      tableId: tool.tableId,
      toolIdentifier: tool.toolIdentifier,
      mcpServerId: tool.mcpServerId ?? '',
    ),
    ResolvedToolType.native => agent.AgentResolvedToolName.native(
      tableId: tool.tableId,
      toolIdentifier: tool.toolIdentifier,
    ),
    ResolvedToolType.skillControl => agent.AgentResolvedToolName.skillControl(
      toolIdentifier: tool.toolIdentifier,
    ),
    ResolvedToolType.skillNative => agent.AgentResolvedToolName.skillNative(
      tableId: tool.tableId,
      skillSlug: tool.skillSlug ?? '',
      toolIdentifier: tool.skillToolSlug ?? tool.toolIdentifier,
    ),
    ResolvedToolType.skillTemplate => agent.AgentResolvedToolName.skillTemplate(
      tableId: tool.tableId,
      skillSlug: tool.skillSlug ?? '',
      toolIdentifier: tool.toolIdentifier,
    ),
  };
}

CancelableOperation<Object?> _builtInOperation(
  ResolvedTool tool,
  Object input,
) {
  final builtInTool = tool.builtInTool;
  final toolService = builtInTool == null
      ? null
      : ToolService.getTool(builtInTool);
  if (toolService == null) {
    throw StateError(
      'No built-in ToolService registered for ${tool.toolIdentifier}.',
    );
  }

  return toolService.runner(input);
}

CancelableOperation<Object?> _nativeOperation(ResolvedTool tool, Object input) {
  final nativeTool = tool.nativeTool;
  final toolService = nativeTool == null
      ? null
      : NativeToolService.getTool(nativeTool);
  if (toolService == null) {
    throw StateError(
      'No NativeToolService registered for ${tool.toolIdentifier}.',
    );
  }

  return toolService.runner(input);
}

Future<Object?> _runCancelableInputTool({
  required String conversationId,
  required Object input,
  required String toolIdentifier,
  required CancelableOperation<Object?> operation,
  required agent.AgentCancellationRuntime agentCancellationRuntime,
}) {
  final _ = (input: input, toolIdentifier: toolIdentifier);
  agentCancellationRuntime.registerCancelableOperation(
    conversationId,
    operation,
  );

  return operation.valueOrCancellation();
}

Future<String> _workspaceIdFor({
  required ConversationRepository? conversationRepository,
  required String conversationId,
}) async {
  final repository = conversationRepository;
  if (repository == null) {
    throw StateError(_conversationRepositoryNotConfigured);
  }
  final conversation = await repository.getConversationById(conversationId);
  if (conversation == null) {
    throw StateError('Conversation not found: $conversationId');
  }

  return conversation.workspaceId;
}

Future<Object?> _runSkillControlTool({
  required String conversationId,
  required String workspaceId,
  required String toolIdentifier,
  required Map<String, dynamic> arguments,
  required LoadConversationSkillUsecase? loadConversationSkillUsecase,
  required UnloadConversationSkillUsecase? unloadConversationSkillUsecase,
  required ListAvailableSkillsUsecase? listAvailableSkillsUsecase,
  required SkillCredentialsRepository? skillCredentialsRepository,
}) async {
  if (toolIdentifier == listSkillCredentialsToolName) {
    return _listSkillCredentials(
      workspaceId: workspaceId,
      conversationId: conversationId,
      arguments: arguments,
      listAvailableSkillsUsecase: listAvailableSkillsUsecase,
      skillCredentialsRepository: skillCredentialsRepository,
    );
  }

  final slug = arguments['slug'];
  if (slug is! String || slug.isEmpty) {
    throw const FormatException('Skill control tools require a slug.');
  }

  if (toolIdentifier == loadSkillToolName) {
    final usecase = loadConversationSkillUsecase;
    if (usecase == null) {
      throw StateError('LoadConversationSkillUsecase is not configured.');
    }
    await usecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      slug: slug,
    );

    return 'Skill "$slug" loaded.';
  }

  final usecase = unloadConversationSkillUsecase;
  if (usecase == null) {
    throw StateError('UnloadConversationSkillUsecase is not configured.');
  }
  await usecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    slug: slug,
  );

  return 'Skill "$slug" unloaded.';
}

Future<Object> _listSkillCredentials({
  required String workspaceId,
  required String conversationId,
  required Map<String, dynamic> arguments,
  required ListAvailableSkillsUsecase? listAvailableSkillsUsecase,
  required SkillCredentialsRepository? skillCredentialsRepository,
}) async {
  final skillSlug = arguments['skillSlug'];
  if (skillSlug is! String || skillSlug.isEmpty) {
    throw const FormatException(
      'Skill credential listing requires a skillSlug.',
    );
  }
  final listSkills = listAvailableSkillsUsecase;
  final credentialsRepository = skillCredentialsRepository;
  if (listSkills == null || credentialsRepository == null) {
    throw StateError('Skill credential listing is not configured.');
  }
  final loadedSkills = await listSkills.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: SkillLoadFilter.loaded,
  );
  final skill = loadedSkills
      .where((skill) => skill.slug == skillSlug)
      .firstOrNull;
  final credentialDefinitionId = skill?.credentialDefinitionId;
  if (skill == null || credentialDefinitionId == null) {
    throw StateError('Loaded skill with credentials not found: $skillSlug');
  }
  final credentials = await credentialsRepository.getCredentialsForDefinition(
    workspaceId: workspaceId,
    credentialDefinitionId: credentialDefinitionId,
  );

  return {
    'skillSlug': skill.slug,
    'credentials': [
      for (final credential in credentials)
        {
          'id': credential.id,
          'name': credential.name,
        },
    ],
  };
}

final resolvedToolServiceProvider = Provider<ResolvedToolService>((ref) {
  return ResolvedToolService(
    agentCancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    mcpToolCaller: ref.watch(mcpToolCallerProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    loadConversationSkillUsecase: ref.watch(
      loadConversationSkillUsecaseProvider,
    ),
    unloadConversationSkillUsecase: ref.watch(
      unloadConversationSkillUsecaseProvider,
    ),
    runSkillTemplateToolUsecase: ref.watch(
      runSkillTemplateToolUsecaseProvider,
    ),
    runSkillsManagerToolUsecase: ref.watch(
      runSkillsManagerToolUsecaseProvider,
    ),
    listAvailableSkillsUsecase: ref.watch(listAvailableSkillsUsecaseProvider),
    skillCredentialsRepository: ref.watch(skillCredentialsRepositoryProvider),
    onSkillsManagerToolSuccess:
        ({
          required workspaceId,
          required toolSlug,
          required result,
        }) {
          _invalidateSkillsManagerToolState(
            ref,
            workspaceId: workspaceId,
            toolSlug: toolSlug,
            result: result,
          );
        },
  );
});

void _invalidateSkillsManagerToolState(
  Ref ref, {
  required String workspaceId,
  required String toolSlug,
  required Object result,
}) {
  final resultMap = result is Map ? result : const <Object?, Object?>{};
  final skillId = resultMap['skillId'];
  final definitionId = resultMap['definitionId'];

  switch (toolSlug) {
    case createUserSkillToolSlug:
    case updateUserSkillToolSlug:
    case deleteUserSkillToolSlug:
      ref.invalidate(workspaceSkillsProvider(workspaceId));
      if (skillId is String && skillId.isNotEmpty) {
        ref.invalidate(skillDetailProvider(workspaceId, skillId));
      }
    case createSkillCredentialDefinitionToolSlug:
    case updateSkillCredentialDefinitionToolSlug:
    case deleteSkillCredentialDefinitionToolSlug:
      ref
        ..invalidate(skillCredentialDefinitionsProvider(workspaceId))
        ..invalidate(serviceConnectionsProvider(workspaceId));
      if (definitionId is String && definitionId.isNotEmpty) {
        ref
          ..invalidate(skillCredentialDefinitionProvider(definitionId))
          ..invalidate(
            skillCredentialsForDefinitionProvider(workspaceId, definitionId),
          );
      }
    case createSkillTemplateToolSlug:
    case updateSkillTemplateToolSlug:
    case deleteSkillTemplateToolSlug:
      if (skillId is String && skillId.isNotEmpty) {
        ref.invalidate(skillTemplateToolsProvider(skillId));
      }
  }
}

final mcpToolCallerProvider = Provider<McpToolCaller>((ref) {
  return ({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) {
    return ref
        .read(mcpConnectionProvider.notifier)
        .callTool(
          mcpServerId: mcpServerId,
          toolIdentifier: toolIdentifier,
          arguments: arguments,
        );
  };
});
