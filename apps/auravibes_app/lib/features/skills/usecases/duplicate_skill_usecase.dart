// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:riverpod/src/providers/provider.dart';

class DuplicateSkillUsecase {
  const DuplicateSkillUsecase(
    this._skillsRepository,
    this._skillTemplateToolsRepository,
    this._createSkillUsecase, {
    this.cloudStore,
  });
  final CloudSkillStore? cloudStore;

  final SkillsRepository? _skillsRepository;
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository;
  final CreateSkillUsecase _createSkillUsecase;

  Future<SkillEntity> call(String skillId) async {
    final cloud = cloudStore;
    final skill = cloud != null
        ? await cloud.skill(skillId)
        : await _skillsRepository?.getSkillById(skillId);
    if (skill == null || skill.source != SkillSource.user) {
      throw StateError('User skill not found: $skillId');
    }

    final title = await _copyTitle(
      workspaceId: skill.workspaceId,
      originalTitle: skill.title,
    );
    final duplicate = await _createSkillUsecase.call(
      skill.workspaceId,
      SkillToCreate(
        kind: skill.kind,
        title: title,
        description: skill.description,
        content: skill.content,
        credentialDefinitionId: skill.credentialDefinitionId,
        isEnabled: skill.isEnabled,
      ),
    );
    final tools = cloud != null
        ? await cloud.tools(skill.id)
        : await _localTools(skill.id);
    for (final tool in tools) {
      final value = SkillTemplateToolToCreate(
        templateType: tool.templateType,
        title: tool.title,
        description: tool.description,
        templateJson: tool.templateJson,
        inputsJson: tool.inputsJson,
        isEnabled: tool.isEnabled,
      );
      if (cloud != null) {
        final _ = await cloud.createTool(duplicate.id, value);
        continue;
      }
      final repository = _skillTemplateToolsRepository;
      if (repository == null) {
        throw StateError('Skill template tool store is unavailable');
      }
      final _ = await repository.createTool(duplicate.id, value);
    }

    return duplicate;
  }

  Future<String> _copyTitle({
    required String workspaceId,
    required String originalTitle,
  }) async {
    var suffix = 1;
    while (true) {
      final title = suffix == 1
          ? '$originalTitle Copy'
          : '$originalTitle Copy $suffix';
      final cloud = cloudStore;
      final repository = _skillsRepository;
      final existing = switch ((cloud: cloud, repository: repository)) {
        (cloud: final cloud?, repository: _) =>
          (await cloud.skills())
              .where((item) => item.title == title)
              .firstOrNull,
        (cloud: _, repository: final repository?) =>
          await repository.getSkillByTitle(
            workspaceId,
            title,
          ),
        _ => throw StateError('Skill store is unavailable'),
      };
      if (existing == null) return title;
      suffix += 1;
    }
  }

  Future<List<SkillTemplateToolEntity>> _localTools(String skillId) {
    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }

    return repository.getSkillTools(skillId);
  }
}

final ProviderFamily<DuplicateSkillUsecase, String>
duplicateSkillUsecaseProvider = Provider.family<DuplicateSkillUsecase, String>(
  (ref, workspaceId) {
    final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

    return DuplicateSkillUsecase(
      cloud == null ? ref.watch(skillsRepositoryProvider) : null,
      cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
      ref.watch(createSkillUsecaseProvider(workspaceId)),
      cloudStore: cloud,
    );
  },
);
