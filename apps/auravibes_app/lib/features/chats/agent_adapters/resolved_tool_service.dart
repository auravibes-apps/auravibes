// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/app_sub_agent_catalog.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_conversation_data_provider.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_command_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:riverpod/riverpod.dart';

const _conversationRepositoryNotConfigured =
    'ConversationRepository is not configured.';
const Set<String> _userSkillToolSlugs = {
  SkillToolSlugs.createUserSkill,
  SkillToolSlugs.updateUserSkill,
  SkillToolSlugs.deleteUserSkill,
};
const Set<String> _credentialDefinitionToolSlugs = {
  SkillToolSlugs.createSkillCredentialDefinition,
  SkillToolSlugs.updateSkillCredentialDefinition,
  SkillToolSlugs.deleteSkillCredentialDefinition,
};
const Set<String> _templateToolSlugs = {
  SkillToolSlugs.createSkillTemplateTool,
  SkillToolSlugs.updateSkillTemplateTool,
  SkillToolSlugs.deleteSkillTemplateTool,
};

typedef SkillsManagerToolSuccessHandler = void Function({
  required String workspaceId,
  required String toolSlug,
  required Object result,
});

class ResolvedToolService {
  static const ResolvedToolService Function() cloud =
      ResolvedToolService._cloud;

  // Null disables mutation side-effects for tests and non-skills callers.
  // ignore: unnecessary-nullable
  new({
    required AgentCancellationRuntime agentCancellationRuntime,
    required McpToolCaller mcpToolCaller,
    ConversationRepository? conversationRepository,
    LoadConversationSkillUsecase Function(String workspaceId)?
    loadConversationSkillUsecase,
    UnloadConversationSkillUsecase Function(String workspaceId)?
    unloadConversationSkillUsecase,
    RunSkillTemplateToolUsecase? runSkillTemplateToolUsecase,
    RunAppSkillToolUsecase? runAppSkillToolUsecase,
    BuildLoadedSkillManifestsUsecase? buildLoadedSkillManifestsUsecase,
    BuildSkillTemplateToolSpecsUsecase? buildSkillTemplateToolSpecsUsecase,
    BuildAppSkillNativeToolSpecsUsecase? buildAppSkillNativeToolSpecsUsecase,
    RunSkillsManagerToolUsecase Function(String workspaceId)?
    runSkillsManagerToolUsecase,
    ListAvailableSkillsUsecase Function(String workspaceId)?
    listAvailableSkillsUsecase,
    ListAppSkillCredentialCandidatesUsecase?
    listAppSkillCredentialCandidatesUsecase,
    AppSkillRegistry? appSkillRegistry,
    SkillCredentialsRepository? skillCredentialsRepository,
    agent.SubAgentRunner? subAgentRunner,
    SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess,
  }) : _delegate = agent.ResolvedToolRunner<ResolvedTool>(
         provider: AppResolvedToolProvider(
           agentCancellationRuntime: agentCancellationRuntime,
           mcpToolCaller: mcpToolCaller,
           conversationRepository: conversationRepository,
           loadConversationSkillUsecase: loadConversationSkillUsecase,
           unloadConversationSkillUsecase: unloadConversationSkillUsecase,
           runSkillTemplateToolUsecase: runSkillTemplateToolUsecase,
           runAppSkillToolUsecase: runAppSkillToolUsecase,
           buildLoadedSkillManifestsUsecase: buildLoadedSkillManifestsUsecase,
           buildSkillTemplateToolSpecsUsecase:
               buildSkillTemplateToolSpecsUsecase,
           buildAppSkillNativeToolSpecsUsecase:
               buildAppSkillNativeToolSpecsUsecase,
           runSkillsManagerToolUsecase: runSkillsManagerToolUsecase,
           listAvailableSkillsUsecase: listAvailableSkillsUsecase,
           listAppSkillCredentialCandidatesUsecase:
               listAppSkillCredentialCandidatesUsecase,
           appSkillRegistry: appSkillRegistry,
           skillCredentialsRepository: skillCredentialsRepository,
           subAgentRunner: subAgentRunner,
           onSkillsManagerToolSuccess: onSkillsManagerToolSuccess,
         ),
       );
  new _cloud() : _delegate = null;

  final agent.ResolvedToolRunner<ResolvedTool>? _delegate;

