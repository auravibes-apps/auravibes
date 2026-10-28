// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/features/agents/agent_adapters/app_sub_agent_catalog.dart';
import 'package:auravibes_app/features/agents/agent_guidance.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/chats/agent_adapters/app_agent_conversation_data_provider.dart';
import 'package:auravibes_app/features/chats/notifiers/mcp_elicitation_notifier.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_agent_language_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/resolved_skill_resource.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_command_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skills_manager_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
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
  SkillToolSlugs.createSkillResource,
  SkillToolSlugs.updateSkillResource,
  SkillToolSlugs.deleteSkillResource,
  SkillToolSlugs.cloneAppSkill,
};

typedef SkillsManagerToolSuccessHandler = void Function({
  required String conversationId,
  required String workspaceId,
  required String toolSlug,
  required Object result,
});

typedef BrowserSkillToolRunner = Future<Object?> Function({
  required String workspaceId,
  required String conversationId,
  required String toolSlug,
  required Map<String, dynamic> arguments,
});

typedef _SkillCommandDependencies = ({
  ListAvailableSkillsUsecase Function(String workspaceId) listSkills,
  LoadConversationSkillUsecase Function(String workspaceId) loadSkill,
  BuildLoadedSkillManifestsUsecase buildManifests,
});

typedef _SkillCommandResources = ({
  ListSkillResourceSummaries? list,
  LoadSkillResourceContent? load,
});

class ResolvedToolService {
  static const ResolvedToolService Function() cloud =
      ResolvedToolService._cloud;

  // Null disables mutation side-effects for tests and non-skills callers.
  // ignore: unnecessary-nullable
  new({
    required AgentCancellationRuntime agentCancellationRuntime,
    required McpToolCaller mcpToolCaller,
    McpElicitationRequester? mcpElicitationRequester,
    ConversationRepository? conversationRepository,
    LoadConversationSkillUsecase Function(String workspaceId)?
    loadConversationSkillUsecase,
    BuildLoadedSkillManifestsUsecase? buildLoadedSkillManifestsUsecase,
    BuildAppSkillNativeToolSpecsUsecase? buildAppSkillNativeToolSpecsUsecase,
    RunSkillsManagerToolUsecase Function(String workspaceId)?
    runSkillsManagerToolUsecase,
    ListAvailableSkillsUsecase Function(String workspaceId)?
    listAvailableSkillsUsecase,
    SkillResourceResolver Function(String workspaceId)? skillResourceResolver,
    agent.SubAgentRunner? subAgentRunner,
    SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess,
    BrowserSkillToolRunner? browserSkillToolRunner,
    ConnectorCommandUsecase? connectorCommandUsecase,
    ConversationAgentLanguageRuntime? conversationLanguageRuntime,
    this.workspaceConversationTools,
  }) : _delegate = agent.ResolvedToolRunner<ResolvedTool>(
         provider: AppResolvedToolProvider(
           agentCancellationRuntime: agentCancellationRuntime,
           mcpToolCaller: mcpToolCaller,
           mcpElicitationRequester: mcpElicitationRequester,
           conversationRepository: conversationRepository,
           loadConversationSkillUsecase: loadConversationSkillUsecase,
           buildLoadedSkillManifestsUsecase: buildLoadedSkillManifestsUsecase,
           buildAppSkillNativeToolSpecsUsecase:
               buildAppSkillNativeToolSpecsUsecase,
           runSkillsManagerToolUsecase: runSkillsManagerToolUsecase,
           listAvailableSkillsUsecase: listAvailableSkillsUsecase,
           skillResourceResolver: skillResourceResolver,
           subAgentRunner: subAgentRunner,
           onSkillsManagerToolSuccess: onSkillsManagerToolSuccess,
           browserSkillToolRunner: browserSkillToolRunner,
           connectorCommandUsecase: connectorCommandUsecase,
           conversationLanguageRuntime: conversationLanguageRuntime,
         ),
       );
  new _cloud() : _delegate = null, workspaceConversationTools = null;

  final WorkspaceConversationToolsUsecase? workspaceConversationTools;
  final agent.ResolvedToolRunner<ResolvedTool>? _delegate;
  final Map<({String conversationId, String toolCallId}), Map<String, Object?>>
  _mcpAppResultData = {};

