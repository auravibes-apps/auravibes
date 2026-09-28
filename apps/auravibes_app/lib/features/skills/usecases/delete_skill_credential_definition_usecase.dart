import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/credential_definition_schema.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const DeleteSkillCredentialDefinitionUsecase({
  final SkillCredentialDefinitionsRepository? definitionsRepository,
  final SkillCredentialsRepository? credentialsRepository,
  final SkillsRepository? skillsRepository,
  final SkillTemplateToolsRepository? toolsRepository,
  final CloudSkillStore? cloudStore,
}) {
  Future<bool> call(String definitionId) async {
    final definition = await _definition(definitionId);
    if (definition == null) return false;

    await _ensureUnlinked(definition, definitionId);

    return await _delete(definitionId);
  }

  Future<SkillCredentialDefinitionEntity?> _definition(String definitionId) {
    final cloud = cloudStore;
    if (cloud != null) return cloud.definition(definitionId);

    return definitionsRepository?.getDefinitionById(definitionId) ??
        Future<SkillCredentialDefinitionEntity?>.value();
  }

  Future<void> _ensureUnlinked(
    SkillCredentialDefinitionEntity definition,
    String definitionId,
  ) async {
    final credentialCount = await _credentialCount(
      definition.workspaceId,
      definitionId,
    );
    if (credentialCount == 0) return;

    final links = await _referenceCounts(definition.workspaceId, definitionId);
    throw CredentialDefinitionConflictException(
      reason: .deletion,
      credentialCount: credentialCount,
      skillCount: links.skills,
      toolCount: links.tools,
    );
  }

  Future<bool> _delete(String definitionId) async {
    final cloud = cloudStore;
    if (cloud != null) {
      await cloud.deleteDefinition(definitionId);
      return true;
    }
    final repository = definitionsRepository;
    if (repository == null) {
      throw StateError('Credential definition store is unavailable');
    }
    return await repository.deleteDefinition(definitionId);
  }

  Future<int> _credentialCount(String workspaceId, String definitionId) {
    final cloud = cloudStore;
    if (cloud != null) return cloud.linkedCredentialCount(definitionId);
    final repository = credentialsRepository;
    if (repository == null) {
      throw StateError('Skill credentials repository is unavailable');
    }
    return repository.countLinkedCredentials(
      workspaceId: workspaceId,
      credentialDefinitionId: definitionId,
    );
  }

  Future<({int skills, int tools})> _referenceCounts(
    String workspaceId,
    String definitionId,
  ) async {
    final skills = await _skillsForWorkspace(workspaceId);
    var toolCount = 0;
    for (final skill in skills) {
      toolCount += await _toolReferenceCount(skill, definitionId);
    }
    final skillCount = skills
        .where((skill) => skill.credentialDefinitionId == definitionId)
        .length;

    return (skills: skillCount, tools: toolCount);
  }

  Future<int> _toolReferenceCount(
    SkillEntity skill,
    String definitionId,
  ) async {
    final tools = await _toolsForSkill(skill);

    return tools
        .where(
          (tool) =>
              (tool.credentialDefinitionId ?? skill.credentialDefinitionId) ==
              definitionId,
        )
        .length;
  }

  Future<List<SkillEntity>> _skillsForWorkspace(String workspaceId) {
    final cloud = cloudStore;
    if (cloud != null) return cloud.skills();
    final repository = skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');
    return repository.getWorkspaceSkills(workspaceId);
  }

  Future<List<SkillTemplateToolEntity>> _toolsForSkill(SkillEntity skill) {
    final cloud = cloudStore;
    if (cloud != null) return cloud.tools(skill.id);
    final repository = toolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }
    return repository.getSkillTools(skill.id);
  }
}

final ProviderFamily<DeleteSkillCredentialDefinitionUsecase, String>
deleteSkillCredentialDefinitionUsecaseProvider =
    Provider.family<DeleteSkillCredentialDefinitionUsecase, String>((
      ref,
      workspaceId,
    ) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));
      return DeleteSkillCredentialDefinitionUsecase(
        definitionsRepository: cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
        credentialsRepository: cloud == null
            ? ref.watch(skillCredentialsRepositoryProvider)
            : null,
        skillsRepository: cloud == null
            ? ref.watch(skillsRepositoryProvider)
            : null,
        toolsRepository: cloud == null
            ? ref.watch(skillTemplateToolsRepositoryProvider)
            : null,
        cloudStore: cloud,
      );
    });