  Future<Object?> call({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
  }) {
    final delegate = _delegate;
    if (delegate == null) {
      throw StateError('Cloud tools execute on the server.');
    }

    return delegate.call(
      conversationId: conversationId,
      tool: tool,
      arguments: arguments,
    );
  }
}

class const AppResolvedToolProvider({
  required final AgentCancellationRuntime agentCancellationRuntime,
  required final McpToolCaller mcpToolCaller,
  final ConversationRepository? conversationRepository,
  final LoadConversationSkillUsecase Function(String workspaceId)?
  loadConversationSkillUsecase,
  final UnloadConversationSkillUsecase Function(String workspaceId)?
  unloadConversationSkillUsecase,
  final RunSkillTemplateToolUsecase? runSkillTemplateToolUsecase,
  final RunAppSkillToolUsecase? runAppSkillToolUsecase,
  final BuildLoadedSkillManifestsUsecase? buildLoadedSkillManifestsUsecase,
  final BuildSkillTemplateToolSpecsUsecase? buildSkillTemplateToolSpecsUsecase,
  final BuildAppSkillNativeToolSpecsUsecase?
  buildAppSkillNativeToolSpecsUsecase,
  final RunSkillsManagerToolUsecase Function(String workspaceId)?
  runSkillsManagerToolUsecase,
  final ListAvailableSkillsUsecase Function(String workspaceId)?
  listAvailableSkillsUsecase,
  final ListAppSkillCredentialCandidatesUsecase?
  listAppSkillCredentialCandidatesUsecase,
  final AppSkillRegistry? appSkillRegistry,
  final SkillCredentialsRepository? skillCredentialsRepository,
  final agent.SubAgentRunner? subAgentRunner,
  final SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess,
}) implements agent.ResolvedToolProvider<ResolvedTool> {
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
      .new(
        conversationId: conversationId,
        input: input,
        toolIdentifier: tool.toolIdentifier,
        operation: _builtInOperation(tool, input),
        agentCancellationRuntime: agentCancellationRuntime,
      ),
    );
  }

  @override
  Future<Object?> runNativeTool({
    required String conversationId,
    required ResolvedTool tool,
    required Object input,
  }) {
    return _runCancelableInputTool(
      .new(
        conversationId: conversationId,
        input: input,
        toolIdentifier: tool.toolIdentifier,
        operation: _nativeOperation(tool, input),
        agentCancellationRuntime: agentCancellationRuntime,
      ),
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
  Future<Object?> runSkillControlTool(agent.SkillControlToolRequest input) =>
      _runSkillControlRequest(this, input);

  @override
  Future<Object?> runSkillTemplateTool(agent.SkillTemplateToolRequest input) {
    final usecase = runSkillTemplateToolUsecase;
    if (usecase == null) {
      throw StateError('RunSkillTemplateToolUsecase is not configured.');
    }

    return usecase.call(
      workspaceId: input.workspaceId,
      skillSlug: input.skillSlug,
      toolSlug: input.toolSlug,
      arguments: input.arguments,
    );
  }

  @override
  Future<Object?> runSkillNativeTool(agent.SkillNativeToolRequest input) {
    return _runSkillNativeTool(
      .new(
        conversationId: input.conversationId,
        workspaceId: input.workspaceId,
        skillSlug: input.skillSlug,
        toolSlug: input.toolSlug,
        arguments: input.arguments,
        provider: this,
      ),
    );
  }
}

Future<Object?> _runSkillControlRequest(
  AppResolvedToolProvider provider,
  _SkillControlToolRequest request,
) {
  if (_hasCombinedSkillCommandDependencies(provider)) {
    return _runConfiguredSkillCommand(provider, request);
  }

  return _runSkillControlTool(
    request: request,
    dependencies: _skillControlToolDependencies(provider),
  );
}

agent.AgentResolvedToolExecution<ResolvedTool> _toExecution(ResolvedTool tool) {
  return agent.AgentResolvedToolExecution(
    descriptor: _toAgentDescriptor(tool),
    tool: tool,
  );
}

agent.AgentResolvedToolName _toAgentDescriptor(ResolvedTool tool) {
  return switch (tool.type) {
    .builtIn => _builtInDescriptor(tool),
    .mcp => _mcpDescriptor(tool),
    .native => _nativeDescriptor(tool),
    .skillControl => _skillControlDescriptor(tool),
    .skillCommand => _skillCommandDescriptor(tool),
    .skillNative => _skillNativeDescriptor(tool),
    .skillTemplate => _skillTemplateDescriptor(tool),
  };
}

agent.AgentResolvedToolName _builtInDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.builtIn(
    tableId: tool.tableId,
    toolIdentifier: tool.toolIdentifier,
  );
}

