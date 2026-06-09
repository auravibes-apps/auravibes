// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
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
import 'package:collection/collection.dart';
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

class RunResolvedToolUsecase {
  // Null disables mutation side-effects for tests and non-skills callers.
  // ignore: unnecessary-nullable
  const RunResolvedToolUsecase({
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

  final AgentCancellationRuntime agentCancellationRuntime;
  final McpToolCaller mcpToolCaller;
  final ConversationRepository? conversationRepository;
  final LoadConversationSkillUsecase? loadConversationSkillUsecase;
  final UnloadConversationSkillUsecase? unloadConversationSkillUsecase;
  final RunSkillTemplateToolUsecase? runSkillTemplateToolUsecase;
  final RunSkillsManagerToolUsecase? runSkillsManagerToolUsecase;
  final ListAvailableSkillsUsecase? listAvailableSkillsUsecase;
  final SkillCredentialsRepository? skillCredentialsRepository;
  final SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess;

  Future<Object?> call({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) async {
    if (tool.isBuiltIn) {
      return _runBuiltInTool(conversationId, tool, arguments);
    }

    if (tool.isNative) {
      return _runNativeTool(conversationId, tool, arguments);
    }

    if (tool.isMcp) {
      return _runMcpTool(tool, arguments);
    }

    if (tool.isSkillControl) {
      return _runSkillControlTool(conversationId, tool, arguments);
    }

    if (tool.isSkillTemplate) {
      return _runSkillTemplateTool(conversationId, tool, arguments);
    }

    if (tool.isSkillNative) {
      return _runSkillNativeTool(conversationId, tool, arguments);
    }

    throw UnsupportedError(
      'Unsupported tool kind for ${tool.toolIdentifier}.',
    );
  }

  Future<Object?> _runBuiltInTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) {
    final input = arguments['input'];
    if (input == null) {
      throw const FormatException('Built-in tools require an input argument.');
    }

    final builtInTool = tool.builtInTool;
    final toolService = builtInTool == null
        ? null
        : ToolService.getTool(builtInTool);
    if (toolService == null) {
      throw StateError(
        'No built-in ToolService registered for ${tool.toolIdentifier}.',
      );
    }

    final operation = toolService.runner(input as Object);
    agentCancellationRuntime.registerCancelableOperation(
      conversationId,
      operation,
    );

    return operation.valueOrCancellation();
  }

  Future<Object?> _runNativeTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) {
    final input = arguments['input'];
    if (input == null) {
      throw const FormatException('Native tools require an input argument.');
    }

    final nativeTool = tool.nativeTool;
    final toolService = nativeTool == null
        ? null
        : NativeToolService.getTool(nativeTool);
    if (toolService == null) {
      throw StateError(
        'No NativeToolService registered for ${tool.toolIdentifier}.',
      );
    }

    final operation = toolService.runner(input as Object);
    agentCancellationRuntime.registerCancelableOperation(
      conversationId,
      operation,
    );

    return operation.valueOrCancellation();
  }

  Future<Object?> _runMcpTool(
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) {
    final mcpServerId = tool.mcpServerId;
    if (mcpServerId == null || mcpServerId.isEmpty) {
      throw StateError(
        'MCP tool ${tool.toolIdentifier} is missing its server binding.',
      );
    }

    return mcpToolCaller(
      mcpServerId: mcpServerId,
      toolIdentifier: tool.toolIdentifier,
      arguments: arguments,
    );
  }

  Future<Object?> _runSkillControlTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    if (tool.toolIdentifier == listSkillCredentialsToolName) {
      return _listSkillCredentials(conversationId, arguments);
    }

    final slug = arguments['slug'];
    if (slug is! String || slug.isEmpty) {
      throw const FormatException('Skill control tools require a slug.');
    }

    final repository = conversationRepository;
    if (repository == null) {
      throw StateError(_conversationRepositoryNotConfigured);
    }
    final conversation = await repository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw StateError('Conversation not found: $conversationId');
    }

