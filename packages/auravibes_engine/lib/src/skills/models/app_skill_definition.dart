import 'package:auravibes_engine/src/skill_context_messages.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';

class const AppSkillResourceDefinition({
  required final String slug,
  required final String title,
  required final String description,
  required final String content,
}) {
  SkillResourceSummary get summary =>
      SkillResourceSummary(slug: slug, title: title, description: description);
}

class const AppSkillDefinition({
  required final String identifier,
  required final String slug,
  required final String title,
  required final String description,
  required final String content,
  final List<AppSkillToolDefinition> tools = const [],
  final List<String> connectorToolIds = const [],
  final List<AppSkillResourceDefinition> resources = const [],
  final bool contentOnly = false,
  final String? titleKey,
  final String? descriptionKey,
  final String? contentKey,
});