agent.AgentResolvedToolName _mcpDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.mcp(
    tableId: tool.tableId,
    toolIdentifier: tool.toolIdentifier,
    mcpServerId: tool.mcpServerId ?? '',
    mcpSlug: tool.mcpSlug ?? '',
  );
}

agent.AgentResolvedToolName _nativeDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.native(
    tableId: tool.tableId,
    toolIdentifier: tool.toolIdentifier,
  );
}

agent.AgentResolvedToolName _skillControlDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.skillControl(
    toolIdentifier: tool.toolIdentifier,
  );
}

agent.AgentResolvedToolName _skillCommandDescriptor(ResolvedTool tool) {
  return tool.target ?? _skillControlDescriptor(tool);
}

agent.AgentResolvedToolName _skillNativeDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.skillNative(
    tableId: tool.tableId,
    skillSlug: tool.skillSlug ?? '',
    toolIdentifier: tool.skillToolSlug ?? tool.toolIdentifier,
  );
}

agent.AgentResolvedToolName _skillTemplateDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.skillTemplate(
    tableId: tool.tableId,
    skillSlug: tool.skillSlug ?? '',
    toolIdentifier: tool.toolIdentifier,
  );
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

Future<Object?> _runCancelableInputTool(_CancelableInputToolRequest request) {
  request.agentCancellationRuntime.registerCancelableOperation(
    request.conversationId,
    request.operation,
  );

  return request.operation.valueOrCancellation();
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
  required _SkillControlToolRequest request,
  required _SkillControlToolDependencies dependencies,
}) {
  if (request.toolIdentifier == SkillToolNames.listCredentials) {
    return _listSkillCredentials(request: request, dependencies: dependencies);
  }

  final slug = _requiredControlSlug(request.arguments);

  if (request.toolIdentifier == agent.loadSkillToolName) {
    return _runLoadSkill(request, dependencies, slug);
  }

  return _runUnloadSkill(request, dependencies, slug);
}

String _requiredControlSlug(Map<String, dynamic> arguments) {
  final slug = arguments['slug'];
  if (slug is! String || slug.isEmpty) {
    throw const FormatException('Skill control tools require a slug.');
  }

  return slug;
}

Future<String> _runLoadSkill(
  _SkillControlToolRequest request,
  _SkillControlToolDependencies dependencies,
  String slug,
) async {
  final usecase = dependencies.loadConversationSkillUsecase?.call(
    request.workspaceId,
  );
  if (usecase == null) {
    throw StateError('LoadConversationSkillUsecase is not configured.');
  }
  await usecase.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    slug: slug,
  );

  return 'Skill "$slug" loaded.';
}

Future<String> _runUnloadSkill(
  _SkillControlToolRequest request,
  _SkillControlToolDependencies dependencies,
  String slug,
) async {
  final usecase = dependencies.unloadConversationSkillUsecase?.call(
    request.workspaceId,
  );
  if (usecase == null) {
    throw StateError('UnloadConversationSkillUsecase is not configured.');
  }
  await usecase.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    slug: slug,
  );

  return 'Skill "$slug" unloaded.';
}

class const _SkillControlToolDependencies({
  required final LoadConversationSkillUsecase Function(String workspaceId)?
  loadConversationSkillUsecase,
  required final UnloadConversationSkillUsecase Function(String workspaceId)?
  unloadConversationSkillUsecase,
  required final ListAvailableSkillsUsecase Function(String workspaceId)?
  listAvailableSkillsUsecase,
  required final ListAppSkillCredentialCandidatesUsecase?
  listAppSkillCredentialCandidatesUsecase,
  required final AppSkillRegistry? appSkillRegistry,
  required final SkillCredentialsRepository? skillCredentialsRepository,
});

typedef _SkillControlToolRequest = agent.SkillControlToolRequest;

class const _CancelableInputToolRequest({
  required final String conversationId,
  required final Object input,
  required final String toolIdentifier,
  required final CancelableOperation<Object?> operation,
  required final AgentCancellationRuntime agentCancellationRuntime,
});

