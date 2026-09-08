import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';

class const AppSkillDefinition({
  required final String identifier,
  required final String slug,
  required final String title,
  required final String description,
  required final String content,
  final List<AppSkillToolDefinition> nativeTools = const [],
  final bool requiresCredential = false,
  final List<String> compatibleModelProviderIds = const [],
  final String? titleKey,
  final String? descriptionKey,
  final String? contentKey,
});
