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
  final AppSkillDefinitionKind kind = AppSkillDefinitionKind.native,
  final List<AppSkillToolDefinition> tools = const [],
  final List<AppSkillResourceDefinition> resources = const [],
  final bool requiresCredential = false,
  final List<String> compatibleModelProviderIds = const [],
  final String? titleKey,
  final String? descriptionKey,
  final String? contentKey,
});

enum AppSkillDefinitionKind { native, template }
