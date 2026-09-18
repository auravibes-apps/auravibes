import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const CreateSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository, {
  final CloudSkillStore? cloudStore,
  final SkillsRepository? skillsRepository,
  final SkillCredentialDefinitionsRepository?
  skillCredentialDefinitionsRepository,
}) {
  Future<SkillTemplateToolEntity> call(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final canonical = await _validatedTool(skillId, tool);

    return await _createTool(skillId, canonical);
  }

  Future<SkillTemplateToolEntity> _createTool(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.createTool(skillId, tool);
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return await repository.createTool(skillId, tool);
  }

  Future<SkillTemplateToolToCreate> _validatedTool(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final source = _definition(tool);
    final definition = source.copyWith(
      credentialDefinitions: {
        ...source.credentialDefinitions,
        ...await _credentialDefinitions(skillId, tool.credentialDefinitionId),
      },
    );
    validateSkillTemplateDefinition(definition);

    return tool.copyWith(
      definitionJson: definition.toJsonString(),
      templateJson: definition.legacyTemplateJson,
      inputsJson: definition.legacyInputsJson,
    );
  }

  SkillTemplateDefinition _definition(SkillTemplateToolToCreate tool) {
    final source = tool.definitionJson.trim();
    if (source.isNotEmpty && source != '{}') {
      return SkillTemplateDefinition.fromJsonString(source);
    }

    return SkillTemplateDefinition.fromLegacyJson(
      templateJson: tool.templateJson,
      inputsJson: tool.inputsJson,
    );
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitions(String skillId, String? toolDefinitionId) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return await _cloudCredentialDefinitions(
        cloud,
        skillId,
        toolDefinitionId,
      );
    }

    return await _localCredentialDefinitions(skillId, toolDefinitionId);
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _cloudCredentialDefinitions(
    CloudSkillStore cloud,
    String skillId,
    String? toolDefinitionId,
  ) async {
    final credentialDefinitionId =
        toolDefinitionId ??
        (await cloud.skill(skillId))?.credentialDefinitionId;
    if (credentialDefinitionId == null) return const {};
    final definition = await cloud.definition(credentialDefinitionId);
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _localCredentialDefinitions(String skillId, String? toolDefinitionId) async {
    final skillsRepository = this.skillsRepository;
    final definitionsRepository = skillCredentialDefinitionsRepository;
    if (skillsRepository == null || definitionsRepository == null) {
      return const {};
    }
    final skill = await skillsRepository.getSkillById(skillId);

    return await _credentialDefinitionValues(
      definitionsRepository,
      toolDefinitionId ?? skill?.credentialDefinitionId,
    );
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitionValues(
    SkillCredentialDefinitionsRepository repository,
    String? credentialDefinitionId,
  ) async {
    if (credentialDefinitionId == null) return const {};
    final definition = await repository.getDefinitionById(
      credentialDefinitionId,
    );
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }
}

final ProviderFamily<CreateSkillTemplateToolUsecase, String>
createSkillTemplateToolUsecaseProvider =
    Provider.family<CreateSkillTemplateToolUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return CreateSkillTemplateToolUsecase(
        cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
        cloudStore: cloud,
        skillsRepository: cloud == null
            ? ref.watch(skillsRepositoryProvider)
            : null,
        skillCredentialDefinitionsRepository: cloud == null
            ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
            : null,
      );
    });
