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
    final chat = await database.conversationDao.getConversationById(
      input.invocation.conversationId,
    );
    if (chat == null) return null;
    final target = await _tool(
      input.settings.runnerToolId,
      input.settings,
      chat.workspaceId,
    );
    final edit = await _tool(
      input.invocation.tool.tableId,
      input.settings,
      chat.workspaceId,
    );
    if (target == null ||
        edit == null ||
        edit.toolIdentifier != input.invocation.tool.toolIdentifier)
      return null;
    if (input.cancellation.isCancellationRequested ||
        !input.request.deadline.isAfter(DateTime.now().toUtc()))
      return null;
    if (!await _allowed(input, target)) return null;
    final session = await openSession(input, target);
    if (input.cancellation.isCancellationRequested ||
        !input.request.deadline.isAfter(DateTime.now().toUtc())) {
      session.close();
      return null;
    }

    // Never cache this adapter in a workspace/provider: it owns one start intent.
    return McpScopedVerificationRunner(
      mcpServerId: input.settings.mcpServerId,
      editMcpServerId: input.invocation.tool.mcpServerId ?? '',
      runnerToolIdentifier: target.toolIdentifier,
      caller: session.call,
      onClose: session.close,
      isAllowed: () => _allowed(input, target),
    );
  }

  Future<bool> _allowed(
    ScopedVerificationRunnerInput input,
    ResolvedTool target,
  ) async {
    if (input.cancellation.isCancellationRequested) return false;
    final workspace = await database.conversationDao.getConversationById(
      input.invocation.conversationId,
    );
    if (workspace == null) return false;
    final current = await repository.getSettings(workspace.workspaceId);
    if (!current.enabled || current.revision != input.settings.revision)
      return false;
    final runner = await _tool(target.tableId, current, workspace.workspaceId);
    final edit = await _tool(
      input.invocation.tool.tableId,
      current,
      workspace.workspaceId,
    );
    if (runner?.toolIdentifier != target.toolIdentifier ||
        edit?.toolIdentifier != input.invocation.tool.toolIdentifier)
      return false;
    final editDecision = await permission((
      conversationId: input.invocation.conversationId,
      workspaceId: workspace.workspaceId,
      toolCallId: input.invocation.toolCallId,
      resolvedTool: input.invocation.tool,
      argumentsRaw: null,
    ));
    if (!editDecision.isGranted() && !editDecision.needsConfirmation)
      return false;
    final runnerDecision = await permission((
      conversationId: input.invocation.conversationId,
      workspaceId: workspace.workspaceId,
      toolCallId: input.request.operationId,
      resolvedTool: target,
      argumentsRaw: jsonEncode(input.request.toJson()),
    ));

    if (!runnerDecision.isGranted()) return false;
    final latest = await repository.getSettings(workspace.workspaceId);

    return latest.enabled &&
        latest.revision == input.settings.revision &&
        !input.cancellation.isCancellationRequested;
  }

  Future<ResolvedTool?> _tool(
    String id,
    ScopedVerificationSettings settings,
    String workspaceId,
  ) async {
    final row = await (database.select(
      database.tools,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (row == null || !row.isEnabled || row.workspaceId != workspaceId)
      return null;
    final groupId = row.workspaceToolsGroupId;
    if (groupId == null) return null;
    final group = await (database.select(
      database.toolsGroups,
    )..where((row) => row.id.equals(groupId))).getSingleOrNull();
    if (group == null ||
        !group.isEnabled ||
        group.workspaceId != row.workspaceId ||
        group.mcpServerId != settings.mcpServerId)
      return null;
    final server = await (database.select(
      database.mcpServers,
    )..where((row) => row.id.equals(settings.mcpServerId))).getSingleOrNull();
    if (server == null ||
        !server.isEnabled ||
        server.workspaceId != row.workspaceId)
      return null;

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
}