class const _SkillNativeToolRequest({
  required final String conversationId,
  required final String workspaceId,
  required final String skillSlug,
  required final String toolSlug,
  required final Map<String, dynamic> arguments,
  required final AppResolvedToolProvider provider,
});

class const _SkillCredentialRequest({
  required final _SkillControlToolRequest request,
  required final _SkillControlToolDependencies dependencies,
  required final String skillSlug,
});

class const _UserSkillCredentialRequest({
  required final _SkillCredentialRequest credentialRequest,
  required final AvailableSkill skill,
  required final String credentialDefinitionId,
  required final SkillCredentialsRepository credentialsRepository,
});

Future<Object?> _runSubAgentTool({required _SkillNativeToolRequest request}) {
  final runner = request.provider.subAgentRunner;
  if (runner == null) {
    throw StateError('SubAgentRunner is not configured.');
  }

  return _runSubAgentToolWithRunner(request, runner);
}

Future<Object?> _runSubAgentToolWithRunner(
  _SkillNativeToolRequest request,
  agent.SubAgentRunner runner,
) {
  return switch (request.toolSlug) {
    agent.listAgentsToolName => runner.listAgents(
      request.workspaceId,
      arguments: request.arguments,
    ),
    agent.runSubAgentToolName => runner.run(
      parentConversationId: request.conversationId,
      workspaceId: request.workspaceId,
      arguments: request.arguments,
    ),
    _ => throw StateError('Unknown sub-agent tool: ${request.toolSlug}'),
  };
}

Future<Object> _listSkillCredentials({
  required _SkillControlToolRequest request,
  required _SkillControlToolDependencies dependencies,
}) async {
  final credentialRequest = _SkillCredentialRequest(
    request: request,
    dependencies: dependencies,
    skillSlug: _requiredSkillSlug(request.arguments),
  );
  final skill = await _loadedSkillForCredential(credentialRequest);

  return await _credentialsForLoadedSkill(credentialRequest, skill);
}

Future<Object> _credentialsForLoadedSkill(
  _SkillCredentialRequest credentialRequest,
  AvailableSkill? skill,
) {
  final loadedSkill = _requiredLoadedSkill(credentialRequest, skill);
  if (loadedSkill.source == SkillSource.app) {
    return _listAppSkillCredentials(credentialRequest);
  }

  return _listUserSkillCredentials(credentialRequest, loadedSkill);
}

AvailableSkill _requiredLoadedSkill(
  _SkillCredentialRequest credentialRequest,
  AvailableSkill? skill,
) {
  if (skill != null) return skill;

  throw StateError(
    'Loaded skill with credentials not found: ${credentialRequest.skillSlug}',
  );
}

Future<Object> _listUserSkillCredentials(
  _SkillCredentialRequest credentialRequest,
  AvailableSkill skill,
) {
  return _loadUserSkillCredentials(
    .new(
      credentialRequest: credentialRequest,
      skill: skill,
      credentialDefinitionId: _requiredCredentialDefinitionId(
        skill,
        credentialRequest.skillSlug,
      ),
      credentialsRepository: _requiredCredentialsRepository(
        credentialRequest.dependencies,
      ),
    ),
  );
}

String _requiredCredentialDefinitionId(AvailableSkill skill, String skillSlug) {
  final credentialDefinitionId = skill.credentialDefinitionId;
  if (credentialDefinitionId == null) {
    throw StateError('Loaded skill with credentials not found: $skillSlug');
  }

  return credentialDefinitionId;
}

SkillCredentialsRepository _requiredCredentialsRepository(
  _SkillControlToolDependencies dependencies,
) {
  final repository = dependencies.skillCredentialsRepository;
  if (repository == null) {
    throw StateError('Skill credential listing is not configured.');
  }

  return repository;
}

Future<Object> _loadUserSkillCredentials(
  _UserSkillCredentialRequest credentialRequest,
) async {
  final credentials = await _loadCredentialsForDefinition(credentialRequest);

  return _credentialResult(
    credentialRequest.skill.slug,
    credentials.map((credential) => (id: credential.id, name: credential.name)),
  );
}

Future<List<SkillCredentialEntity>> _loadCredentialsForDefinition(
  _UserSkillCredentialRequest credentialRequest,
) {
  return credentialRequest.credentialsRepository.getCredentialsForDefinition(
    workspaceId: credentialRequest.credentialRequest.request.workspaceId,
    credentialDefinitionId: credentialRequest.credentialDefinitionId,
  );
}

