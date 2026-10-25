import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

enum ResolvedToolType {
  builtIn,
  mcp,
  native,
  skillControl,
  connectorCommand,
  skillNative,
}

/// Represents a resolved tool that can be built-in, native, or MCP.
///
/// This abstraction allows the tool calling manager to handle both types
/// uniformly while preserving the necessary information for execution.
class ResolvedTool._({
  required final ResolvedToolType type,
  required final String tableId,
  required final String toolIdentifier,
  required final String fullName,
  final UserToolType? builtInTool,
  final String? mcpServerId,
  final String? mcpSlug,
  final String? outputSchemaJson,
  final NativeToolType? nativeTool,
  final String? skillSlug,
  final String? skillToolSlug,
}) {
  /// Creates a resolved MCP tool.
  static const ResolvedTool Function({
    required String tableId,
    required String toolIdentifier,
    required ({String mcpServerId, String mcpSlug, String? outputSchemaJson})
    mcp,
  })
  mcp = _mcp;

  /// Creates a resolved built-in tool.
  static const ResolvedTool Function({
    required String tableId,
    required String toolIdentifier,
    required UserToolType tooltype,
  })
  builtIn = _builtIn;

  static const ResolvedTool Function({
    required String tableId,
    required NativeToolType nativeToolType,
  })
  native = _native;

  static const ResolvedTool Function({required String toolIdentifier})
  skillControl = _skillControl;

  static const ResolvedTool Function({required String commandName})
  connectorCommand = _connectorCommand;

  static const ResolvedTool Function({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  })
  skillNative = _skillNative;

  static ResolvedTool workspaceCommand() => ResolvedTool._(
    type: .builtIn,
    tableId: workspaceCommandTableId,
    toolIdentifier: workspaceCommandToolName,
    fullName: workspaceCommandToolName,
  );
  bool get isWorkspaceCommand =>
      tableId == workspaceCommandTableId &&
      toolIdentifier == workspaceCommandToolName &&
      type == .builtIn;

  final bool isBuiltIn = type == .builtIn;
  final bool isMcp = type == .mcp;
  final bool isNative = type == .native;
  final bool isSkillControl = type == .skillControl;
  final bool isConnectorCommand = type == .connectorCommand;
  final bool isSkillNative = type == .skillNative;
}

ResolvedTool _mcp({
  required String tableId,
  required String toolIdentifier,
  required ({String mcpServerId, String mcpSlug, String? outputSchemaJson}) mcp,
}) => ResolvedTool._(
  type: .mcp,
  tableId: tableId,
  toolIdentifier: toolIdentifier,
  fullName: toolIdentifier,
  mcpServerId: mcp.mcpServerId,
  mcpSlug: mcp.mcpSlug,
  outputSchemaJson: mcp.outputSchemaJson,
);

ResolvedTool _builtIn({
  required String tableId,
  required String toolIdentifier,
  required UserToolType tooltype,
}) => ResolvedTool._(
  type: .builtIn,
  tableId: tableId,
  toolIdentifier: toolIdentifier,
  fullName: toolIdentifier,
  builtInTool: tooltype,
);

ResolvedTool _native({
  required String tableId,
  required NativeToolType nativeToolType,
}) => ResolvedTool._(
  type: .native,
  tableId: tableId,
  toolIdentifier: nativeToolType.value,
  fullName: nativeToolType.value,
  nativeTool: nativeToolType,
);

ResolvedTool _skillControl({required String toolIdentifier}) => ResolvedTool._(
  type: .skillControl,
  tableId: toolIdentifier,
  toolIdentifier: toolIdentifier,
  fullName: toolIdentifier,
);

ResolvedTool _connectorCommand({required String commandName}) => ResolvedTool._(
  type: .connectorCommand,
  tableId: commandName,
  toolIdentifier: commandName,
  fullName: commandName,
);

ResolvedTool _skillNative({
  required String tableId,
  required String skillSlug,
  required String toolIdentifier,
}) => ResolvedTool._(
  type: .skillNative,
  tableId: tableId,
  toolIdentifier: toolIdentifier,
  fullName: _skillNativeName(tableId, skillSlug, toolIdentifier),
  skillSlug: skillSlug,
  skillToolSlug: toolIdentifier,
);

String _skillNativeName(String tableId, String skillSlug, String tool) =>
    AgentResolvedToolName.skillNative(
      tableId: tableId,
      skillSlug: skillSlug,
      toolIdentifier: tool,
    ).fullName;
