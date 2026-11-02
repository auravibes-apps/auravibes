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
  final database = dependencies.database;
  final invocation = input.invocation;
  final settings = input.settings;
  final conversation = await database.conversationDao.getConversationById(
    invocation.conversationId,
  );
  if (conversation == null) return null;
  final target = await _resolveTool((
    database: database,
    id: settings.runnerToolId,
    settings: settings,
    workspaceId: conversation.workspaceId,
  ));
  final edit = await _resolveTool((
    database: database,
    id: invocation.tool.tableId,
    settings: settings,
    workspaceId: conversation.workspaceId,
  ));
  if (edit?.toolIdentifier != invocation.tool.toolIdentifier) return null;

  return target;
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
  if (!await _toolsMatch((
    database: request.dependencies.database,
    input: request.input,
    target: request.target,
    settings: request.settings,
    workspaceId: request.workspaceId,
  ))) {
    return false;
  }
  if (!await _permissionDecisionsMatch((
    dependencies: request.dependencies,
    input: request.input,
    target: request.target,
    workspaceId: request.workspaceId,
  ))) {
    return false;
  }

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

typedef _ToolMatchRequest = ({
  AppDatabase database,
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
  ScopedVerificationSettings settings,
  String workspaceId,
});

Future<bool> _toolsMatch(_ToolMatchRequest request) async {
  final runner = await _resolveTool((
    database: request.database,
    id: request.target.tableId,
    settings: request.settings,
    workspaceId: request.workspaceId,
  ));
  final edit = await _resolveTool((
    database: request.database,
    id: request.input.invocation.tool.tableId,
    settings: request.settings,
    workspaceId: request.workspaceId,
  ));

  return runner?.toolIdentifier == request.target.toolIdentifier &&
      edit?.toolIdentifier == request.input.invocation.tool.toolIdentifier;
}

typedef _PermissionDecisionRequest = ({
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
  String workspaceId,
});

Future<bool> _permissionDecisionsMatch(
  _PermissionDecisionRequest request,
) async {
  final invocation = request.input.invocation;
  final workspaceId = request.workspaceId;
  final edit = await request.dependencies.permission((
    conversationId: invocation.conversationId,
    workspaceId: workspaceId,
    toolCallId: invocation.toolCallId,
    resolvedTool: invocation.tool,
    argumentsRaw: null,
  ));
  if (!edit.isGranted() && !edit.needsConfirmation) return false;
  final runnerRequest = request.input.request;
  final runner = await request.dependencies.permission((
    conversationId: invocation.conversationId,
    workspaceId: workspaceId,
    toolCallId: runnerRequest.operationId,
    resolvedTool: request.target,
    argumentsRaw: jsonEncode(runnerRequest.toJson()),
  ));

  return runner.isGranted();
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
  final group = await _enabledToolGroup((
    database: request.database,
    id: groupId,
    workspaceId: row.workspaceId,
    serverId: request.settings.mcpServerId,
  ));
  if (group == null) return null;
  final server = await _enabledMcpServer(
    request.database,
    request.settings.mcpServerId,
    row.workspaceId,
  );
  if (server == null) return null;

  return ResolvedTool.mcp(
    tableId: row.id,
    toolIdentifier: row.toolId,
    mcp: (
      mcpServerId: request.settings.mcpServerId,
      mcpSlug: request.settings.mcpServerId,
      outputSchemaJson: row.outputSchema,
    ),
  );
}

typedef _EnabledToolGroupRequest = ({
  AppDatabase database,
  String id,
  String workspaceId,
  String serverId,
});

Future<ToolsGroupsTable?> _enabledToolGroup(
  _EnabledToolGroupRequest request,
) async {
  final group = await (request.database.select(
    request.database.toolsGroups,
  )..where((row) => row.id.equals(request.id))).getSingleOrNull();
  if (group == null ||
      !group.isEnabled ||
      group.workspaceId != request.workspaceId ||
      group.mcpServerId != request.serverId) {
    return null;
  }

  return group;
}

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
