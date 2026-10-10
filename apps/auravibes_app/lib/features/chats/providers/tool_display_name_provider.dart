// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/tools/providers/mcp_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tool_display_name_provider.g.dart';

typedef SkillToolCallDisplayTitles = ({
  String skillId,
  SkillSource skillSource,
  String skillTitle,
  String? skillTitleKey,
  String? toolTitle,
  String? toolTitleKey,
  String? toolDescription,
  String? toolDescriptionKey,
});

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Callers may pass a presentation-only effective target while retaining the
/// original tool-call identity for approval actions.
/// Uses Riverpod's family caching to avoid repeated lookups.
@riverpod
Future<String> toolDisplayName(
  Ref ref,
  String workspaceId,
  String compositeToolId,
) async {
  final presentationTarget = ToolNameFormatter.parse(compositeToolId);

  // For MCP tools, try to get the original server name.
  String? mcpServerName;
  final mcpServerId = presentationTarget?.mcpServerId;
  if (mcpServerId != null) {
    mcpServerName = await ref.watch(
      mcpServerNameProvider(workspaceId, mcpServerId).future,
    );
  }

  return ToolNameFormatter.formatDisplayName(
    presentationTarget,
    rawName: compositeToolId,
    mcpServerName: mcpServerName,
  );
}

@riverpod
Future<SkillToolCallDisplayTitles?> skillToolCallDisplayTitles(
  Ref ref,
  String workspaceId,
  String skillSlug,
  String toolSlug,
) => _resolveSkillToolCallDisplayTitles(ref, workspaceId, skillSlug, toolSlug);

typedef _SkillToolMetadata = ({
  String? title,
  String? titleKey,
  String? description,
  String? descriptionKey,
});

Future<SkillToolCallDisplayTitles?> _resolveSkillToolCallDisplayTitles(
  Ref ref,
  String workspaceId,
  String skillSlug,
  String toolSlug,
) async {
  final skill = await _workspaceSkillBySlug(ref, workspaceId, skillSlug);
  if (skill == null) return null;

  final toolMetadata = await _toolTitlesForSkill(
    ref,
    workspaceId,
    skill,
    toolSlug,
  );

  return (
    skillId: skill.id,
    skillSource: skill.source,
    skillTitle: skill.title,
    skillTitleKey: skill.titleKey,
    toolTitle: toolMetadata.title,
    toolTitleKey: toolMetadata.titleKey,
    toolDescription: toolMetadata.description,
    toolDescriptionKey: toolMetadata.descriptionKey,
  );
}

Future<WorkspaceSkill?> _workspaceSkillBySlug(
  Ref ref,
  String workspaceId,
  String skillSlug,
) async {
  final skills = await ref.watch(workspaceSkillsProvider(workspaceId).future);

  return skills.where((skill) => skill.slug == skillSlug).firstOrNull;
}

Future<_SkillToolMetadata> _toolTitlesForSkill(
  Ref ref,
  String workspaceId,
  WorkspaceSkill skill,
  String toolSlug,
) async {
  if (skill.source == SkillSource.app) {
    return _appSkillToolTitles(ref, skill, toolSlug);
  }
  if (skill.kind != SkillKind.template) {
    return (
      title: null,
      titleKey: null,
      description: null,
      descriptionKey: null,
    );
  }

  return await _templateSkillToolTitles(ref, workspaceId, skill.id, toolSlug);
}

_SkillToolMetadata _appSkillToolTitles(
  Ref ref,
  WorkspaceSkill skill,
  String toolSlug,
) {
  final appSkill = ref
      .watch(appSkillRegistryProvider)
      .getByIdentifier(skill.id);
  final tool = appSkill?.tools
      .where((tool) => tool.slug == toolSlug)
      .firstOrNull;

  return (
    title: tool?.title,
    titleKey: tool?.titleKey,
    description: tool?.description,
    descriptionKey: tool?.descriptionKey,
  );
}

Future<_SkillToolMetadata> _templateSkillToolTitles(
  Ref ref,
  String workspaceId,
  String skillId,
  String toolSlug,
) async {
  final tools = await ref.watch(
    skillTemplateToolsProvider(workspaceId, skillId).future,
  );
  final tool = tools.where((tool) => tool.slug == toolSlug).firstOrNull;

  return (
    title: tool?.title,
    titleKey: null,
    description: tool?.description,
    descriptionKey: null,
  );
}

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.
@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<String?> mcpServerName(
  Ref ref,
  String workspaceId,
  String mcpServerId,
) async {
  try {
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    final repository = ref.read(mcpServersRepositoryProvider(session));
    final server = await repository.getMcpServerById(mcpServerId);

    return server?.name;
  } on Exception {
    // Ignore errors, fall back to null (will use slug name).
    return null;
  }
}
