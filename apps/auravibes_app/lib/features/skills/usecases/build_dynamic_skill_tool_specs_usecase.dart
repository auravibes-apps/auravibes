import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:riverpod/riverpod.dart';

const loadSkillToolName = 'load_skill';
const unloadSkillToolName = 'unload_skill';
const listSkillCredentialsToolName = 'list_skill_credentials';

class BuildDynamicSkillToolSpecsUsecase {
  const BuildDynamicSkillToolSpecsUsecase(this._listAvailableSkillsUsecase);

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadableSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loadable,
    );
    final loadedSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );

    return [
      if (loadableSkills.isNotEmpty)
        _buildSpec(
          name: loadSkillToolName,
          action: 'Load',
          skills: loadableSkills,
        ),
      if (loadedSkills.isNotEmpty)
        _buildSpec(
          name: unloadSkillToolName,
          action: 'Unload',
          skills: loadedSkills,
        ),
      if (loadedSkills.any(
        (skill) =>
            skill.source == SkillSource.user &&
            skill.credentialDefinitionId != null,
      ))
        _buildListCredentialsSpec(loadedSkills),
    ];
  }

  ToolSpec _buildSpec({
    required String name,
    required String action,
    required List<AvailableSkill> skills,
  }) {
    return ToolSpec(
      name: name,
      description: _description(action, skills),
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          'slug': {
            'type': 'string',
            'enum': [for (final skill in skills) skill.slug],
            'description': 'Skill slug to ${action.toLowerCase()}.',
          },
        },
        'required': const ['slug'],
        'additionalProperties': false,
      },
    );
  }

  String _description(String action, List<AvailableSkill> skills) {
    if (skills.isEmpty) {
      return '$action a skill. No skills are currently eligible.';
    }

    final buffer = StringBuffer('$action a skill by slug. Eligible skills:');
    for (final skill in skills) {
      buffer.write(
        ' ${skill.title} (${skill.slug}, ${skill.source.name}, '
        '${skill.kind.name}) - ${skill.description};',
      );
    }

    return buffer.toString();
  }

  ToolSpec _buildListCredentialsSpec(List<AvailableSkill> loadedSkills) {
    final skills = loadedSkills
        .where(
          (skill) =>
              skill.source == SkillSource.user &&
              skill.credentialDefinitionId != null,
        )
        .toList();

    return ToolSpec(
      name: listSkillCredentialsToolName,
      description:
          'List available saved credentials for a loaded user skill. Returns '
          'credential id and name only, never secret values.',
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          'skillSlug': {
            'type': 'string',
            'enum': [for (final skill in skills) skill.slug],
            'description': 'Loaded skill slug.',
          },
        },
        'required': const ['skillSlug'],
        'additionalProperties': false,
      },
    );
  }
}

final buildDynamicSkillToolSpecsUsecaseProvider =
    Provider<BuildDynamicSkillToolSpecsUsecase>((ref) {
      return BuildDynamicSkillToolSpecsUsecase(
        ref.watch(listAvailableSkillsUsecaseProvider),
      );
    });
