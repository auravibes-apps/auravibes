// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/features/tools/models/mcp_tool_display_metadata.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_display_name_provider.g.dart';

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Callers may pass a presentation-only effective target while retaining the
/// original tool-call identity for approval actions.
/// Uses Riverpod's family caching to avoid repeated lookups.
@riverpod
Future<String> toolDisplayName(
  Ref ref,
  String workspaceId,
  String compositeToolId,
) async {
  final presentationTarget = ToolNameFormatter.parse(compositeToolId);
  final mcpServerId = presentationTarget?.mcpServerId;
  McpToolDisplayMetadata? mcpMetadata;

  if (mcpServerId != null) {
    try {
      mcpMetadata = await ref.watch(
        mcpToolDisplayMetadataProvider((
          workspaceId: workspaceId,
          compositeToolId: compositeToolId,
        )).future,
      );
    } on Exception {
      // Keep the stable-name fallback available if metadata storage is absent.
    }
  }

  String? mcpServerName;
  if (mcpServerId != null) {
    try {
      mcpServerName = await ref.watch(
        mcpServerNameProvider(workspaceId, mcpServerId).future,
      );
    } on Exception {
      // The title or stable identifier still provides a usable fallback.
    }
  }

  if (mcpMetadata?.title case final title?) {
    return switch (mcpServerName) {
      final name? when name.trim().isNotEmpty => '$name: $title',
      _ => title,
    };
  }

  return ToolNameFormatter.formatDisplayName(
    presentationTarget,
    rawName: compositeToolId,
    mcpServerName: mcpServerName,
  );
}

/// Looks up only persisted, display-only metadata for an MCP tool.
final mcpToolDisplayMetadataProvider = FutureProvider.autoDispose
    .family<
      McpToolDisplayMetadata,
      ({String workspaceId, String compositeToolId})
    >((ref, request) async {
      final target = ToolNameFormatter.parse(request.compositeToolId);
      final serverId = target?.mcpServerId;
      if (target == null || serverId == null) {
        return const McpToolDisplayMetadata();
      }

      final session = await ref.watch(
        workspaceSessionForRouteProvider(request.workspaceId).future,
      );
      final group = await ref
          .watch(toolsGroupsRepositoryProvider(session))
          .getToolsGroupByMcpServerId(serverId);
      if (group == null) return const McpToolDisplayMetadata();

      final tools = await ref.watch(
        workspaceToolsProvider(request.workspaceId).future,
      );
      final matchingTools = tools.where(
        (tool) =>
            tool.workspaceToolsGroupId == group.id &&
            _sanitizeMcpToolIdentifier(tool.toolId) == target.toolIdentifier,
      );
      final iterator = matchingTools.iterator;
      if (!iterator.moveNext()) return const McpToolDisplayMetadata();
      final match = iterator.current;
      if (iterator.moveNext()) return const McpToolDisplayMetadata();

      return McpToolDisplayMetadata.fromWorkspaceTool(match);
    });

String _sanitizeMcpToolIdentifier(String toolName) =>
    toolName.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.
@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<String?> mcpServerName(
  Ref ref,
  String workspaceId,
  String mcpServerId,
) async {
  try {
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    final repository = ref.read(mcpServersRepositoryProvider(session));
    final server = await repository.getMcpServerById(mcpServerId);

    return server?.name;
  } on Exception {
    // Ignore errors, fall back to null (will use slug name).
    return null;
  }
}
