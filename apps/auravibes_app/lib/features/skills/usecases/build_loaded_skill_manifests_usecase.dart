import 'package:auravibes_app/features/agents/agent_guidance.dart';
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
    String? languageCode,
  }) async {
    final skills = await _loadedSkills(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );

    return [for (final skill in skills) _manifest(skill, languageCode)]
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

    return _uniqueSkills([...loadedSkills, ...extraSkills]);
  }

  SkillManifest _manifest(AvailableSkill skill, String? languageCode) {
    final connectorToolIds = _sortedConnectorToolIds(skill.connectorToolIds);

    return SkillManifest(
      slug: skill.slug,
      title: skill.title,
      description: skill.description,
      revision: _revision(skill, connectorToolIds, languageCode),
      connectorToolIds: connectorToolIds,
    );
  }

  String _revision(
    AvailableSkill skill,
    List<String> connectorToolIds,
    String? languageCode,
  ) => buildSkillRevision(
    identity: _identity(skill),
    slug: skill.slug,
    title: skill.title,
    description: skill.description,
    instructions: skill.slug == agentsSkillSlug
        ? AgentGuidance.agentsSkillContentForLanguageCode(languageCode)
        : skill.content,
    connectorToolIds: connectorToolIds,
  );

  String _identity(AvailableSkill skill) => '${skill.source.name}:${skill.id}';

  List<AvailableSkill> _uniqueSkills(List<AvailableSkill> skills) {
    final identities = <String>{};

    return skills.where((skill) => identities.add(_identity(skill))).toList();
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
