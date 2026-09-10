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
class ResolvedTool {
  const ResolvedTool._({
    required this.type,
    required this.tableId,
    required this.toolIdentifier,
    required this.fullName,
    this.builtInTool,
    this.mcpServerId,
    this.mcpSlug,
    this.nativeTool,
    this.skillSlug,
    this.skillToolSlug,
    this.target,
  }) : isBuiltIn = type == ResolvedToolType.builtIn,
       isMcp = type == ResolvedToolType.mcp,
       isNative = type == ResolvedToolType.native,
       isSkillControl = type == ResolvedToolType.skillControl,
       isSkillCommand = type == ResolvedToolType.skillCommand,
       isSkillNative = type == ResolvedToolType.skillNative,
       isSkillTemplate = type == ResolvedToolType.skillTemplate;

  /// The type of tool (built-in or MCP).
  final ResolvedToolType type;

  /// The database table ID for permission checks.
  final String tableId;

  /// The tool identifier (for example, "calculator" or original MCP tool name).
  final String toolIdentifier;

  final UserToolType? builtInTool;
  final String? mcpServerId;
  final String? mcpSlug;
  final NativeToolType? nativeTool;
  final String? skillSlug;
  final String? skillToolSlug;
  final AgentResolvedToolName? target;
  final String fullName;
  final bool isBuiltIn;
  final bool isMcp;
  final bool isNative;
  final bool isSkillControl;
  final bool isSkillCommand;
  final bool isSkillNative;
  final bool isSkillTemplate;

  static ResolvedTool _create({
    required ResolvedToolType type,
    required String tableId,
    required String toolIdentifier,
    required String fullName,
    UserToolType? builtInTool,
    String? mcpServerId,
    String? mcpSlug,
    NativeToolType? nativeTool,
    String? skillSlug,
    String? skillToolSlug,
    AgentResolvedToolName? target,
  }) => ResolvedTool._(
    type: type,
    tableId: tableId,
    toolIdentifier: toolIdentifier,
    fullName: fullName,
    builtInTool: builtInTool,
    mcpServerId: mcpServerId,
    mcpSlug: mcpSlug,
    nativeTool: nativeTool,
    skillSlug: skillSlug,
    skillToolSlug: skillToolSlug,
    target: target,
  );

  /// Creates a resolved built-in tool.
  static ResolvedTool builtIn({
    required String tableId,
    required String toolIdentifier,
    required UserToolType tooltype,
  }) => _create(
    type: .builtIn,
    tableId: tableId,
    toolIdentifier: toolIdentifier,
    fullName: toolIdentifier,
    builtInTool: tooltype,
  );

  /// Creates a resolved MCP tool.
  static ResolvedTool mcp({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
    required String mcpSlug,
  }) => _create(
    type: .mcp,
    tableId: tableId,
    toolIdentifier: toolIdentifier,
    fullName: toolIdentifier,
    mcpServerId: mcpServerId,
    mcpSlug: mcpSlug,
  );

  static ResolvedTool native({
    required String tableId,
    required NativeToolType nativeToolType,
  }) => _create(
    type: .native,
    tableId: tableId,
    toolIdentifier: nativeToolType.value,
    fullName: nativeToolType.value,
    nativeTool: nativeToolType,
  );

  static ResolvedTool skillControl({required String toolIdentifier}) => _create(
    type: .skillControl,
    tableId: toolIdentifier,
    toolIdentifier: toolIdentifier,
    fullName: toolIdentifier,
  );

  static ResolvedTool skillCommand({
    required String commandName,
    AgentResolvedToolName? target,
  }) => _create(
    type: .skillCommand,
    tableId: commandName,
    toolIdentifier: commandName,
    fullName: target?.fullName ?? commandName,
    target: target,
  );

  static ResolvedTool skillTemplate({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) => _create(
    type: .skillTemplate,
    tableId: tableId,
    toolIdentifier: toolIdentifier,
    fullName: _skillTemplateName(tableId, skillSlug, toolIdentifier),
    skillSlug: skillSlug,
  );

  static ResolvedTool skillNative({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) => _create(
    type: .skillNative,
    tableId: tableId,
    toolIdentifier: toolIdentifier,
    fullName: _skillNativeName(tableId, skillSlug, toolIdentifier),
    skillSlug: skillSlug,
    skillToolSlug: toolIdentifier,
  );
}

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
