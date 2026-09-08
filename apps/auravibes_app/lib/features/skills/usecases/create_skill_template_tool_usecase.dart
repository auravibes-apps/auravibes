// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/load_skill_credential_definitions_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/src/providers/provider.dart';

class const CreateSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository, {
  required final LoadSkillCredentialDefinitionsUsecase
  loadSkillCredentialDefinitions,
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillTemplateToolEntity> call(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final credentialDefinitions = await loadSkillCredentialDefinitions(skillId);
    validateSkillTemplateTool(
      templateJson: tool.templateJson,
      inputsJson: tool.inputsJson,
      credentialDefinitions: credentialDefinitions,
    );

    final canonical = tool.copyWith(
      templateJson: canonicalSkillUrlTemplateJson(tool.templateJson),
    );
    final cloud = cloudStore;
    if (cloud != null) return await cloud.createTool(skillId, canonical);
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return await repository.createTool(skillId, canonical);
  }
}

final ProviderFamily<CreateSkillTemplateToolUsecase, String>
createSkillTemplateToolUsecaseProvider =
    Provider.family<CreateSkillTemplateToolUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return CreateSkillTemplateToolUsecase(
        cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
        loadSkillCredentialDefinitions: ref.watch(
          loadSkillCredentialDefinitionsUsecaseProvider(workspaceId),
        ),
        cloudStore: cloud,
      );
    });