    if (tool.toolIdentifier == loadSkillToolName) {
      final usecase = loadConversationSkillUsecase;
      if (usecase == null) {
        throw StateError('LoadConversationSkillUsecase is not configured.');
      }
      await usecase.call(
        conversationId: conversationId,
        workspaceId: conversation.workspaceId,
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
      workspaceId: conversation.workspaceId,
      slug: slug,
    );

    return 'Skill "$slug" unloaded.';
  }

  Future<Object> _listSkillCredentials(
    String conversationId,
    Map<String, dynamic> arguments,
  ) async {
    final skillSlug = arguments['skillSlug'];
    if (skillSlug is! String || skillSlug.isEmpty) {
      throw const FormatException(
        'Skill credential listing requires a skillSlug.',
      );
    }
    final repository = conversationRepository;
    if (repository == null) {
      throw StateError(_conversationRepositoryNotConfigured);
    }
    final conversation = await repository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw StateError('Conversation not found: $conversationId');
    }
    final listSkills = listAvailableSkillsUsecase;
    final credentialsRepository = skillCredentialsRepository;
    if (listSkills == null || credentialsRepository == null) {
      throw StateError('Skill credential listing is not configured.');
    }
    final loadedSkills = await listSkills.call(
      conversationId: conversationId,
      workspaceId: conversation.workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final matchingSkills = loadedSkills.where(
      (skill) => skill.slug == skillSlug,
    );
    final skill = matchingSkills.firstOrNull;
    final credentialDefinitionId = skill?.credentialDefinitionId;
    if (skill == null || credentialDefinitionId == null) {
      throw StateError('Loaded skill with credentials not found: $skillSlug');
    }
    final credentials = await credentialsRepository.getCredentialsForDefinition(
      workspaceId: conversation.workspaceId,
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

  Future<Object?> _runSkillTemplateTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    final skillSlug = tool.skillSlug;
    if (skillSlug == null || skillSlug.isEmpty) {
      throw StateError('Skill template tool is missing skill slug.');
    }
    final repository = conversationRepository;
    if (repository == null) {
      throw StateError(_conversationRepositoryNotConfigured);
    }
    final conversation = await repository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw StateError('Conversation not found: $conversationId');
    }
    final usecase = runSkillTemplateToolUsecase;
    if (usecase == null) {
      throw StateError('RunSkillTemplateToolUsecase is not configured.');
    }

    return usecase.call(
      workspaceId: conversation.workspaceId,
      skillSlug: skillSlug,
      toolSlug: tool.toolIdentifier,
      arguments: arguments,
    );
  }

  Future<Object?> _runSkillNativeTool(
    String conversationId,
    ResolvedTool tool,
    Map<String, dynamic> arguments,
  ) async {
    final skillSlug = tool.skillSlug;
    final toolSlug = tool.skillToolSlug;
    if (skillSlug == null || skillSlug.isEmpty) {
      throw StateError('Skill native tool is missing skill slug.');
    }
    if (toolSlug == null || toolSlug.isEmpty) {
      throw StateError('Skill native tool is missing tool slug.');
    }
    final repository = conversationRepository;
    if (repository == null) {
      throw StateError(_conversationRepositoryNotConfigured);
    }
    final conversation = await repository.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw StateError('Conversation not found: $conversationId');
    }
    final usecase = runSkillsManagerToolUsecase;
    if (usecase == null) {
      throw StateError('RunSkillsManagerToolUsecase is not configured.');
    }
    final result = await usecase.call(
      workspaceId: conversation.workspaceId,
      toolSlug: toolSlug,
      arguments: arguments,
    );
    onSkillsManagerToolSuccess?.call(
      workspaceId: conversation.workspaceId,
      toolSlug: toolSlug,
      result: result,
    );

    return result;
  }
}

final runResolvedToolUsecaseProvider = Provider<RunResolvedToolUsecase>((ref) {
  return RunResolvedToolUsecase(
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
