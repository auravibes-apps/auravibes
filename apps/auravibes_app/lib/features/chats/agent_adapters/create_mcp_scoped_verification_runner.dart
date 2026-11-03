import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/mcp_scoped_verification_runner.dart';
import 'package:auravibes_app/features/chats/models/scoped_verification_invocation.dart';
import 'package:auravibes_app/features/tools/models/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Maps owner-selected tool rows to a fresh single-operation transport adapter.
class const CreateMcpScopedVerificationRunner({
  required final AppDatabase database,
  required final WorkspaceVerificationRepository repository,
  required final Future<ScopedVerificationOwnedCaller> Function(
    ScopedVerificationRunnerInput input,
    ResolvedTool target,
  )
  openSession,
  required final Future<ToolApprovalDecision> Function(
    AgentToolApprovalRequest<ResolvedTool> request,
  )
  permission,
}) {
  Future<ScopedVerificationRunner?> call(
    ScopedVerificationRunnerInput input,
  ) async {
    final dependencies = (
      database: database,
      repository: repository,
      permission: permission,
      openSession: openSession,
    );
    final target = await _runnerTarget(dependencies, input);

    return await _openAllowedRunner(dependencies, input, target);
  }
}

typedef _RunnerFactoryDependencies = ({
  AppDatabase database,
  WorkspaceVerificationRepository repository,
  Future<ToolApprovalDecision> Function(
    AgentToolApprovalRequest<ResolvedTool> request,
  )
  permission,
  Future<ScopedVerificationOwnedCaller> Function(
    ScopedVerificationRunnerInput input,
    ResolvedTool target,
  )
  openSession,
});

Future<ScopedVerificationRunner?> _openAllowedRunner(
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
  ResolvedTool? target,
) async {
  if (target == null || !_requestActive(input)) return null;
  if (!await _runnerPermissionAllowed(dependencies, input, target)) return null;

  final session = await dependencies.openSession(input, target);
  if (!_requestActive(input)) return _closeRunnerSession(session);

  return _scopedRunner(input, target, session, dependencies);
}

ScopedVerificationRunner? _closeRunnerSession(
  ScopedVerificationOwnedCaller session,
) {
  session.close();

  return null;
}

Future<ResolvedTool?> _runnerTarget(
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
) async {
  final workspaceId = await _workspaceId(dependencies.database, input);
  if (workspaceId == null) return null;

  return await _runnerTargetForWorkspace(dependencies, input, workspaceId);
}

Future<ResolvedTool?> _runnerTargetForWorkspace(
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
  String workspaceId,
) async {
  final target = await _configuredRunnerTool(
    dependencies.database,
    input,
    workspaceId,
  );
  if (target == null) return null;
  if (!await _editingToolMatches(dependencies.database, input, workspaceId)) {
    return null;
  }

  return target;
}

Future<ResolvedTool?> _configuredRunnerTool(
  AppDatabase database,
  ScopedVerificationRunnerInput input,
  String workspaceId,
) => _resolveTool((
  database: database,
  id: input.settings.runnerToolId,
  settings: input.settings,
  workspaceId: workspaceId,
));

Future<bool> _editingToolMatches(
  AppDatabase database,
  ScopedVerificationRunnerInput input,
  String workspaceId,
) async {
  final edit = await _resolveTool((
    database: database,
    id: input.invocation.tool.tableId,
    settings: input.settings,
    workspaceId: workspaceId,
  ));

  return edit?.toolIdentifier == input.invocation.tool.toolIdentifier;
}

Future<bool> _runnerPermissionAllowed(
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
) async {
  if (!_requestActive(input)) return false;
  final workspaceId = await _workspaceId(dependencies.database, input);
  if (workspaceId == null) return false;
  final current = await dependencies.repository.getSettings(workspaceId);
  if (!_settingsMatch(input.settings, current)) return false;

  return await _runnerPermissionsCurrent((
    dependencies: dependencies,
    input: input,
    target: target,
    settings: current,
    workspaceId: workspaceId,
  ));
}

typedef _RunnerPermissionRequest = ({
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
  ScopedVerificationSettings settings,
  String workspaceId,
});

Future<bool> _runnerPermissionsCurrent(_RunnerPermissionRequest request) async {
  if (!await _toolsMatch(request)) return false;
  if (!await _permissionDecisionsMatch(request)) return false;

  return await _settingsRemainCurrent(
    request.dependencies.repository,
    request.input,
    request.workspaceId,
  );
}

Future<String?> _workspaceId(
  AppDatabase database,
  ScopedVerificationRunnerInput input,
) async => (await database.conversationDao.getConversationById(
  input.invocation.conversationId,
))?.workspaceId;

bool _settingsMatch(
  ScopedVerificationSettings requested,
  ScopedVerificationSettings current,
) => current.enabled && current.revision == requested.revision;

Future<bool> _toolsMatch(_RunnerPermissionRequest request) async {
  if (!await _runnerToolMatches(request)) return false;

  return await _editToolMatches(request);
}

Future<bool> _runnerToolMatches(_RunnerPermissionRequest request) async {
  final runner = await _resolveTool((
    database: request.dependencies.database,
    id: request.target.tableId,
    settings: request.settings,
    workspaceId: request.workspaceId,
  ));

  return runner?.toolIdentifier == request.target.toolIdentifier;
}

