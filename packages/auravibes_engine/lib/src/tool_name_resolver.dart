enum AgentResolvedToolKind {
  builtIn,
  mcp,
  native,
  skillControl,
  skillNative,
  skillTemplate,
}

class AgentResolvedToolName {
  const AgentResolvedToolName._({
    required this.kind,
    required this.tableId,
    required this.toolIdentifier,
    this.mcpServerId,
    this.skillSlug,
    this.skillToolSlug,
  });

  factory AgentResolvedToolName.builtIn({
    required String tableId,
    required String toolIdentifier,
  }) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.builtIn,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  factory AgentResolvedToolName.mcp({
    required String tableId,
    required String toolIdentifier,
    required String mcpServerId,
  }) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.mcp,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
      mcpServerId: mcpServerId,
    );
  }

  factory AgentResolvedToolName.native({
    required String tableId,
    required String toolIdentifier,
  }) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.native,
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  factory AgentResolvedToolName.skillControl({
    required String toolIdentifier,
  }) {
    return AgentResolvedToolName._(
      kind: AgentResolvedToolKind.skillControl,
      tableId: toolIdentifier,
      toolIdentifier: toolIdentifier,
    );
  }

  factory AgentResolvedToolName.skillTemplate({
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

  factory AgentResolvedToolName.skillNative({
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

  final AgentResolvedToolKind kind;
  final String tableId;
  final String toolIdentifier;
  final String? mcpServerId;
  final String? skillSlug;
  final String? skillToolSlug;

  String get fullName {
    if (kind == AgentResolvedToolKind.skillTemplate) {
      return 'skill__user__${skillSlug}__$toolIdentifier';
    }
    if (kind == AgentResolvedToolKind.skillNative) {
      return 'skill__app__${skillSlug}__$toolIdentifier';
    }

    return toolIdentifier;
  }
}

class AgentToolNameResolver {
  const AgentToolNameResolver({
    this.skillControlToolNames = const <String>{},
  });

  final Set<String> skillControlToolNames;

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

  ({String mcpServerId, String toolIdentifier})? _parseMcpTool(
    String compositeId,
  ) {
    final match = RegExp(r'^mcp_([^_]+)_([^_]+)_(.+)$').firstMatch(
      compositeId,
    );
    if (match == null) return null;

    final mcpId = match.group(1);
    final tool = match.group(3);
    if (mcpId == null || tool == null) return null;
    if (mcpId.isEmpty || tool.isEmpty) return null;

    return (mcpServerId: mcpId, toolIdentifier: tool);
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
