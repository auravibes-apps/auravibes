import 'package:auravibes_engine/src/skills/skill_command.dart';

enum AgentResolvedToolKind {
  builtIn,
  mcp,
  native,
  skillControl,
  skillNative,
  skillTemplate,
}

class const AgentResolvedToolName._({
  required final AgentResolvedToolKind kind,
  required final String tableId,
  required final String toolIdentifier,
  final String? mcpServerId,
  final String? mcpSlug,
  final String? skillSlug,
  final String? skillToolSlug,
}) {
  factory builtIn({required String tableId, required String toolIdentifier}) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.builtIn,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  factory mcp({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
    required String mcpSlug,
  }) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.mcp,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      mcpServerId: mcpServerId,
      mcpSlug: mcpSlug,
    );
  }

  factory native({required String tableId, required String toolIdentifier}) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.native,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  factory skillControl({required String toolIdentifier}) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.skillControl,
      tableId: toolIdentifier,
      toolIdentifier: toolIdentifier,
    );
  }

  factory skillTemplate({
    required String tableId,
    required String skillSlug,
    required String toolIdentifier,
  }) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.skillTemplate,
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
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.skillNative,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      skillSlug: skillSlug,
      skillToolSlug: toolIdentifier,
    );
  }

  String get fullName {
    return switch (kind) {
      AgentResolvedToolKind.builtIn => 'built_in_${tableId}_$toolIdentifier',
      AgentResolvedToolKind.mcp =>
        'mcp_${mcpServerId}_${mcpSlug}_$toolIdentifier',
      AgentResolvedToolKind.native => 'native_${tableId}_$toolIdentifier',
      AgentResolvedToolKind.skillControl => toolIdentifier,
      AgentResolvedToolKind.skillTemplate =>
        'skill__user__${skillSlug}__$toolIdentifier',
      AgentResolvedToolKind.skillNative =>
        'skill__app__${skillSlug}__$toolIdentifier',
    };
  }

  bool get isSkill =>
      kind == AgentResolvedToolKind.skillTemplate ||
      kind == AgentResolvedToolKind.skillNative;
}

class const AgentToolNameResolver({
  final Set<String> skillControlToolNames = skillCommandToolNames,
}) {
  AgentResolvedToolName? resolve(String compositeToolName) {
    if (skillControlToolNames.contains(compositeToolName)) {
      return AgentResolvedToolName.skillControl(
        toolIdentifier: compositeToolName,
      );
    }

    final skillTool = _parseSkillToolName(compositeToolName);
    if (skillTool != null) {
      if (skillTool.source == 'app') {
        return AgentResolvedToolName.skillNative(
          tableId: skillTool.toolSlug,
          skillSlug: skillTool.skillSlug,
          toolIdentifier: skillTool.toolSlug,
        );
      }

      return AgentResolvedToolName.skillTemplate(
        tableId: skillTool.toolSlug,
        skillSlug: skillTool.skillSlug,
        toolIdentifier: skillTool.toolSlug,
      );
    }

    final mcpTool = _parseMcpTool(compositeToolName);
    if (mcpTool != null) {
      return AgentResolvedToolName.mcp(
        tableId: mcpTool.mcpServerId,
        toolIdentifier: mcpTool.toolIdentifier,
        mcpServerId: mcpTool.mcpServerId,
        mcpSlug: mcpTool.mcpSlug,
      );
    }

    final builtInTool = _parseTableTool(compositeToolName, 'built_in');
    if (builtInTool != null) {
      return AgentResolvedToolName.builtIn(
        tableId: builtInTool.tableId,
        toolIdentifier: builtInTool.toolIdentifier,
      );
    }

    final nativeTool = _parseTableTool(compositeToolName, 'native');
    if (nativeTool != null) {
      return AgentResolvedToolName.native(
        tableId: nativeTool.tableId,
        toolIdentifier: nativeTool.toolIdentifier,
      );
    }

    return null;
  }

  ({String mcpServerId, String mcpSlug, String toolIdentifier})? _parseMcpTool(
    String compositeId,
  ) {
    final match = RegExp(r'^mcp_([^_]+)_([^_]+)_(.+)$').firstMatch(compositeId);
    if (match == null) return null;

    final mcpId = match.group(1);
    final mcpSlug = match.group(2);
    final tool = match.group(3);
    if (mcpId == null || mcpSlug == null || tool == null) return null;
    if (mcpId.isEmpty || mcpSlug.isEmpty || tool.isEmpty) return null;

    return (mcpServerId: mcpId, mcpSlug: mcpSlug, toolIdentifier: tool);
  }

  ({String tableId, String toolIdentifier})? _parseTableTool(
    String value,
    String prefix,
  ) {
    final match = RegExp(
      '^${RegExp.escape(prefix)}'
      r'_([^_]+)_(.+)$',
    ).firstMatch(value);
    if (match == null) return null;

    final tableId = match.group(1);
    final toolIdentifier = match.group(2);
    if (tableId == null || toolIdentifier == null) return null;
    if (tableId.isEmpty || toolIdentifier.isEmpty) return null;

    return (tableId: tableId, toolIdentifier: toolIdentifier);
  }

  ({String source, String skillSlug, String toolSlug})? _parseSkillToolName(
    String compositeId,
  ) {
    return switch (compositeId.split('__')) {
      ['skill', final source, final skillSlug, final toolSlug]
          when (source == 'user' || source == 'app') &&
              skillSlug.isNotEmpty &&
              toolSlug.isNotEmpty =>
        (source: source, skillSlug: skillSlug, toolSlug: toolSlug),
      _ => null,
    };
  }
}

String generateSkillSlug(String title) {
  return title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
}