Future<AvailableSkill?> _loadedSkillForCredential(
  _SkillCredentialRequest credentialRequest,
) async {
  final loadedSkills = await _loadCredentialSkills(credentialRequest);

  return _findLoadedSkill(loadedSkills, credentialRequest.skillSlug);
}

Future<List<AvailableSkill>> _loadCredentialSkills(
  _SkillCredentialRequest credentialRequest,
) {
  final listSkills = _requiredCredentialSkillLister(credentialRequest);

  return listSkills.call(
    conversationId: credentialRequest.request.conversationId,
    workspaceId: credentialRequest.request.workspaceId,
    filter: .loaded,
  );
}

AvailableSkill? _findLoadedSkill(
  Iterable<AvailableSkill> loadedSkills,
  String skillSlug,
) {
  return loadedSkills.where((skill) => skill.slug == skillSlug).firstOrNull;
}

ListAvailableSkillsUsecase _requiredCredentialSkillLister(
  _SkillCredentialRequest credentialRequest,
) {
  final dependencies = credentialRequest.dependencies;
  final listSkills = dependencies.listAvailableSkillsUsecase?.call(
    credentialRequest.request.workspaceId,
  );
  if (listSkills == null || dependencies.skillCredentialsRepository == null) {
    throw StateError('Skill credential listing is not configured.');
  }

  return listSkills;
}

String _requiredSkillSlug(Map<String, dynamic> arguments) {
  final skillSlug = arguments['skillSlug'];
  if (skillSlug is! String || skillSlug.isEmpty) {
    throw const FormatException(
      'Skill credential listing requires a skillSlug.',
    );
  }

  return skillSlug;
}

Future<Object> _listAppSkillCredentials(
  _SkillCredentialRequest credentialRequest,
) async {
  final skillSlug = credentialRequest.skillSlug;
  final appSkill = _requiredAppSkill(credentialRequest);
  final credentials = await _loadAppCredentials(credentialRequest, appSkill);

  return _credentialResult(
    skillSlug,
    credentials.map((credential) => (id: credential.id, name: credential.name)),
  );
}

agent.AppSkillDefinition _requiredAppSkill(
  _SkillCredentialRequest credentialRequest,
) {
  final dependencies = credentialRequest.dependencies;
  final registry = dependencies.appSkillRegistry;
  if (registry == null) {
    throw StateError('App skill credential listing is not configured.');
  }

  return _requiredRegisteredAppSkill(registry, credentialRequest.skillSlug);
}

agent.AppSkillDefinition _requiredRegisteredAppSkill(
  AppSkillRegistry registry,
  String skillSlug,
) {
  final appSkill = registry.getBySlug(skillSlug);
  if (appSkill == null) {
    throw StateError('Loaded skill with credentials not found: $skillSlug');
  }

  return appSkill;
}

Future<List<AppSkillCredentialCandidate>> _loadAppCredentials(
  _SkillCredentialRequest credentialRequest,
  agent.AppSkillDefinition appSkill,
) {
  final appCandidates =
      credentialRequest.dependencies.listAppSkillCredentialCandidatesUsecase;
  if (appCandidates == null) {
    throw StateError('App skill credential listing is not configured.');
  }

  return appCandidates.call(
    workspaceId: credentialRequest.request.workspaceId,
    skill: appSkill,
  );
}

Map<String, Object> _credentialResult(
  String skillSlug,
  Iterable<({String id, String name})> credentials,
) {
  return {
    'skillSlug': skillSlug,
    'credentials': [
      for (final credential in credentials)
        {'id': credential.id, 'name': credential.name},
    ],
  };
}

Future<Object?> _runSkillNativeTool(_SkillNativeToolRequest request) {
  if (request.skillSlug == agent.agentsSkillSlug) {
    return _runSubAgentNativeTool(request);
  }
  if (request.skillSlug != SkillToolSlugs.skillsManager) {
    return _runAppNativeTool(request);
  }

  return _runSkillsManagerNativeTool(request);
}

Future<Object?> _runSubAgentNativeTool(_SkillNativeToolRequest request) {
  final operation = CancelableOperation<Object?>.fromFuture(
    _runSubAgentTool(request: request),
  );
  request.provider.agentCancellationRuntime.registerCancelableOperation(
    request.conversationId,
    operation,
  );

  return operation.valueOrCancellation();
}

