import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';

enum ResolvedToolType {
  builtIn,
  mcp,
  native,
  skillControl,
  skillNative,
  skillTemplate,
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
    this.skillSlug,
    this.skillToolSlug,
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
    required NativeToolType nativeToolType,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.native,
      tableId: tableId,
      toolIdentifier: nativeToolType.value,
      nativeTool: nativeToolType,
    );
  }

  factory ResolvedTool.skillControl({
    required String toolIdentifier,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.skillControl,
      tableId: toolIdentifier,
      toolIdentifier: toolIdentifier,
    );
  }

  factory ResolvedTool.skillTemplate({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.skillTemplate,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      skillSlug: skillSlug,
    );
  }

  factory ResolvedTool.skillNative({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.skillNative,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      skillSlug: skillSlug,
      skillToolSlug: toolIdentifier,
    );
  }

  /// The type of tool (built-in or MCP).
  final ResolvedToolType type;

  /// The database table ID for permission checks.
  final String tableId;

  /// The tool identifier (for example, "calculator" or original MCP tool name).
  final String toolIdentifier;

  final UserToolType? builtInTool;

  final String? mcpServerId;

  final NativeToolType? nativeTool;

  final String? skillSlug;

  final String? skillToolSlug;

  bool get isBuiltIn => type == ResolvedToolType.builtIn;

  bool get isMcp => type == ResolvedToolType.mcp;

  bool get isNative => type == ResolvedToolType.native;

  bool get isSkillControl => type == ResolvedToolType.skillControl;

  bool get isSkillNative => type == ResolvedToolType.skillNative;

  bool get isSkillTemplate => type == ResolvedToolType.skillTemplate;
}
