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
    );
    final target = await _runnerTarget(dependencies, input);
    if (target == null || !_requestActive(input)) return null;
    if (!await _runnerPermissionAllowed(dependencies, input, target)) {
      return null;
    }

    final session = await openSession(input, target);
    if (!_requestActive(input)) {
      session.close();

      return null;
    }

    return _scopedRunner(input, target, session, dependencies);
  }
}

typedef _RunnerFactoryDependencies = ({
  AppDatabase database,
  WorkspaceVerificationRepository repository,
  Future<ToolApprovalDecision> Function(
    AgentToolApprovalRequest<ResolvedTool> request,
  )
  permission,
});

Future<ResolvedTool?> _runnerTarget(
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
) async {
  final conversation = await dependencies.database.conversationDao
      .getConversationById(input.invocation.conversationId);
  if (conversation == null) return null;
  final target = await _resolveTool(
    dependencies.database,
    input.settings.runnerToolId,
    input.settings,
    conversation.workspaceId,
  );
  final edit = await _resolveTool(
    dependencies.database,
    input.invocation.tool.tableId,
    input.settings,
    conversation.workspaceId,
  );
  if (edit?.toolIdentifier != input.invocation.tool.toolIdentifier) {
    return null;
  }

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
  if (!await _toolsMatch(
    dependencies.database,
    input,
    target,
    current,
    workspaceId,
  )) {
    return false;
  }
  if (!await _permissionDecisionsMatch(
    dependencies,
    input,
    target,
    workspaceId,
  )) {
    return false;
  }

  return _settingsRemainCurrent(dependencies.repository, input, workspaceId);
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

Future<bool> _toolsMatch(
  AppDatabase database,
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
  ScopedVerificationSettings settings,
  String workspaceId,
) async {
  final runner = await _resolveTool(
    database,
    target.tableId,
    settings,
    workspaceId,
  );
  final edit = await _resolveTool(
    database,
    input.invocation.tool.tableId,
    settings,
    workspaceId,
  );

  return runner?.toolIdentifier == target.toolIdentifier &&
      edit?.toolIdentifier == input.invocation.tool.toolIdentifier;
}

Future<bool> _permissionDecisionsMatch(
  _RunnerFactoryDependencies dependencies,
  ScopedVerificationRunnerInput input,
  ResolvedTool target,
  String workspaceId,
) async {
  final edit = await dependencies.permission((
    conversationId: input.invocation.conversationId,
    workspaceId: workspaceId,
    toolCallId: input.invocation.toolCallId,
    resolvedTool: input.invocation.tool,
    argumentsRaw: null,
  ));
  if (!edit.isGranted() && !edit.needsConfirmation) return false;
  final runner = await dependencies.permission((
    conversationId: input.invocation.conversationId,
    workspaceId: workspaceId,
    toolCallId: input.request.operationId,
    resolvedTool: target,
    argumentsRaw: jsonEncode(input.request.toJson()),
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

Future<ResolvedTool?> _resolveTool(
  AppDatabase database,
  String id,
  ScopedVerificationSettings settings,
  String workspaceId,
) async {
  final row = await _enabledToolRow(database, id, workspaceId);
  if (row == null) return null;
  final groupId = row.workspaceToolsGroupId;
  if (groupId == null) return null;
  final group = await _enabledToolGroup(
    database,
    groupId,
    row.workspaceId,
    settings.mcpServerId,
  );
  if (group == null) return null;
  final server = await _enabledMcpServer(
    database,
    settings.mcpServerId,
    row.workspaceId,
  );
  if (server == null) return null;

  return ResolvedTool.mcp(
    tableId: row.id,
    toolIdentifier: row.toolId,
    mcp: (
      mcpServerId: settings.mcpServerId,
      mcpSlug: settings.mcpServerId,
      outputSchemaJson: row.outputSchema,
    ),
  );
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

Future<ToolsGroupsTable?> _enabledToolGroup(
  AppDatabase database,
  String id,
  String workspaceId,
  String serverId,
) async {
  final group = await (database.select(
    database.toolsGroups,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  if (group == null ||
      !group.isEnabled ||
      group.workspaceId != workspaceId ||
      group.mcpServerId != serverId) {
    return null;
  }

  return group;
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
