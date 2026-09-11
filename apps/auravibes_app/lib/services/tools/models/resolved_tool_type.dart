import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

enum ResolvedToolType {
  builtIn,
  mcp,
  native,
  skillControl,
  skillCommand,
  skillNative,
  skillTemplate,
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
  final NativeToolType? nativeTool,
  final String? skillSlug,
  final String? skillToolSlug,
  final AgentResolvedToolName? target,
}) {
  /// Creates a resolved MCP tool.
  static final ResolvedTool Function({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
    required String mcpSlug,
  }) mcp = _mcp;

  /// Creates a resolved built-in tool.
  static final ResolvedTool Function({
    required String tableId,
    required String toolIdentifier,
    required UserToolType tooltype,
  }) builtIn = _builtIn;

  static final ResolvedTool Function({
    required String tableId,
    required NativeToolType nativeToolType,
  }) native = _native;

  static final ResolvedTool Function({required String toolIdentifier})
      skillControl = _skillControl;

  static final ResolvedTool Function({
    required String commandName,
    AgentResolvedToolName? target,
  }) skillCommand = _skillCommand;

  static final ResolvedTool Function({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) skillTemplate = _skillTemplate;

  static final ResolvedTool Function({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) skillNative = _skillNative;

  final bool isBuiltIn = type == .builtIn;
  final bool isMcp = type == .mcp;
  final bool isNative = type == .native;
  final bool isSkillControl = type == .skillControl;
  final bool isSkillCommand = type == .skillCommand;
  final bool isSkillNative = type == .skillNative;
  final bool isSkillTemplate = type == .skillTemplate;
}

ResolvedTool _mcp({
  required String tableId,
  required String toolIdentifier,
  required String mcpServerId,
  required String mcpSlug,
}) => ResolvedTool._(
  type: .mcp,
  tableId: tableId,
  toolIdentifier: toolIdentifier,
  fullName: toolIdentifier,
  mcpServerId: mcpServerId,
  mcpSlug: mcpSlug,
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

ResolvedTool _skillCommand({
  required String commandName,
  AgentResolvedToolName? target,
}) => ResolvedTool._(
  type: .skillCommand,
  tableId: commandName,
  toolIdentifier: commandName,
  fullName: target?.fullName ?? commandName,
  target: target,
);

ResolvedTool _skillTemplate({
  required String tableId,
  required String skillSlug,
  required String toolIdentifier,
}) => ResolvedTool._(
  type: .skillTemplate,
  tableId: tableId,
  toolIdentifier: toolIdentifier,
  fullName: _skillTemplateName(tableId, skillSlug, toolIdentifier),
  skillSlug: skillSlug,
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

String _skillTemplateName(String tableId, String skillSlug, String tool) =>
    AgentResolvedToolName.skillTemplate(
      tableId: tableId,
      skillSlug: skillSlug,
      toolIdentifier: tool,
    ).fullName;

String _skillNativeName(String tableId, String skillSlug, String tool) =>
    AgentResolvedToolName.skillNative(
      tableId: tableId,
      skillSlug: skillSlug,
      toolIdentifier: tool,
    ).fullName;
