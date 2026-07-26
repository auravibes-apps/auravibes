import 'package:auravibes_engine/src/tool_spec.dart';

const loadSkillToolName = 'load_skill';
const unloadSkillToolName = 'unload_skill';
const skillControlToolNames = <String>{
  loadSkillToolName,
  unloadSkillToolName,
};

List<ToolSpec> buildSkillControlToolSpecs({
  required Iterable<String> loadableSkillSlugs,
  required Iterable<String> loadedSkillSlugs,
}) {
  final loadable = loadableSkillSlugs.toSet().toList(growable: false);
  final loaded = loadedSkillSlugs.toSet().toList(growable: false);
  return [
    if (loadable.isNotEmpty)
      _skillControlToolSpec(
        name: loadSkillToolName,
        description: 'Load a skill for the current conversation.',
        skillSlugs: loadable,
      ),
    if (loaded.isNotEmpty)
      _skillControlToolSpec(
        name: unloadSkillToolName,
        description: 'Unload a skill from the current conversation.',
        skillSlugs: loaded,
      ),
  ];
}

ToolSpec _skillControlToolSpec({
  required String name,
  required String description,
  required Iterable<String> skillSlugs,
}) => ToolSpec(
  name: name,
  description: description,
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'slug': {
        'type': 'string',
        'enum': skillSlugs.toSet().toList(growable: false),
      },
    },
    'required': const ['slug'],
    'additionalProperties': false,
  },
);