Future<bool> _editToolMatches(_RunnerPermissionRequest request) async {
  final edit = await _resolveTool((
    database: request.dependencies.database,
    id: request.input.invocation.tool.tableId,
    settings: request.settings,
    workspaceId: request.workspaceId,
  ));

  return edit?.toolIdentifier == request.input.invocation.tool.toolIdentifier;
}

Future<bool> _permissionDecisionsMatch(_RunnerPermissionRequest request) async {
  final edit = await _editPermissionDecision(request);
  if (!edit.isGranted() && !edit.needsConfirmation) return false;

  final runner = await _runnerPermissionDecision(request);

  return runner.isGranted();
}

Future<ToolApprovalDecision> _editPermissionDecision(
  _RunnerPermissionRequest request,
) {
  final invocation = request.input.invocation;
  return request.dependencies.permission((
    conversationId: invocation.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: invocation.toolCallId,
    resolvedTool: invocation.tool,
    argumentsRaw: null,
  ));
}

Future<ToolApprovalDecision> _runnerPermissionDecision(
  _RunnerPermissionRequest request,
) {
  final invocation = request.input.invocation;
  final runnerRequest = request.input.request;
  return request.dependencies.permission((
    conversationId: invocation.conversationId,
    workspaceId: request.workspaceId,
    toolCallId: runnerRequest.operationId,
    resolvedTool: request.target,
    argumentsRaw: jsonEncode(runnerRequest.toJson()),
  ));
}

Future<bool> _settingsRemainCurrent(
  WorkspaceVerificationRepository repository,
  ScopedVerificationRunnerInput input,
  String workspaceId,
) async {
  final latest = await repository.getSettings(workspaceId);

  return _settingsMatch(input.settings, latest) && _requestActive(input);
}

typedef _ToolResolutionRequest = ({
  AppDatabase database,
  String id,
  ScopedVerificationSettings settings,
  String workspaceId,
});

Future<ResolvedTool?> _resolveTool(_ToolResolutionRequest request) async {
  final row = await _enabledToolRow(
    request.database,
    request.id,
    request.workspaceId,
  );
  if (row == null) return null;

  return await _resolveToolGroup(row, request);
}

Future<ResolvedTool?> _resolveToolGroup(
  ToolsTable row,
  _ToolResolutionRequest request,
) async {
  final groupId = row.workspaceToolsGroupId;
  if (groupId == null) return null;
  final group = await _enabledToolGroup(_toolGroupRequest(row, request));
  if (group == null) return null;
  final serverId = request.settings.mcpServerId;
  final server = await _enabledMcpServer(
    request.database,
    serverId,
    row.workspaceId,
  );
  if (server == null) return null;

  return _resolvedMcpTool(row, serverId, server);
}

_EnabledToolGroupRequest _toolGroupRequest(
  ToolsTable row,
  _ToolResolutionRequest request,
) => (
  database: request.database,
  id: row.workspaceToolsGroupId!,
  workspaceId: row.workspaceId,
  serverId: request.settings.mcpServerId,
);

ResolvedTool _resolvedMcpTool(
  ToolsTable row,
  String serverId,
  McpServersTable server,
) => ResolvedTool.mcp(
  tableId: row.id,
  toolIdentifier: row.toolId,
  mcp: (
    mcpServerId: serverId,
    mcpSlug: serverId,
    outputSchemaJson: row.outputSchema,
  ),
);

typedef _EnabledToolGroupRequest = ({
  AppDatabase database,
  String id,
  String workspaceId,
  String serverId,
});

Future<ToolsGroupsTable?> _enabledToolGroup(
  _EnabledToolGroupRequest request,
) async {
  final group = await _findToolGroup(request);
  if (!_toolGroupIsEnabledForRequest(group, request)) return null;

  return group;
}

Future<ToolsGroupsTable?> _findToolGroup(_EnabledToolGroupRequest request) =>
    (request.database.select(
      request.database.toolsGroups,
    )..where((row) => row.id.equals(request.id))).getSingleOrNull();

bool _toolGroupIsEnabledForRequest(
  ToolsGroupsTable? group,
  _EnabledToolGroupRequest request,
) =>
    group != null &&
    group.isEnabled &&
    group.workspaceId == request.workspaceId &&
    group.mcpServerId == request.serverId;

Future<ToolsTable?> _enabledToolRow(
  AppDatabase database,
  String id,
  String workspaceId,
) async {
  final row = await (database.select(
    database.tools,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  if (row == null || !row.isEnabled || row.workspaceId != workspaceId) {
    return null;
  }

  return row;
}

Future<McpServersTable?> _enabledMcpServer(
  AppDatabase database,
  String id,
  String workspaceId,
) async {
  final server = await (database.select(
    database.mcpServers,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  if (server == null ||
      !server.isEnabled ||
      server.workspaceId != workspaceId) {
    return null;
  }

  return server;
}

bool _requestActive(ScopedVerificationRunnerInput input) =>
    !input.cancellation.isCancellationRequested &&
    input.request.deadline.isAfter(DateTime.now().toUtc());

ScopedVerificationRunner _scopedRunner(
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
  ScopedVerificationOwnedCaller session,
  _RunnerFactoryDependencies dependencies,
) => McpScopedVerificationRunner(
  mcpServerId: input.settings.mcpServerId,
  editMcpServerId: input.invocation.tool.mcpServerId ?? '',
  runnerToolIdentifier: target.toolIdentifier,
  caller: session.call,
  isAllowed: () => _runnerPermissionAllowed(dependencies, input, target),
  onClose: session.close,
);
