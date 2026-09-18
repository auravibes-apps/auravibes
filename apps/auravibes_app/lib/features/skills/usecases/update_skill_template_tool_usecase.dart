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
  ) async => await _updateTool(toolId, await _validatedTool(toolId, tool));

  Future<SkillTemplateToolToUpdate> _validatedTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    if (!_requiresValidation(tool)) return tool;

    final existing = await _requiredExistingTool(toolId);
    final validated = await _validatedDefinition(existing, tool);
    validateSkillTemplateDefinition(validated);

    return tool.copyWith(
      definitionJson: validated.toJsonString(),
      templateJson: validated.legacyTemplateJson,
      inputsJson: validated.legacyInputsJson,
    );
  }

  Future<SkillTemplateToolEntity> _requiredExistingTool(String toolId) async {
    final existing = await _existingTool(toolId);
    if (existing == null) {
      throw StateError('Skill template tool not found: $toolId');
    }

    return existing;
  }

  Future<SkillTemplateDefinition> _validatedDefinition(
    SkillTemplateToolEntity existing,
    SkillTemplateToolToUpdate tool,
  ) async {
    final definition = _definition(tool, existing);
    final credentialDefinitionId = tool.clearCredentialDefinition
        ? null
        : tool.credentialDefinitionId ?? existing.credentialDefinitionId;
    final credentialDefinitions = await _credentialDefinitions(
      existing.skillId,
      credentialDefinitionId,
    );

    return definition.copyWith(
      credentialDefinitions: {
        ...definition.credentialDefinitions,
        ...credentialDefinitions,
      },
    );
  }
}

extension _UpdateSkillTemplateValidationOperations
    on UpdateSkillTemplateToolUsecase {
  bool _requiresValidation(SkillTemplateToolToUpdate tool) =>
      tool.definitionJson != null ||
      tool.templateJson != null ||
      tool.inputsJson != null;

  SkillTemplateDefinition _definition(
    SkillTemplateToolToUpdate value,
    SkillTemplateToolEntity existing,
  ) {
    final source = value.definitionJson;
    if (source != null && source.trim().isNotEmpty && source != '{}') {
      return SkillTemplateDefinition.fromJsonString(source);
    }
    final template = value.templateJson ?? existing.templateJson;
    final inputs = value.inputsJson ?? existing.inputsJson;

    return SkillTemplateDefinition.fromLegacyJson(
      templateJson: template,
      inputsJson: inputs,
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
    final definitionsRepository = this.skillCredentialDefinitionsRepository;
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
