import 'package:auravibes_engine/src/skills/skill_command.dart';
import 'package:auravibes_engine/src/tool_spec.dart';

@Deprecated('Use skillCommandToolNames instead.')
const Set<String> skillControlToolNames = skillCommandToolNames;

@Deprecated('Use buildSkillCommandToolSpecs() instead.')
List<ToolSpec> buildSkillControlToolSpecs({
  required Iterable<String> loadableSkillSlugs,
  required Iterable<String> loadedSkillSlugs,
}) => buildSkillCommandToolSpecs();