Future<Object?> _runAppNativeTool(_SkillNativeToolRequest request) {
  final usecase = request.provider.runAppSkillToolUsecase;
  if (usecase == null) {
    throw StateError('RunAppSkillToolUsecase is not configured.');
  }

  final operation = usecase.callCancelable(
    workspaceId: request.workspaceId,
    skillSlug: request.skillSlug,
    toolSlug: request.toolSlug,
    arguments: request.arguments,
  );

  return _registerNativeOperation(request, operation);
}

Future<Object?> _registerNativeOperation(
  _SkillNativeToolRequest request,
  CancelableOperation<Object?> operation,
) {
  request.provider.agentCancellationRuntime.registerCancelableOperation(
    request.conversationId,
    operation,
  );

  return operation.valueOrCancellation();
}

Future<Object?> _runSkillsManagerNativeTool(
  _SkillNativeToolRequest request,
) async {
  final usecase = _skillsManagerUsecase(request);
  final result = await usecase.call(
    workspaceId: request.workspaceId,
    toolSlug: request.toolSlug,
    arguments: request.arguments,
  );
  _notifySkillsManagerSuccess(request, result);

  return result;
}

RunSkillsManagerToolUsecase _skillsManagerUsecase(
  _SkillNativeToolRequest request,
) {
  final usecase = request.provider.runSkillsManagerToolUsecase?.call(
    request.workspaceId,
  );
  if (usecase == null) {
    throw StateError('RunSkillsManagerToolUsecase is not configured.');
  }

  return usecase;
}

void _notifySkillsManagerSuccess(
  _SkillNativeToolRequest request,
  Object result,
) {
  request.provider.onSkillsManagerToolSuccess?.call(
    workspaceId: request.workspaceId,
    toolSlug: request.toolSlug,
    result: result,
  );
}

bool _hasCombinedSkillCommandDependencies(AppResolvedToolProvider provider) {
  return provider.buildLoadedSkillManifestsUsecase != null &&
      provider.buildSkillTemplateToolSpecsUsecase != null &&
      provider.buildAppSkillNativeToolSpecsUsecase != null &&
      provider.runSkillTemplateToolUsecase != null &&
      provider.runAppSkillToolUsecase != null &&
      provider.listAvailableSkillsUsecase != null &&
      provider.loadConversationSkillUsecase != null &&
      provider.unloadConversationSkillUsecase != null;
}

Future<Object?> _runConfiguredSkillCommand(
  AppResolvedToolProvider provider,
  _SkillControlToolRequest request,
) {
  return _ConfiguredSkillCommandRunner(provider).run(request);
}

class _ConfiguredSkillCommandRunner {
  new(this._provider) {
    _usecase = _buildConfiguredSkillCommand(
      _configuredSkillCommandDependencies(_provider),
      _listSkillCredentialsForCommand,
    );
  }

  final AppResolvedToolProvider _provider;
  RunSkillCommandUsecase? _usecase;

  Future<Object?> run(_SkillControlToolRequest request) {
    final usecase = _usecase;
    if (usecase == null) {
      throw StateError('Combined skill command is not configured.');
    }

    return usecase.call((
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      commandName: request.toolIdentifier,
      arguments: request.arguments,
    ));
  }

  Future<Map<String, Object?>> _listSkillCredentialsForCommand({
    required String conversationId,
    required String workspaceId,
    required Map<String, dynamic> arguments,
  }) async {
    final result = await _listSkillCredentials(
      request: _skillCredentialsCommandRequest(
        conversationId,
        workspaceId,
        arguments,
      ),
      dependencies: _skillControlToolDependencies(_provider),
    );

    return _credentialMap(result);
  }
}

_SkillControlToolRequest _skillCredentialsCommandRequest(
  String conversationId,
  String workspaceId,
  Map<String, dynamic> arguments,
) {
  return (
    conversationId: conversationId,
    workspaceId: workspaceId,
    toolIdentifier: SkillToolNames.listCredentials,
    arguments: arguments,
  );
}

Map<String, Object?> _credentialMap(Object result) {
  return Map<String, Object?>.from(result as Map);
}

