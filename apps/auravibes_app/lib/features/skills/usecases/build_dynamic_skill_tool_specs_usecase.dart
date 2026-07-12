import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show ToolSpec;
import 'package:riverpod/riverpod.dart';

const loadSkillToolName = 'load_skill';
const unloadSkillToolName = 'unload_skill';
const listSkillCredentialsToolName = 'list_skill_credentials';

class BuildDynamicSkillToolSpecsUsecase {
  const BuildDynamicSkillToolSpecsUsecase(
    this._listAvailableSkillsUsecase,
    this._appSkillRegistry,
    this._listAppSkillCredentialCandidatesUsecase,
  );

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;
  final AppSkillRegistry _appSkillRegistry;
  final ListAppSkillCredentialCandidatesUsecase
  _listAppSkillCredentialCandidatesUsecase;

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
    final credentialBackedSkills = _credentialBackedSkills(loadedSkills);

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
      if (credentialBackedSkills.isNotEmpty)
        _buildListCredentialsSpec(credentialBackedSkills),
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

    final buffer = StringBuffer(_actionDescription(action));
    for (final skill in skills) {
      buffer.write(
        ' ${skill.title} (${skill.slug}, ${skill.source.name}, '
        '${skill.kind.name}) - ${skill.description};',
      );
    }

    return buffer.toString();
  }

  String _actionDescription(String action) {
    return switch (action) {
      'Load' =>
        'Load a skill by slug. Loading adds skill tools to this conversation '
            'so they can be called. Eligible skills:',
      'Unload' =>
        'Unload a skill by slug. Unloading removes skill tools from this '
            'conversation; do not unload if you still need to call those '
            'tools. Eligible loaded skills:',
      _ => '$action a skill by slug. Eligible skills:',
    };
  }

  ToolSpec _buildListCredentialsSpec(List<AvailableSkill> skills) {
    return ToolSpec(
      name: listSkillCredentialsToolName,
      description:
          'List available saved credentials for a loaded skill. Returns '
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

  List<AvailableSkill> _credentialBackedSkills(
    List<AvailableSkill> loadedSkills,
  ) {
    final result = <AvailableSkill>[];
    for (final skill in loadedSkills) {
      if (skill.source == SkillSource.user &&
          skill.credentialDefinitionId != null) {
        result.add(skill);
        continue;
      }
      if (skill.source != SkillSource.app) continue;
      final appSkill = _appSkillRegistry.getBySlug(skill.slug);
      if (appSkill == null ||
          !_listAppSkillCredentialCandidatesUsecase.isCredentialRequired(
            appSkill,
          )) {
        continue;
      }
      result.add(skill);
    }

    return result;
  }
}

final buildDynamicSkillToolSpecsUsecaseProvider =
    Provider<BuildDynamicSkillToolSpecsUsecase>((ref) {
      return BuildDynamicSkillToolSpecsUsecase(
        ref.watch(listAvailableSkillsUsecaseProvider),
        ref.watch(appSkillRegistryProvider),
        ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
      );
    });
