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

typedef _ToolValidationRequest = ({
  SkillTemplateToolToUpdate tool,
  SkillTemplateToolEntity existing,
  Map<String, SkillCredentialAttributeDefinition> credentialDefinitions,
});

class const UpdateSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository, {
  final CloudSkillStore? cloudStore,
  final SkillsRepository? skillsRepository,
  final SkillCredentialDefinitionsRepository?
  skillCredentialDefinitionsRepository,
}) {
  Future<SkillTemplateToolEntity> call(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async => _updateTool(toolId, await _validatedTool(toolId, tool));

  Future<SkillTemplateToolToUpdate> _validatedTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final templateJson = tool.templateJson;
    final inputsJson = tool.inputsJson;
    if (!_requiresValidation(templateJson, inputsJson)) return tool;

    await _validateExistingTool(toolId, tool);

    return _canonicalToolUpdate(tool, templateJson);
  }

  Future<void> _validateExistingTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final existing = await _existingTool(toolId);
    if (existing == null) {
      throw StateError('Skill template tool not found: $toolId');
    }
    final credentialDefinitions = await _credentialDefinitions(
      existing.skillId,
    );
    await _validateToolFields((
      tool: tool,
      existing: existing,
      credentialDefinitions: credentialDefinitions,
    ));
  }
}

extension _UpdateSkillTemplateValidationOperations
    on UpdateSkillTemplateToolUsecase {
  bool _requiresValidation(String? templateJson, String? inputsJson) =>
      templateJson != null || inputsJson != null;

  SkillTemplateToolToUpdate _canonicalToolUpdate(
    SkillTemplateToolToUpdate tool,
    String? templateJson,
  ) => templateJson == null
      ? tool
      : tool.copyWith(
          templateJson: canonicalSkillUrlTemplateJson(templateJson),
        );

  Future<void> _validateToolFields(_ToolValidationRequest request) async {
    validateSkillTemplateTool(
      templateJson: request.tool.templateJson ?? request.existing.templateJson,
      inputsJson: request.tool.inputsJson ?? request.existing.inputsJson,
      credentialDefinitions: request.credentialDefinitions,
    );
  }

  Future<SkillTemplateToolEntity?> _existingTool(String toolId) {
    final cloud = cloudStore;
    if (cloud != null) return cloud.tool(toolId);

    final repository = _skillTemplateToolsRepository;
    if (repository == null) return Future.value();

    return repository.getToolById(toolId);
  }

  Future<SkillTemplateToolEntity> _updateTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return await cloud.updateTool(toolId, tool);
    }
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return await repository.updateTool(toolId, tool);
  }
}

extension _UpdateSkillTemplateCredentialOperations
    on UpdateSkillTemplateToolUsecase {
  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitions(String skillId) async {
    final cloud = cloudStore;
    if (cloud != null) return _cloudCredentialDefinitions(cloud, skillId);

    return _localCredentialDefinitions(skillId);
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _cloudCredentialDefinitions(CloudSkillStore cloud, String skillId) async {
    final skill = await cloud.skill(skillId);
    final credentialDefinitionId = skill?.credentialDefinitionId;
    if (credentialDefinitionId == null) return const {};
    final definition = await cloud.definition(credentialDefinitionId);
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _localCredentialDefinitions(String skillId) async {
    final skillsRepository = this.skillsRepository;
    final definitionsRepository = this.skillCredentialDefinitionsRepository;
    if (skillsRepository == null || definitionsRepository == null) {
      return const {};
    }
    final skill = await skillsRepository.getSkillById(skillId);
    return _credentialDefinitionValues(
      definitionsRepository,
      skill?.credentialDefinitionId,
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

final ProviderFamily<UpdateSkillTemplateToolUsecase, String>
updateSkillTemplateToolUsecaseProvider =
    Provider.family<UpdateSkillTemplateToolUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UpdateSkillTemplateToolUsecase(
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
