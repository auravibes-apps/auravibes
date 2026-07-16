import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class UpdateSkillTemplateToolUsecase {
  const UpdateSkillTemplateToolUsecase(
    this._skillTemplateToolsRepository, {
    this.cloudStore,
    this.skillsRepository,
    this.skillCredentialDefinitionsRepository,
  });

  final SkillTemplateToolsRepository? _skillTemplateToolsRepository;
  final CloudSkillStore? cloudStore;
  final SkillsRepository? skillsRepository;
  final SkillCredentialDefinitionsRepository?
  skillCredentialDefinitionsRepository;

  Future<SkillTemplateToolEntity> call(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final templateJson = tool.templateJson;
    final inputsJson = tool.inputsJson;
    var toolToUpdate = tool;
    if (templateJson != null || inputsJson != null) {
      final existing =
          await cloudStore?.tool(toolId) ??
          await _skillTemplateToolsRepository?.getToolById(toolId);
      if (existing == null) {
        throw StateError('Skill template tool not found: $toolId');
      }
      final credentialDefinitions = await _credentialDefinitions(
        existing.skillId,
      );
      validateSkillTemplateTool(
        templateJson: templateJson ?? existing.templateJson,
        inputsJson: inputsJson ?? existing.inputsJson,
        credentialDefinitions: credentialDefinitions,
      );
      if (templateJson != null) {
        toolToUpdate = tool.copyWith(
          templateJson: canonicalSkillUrlTemplateJson(templateJson),
        );
      }
    }

    final cloud = cloudStore;
    if (cloud != null) return cloud.updateTool(toolId, toolToUpdate);
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return repository.updateTool(toolId, toolToUpdate);
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitions(String skillId) async {
    final cloud = cloudStore;
    if (cloud != null) {
      final skill = await cloud.skill(skillId);
      final credentialDefinitionId = skill?.credentialDefinitionId;
      if (credentialDefinitionId == null) return const {};
      final definition = await cloud.definition(credentialDefinitionId);
      if (definition == null) return const {};

      return SkillCredentialAttributeDefinition.parseMap(
        definition.attributesJson,
      );
    }
    final skillsRepository = this.skillsRepository;
    final credentialDefinitionsRepository =
        skillCredentialDefinitionsRepository;
    if (skillsRepository == null || credentialDefinitionsRepository == null) {
      return const {};
    }
    final skill = await skillsRepository.getSkillById(skillId);
    final credentialDefinitionId = skill?.credentialDefinitionId;
    if (credentialDefinitionId == null) return const {};
    final definition = await credentialDefinitionsRepository.getDefinitionById(
      credentialDefinitionId,
    );
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }
}

final updateSkillTemplateToolUsecaseProvider =
    Provider<UpdateSkillTemplateToolUsecase>(
      (ref) {
        final cloud = ref.watch(cloudSkillStoreProvider);

        return UpdateSkillTemplateToolUsecase(
          cloud == null
              ? ref.watch(skillTemplateToolsRepositoryProvider)
              : null,
          cloudStore: cloud,
          skillsRepository: cloud == null
              ? ref.watch(skillsRepositoryProvider)
              : null,
          skillCredentialDefinitionsRepository: cloud == null
              ? ref.watch(skillCredentialDefinitionsRepositoryProvider)
              : null,
        );
      },
      dependencies: [cloudSkillStoreProvider],
    );
