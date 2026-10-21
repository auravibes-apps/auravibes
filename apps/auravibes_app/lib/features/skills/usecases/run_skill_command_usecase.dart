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
        _ => throw FormatException(
          'Unknown skill command: ${request.commandName}',
        ),
      };
}

extension on RunSkillCommandUsecase {
  Future<Object?> _activate(RunSkillCommandRequest request) {
    final target = SkillActivationTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );

    return _activateTarget(this, request, target);
  }

  Future<Object?> _activateSkill(
    _SkillActivationRequest request,
    AvailableSkill skill,
  ) async {
    final manifest = await _manifestForSkill(request, skill);
    _requireCurrentRevision(manifest, request);
    await _loadSkill(request);
    final resources = await _resourcesForSkill(request);

    return buildSkillActivationResult(
      manifest: manifest,
      content: skill.content,
      resources: resources,
    );
  }

  void _requireCurrentRevision(
    SkillManifest manifest,
    _SkillActivationRequest request,
  ) {
    if (manifest.revision == request.revision) return;

    throw FormatException(
      'Skill revision changed; use the current skill catalog to refresh: '
      '${request.slug}',
    );
  }

  Future<void> _loadSkill(_SkillActivationRequest request) =>
      loadConversationSkillUsecase(request.workspaceId).call(
        conversationId: request.conversationId,
        workspaceId: request.workspaceId,
        slug: request.slug,
      );

  Future<List<SkillResourceSummary>> _resourcesForSkill(
    _SkillActivationRequest request,
  ) async {
    final listResources = listSkillResourceSummaries;
    if (listResources == null) return const [];

    return await listResources(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      skillSlug: request.slug,
    );
  }

  Future<Object?> _loadResource(RunSkillCommandRequest request) {
    final target = SkillResourceTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );

    return _loadResourceTarget(request, target);
  }

  Future<Object?> _loadResourceTarget(
    RunSkillCommandRequest request,
    SkillResourceTarget target,
  ) async {
    final resource = await _loadedResource(
      request,
      target.skill,
      target.resource,
    );

    return buildSkillResourceResult(
      skillSlug: target.skill,
      resourceSlug: target.resource,
      title: resource.title,
      content: resource.content,
    );
  }

  Future<({String title, String content})> _loadedResource(
    RunSkillCommandRequest request,
    String skillSlug,
    String resourceSlug,
  ) async {
    await _requireLoadedSkill(this, request, skillSlug);

    return await _skillResourceContent(this, request, skillSlug, resourceSlug);
  }

  Future<AvailableSkill> _availableSkill(
    RunSkillCommandRequest request,
    String slug,
  ) async {
    final skills = await this.listAvailableSkillsUsecase(request.workspaceId)(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      filter: .catalog,
    );
    final skill = skills
        .where((candidate) => candidate.slug == slug)
        .firstOrNull;
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

Future<Object?> _activateTarget(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
  SkillActivationTarget target,
) async {
  final skill = await usecase._availableSkill(request, target.slug);
  final manifestRequest = _SkillActivationRequest(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    slug: target.slug,
    revision: target.revision,
  );

  return await usecase._activateSkill(manifestRequest, skill);
}

Future<void> _requireLoadedSkill(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
  String skillSlug,
) async {
  final manifests = await usecase.buildLoadedSkillManifestsUsecase.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
  );
  if (manifests.any((candidate) => candidate.slug == skillSlug)) return;

  throw StateError('Skill is not loaded: $skillSlug');
}

Future<({String title, String content})> _skillResourceContent(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
  String skillSlug,
  String resourceSlug,
) async {
  final loadResource = usecase.loadSkillResourceContent;
  if (loadResource == null) {
    throw StateError('Skill resource is unavailable: $skillSlug/$resourceSlug');
  }
  final resource = await loadResource(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    skillSlug: skillSlug,
    resourceSlug: resourceSlug,
  );
  if (resource == null) {
    throw StateError('Skill resource is unavailable: $skillSlug/$resourceSlug');
  }

  return resource;
}
