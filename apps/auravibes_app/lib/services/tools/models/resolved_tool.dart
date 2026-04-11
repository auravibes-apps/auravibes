import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';

enum ResolvedToolType {
  builtIn,
  mcp,
  native,
}

/// Represents a resolved tool that can be built-in, native, or MCP.
///
/// This abstraction allows the tool calling manager to handle both types
/// uniformly while preserving the necessary information for execution.
class ResolvedTool {
  const ResolvedTool._({
    required this.type,
    required this.tableId,
    required this.toolIdentifier,
    this.builtInTool,
    this.mcpServerId,
    this.nativeTool,
  });

  /// Creates a resolved built-in tool.
  factory ResolvedTool.builtIn({
    required String tableId,
    required String toolIdentifier,
    required UserToolType tooltype,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.builtIn,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      builtInTool: tooltype,
    );
  }

  /// Creates a resolved MCP tool.
  factory ResolvedTool.mcp({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.mcp,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      mcpServerId: mcpServerId,
    );
  }

  factory ResolvedTool.native({
    required String tableId,
    required String toolIdentifier,
    required NativeToolType nativeToolType,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.native,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      nativeTool: nativeToolType,
    );
  }

  /// The type of tool (built-in or MCP)
  final ResolvedToolType type;

  /// The database table ID for permission checks
  final String tableId;

  /// The tool identifier (e.g., "calculator" or original MCP tool name)
  final String toolIdentifier;

  final UserToolType? builtInTool;

  final String? mcpServerId;

  final NativeToolType? nativeTool;

  bool get isBuiltIn => type == ResolvedToolType.builtIn;

  bool get isMcp => type == ResolvedToolType.mcp;

  bool get isNative => type == ResolvedToolType.native;
}

/// Internal class to hold tool resolution result.
class ToolResolution {
  const ToolResolution({
    required this.resolvedTool,
    required this.failureStatus,
  });

  final ResolvedTool? resolvedTool;

  /// The status to use if tool resolution failed (null if resolved)
  final ToolCallResultStatus? failureStatus;
}
