// Required: Existing argument values intentionally repeat.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';

class _BuiltInToolIdComponents {
  const _BuiltInToolIdComponents({
    required this.tableId,
    required this.toolIdentifier,
  });

  final String tableId;
  final String toolIdentifier;
}

class _NativeToolIdComponents {
  const _NativeToolIdComponents({
    required this.tableId,
    required this.toolIdentifier,
  });

  final String tableId;
  final String toolIdentifier;
}

class _SkillTemplateToolIdComponents {
  const _SkillTemplateToolIdComponents({
    required this.source,
    required this.skillSlug,
    required this.toolSlug,
  });

  final String source;
  final String skillSlug;
  final String toolSlug;
}

class ToolResolverService {
  // ============================================================.
  // Helper: Tool resolution.
  // ============================================================.

  /// Resolves a composite tool name to its implementation.
  ///
  /// Composite tool name formats:
  /// - Built-in: `built_in_<table_id>_<tool_identifier>`
  /// - MCP: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
  /// - Native: `native_<table_id>_<tool_identifier>`
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  ///
  /// Returns the resolved tool and null failureStatus, or null tool with
  /// failureStatus.

  ResolvedTool? resolveTool(String compositeToolName) {
    if (compositeToolName == loadSkillToolName ||
        compositeToolName == unloadSkillToolName ||
        compositeToolName == listSkillCredentialsToolName) {
      return ResolvedTool.skillControl(toolIdentifier: compositeToolName);
    }

    final skillTemplateTool = _parseSkillTemplateToolId(compositeToolName);
    if (skillTemplateTool != null) {
      if (skillTemplateTool.source == 'app') {
        return ResolvedTool.skillNative(
          tableId: skillTemplateTool.toolSlug,
          skillSlug: skillTemplateTool.skillSlug,
          toolIdentifier: skillTemplateTool.toolSlug,
        );
      }

      return ResolvedTool.skillTemplate(
        tableId: skillTemplateTool.toolSlug,
        skillSlug: skillTemplateTool.skillSlug,
        toolIdentifier: skillTemplateTool.toolSlug,
      );
    }

    final components = McpToolIdComponents.fromComposite(
      compositeToolName,
    );
    if (components != null) {
      return ResolvedTool.mcp(
        tableId: components.mcpServerId, // MCP server ID serves as table ID.
        toolIdentifier: components.toolIdentifier,
        mcpServerId: components.mcpServerId,
      );
    }

    final builtInTool = _parseBuiltInToolId(compositeToolName);

    if (builtInTool != null) {
      final toolType = UserToolType.fromValue(builtInTool.toolIdentifier);
      if (toolType != null) {
        return ResolvedTool.builtIn(
          tableId: builtInTool.tableId,
          toolIdentifier: builtInTool.toolIdentifier,
          tooltype: toolType,
        );
      }
    }

    final nativeTool = _parseNativeToolId(compositeToolName);
    if (nativeTool != null) {
      final toolType = NativeToolType.fromValue(nativeTool.toolIdentifier);
      if (toolType != null) {
        return ResolvedTool.native(
          tableId: nativeTool.tableId,
          nativeToolType: toolType,
        );
      }
    }

    return null;
  }

  /// Parses a built-in tool composite ID.
  ///
  /// Format: `built_in_<table_id>_<tool_identifier>`
  /// Returns null if the format is invalid.
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  static _BuiltInToolIdComponents? _parseBuiltInToolId(String compositeId) {
    final match = RegExp(r'^built_in_([^_]+)_(.+)$').firstMatch(compositeId);
    if (match == null) return null;

    final tableId = match.group(1);
    final toolIdentifier = match.group(2);
    if (tableId == null || toolIdentifier == null) return null;

    if (tableId.isEmpty || toolIdentifier.isEmpty) {
      return null;
    }

    return _BuiltInToolIdComponents(
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  static _NativeToolIdComponents? _parseNativeToolId(String compositeId) {
    final match = RegExp(r'^native_([^_]+)_(.+)$').firstMatch(compositeId);
    if (match == null) return null;

    final tableId = match.group(1);
    final toolIdentifier = match.group(2);
    if (tableId == null || toolIdentifier == null) return null;

    if (tableId.isEmpty || toolIdentifier.isEmpty) {
      return null;
    }

    return _NativeToolIdComponents(
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  static _SkillTemplateToolIdComponents? _parseSkillTemplateToolId(
    String compositeId,
  ) {
    const userPrefix = 'skill__user__';
    const appPrefix = 'skill__app__';
    final isUserTool = compositeId.startsWith(userPrefix);
    final isAppTool = compositeId.startsWith(appPrefix);
    if (!isUserTool && !isAppTool) return null;

    final source = isUserTool ? 'user' : 'app';
    final prefix = isUserTool ? userPrefix : appPrefix;
    final match = RegExp(
      '^${RegExp.escape(prefix)}'
      r'(.+)__(.+)$',
    ).firstMatch(compositeId);
    if (match == null) return null;

    final skillSlug = match.group(1);
    final toolSlug = match.group(2);
    if (skillSlug == null || toolSlug == null) return null;
    if (skillSlug.isEmpty || toolSlug.isEmpty) return null;

    return _SkillTemplateToolIdComponents(
      source: source,
      skillSlug: skillSlug,
      toolSlug: toolSlug,
    );
  }
}
