import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef ListSkillResourceSummaries =
    Future<List<SkillResourceSummary>> Function({
      required String conversationId,
      required String workspaceId,
      required String skillSlug,
    });

typedef LoadSkillResourceContent =
    Future<({String title, String content})?> Function({
      required String conversationId,
      required String workspaceId,
      required String skillSlug,
      required String resourceSlug,
    });

typedef RunSkillCommandRequest = ({
  String conversationId,
  String workspaceId,
  String commandName,
  Map<String, dynamic> arguments,
});

class const _SkillActivationRequest({
  required final String conversationId,
  required final String workspaceId,
  required final String slug,
  required final String revision,
});

class const RunSkillCommandUsecase({
  required final ListAvailableSkillsUsecase Function(String workspaceId)
  listAvailableSkillsUsecase,
  required final LoadConversationSkillUsecase Function(String workspaceId)
  loadConversationSkillUsecase,
  required final BuildLoadedSkillManifestsUsecase
  buildLoadedSkillManifestsUsecase,
  final ListSkillResourceSummaries? listSkillResourceSummaries,
  final LoadSkillResourceContent? loadSkillResourceContent,
}) {
  Future<Object?> call(RunSkillCommandRequest request) =>
      switch (request.commandName) {
        activateSkillToolName => _activate(request),
        loadSkillResourceToolName => _loadResource(request),
        _ => throw FormatException('Unknown skill command: ${request.commandName}'),
      };

  Future<Object?> _activate(RunSkillCommandRequest request) async {
    final target = SkillActivationTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );
    final skill = await _availableSkill(request, target.slug);
    final manifestRequest = _SkillActivationRequest(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      slug: target.slug,
      revision: target.revision,
    );
    final manifest = await _manifestForSkill(manifestRequest, skill);
    if (manifest.revision != target.revision) {
      throw FormatException(
        'Skill revision changed; use the current skill catalog to refresh: '
        '${target.slug}',
      );
    }

    await loadConversationSkillUsecase(request.workspaceId).call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      slug: target.slug,
    );
    final resources = await listSkillResourceSummaries?.call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      skillSlug: target.slug,
    );

    return buildSkillActivationResult(
      manifest: manifest,
      content: skill.content,
      resources: resources ?? const [],
    );
  }

  Future<Object?> _loadResource(RunSkillCommandRequest request) async {
    final target = SkillResourceTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );
    final manifest = (await buildLoadedSkillManifestsUsecase.call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
    )).where((candidate) => candidate.slug == target.skill).firstOrNull;
    if (manifest == null) {
      throw StateError('Skill is not loaded: ${target.skill}');
    }
    final resource = await loadSkillResourceContent?.call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      skillSlug: target.skill,
      resourceSlug: target.resource,
    );
    if (resource == null) {
      throw StateError(
        'Skill resource is unavailable: ${target.skill}/${target.resource}',
      );
    }

    return buildSkillResourceResult(
      skillSlug: target.skill,
      resourceSlug: target.resource,
      title: resource.title,
      content: resource.content,
    );
  }

  Future<AvailableSkill> _availableSkill(
    RunSkillCommandRequest request,
    String slug,
  ) async {
    final skills = await listAvailableSkillsUsecase(request.workspaceId)(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      filter: .catalog,
    );
    final skill = skills.where((candidate) => candidate.slug == slug).firstOrNull;
    if (skill == null) throw StateError('Skill is unavailable: $slug');

    return skill;
  }

  Future<SkillManifest> _manifestForSkill(
    _SkillActivationRequest request,
    AvailableSkill skill,
  ) async {
    final manifests = await buildLoadedSkillManifestsUsecase.call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      extraSkills: [skill],
    );
    final manifest = manifests
        .where((candidate) => candidate.slug == request.slug)
        .firstOrNull;
    if (manifest == null) {
      throw StateError('Skill manifest unavailable: ${request.slug}');
    }

    return manifest;
  }
}