  Map<String, Object?>? takeMcpAppResultData({
    required String conversationId,
    required String toolCallId,
  }) => _mcpAppResultData.remove((
    conversationId: conversationId,
    toolCallId: toolCallId,
  ));

  bool supportsCancellation(ResolvedTool tool) =>
      _delegate?.supportsCancellation(tool) ?? false;

  Future<Object?> call({
    required String conversationId,
    required ResolvedTool tool,
    required Map<String, dynamic> arguments,
    String toolCallId = '',
  }) async {
    final delegate = _delegate;
    if (delegate == null) {
      throw StateError('Cloud tools execute on the server.');
    }

    if (tool.isWorkspaceCommand) {
      return await _workspaceCommand(
        conversationId,
        tool.toolIdentifier,
        arguments,
        toolCallId,
      );
    }
    final result = await delegate.call(
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
      arguments: arguments,
    );

    return _modelToolResult(
      result,
      conversationId,
      toolCallId,
      _mcpAppResultData,
    );
  }

  Future<Object?> _workspaceCommand(
    String conversationId,
    String toolName,
    Map<String, dynamic> arguments,
    String toolCallId,
  ) async {
    final commands = workspaceConversationTools;
    if (commands == null) {
      throw StateError('Workspace commands are not configured.');
    }

    try {
      return await commands.call(
        conversationId: conversationId,
        arguments: agent.workspaceToolArgumentsForExecution(
          toolName,
          arguments,
        ),
        operationId: toolCallId,
      );
    } on WorkspaceTableException catch (error, stackTrace) {
      var code = 'invalid';
      if (error.conflict) code = 'conflict';
      if (error.denied) code = 'unavailable';
      if (error.incompatibleRelationship) code = 'incompatible_relationship';
      if (error.unsupportedCopy) code = 'unsupported';
      final response = agent.workspaceFailureContext(
        jsonEncode({'code': code}),
      );
      Error.throwWithStackTrace(
        agent.AgentToolExecutionFailure(
          responseRaw: jsonEncode(response),
          error: error,
          stackTrace: stackTrace,
          failurePhase: 'workspace.command',
        ),
        stackTrace,
      );
    } on FormatException catch (error, stackTrace) {
      final response = agent.workspaceFailureContext(
        jsonEncode({'code': 'invalid', 'detail': error.message}),
      );
      Error.throwWithStackTrace(
        agent.AgentToolExecutionFailure(
          responseRaw: jsonEncode(response),
          error: error,
          stackTrace: stackTrace,
          failurePhase: 'workspace.command',
        ),
        stackTrace,
      );
    }
  }
}

Object? _modelToolResult(
  Object? result,
  String conversationId,
  String toolCallId,
  Map<({String conversationId, String toolCallId}), Map<String, Object?>>
  appResults,
) {
  if (result case final McpToolCallerResult appResult) {
    if (toolCallId.isNotEmpty && appResult.appData.isNotEmpty) {
      appResults[(conversationId: conversationId, toolCallId: toolCallId)] =
          appResult.appData;
    }

    return appResult.modelText;
  }

  return result;
}

