import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const DuplicateSkillUsecase(
  final SkillsRepository? _skillsRepository,
  final SkillTemplateToolsRepository? _skillTemplateToolsRepository,
  final CreateSkillUsecase _createSkillUsecase, {
  final CloudSkillStore? cloudStore,
}) {
  Future<SkillEntity> call(String skillId) async {
    final skill = await _loadSkill(skillId);
    final title = await _copyTitle(
      workspaceId: skill.workspaceId,
      originalTitle: skill.title,
    );
    final duplicate = await _createSkill(skill, title);
    await _copyTools(skill.id, duplicate.id);

    return duplicate;
  }
}

extension on DuplicateSkillUsecase {
  Future<SkillEntity> _loadSkill(String skillId) async {
    final cloud = cloudStore;
    final skill = cloud != null
        ? await cloud.skill(skillId)
        : await _skillsRepository?.getSkillById(skillId);
    if (skill == null || skill.source != SkillSource.user) {
      throw StateError('User skill not found: $skillId');
    }

    return skill;
  }

  Future<SkillEntity> _createSkill(SkillEntity skill, String title) {
    return _createSkillUsecase.call(
      skill.workspaceId,
      .new(
        kind: skill.kind,
        title: title,
        description: skill.description,
        content: skill.content,
        credentialDefinitionId: skill.credentialDefinitionId,
        isEnabled: skill.isEnabled,
      ),
    );
  }

  Future<void> _copyTools(String skillId, String duplicateId) async {
    final store = cloudStore;
    final tools = store != null
        ? await store.tools(skillId)
        : await _localTools(skillId);
    for (final tool in tools) {
      await _copyTool(duplicateId, tool);
    }
  }

  Future<void> _copyTool(String duplicateId, SkillTemplateToolEntity tool) {
    final value = SkillTemplateToolToCreate(
      templateType: tool.templateType,
      title: tool.title,
      description: tool.description,
      templateJson: tool.templateJson,
      inputsJson: tool.inputsJson,
      isEnabled: tool.isEnabled,
    );

    return _createTool(duplicateId, value);
  }

  Future<void> _createTool(
    String duplicateId,
    SkillTemplateToolToCreate value,
  ) async {
    final cloud = cloudStore;
    if (cloud != null) {
      final _ = await cloud.createTool(duplicateId, value);

      return;
    }

    final repository = _skillTemplateToolsRepository;
    if (repository == null) {
      throw StateError('Skill template tool store is unavailable');
    }
    final _ = await repository.createTool(duplicateId, value);
  }

  Future<String> _copyTitle({
    required String workspaceId,
    required String originalTitle,
  }) async {
    for (var suffix = 1; ; suffix++) {
      final title = _copyTitleValue(originalTitle, suffix);
      if (!await _titleExists(workspaceId, title)) return title;
    }
  }

  String _copyTitleValue(String originalTitle, int suffix) =>
      suffix == 1 ? '$originalTitle Copy' : '$originalTitle Copy $suffix';

  Future<bool> _titleExists(String workspaceId, String title) {
    final cloud = cloudStore;
    if (cloud != null) return _cloudTitleExists(cloud, title);

    return _localTitleExists(workspaceId, title);
  }

  Future<bool> _cloudTitleExists(CloudSkillStore cloud, String title) async =>
      (await cloud.skills()).any((item) => item.title == title);
}

extension on DuplicateSkillUsecase {
  Future<bool> _localTitleExists(String workspaceId, String title) async {
    final repository = _skillsRepository;
    if (repository == null) {
      throw StateError('Skill store is unavailable');
    }

    return await repository.getSkillByTitle(workspaceId, title) != null;
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
duplicateSkillUsecaseProvider = Provider.family<DuplicateSkillUsecase, String>((
  ref,
  workspaceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

  return DuplicateSkillUsecase(
    cloud == null ? ref.watch(skillsRepositoryProvider) : null,
    cloud == null ? ref.watch(skillTemplateToolsRepositoryProvider) : null,
    ref.watch(createSkillUsecaseProvider(workspaceId)),
    cloudStore: cloud,
  );
});