class const _ConfiguredSkillCommandDependencies(
  final ListAvailableSkillsUsecase Function(String workspaceId)
  listAvailableSkillsUsecase,
  final LoadConversationSkillUsecase Function(String workspaceId)
  loadConversationSkillUsecase,
  final UnloadConversationSkillUsecase Function(String workspaceId)
  unloadConversationSkillUsecase,
  final BuildLoadedSkillManifestsUsecase buildLoadedSkillManifestsUsecase,
  final BuildSkillTemplateToolSpecsUsecase buildSkillTemplateToolSpecsUsecase,
  final BuildAppSkillNativeToolSpecsUsecase buildAppSkillNativeToolSpecsUsecase,
  final RunSkillTemplateToolUsecase runSkillTemplateToolUsecase,
  final RunAppSkillToolUsecase runAppSkillToolUsecase,
);

_ConfiguredSkillCommandDependencies _configuredSkillCommandDependencies(
  AppResolvedToolProvider provider,
) {
  const r = _requiredConfigured;

  return _ConfiguredSkillCommandDependencies(
    r(provider.listAvailableSkillsUsecase),
    r(provider.loadConversationSkillUsecase),
    r(provider.unloadConversationSkillUsecase),
    r(provider.buildLoadedSkillManifestsUsecase),
    r(provider.buildSkillTemplateToolSpecsUsecase),
    r(provider.buildAppSkillNativeToolSpecsUsecase),
    r(provider.runSkillTemplateToolUsecase),
    r(provider.runAppSkillToolUsecase),
  );
}

RunSkillCommandUsecase _buildConfiguredSkillCommand(
  _ConfiguredSkillCommandDependencies deps,
  ListSkillCredentials listSkillCredentials,
) {
  return RunSkillCommandUsecase(
    listAvailableSkillsUsecase: deps.listAvailableSkillsUsecase,
    loadConversationSkillUsecase: deps.loadConversationSkillUsecase,
    unloadConversationSkillUsecase: deps.unloadConversationSkillUsecase,
    buildLoadedSkillManifestsUsecase: deps.buildLoadedSkillManifestsUsecase,
    buildSkillTemplateToolSpecsUsecase: deps.buildSkillTemplateToolSpecsUsecase,
    buildAppSkillNativeToolSpecsUsecase:
        deps.buildAppSkillNativeToolSpecsUsecase,
    runSkillTemplateToolUsecase: deps.runSkillTemplateToolUsecase,
    runAppSkillToolUsecase: deps.runAppSkillToolUsecase,
    listSkillCredentials: listSkillCredentials,
  );
}

_SkillControlToolDependencies _skillControlToolDependencies(
  AppResolvedToolProvider provider,
) {
  return _SkillControlToolDependencies(
    loadConversationSkillUsecase: provider.loadConversationSkillUsecase,
    unloadConversationSkillUsecase: provider.unloadConversationSkillUsecase,
    listAvailableSkillsUsecase: provider.listAvailableSkillsUsecase,
    listAppSkillCredentialCandidatesUsecase:
        provider.listAppSkillCredentialCandidatesUsecase,
    appSkillRegistry: provider.appSkillRegistry,
    skillCredentialsRepository: provider.skillCredentialsRepository,
  );
}

T _requiredConfigured<T>(T? value) {
  if (value == null) {
    throw StateError('Combined skill command dependencies are incomplete.');
  }

  return value;
}

