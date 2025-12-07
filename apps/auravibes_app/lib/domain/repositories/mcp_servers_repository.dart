import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';

/// Repository interface for MCP server data operations.
///
/// This abstract class defines the contract for MCP server access,
/// following the Repository pattern from Clean Architecture.
/// Implementations should handle data persistence, retrieval, and
/// business logic for MCP server operations including tools management.
abstract class McpServersRepository {
  /// Add a new MCP server with its tools as a group.
  ///
  /// This will:
  /// 1. Insert the MCP server to the database
  /// 2. Create a ToolsGroup with the MCP server name
  /// 3. Insert all tools to the Tools table with the group ID
  ///
  /// [workspaceId] The ID of the workspace to add the MCP server to.
  /// [serverToCreate] The MCP server configuration to create.
  /// [tools] The list of tools from the MCP server.
  /// Returns the created MCP server entity.
  /// Throws [McpServersException] if there's an error adding the server.
  Future<McpServerEntity> addMcpServerWithTools({
    required String workspaceId,
    required McpServerToCreate serverToCreate,
    required List<McpToolInfo> tools,
  });

  /// Delete an MCP server by ID.
  ///
  /// This will cascade delete:
  /// - The ToolsGroup linked to this MCP server
  /// - All Tools belonging to that group
  ///
  /// [serverId] The ID of the MCP server to delete.
  /// Returns true if the server was deleted, false if not found.
  /// Throws [McpServersException] if there's an error deleting the server.
  Future<bool> deleteMcpServer(String serverId);

  /// Sync tools for an MCP server.
  ///
  /// Compares the current tools from the MCP server with existing tools:
  /// - Adds new tools (isEnabled=true, permissions=ask by default)
  /// - Removes tools that no longer exist
  /// - Keeps existing tools unchanged (preserves user customizations)
  ///
  /// [mcpServerId] The ID of the MCP server.
  /// [currentTools] The current list of tools from the MCP server.
  /// Throws [McpServersException] if there's an error syncing tools.
  Future<void> syncMcpTools({
    required String mcpServerId,
    required List<McpToolInfo> currentTools,
  });

  /// Get all MCP servers for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// Returns a list of MCP servers ordered by creation date (newest first).
  /// Throws [McpServersException] if there's an error retrieving servers.
  Future<List<McpServerEntity>> getMcpServersForWorkspace(String workspaceId);

  /// Get all enabled MCP servers for a workspace.
  ///
  /// [workspaceId] The ID of the workspace.
  /// Returns a list of enabled MCP servers.
  /// Throws [McpServersException] if there's an error retrieving servers.
  Future<List<McpServerEntity>> getEnabledMcpServersForWorkspace(
    String workspaceId,
  );

  /// Get an MCP server by ID.
  ///
  /// [serverId] The ID of the MCP server.
  /// Returns the MCP server entity, or null if not found.
  /// Throws [McpServersException] if there's an error retrieving the server.
  Future<McpServerEntity?> getMcpServerById(String serverId);
}

/// Base exception for MCP servers-related operations.
class McpServersException implements Exception {
  /// Creates a new McpServersException
  const McpServersException(this.message, [this.cause]);

  /// Error message describing the exception
  final String message;

  /// Optional original exception that caused this exception
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return 'McpServersException: $message$causedBy';
  }
}

/// Exception thrown when an MCP server is not found.
class McpServerNotFoundException extends McpServersException {
  /// Creates a new McpServerNotFoundException
  const McpServerNotFoundException(
    this.serverId, [
    Exception? cause,
  ]) : super('MCP server "$serverId" not found', cause);

  /// ID of the MCP server that was not found
  final String serverId;
}
