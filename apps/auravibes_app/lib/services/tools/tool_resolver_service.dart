// Required: Existing argument values intentionally repeat.
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ToolResolverService([
  final AgentToolNameResolver _resolver = _defaultResolver,
]) {
  static const _defaultResolver = AgentToolNameResolver();

  ResolvedTool? resolveTool(
    String modelToolName,
    ToolCatalog<ResolvedTool> catalog,
  ) {
    return catalog.resolve(modelToolName) ?? _resolveLegacyName(modelToolName);
  }

  ResolvedTool? _resolveLegacyName(String compositeToolName) {
    if (compositeToolName == listAgentsToolName ||
        compositeToolName == runSubAgentToolName) {
      return _resolveLegacyAgent(compositeToolName);
    }

    final resolved = _resolver.resolve(compositeToolName);
    if (resolved == null) return null;

    return _resolveResolvedTool(resolved);
  }

  ResolvedTool? _resolveResolvedTool(AgentResolvedToolName resolved) =>
      switch (resolved.kind) {
        .skillControl => ResolvedTool.skillCommand(
          commandName: resolved.toolIdentifier,
        ),
        .skillNative || .skillTemplate => _resolveSkillTool(resolved),
        .mcp => _resolveMcpTool(resolved),
        .builtIn => _resolveBuiltInTool(resolved),
        .native => _resolveNativeTool(resolved),
      };

  ResolvedTool _resolveSkillTool(AgentResolvedToolName resolved) {
    final skillSlug = resolved.skillSlug ?? '';
    if (resolved.kind == AgentResolvedToolKind.skillNative) {
      return ResolvedTool.skillNative(
        tableId: resolved.tableId,
        skillSlug: skillSlug,
        toolIdentifier: resolved.toolIdentifier,
      );
    }

    return ResolvedTool.skillTemplate(
      tableId: resolved.tableId,
      skillSlug: skillSlug,
      toolIdentifier: resolved.toolIdentifier,
    );
  }

  ResolvedTool _resolveMcpTool(AgentResolvedToolName resolved) =>
      ResolvedTool.mcp(
        tableId: resolved.tableId,
        toolIdentifier: resolved.toolIdentifier,
        mcpServerId: resolved.mcpServerId ?? '',
        mcpSlug: resolved.mcpSlug ?? '',
      );

  ResolvedTool _resolveLegacyAgent(String toolName) => ResolvedTool.skillNative(
    tableId: toolName,
    skillSlug: agentsSkillSlug,
    toolIdentifier: toolName,
  );

  ResolvedTool? _resolveBuiltInTool(AgentResolvedToolName resolved) {
    final toolType = UserToolType.fromValue(resolved.toolIdentifier);
    if (toolType == null) return null;

    return ResolvedTool.builtIn(
      tableId: resolved.tableId,
      toolIdentifier: resolved.toolIdentifier,
      tooltype: toolType,
    );
  }

  ResolvedTool? _resolveNativeTool(AgentResolvedToolName resolved) {
    final toolType = NativeToolType.fromValue(resolved.toolIdentifier);
    if (toolType == null) return null;

    return ResolvedTool.native(
      tableId: resolved.tableId,
      nativeToolType: toolType,
    );
  }
}