final Provider<ResolvedToolService>
resolvedToolServiceProvider = Provider<ResolvedToolService>((ref) {
  final agentCancellationRuntime = ref.watch(agentCancellationRuntimeProvider);
  final activeSubAgents = ref.watch(activeSubAgentRuntimeProvider.notifier);

  return ResolvedToolService(
    agentCancellationRuntime: agentCancellationRuntime,
    mcpToolCaller: ref.watch(mcpToolCallerProvider),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    loadConversationSkillUsecase: (workspaceId) =>
        ref.read(loadConversationSkillUsecaseProvider(workspaceId)),
    unloadConversationSkillUsecase: (workspaceId) =>
        ref.read(unloadConversationSkillUsecaseProvider(workspaceId)),
    runSkillTemplateToolUsecase: ref.watch(runSkillTemplateToolUsecaseProvider),
    runAppSkillToolUsecase: ref.watch(runAppSkillToolUsecaseProvider),
    buildLoadedSkillManifestsUsecase: ref.watch(
      buildLoadedSkillManifestsUsecaseProvider,
    ),
    buildSkillTemplateToolSpecsUsecase: ref.watch(
      buildSkillTemplateToolSpecsUsecaseProvider,
    ),
    buildAppSkillNativeToolSpecsUsecase: ref.watch(
      buildAppSkillNativeToolSpecsUsecaseProvider,
    ),
    runSkillsManagerToolUsecase: (workspaceId) =>
        ref.read(runSkillsManagerToolUsecaseProvider(workspaceId)),
    listAvailableSkillsUsecase: (workspaceId) =>
        ref.read(listAvailableSkillsUsecaseProvider(workspaceId)),
    listAppSkillCredentialCandidatesUsecase: ref.watch(
      listAppSkillCredentialCandidatesUsecaseProvider,
    ),
    appSkillRegistry: ref.watch(appSkillRegistryProvider),
    skillCredentialsRepository: ref.watch(skillCredentialsRepositoryProvider),
    subAgentRunner: .new(
      agentCatalog: AppSubAgentCatalog(ref.watch(agentsRepositoryProvider)),
      conversationStore: AppSubAgentConversationStore(
        ref.watch(conversationRepositoryProvider),
      ),
      messageStore: AppSubAgentMessageStore(
        ref.watch(messageRepositoryProvider),
      ),
      startRequest: activeSubAgents.start,
      continueAgentTurn: ({required conversationId, required context}) {
        return ref
            .read(appAgentLoopProvider)
            .call(conversationId: conversationId, context: context);
      },
      onChildStarted: ({required parentId, required childId}) {
        agentCancellationRuntime.registerCleanup(parentId, () {
          if (activeSubAgents.parentOf(childId) != parentId) return;
          agentCancellationRuntime.requestStopOnStart(childId);
          activeSubAgents.finish(
            parentId: parentId,
            childId: childId,
            status: agent.SubAgentCompletionStatus.stopped,
          );
        });
      },
    ),
    onSkillsManagerToolSuccess:
        ({required workspaceId, required toolSlug, required result}) {
          _invalidateSkillsManagerToolState(
            .new(
              ref: ref,
              workspaceId: workspaceId,
              toolSlug: toolSlug,
              result: result,
            ),
          );
        },
  );
});

void _invalidateSkillsManagerToolState(
  _SkillManagerInvalidationRequest request,
) {
  if (_userSkillToolSlugs.contains(request.toolSlug)) {
    _invalidateUserSkill(request);

    return;
  }
  if (_credentialDefinitionToolSlugs.contains(request.toolSlug)) {
    _invalidateCredentialDefinition(request);

    return;
  }
  if (_templateToolSlugs.contains(request.toolSlug)) {
    _invalidateTemplateTool(request);
  }
}

class const _SkillManagerInvalidationRequest({
  required final Ref ref,
  required final String workspaceId,
  required final String toolSlug,
  required final Object result,
});

void _invalidateUserSkill(_SkillManagerInvalidationRequest request) {
  request.ref.invalidate(workspaceSkillsProvider(request.workspaceId));
  final skillId = _resultValue(request.result, 'skillId');
  if (skillId is String && skillId.isNotEmpty) {
    request.ref.invalidate(skillDetailProvider(request.workspaceId, skillId));
  }
}

void _invalidateCredentialDefinition(_SkillManagerInvalidationRequest request) {
  request.ref
    ..invalidate(skillCredentialDefinitionsProvider(request.workspaceId))
    ..invalidate(serviceConnectionsProvider(request.workspaceId));
  final definitionId = _resultValue(request.result, 'definitionId');
  if (definitionId is String && definitionId.isNotEmpty) {
    _invalidateCredentialDefinitionDetails(request, definitionId);
  }
}

void _invalidateCredentialDefinitionDetails(
  _SkillManagerInvalidationRequest request,
  String definitionId,
) {
  request.ref
    ..invalidate(
      skillCredentialDefinitionProvider(request.workspaceId, definitionId),
    )
    ..invalidate(
      skillCredentialsForDefinitionProvider(request.workspaceId, definitionId),
    );
}

void _invalidateTemplateTool(_SkillManagerInvalidationRequest request) {
  final skillId = _resultValue(request.result, 'skillId');
  if (skillId is String && skillId.isNotEmpty) {
    request.ref.invalidate(
      skillTemplateToolsProvider(request.workspaceId, skillId),
    );
  }
}

Object? _resultValue(Object result, String key) {
  final resultMap = result is Map ? result : const <Object?, Object?>{};

  return resultMap[key];
}
