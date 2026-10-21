import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/riverpod.dart';

class const BuildLoadedSkillManifestsUsecase(
  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase,
) {
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final skills = await _loadedSkills(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );

    return [for (final skill in skills) _manifest(skill)]
      ..sort((left, right) => left.slug.compareTo(right.slug));
  }
}

extension on BuildLoadedSkillManifestsUsecase {
  Future<List<AvailableSkill>> _loadedSkills({
    required String conversationId,
    required String workspaceId,
    required List<AvailableSkill> extraSkills,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: .loaded,
    );
    final identities = <String>{};

    return [...loadedSkills, ...extraSkills]
        .where((skill) => identities.add('${skill.source.name}:${skill.id}'))
        .toList();
  }

  SkillManifest _manifest(AvailableSkill skill) {
    final connectorToolIds = _sortedConnectorToolIds(skill.connectorToolIds);

    return SkillManifest(
      slug: skill.slug,
      title: skill.title,
      description: skill.description,
      revision: buildSkillRevision(
        identity: '${skill.source.name}:${skill.id}',
        slug: skill.slug,
        title: skill.title,
        description: skill.description,
        instructions: skill.content,
        connectorToolIds: connectorToolIds,
      ),
      connectorToolIds: connectorToolIds,
    );
  }

  List<String> _sortedConnectorToolIds(Iterable<String> toolIds) =>
      toolIds.where((id) => id.trim().isNotEmpty).toSet().toList()..sort();
}

final buildLoadedSkillManifestsUsecaseProvider =
    Provider<BuildLoadedSkillManifestsUsecase>((ref) {
      return BuildLoadedSkillManifestsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
      );
    });
