import 'package:auravibes_engine/src/skill_context_messages.dart';

class const AppSkillResourceDefinition({
  required final String slug,
  required final String title,
  required final String description,
  required final String content,
}) {
  SkillResourceSummary get summary =>
      SkillResourceSummary(slug: slug, title: title, description: description);
}
