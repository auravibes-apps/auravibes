// Required: Existing argument values intentionally repeat.
import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';

class ToolResolverService {
  const ToolResolverService([this._resolver = _defaultResolver]);

  static const _defaultResolver = AgentToolNameResolver(
    skillControlToolNames: {
      loadSkillToolName,
      unloadSkillToolName,
      listSkillCredentialsToolName,
    },
  );

  final AgentToolNameResolver _resolver;

  ResolvedTool? resolveTool(String compositeToolName) {
    final resolved = _resolver.resolve(compositeToolName);
    if (resolved == null) return null;

    return switch (resolved.kind) {
      AgentResolvedToolKind.skillControl => ResolvedTool.skillControl(
        toolIdentifier: resolved.toolIdentifier,
      ),
      AgentResolvedToolKind.skillNative => ResolvedTool.skillNative(
        tableId: resolved.tableId,
        skillSlug: resolved.skillSlug ?? '',
        toolIdentifier: resolved.toolIdentifier,
      ),
      AgentResolvedToolKind.skillTemplate => ResolvedTool.skillTemplate(
        tableId: resolved.tableId,
        skillSlug: resolved.skillSlug ?? '',
        toolIdentifier: resolved.toolIdentifier,
      ),
      AgentResolvedToolKind.mcp => ResolvedTool.mcp(
        tableId: resolved.tableId,
        toolIdentifier: resolved.toolIdentifier,
        mcpServerId: resolved.mcpServerId ?? '',
      ),
      AgentResolvedToolKind.builtIn => _resolveBuiltInTool(resolved),
      AgentResolvedToolKind.native => _resolveNativeTool(resolved),
    };
  }

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
