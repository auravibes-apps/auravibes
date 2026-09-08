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
class const ResolvedTool._({
  /// The type of tool (built-in or MCP).
  required final ResolvedToolType type,

  /// The database table ID for permission checks.
  required final String tableId,

  /// The tool identifier (for example, "calculator" or original MCP tool name).
  required final String toolIdentifier,
  final UserToolType? builtInTool,
  final String? mcpServerId,
  final String? mcpSlug,
  final NativeToolType? nativeTool,
  final String? skillSlug,
  final String? skillToolSlug,
  final AgentResolvedToolName? target,
}) {
  /// Creates a resolved built-in tool.
  factory builtIn({
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
  factory mcp({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
    required String mcpSlug,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.mcp,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      mcpServerId: mcpServerId,
      mcpSlug: mcpSlug,
    );
  }

  factory native({
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

  factory skillControl({required String toolIdentifier}) {
    return ResolvedTool._(
      type: ResolvedToolType.skillControl,
      tableId: toolIdentifier,
      toolIdentifier: toolIdentifier,
    );
  }

  factory skillCommand({
    required String commandName,
    AgentResolvedToolName? target,
  }) {
    return ResolvedTool._(
      type: ResolvedToolType.skillCommand,
      tableId: commandName,
      toolIdentifier: commandName,
      target: target,
    );
  }

  factory skillTemplate({
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

  factory skillNative({
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

  bool get isBuiltIn => type == ResolvedToolType.builtIn;

  bool get isMcp => type == ResolvedToolType.mcp;

  bool get isNative => type == ResolvedToolType.native;

  bool get isSkillControl => type == ResolvedToolType.skillControl;

  bool get isSkillCommand => type == ResolvedToolType.skillCommand;

  bool get isSkillNative => type == ResolvedToolType.skillNative;

  bool get isSkillTemplate => type == ResolvedToolType.skillTemplate;

  String get fullName => switch ((type: type, skillSlug: skillSlug)) {
    (type: ResolvedToolType.skillCommand, skillSlug: _) =>
      target?.fullName ?? toolIdentifier,
    (type: ResolvedToolType.skillTemplate, skillSlug: final skillSlug?) =>
      AgentResolvedToolName.skillTemplate(
        tableId: tableId,
        skillSlug: skillSlug,
        toolIdentifier: toolIdentifier,
      ).fullName,
    (type: ResolvedToolType.skillNative, skillSlug: final skillSlug?) =>
      AgentResolvedToolName.skillNative(
        tableId: tableId,
        skillSlug: skillSlug,
        toolIdentifier: toolIdentifier,
      ).fullName,
    (
      type: ResolvedToolType.skillTemplate || ResolvedToolType.skillNative,
      skillSlug: null,
    ) =>
      throw StateError('Skill tool requires a skill slug'),
    _ => toolIdentifier,
  };
}