class const AppResolvedToolProvider({
  required final AgentCancellationRuntime agentCancellationRuntime,
  required final McpToolCaller mcpToolCaller,
  final McpElicitationRequester? mcpElicitationRequester,
  final ConversationRepository? conversationRepository,
  final LoadConversationSkillUsecase Function(String workspaceId)?
  loadConversationSkillUsecase,
  final BuildLoadedSkillManifestsUsecase? buildLoadedSkillManifestsUsecase,
  final BuildAppSkillNativeToolSpecsUsecase?
  buildAppSkillNativeToolSpecsUsecase,
  final RunSkillsManagerToolUsecase Function(String workspaceId)?
  runSkillsManagerToolUsecase,
  final ListAvailableSkillsUsecase Function(String workspaceId)?
  listAvailableSkillsUsecase,
  final SkillResourceResolver Function(String workspaceId)?
  skillResourceResolver,
  final agent.SubAgentRunner? subAgentRunner,
  final SkillsManagerToolSuccessHandler? onSkillsManagerToolSuccess,
  final BrowserSkillToolRunner? browserSkillToolRunner,
  final ConnectorCommandUsecase? connectorCommandUsecase,
  final ConversationAgentLanguageRuntime? conversationLanguageRuntime,
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
    required String toolCallId,
    required ResolvedTool tool,
    required Object input,
  }) {
    return _runCancelableInputTool(
      .new(
        conversationId: conversationId,
        toolCallId: toolCallId,
        input: input,
        toolIdentifier: tool.toolIdentifier,
        isCancellationSupported: false,
        operation: _builtInOperation(tool, input),
        agentCancellationRuntime: agentCancellationRuntime,
      ),
    );
  }

  @override
  Future<Object?> runNativeTool({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required Object input,
  }) {
    return _runCancelableInputTool(
      .new(
        conversationId: conversationId,
        toolCallId: toolCallId,
        input: input,
        toolIdentifier: tool.toolIdentifier,
        isCancellationSupported: true,
        operation: _nativeOperation(tool, input),
        agentCancellationRuntime: agentCancellationRuntime,
      ),
    );
  }

  @override
  Future<Object?> runMcpTool(agent.McpToolCallRequest request) =>
      _runMcpToolCall(this, request);

  @override
  Future<Object?> runConnectorCommandTool(
    agent.ConnectorCommandToolRequest request,
  ) {
    final usecase = connectorCommandUsecase;
    if (usecase == null) {
      throw StateError('Connector commands are not configured.');
    }

    return usecase.call(
      workspaceId: request.workspaceId,
      commandName: request.toolIdentifier,
      arguments: request.arguments,
      operationId: request.toolCallId,
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
      _runSkillControlRequest(
        this,
        input,
        languageCode: conversationLanguageRuntime?.languageCodeFor(
          input.conversationId,
        ),
      );

  @override
  Future<Object?> runSkillNativeTool(agent.SkillNativeToolRequest input) {
    return _runSkillNativeTool(
      .new(
        conversationId: input.conversationId,
        toolCallId: input.toolCallId,
        workspaceId: input.workspaceId,
        skillSlug: input.skillSlug,
        toolSlug: input.toolSlug,
        arguments: input.arguments,
        languageCode: conversationLanguageRuntime?.languageCodeFor(
          input.conversationId,
        ),
        provider: this,
      ),
    );
  }
}

Future<Object?> _runSkillControlRequest(
  AppResolvedToolProvider provider,
  _SkillControlToolRequest request, {
  String? languageCode,
}) {
  final usecase = _skillCommandUsecase(
    _skillCommandDependencies(provider),
    _skillCommandResources(provider),
  );

  final commandRequest = (
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    commandName: request.toolIdentifier,
    arguments: request.arguments,
  );

  return usecase.call(commandRequest, languageCode: languageCode);
}

_SkillCommandDependencies _skillCommandDependencies(
  AppResolvedToolProvider provider,
) {
  final listSkills = provider.listAvailableSkillsUsecase;
  final loadSkill = provider.loadConversationSkillUsecase;
  final buildManifests = provider.buildLoadedSkillManifestsUsecase;
  if (listSkills == null || loadSkill == null || buildManifests == null) {
    throw StateError('Skill commands are not configured.');
  }

  return (
    listSkills: listSkills,
    loadSkill: loadSkill,
    buildManifests: buildManifests,
  );
}

_SkillCommandResources _skillCommandResources(
  AppResolvedToolProvider provider,
) {
  final resolver = provider.skillResourceResolver;

  return (
    list: _listSkillResourceSummaries(resolver),
    load: _loadSkillResourceContent(resolver),
  );
}

RunSkillCommandUsecase _skillCommandUsecase(
  _SkillCommandDependencies dependencies,
  _SkillCommandResources resources,
) => RunSkillCommandUsecase(
  listAvailableSkillsUsecase: dependencies.listSkills,
  loadConversationSkillUsecase: dependencies.loadSkill,
  buildLoadedSkillManifestsUsecase: dependencies.buildManifests,
  listSkillResourceSummaries: resources.list,
  loadSkillResourceContent: resources.load,
);

agent.AgentResolvedToolExecution<ResolvedTool> _toExecution(ResolvedTool tool) {
  return agent.AgentResolvedToolExecution(
    descriptor: _toAgentDescriptor(tool),
    tool: tool,
    supportsCancellation: _supportsCancellation(tool),
  );
}

bool _supportsCancellation(ResolvedTool tool) => switch (tool.type) {
  .builtIn || .mcp || .skillControl || .connectorCommand => false,
  .native => true,
  .skillNative => _supportsSkillNativeCancellation(
    tool.skillSlug,
    tool.toolIdentifier,
  ),
};

bool _supportsSkillNativeCancellation(String? skillSlug, String toolSlug) {
  if (skillSlug == agent.agentsSkillSlug) {
    return toolSlug == agent.runSubAgentToolName;
  }

  return skillSlug != SkillToolSlugs.skillsManager;
}

Future<Object?> _runMcpToolCall(
  AppResolvedToolProvider provider,
  agent.McpToolCallRequest input,
) => _registerAndAwaitCancelableOperation(
  _mcpToolOperationRequest(provider, input),
);

_CancelableOperationRequest _mcpToolOperationRequest(
  AppResolvedToolProvider provider,
  agent.McpToolCallRequest input,
) => (
  runtime: provider.agentCancellationRuntime,
  conversationId: input.conversationId,
  toolCallId: input.toolCallId,
  operation: _mcpToolOperation(provider, input),
  isCancellationSupported: false,
);

CancelableOperation<Object?> _mcpToolOperation(
  AppResolvedToolProvider provider,
  agent.McpToolCallRequest input,
) {
  final requester = provider.mcpElicitationRequester;

  return CancelableOperation<Object?>.fromFuture(
    provider.mcpToolCaller(
      mcpServerId: input.mcpServerId,
      toolIdentifier: input.toolIdentifier,
      arguments: input.arguments,
      onElicitation: requester == null
          ? null
          : (request) => requester(input.conversationId, request),
    ),
  );
}

agent.AgentResolvedToolName _toAgentDescriptor(ResolvedTool tool) {
  return switch (tool.type) {
    .builtIn => _builtInDescriptor(tool),
    .mcp => _mcpDescriptor(tool),
    .native => _nativeDescriptor(tool),
    .connectorCommand => agent.AgentResolvedToolName.connectorCommand(
      toolIdentifier: tool.toolIdentifier,
    ),
    .skillControl => _skillControlDescriptor(tool),
    .skillNative => _skillNativeDescriptor(tool),
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

agent.AgentResolvedToolName _skillNativeDescriptor(ResolvedTool tool) {
  return agent.AgentResolvedToolName.skillNative(
    tableId: tool.tableId,
    skillSlug: tool.skillSlug ?? '',
    toolIdentifier: tool.skillToolSlug ?? tool.toolIdentifier,
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

Future<Object?> _runCancelableInputTool(_CancelableInputToolRequest request) =>
    _registerAndAwaitCancelableOperation((
      runtime: request.agentCancellationRuntime,
      conversationId: request.conversationId,
      toolCallId: request.toolCallId,
      operation: request.operation,
      isCancellationSupported: request.isCancellationSupported,
    ));

Future<Object?> _registerAndAwaitCancelableOperation(
  _CancelableOperationRequest request,
) async {
  final operationResult = request.operation.valueOrCancellation();
  final handle = _registerCancelableOperation(request, operationResult);

  return await _awaitCancelableOperation(
    request: request,
    operationResult: operationResult,
    handle: handle,
  );
}

AgentToolCancellationHandle _registerCancelableOperation(
  _CancelableOperationRequest request,
  Future<Object?> operationResult,
) => request.runtime.registerToolCancellationHandle((
  conversationId: request.conversationId,
  toolCallId: request.toolCallId,
  isSupported: request.isCancellationSupported,
  cancel: request.operation.cancel,
  operationResult: operationResult,
  isCancellationConfirmed: () => request.operation.isCanceled,
));

Future<Object?> _awaitCancelableOperation({
  required _CancelableOperationRequest request,
  required Future<Object?> operationResult,
  required AgentToolCancellationHandle handle,
}) async {
  try {
    return await Future.any<Object?>([
      operationResult,
      _backgroundWorkAcknowledgementAfterDetach(handle.detached),
    ]);
  } finally {
    _completeCancelableOperation(request: request, handle: handle);
  }
}

void _completeCancelableOperation({
  required _CancelableOperationRequest request,
  required AgentToolCancellationHandle handle,
}) {
  if (handle.backgroundWorkId == null) {
    request.runtime.completeToolCancellationHandle(
      conversationId: request.conversationId,
      toolCallId: request.toolCallId,
      handle: handle,
    );
  }
}

Map<String, Object> _backgroundWorkAcknowledgement(String workId) => {
  'status': 'running_in_background',
  'work_id': workId,
};

Future<Object?> _backgroundWorkAcknowledgementAfterDetach(
  Future<String> workId,
) async => _backgroundWorkAcknowledgement(await workId);

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

typedef _SkillControlToolRequest = agent.SkillControlToolRequest;

class const _CancelableInputToolRequest({
  required final String conversationId,
  required final String toolCallId,
  required final Object input,
  required final String toolIdentifier,
  required final bool isCancellationSupported,
  required final CancelableOperation<Object?> operation,
  required final AgentCancellationRuntime agentCancellationRuntime,
});

typedef _CancelableOperationRequest = ({
  AgentCancellationRuntime runtime,
  String conversationId,
  String toolCallId,
  CancelableOperation<Object?> operation,
  bool isCancellationSupported,
});

typedef _SubAgentCancellationRequest = ({
  _SkillNativeToolRequest request,
  Completer<String> childStartedId,
  Future<Object?> operation,
});

class const _SkillNativeToolRequest({
  required final String conversationId,
  required final String toolCallId,
  required final String workspaceId,
  required final String skillSlug,
  required final String toolSlug,
  required final Map<String, dynamic> arguments,
  required final AppResolvedToolProvider provider,
  final String? languageCode,
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
) async {
  if (request.toolSlug == agent.listAgentsToolName) {
    final result = await runner.listAgents(
      request.workspaceId,
      arguments: request.arguments,
    );

    return AgentGuidance.localizeListAgentsResult(result, request.languageCode);
  }
  if (request.toolSlug != agent.runSubAgentToolName) {
    throw StateError('Unknown sub-agent tool: ${request.toolSlug}');
  }

  return await _runCancellableSubAgent(request, runner);
}

Future<Object?> _runCancellableSubAgent(
  _SkillNativeToolRequest request,
  agent.SubAgentRunner runner,
) {
  final childStartedId = Completer<String>();
  final operation = _startSubAgentOperation(request, runner, childStartedId);

  return _awaitSubAgentOperation(
    request: request,
    runtime: request.provider.agentCancellationRuntime,
    childStartedId: childStartedId,
    operation: operation,
  );
}

Future<Object?> _startSubAgentOperation(
  _SkillNativeToolRequest request,
  agent.SubAgentRunner runner,
  Completer<String> childStartedId,
) => runner.run(
  parentConversationId: request.conversationId,
  workspaceId: request.workspaceId,
  arguments: request.arguments,
  onChildStarted: ({required childId, required parentId}) =>
      _recordStartedSubAgent(
        childStartedId,
        childId,
        request.languageCode,
        request.provider.conversationLanguageRuntime,
      ),
);

void _recordStartedSubAgent(
  Completer<String> childStartedId,
  String childId,
  String? languageCode,
  ConversationAgentLanguageRuntime? languageRuntime,
) {
  languageRuntime?.remember(childId, languageCode);
  if (!childStartedId.isCompleted) childStartedId.complete(childId);
}

Future<Object?> _awaitSubAgentOperation({
  required _SkillNativeToolRequest request,
  required AgentCancellationRuntime runtime,
  required Completer<String> childStartedId,
  required Future<Object?> operation,
}) async {
  final cancellationRequest = (
    request: request,
    childStartedId: childStartedId,
    operation: operation,
  );
  final handle = _registerSubAgentCancellationHandle(
    runtime,
    request,
    cancellationRequest,
  );
  try {
    return await Future.any<Object?>([
      operation,
      _backgroundWorkAcknowledgementAfterDetach(handle.detached),
    ]);
  } finally {
    if (handle.backgroundWorkId == null) {
      _completeSubAgentCancellationHandle(runtime, request, handle);
    }
  }
}

AgentToolCancellationHandle _registerSubAgentCancellationHandle(
  AgentCancellationRuntime runtime,
  _SkillNativeToolRequest request,
  _SubAgentCancellationRequest cancellationRequest,
) {
  final handle = runtime.registerToolCancellationHandle((
    conversationId: request.conversationId,
    toolCallId: request.toolCallId,
    isSupported: true,
    cancel: () => _cancelSubAgentOperation(runtime, cancellationRequest),
    operationResult: cancellationRequest.operation,
    isCancellationConfirmed: () => true,
  ));
  unawaited(
    _recordSubAgentChildConversationWhenStarted(
      childStartedId: cancellationRequest.childStartedId,
      operation: cancellationRequest.operation,
      handle: handle,
    ),
  );

  return handle;
}

Future<void> _recordSubAgentChildConversationWhenStarted({
  required Completer<String> childStartedId,
  required Future<Object?> operation,
  required AgentToolCancellationHandle handle,
}) async {
  final childConversationId = await Future.any<String?>([
    childStartedId.future,
    _subAgentCompletesBeforeStart(operation),
  ]);
  if (childConversationId == null) return;
  handle.childConversation.record(childConversationId);
}

void _completeSubAgentCancellationHandle(
  AgentCancellationRuntime runtime,
  _SkillNativeToolRequest request,
  AgentToolCancellationHandle handle,
) {
  runtime.completeToolCancellationHandle(
    conversationId: request.conversationId,
    toolCallId: request.toolCallId,
    handle: handle,
  );
}

Future<void> _cancelSubAgentOperation(
  AgentCancellationRuntime runtime,
  _SubAgentCancellationRequest request,
) async {
  final childId = await _childIdForCancellation(request);
  runtime.requestStopOnStart(childId);
  final stopped = await Future.any<bool>([
    _childCleanupCompletes(runtime, childId),
    _subAgentFinishes(request.operation),
  ]);
  if (!stopped) {
    throw StateError('Sub-agent stop was requested but not confirmed.');
  }
}

Future<bool> _childCleanupCompletes(
  AgentCancellationRuntime runtime,
  String childId,
) async {
  await runtime.waitForCompletion(childId);

  return true;
}

Future<String> _childIdForCancellation(
  _SubAgentCancellationRequest request,
) async {
  final childId = await Future.any<String?>([
    request.childStartedId.future,
    _subAgentCompletesBeforeStart(request.operation),
  ]);
  if (childId == null) {
    throw StateError('Sub-agent ended before cancellation was sent.');
  }

  return childId;
}

Future<String?> _subAgentCompletesBeforeStart(Future<Object?> operation) async {
  final _ = await _futureValueOrNull(operation);

  return null;
}

Future<bool> _subAgentFinishes(Future<Object?> operation) async {
  final _ = await _futureValueOrNull(operation);

  return false;
}

Future<T?> _futureValueOrNull<T>(Future<T> future) async {
  try {
    return await future;
  } on Object catch (_) {
    return null;
  }
}

Future<Object?> _runSkillNativeTool(_SkillNativeToolRequest request) async {
  final toolName = await _validateSkillNativeTool(request);

  return await _dispatchSkillNativeTool(request, toolName);
}

Future<String> _validateSkillNativeTool(_SkillNativeToolRequest request) async {
  final buildSpecs = request.provider.buildAppSkillNativeToolSpecsUsecase;
  if (buildSpecs == null) {
    throw StateError('App skill tool specifications are not configured.');
  }
  final toolName = _skillNativeToolName(request);
  await _requireSkillNativeTool(buildSpecs, request, toolName);

  return toolName;
}

String _skillNativeToolName(_SkillNativeToolRequest request) =>
    agent.AgentResolvedToolName.skillNative(
      tableId: request.toolSlug,
      skillSlug: request.skillSlug,
      toolIdentifier: request.toolSlug,
    ).fullName;

Future<void> _requireSkillNativeTool(
  BuildAppSkillNativeToolSpecsUsecase buildSpecs,
  _SkillNativeToolRequest request,
  String toolName,
) async {
  final specs = await buildSpecs.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    languageCode: request.languageCode,
  );
  if (!specs.any((spec) => spec.name == toolName)) {
    throw StateError('App skill tool is not currently available: $toolName');
  }
}

Future<Object?> _dispatchSkillNativeTool(
  _SkillNativeToolRequest request,
  String toolName,
) => switch (request.skillSlug) {
  AppSkillRegistry.browserSkillSlug => _runBrowserSkillTool(request),
  agent.agentsSkillSlug => _runSubAgentNativeTool(request),
  SkillToolSlugs.skillsManager => _runSkillsManagerNativeTool(request),
  _ => throw StateError('Unknown app skill tool: $toolName'),
};

Future<Object?> _runBrowserSkillTool(_SkillNativeToolRequest request) {
  final runner = request.provider.browserSkillToolRunner;
  if (runner == null) {
    throw StateError('Browser skill tools are not configured.');
  }

  return runner(
    workspaceId: request.workspaceId,
    conversationId: request.conversationId,
    toolSlug: request.toolSlug,
    arguments: request.arguments,
  );
}

Future<Object?> _runSubAgentNativeTool(_SkillNativeToolRequest request) {
  return _runSubAgentTool(request: request);
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
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    toolSlug: request.toolSlug,
    result: result,
  );
}

ListSkillResourceSummaries? _listSkillResourceSummaries(
  SkillResourceResolver Function(String workspaceId)? resourceResolver,
) {
  if (resourceResolver == null) return null;

  return ({
    required conversationId,
    required workspaceId,
    required skillSlug,
  }) => resourceResolver(workspaceId).list(workspaceId, skillSlug);
}

LoadSkillResourceContent? _loadSkillResourceContent(
  SkillResourceResolver Function(String workspaceId)? resourceResolver,
) {
  final resolver = resourceResolver;
  if (resolver == null) return null;

  return ({
    required conversationId,
    required workspaceId,
    required skillSlug,
    required resourceSlug,
  }) => _resolveSkillResourceContent(
    resolver,
    workspaceId,
    skillSlug,
    resourceSlug,
  );
}

Future<({String title, String content})?> _resolveSkillResourceContent(
  SkillResourceResolver Function(String workspaceId) resolver,
  String workspaceId,
  String skillSlug,
  String resourceSlug,
) async {
  final resource = await resolver(workspaceId)
      .get(workspaceId, skillSlug, resourceSlug);
  if (resource == null) return null;

  return (title: resource.summary.title, content: resource.content);
}

final Provider<ResolvedToolService>
resolvedToolServiceProvider = Provider<ResolvedToolService>((ref) {
  final container = ref.container;
  final agentCancellationRuntime = ref.watch(agentCancellationRuntimeProvider);
  final activeSubAgents = ref.watch(activeSubAgentRuntimeProvider.notifier);

  return ResolvedToolService(
    agentCancellationRuntime: agentCancellationRuntime,
    mcpToolCaller: ref.watch(mcpToolCallerProvider),
    mcpElicitationRequester: (conversationId, request) => container
        .read(mcpElicitationProvider(conversationId).notifier)
        .request(request),
    conversationRepository: ref.watch(conversationRepositoryProvider),
    loadConversationSkillUsecase: (workspaceId) =>
        container.read(loadConversationSkillUsecaseProvider(workspaceId)),
    buildLoadedSkillManifestsUsecase: ref.watch(
      buildLoadedSkillManifestsUsecaseProvider,
    ),
    buildAppSkillNativeToolSpecsUsecase: ref.watch(
      buildAppSkillNativeToolSpecsUsecaseProvider,
    ),
    runSkillsManagerToolUsecase: (workspaceId) =>
        container.read(runSkillsManagerToolUsecaseProvider(workspaceId)),
    listAvailableSkillsUsecase: (workspaceId) =>
        container.read(listAvailableSkillsUsecaseProvider(workspaceId)),
    skillResourceResolver: (workspaceId) =>
        container.read(skillResourceResolverProvider(workspaceId)),
    subAgentRunner: .new(
      agentCatalog: AppSubAgentCatalog(ref.watch(agentsRepositoryProvider)),
      conversationStore: AppSubAgentConversationStore(
        ref.watch(conversationRepositoryProvider),
      ),
      messageStore: AppSubAgentMessageStore(
        ref.watch(messageRepositoryProvider),
      ),
      startRequest: activeSubAgents.start,
      continueAgentTurn: ({required conversationId, required context}) async {
        final decision = await container
            .read(appAgentLoopProvider)
            .call(conversationId: conversationId, context: context);
        if (decision == agent.AgentIterationDecision.waitForToolApproval) {
          activeSubAgents.markAwaitingApproval(conversationId);
        }

        return decision;
      },
      onChildStarted: ({required parentId, required childId}) {
        agentCancellationRuntime.registerCleanup(parentId, () {
          if (activeSubAgents.parentOf(childId) != parentId) return;
          agentCancellationRuntime.requestStopOnStart(childId);
          activeSubAgents.finish((
            parentId: parentId,
            childId: childId,
            status: agent.SubAgentCompletionStatus.stopped,
            error: null,
            stackTrace: null,
          ));
        });
      },
    ),
    onSkillsManagerToolSuccess:
        ({
          required conversationId,
          required workspaceId,
          required toolSlug,
          required result,
        }) {
          SkillsManagerToolStateInvalidator.invalidate((
            container: container,
            conversationId: conversationId,
            workspaceId: workspaceId,
            toolSlug: toolSlug,
            result: result,
          ));
        },
    browserSkillToolRunner:
        ({
          required workspaceId,
          required conversationId,
          required toolSlug,
          required arguments,
        }) => container
            .read(browserSessionProvider(workspaceId, conversationId).notifier)
            .runSkillTool(toolSlug, arguments),
    connectorCommandUsecase: ref.watch(connectorCommandUsecaseProvider),
    conversationLanguageRuntime: ref.watch(
      conversationAgentLanguageRuntimeProvider,
    ),
    workspaceConversationTools: ref.watch(workspaceConversationToolsProvider),
  );
});

typedef SkillsManagerToolInvalidationRequest = ({
  ProviderContainer container,
  String conversationId,
  String workspaceId,
  String toolSlug,
  Object result,
});

abstract final class SkillsManagerToolStateInvalidator {
  static void invalidate(SkillsManagerToolInvalidationRequest request) =>
      _invalidateSkillsManagerToolState(request);
}

typedef _SkillManagerInvalidationHandler = void Function(
  SkillsManagerToolInvalidationRequest request,
);

void _invalidateSkillsManagerToolState(
  SkillsManagerToolInvalidationRequest request,
) {
  final invalidateMutation = _skillManagerInvalidationHandler(request.toolSlug);
  if (invalidateMutation == null) return;
  invalidateMutation(request);
  _invalidateConversationSkillState(request);
}

_SkillManagerInvalidationHandler? _skillManagerInvalidationHandler(
  String toolSlug,
) => _userSkillToolSlugs.contains(toolSlug) ? _invalidateUserSkill : null;

void _invalidateConversationSkillState(
  SkillsManagerToolInvalidationRequest request,
) {
  if (request.conversationId.isEmpty) return;
  request.container
      .read(conversationSkillContextRuntimeProvider.notifier)
      .markNeedsContext(request.conversationId);
  request.container.invalidate(
    conversationSkillSelectorProvider(
      request.workspaceId,
      request.conversationId,
    ),
  );
}

void _invalidateUserSkill(SkillsManagerToolInvalidationRequest request) {
  request.container.invalidate(workspaceSkillsProvider(request.workspaceId));
  final skillId = _resultValue(request.result, 'skillId');
  if (skillId is String && skillId.isNotEmpty) {
    request.container.invalidate(
      skillDetailProvider(request.workspaceId, skillId),
    );
  }
}

Object? _resultValue(Object result, String key) {
  final resultMap = result is Map ? result : const <Object?, Object?>{};

  return resultMap[key];
}
