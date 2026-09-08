// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/load_skill_credential_definitions_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class const UpdateSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository, {
  required final LoadSkillCredentialDefinitionsUsecase
  loadSkillCredentialDefinitions,
  final CloudSkillStore? cloudStore,
}) {
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
      final credentialDefinitions = await loadSkillCredentialDefinitions(
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
    if (cloud != null) {
      return await cloud.updateTool(toolId, toolToUpdate);
    }
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return await repository.updateTool(toolId, toolToUpdate);
  }
}

final ProviderFamily<UpdateSkillTemplateToolUsecase, String>
updateSkillTemplateToolUsecaseProvider =
    Provider.family<UpdateSkillTemplateToolUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return UpdateSkillTemplateToolUsecase(
        cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
        loadSkillCredentialDefinitions: ref.watch(
          loadSkillCredentialDefinitionsUsecaseProvider(workspaceId),
        ),
        cloudStore: cloud,
      );
    });
