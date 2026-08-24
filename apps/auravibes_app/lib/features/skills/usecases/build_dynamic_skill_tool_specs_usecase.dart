import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show ToolSpec, buildSkillControlToolSpecs;
import 'package:riverpod/riverpod.dart';

abstract final class SkillToolNames {
  static const listCredentials = 'list_skill_credentials';
}

class BuildDynamicSkillToolSpecsUsecase {
  const BuildDynamicSkillToolSpecsUsecase(
    this._listAvailableSkillsUsecase,
    this._appSkillRegistry,
    this._listAppSkillCredentialCandidatesUsecase,
  );

  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase;
  final AppSkillRegistry _appSkillRegistry;
  final ListAppSkillCredentialCandidatesUsecase
  _listAppSkillCredentialCandidatesUsecase;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadableSkills = await _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loadable,
    );
    final loadedSkills = await _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final credentialBackedSkills = _credentialBackedSkills(loadedSkills);

    return [
      ...buildSkillControlToolSpecs(
        loadableSkillSlugs: loadableSkills.map((skill) => skill.slug),
        loadedSkillSlugs: loadedSkills.map((skill) => skill.slug),
      ),
      if (credentialBackedSkills.isNotEmpty)
        _buildListCredentialsSpec(credentialBackedSkills),
    ];
  }

  ToolSpec _buildListCredentialsSpec(List<AvailableSkill> skills) {
    return ToolSpec(
      name: SkillToolNames.listCredentials,
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
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(appSkillRegistryProvider),
        ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
      );
    });
