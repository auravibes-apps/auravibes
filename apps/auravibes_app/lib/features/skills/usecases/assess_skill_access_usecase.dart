import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';

/// Describes stored access metadata, never remote connectivity or chat context.
class const AssessSkillAccessUsecase({
  required final Future<bool> Function(String definitionId) hasCredential,
  required final Future<bool> Function(String skillId) hasAppCredential,
  final CloudSkillStore? cloudStore,
  final bool Function(String skillId)? requiresAppCredential,
}) {
  Future<SkillAccessSummary> call({
    required SkillDetail skill,
    required List<SkillTemplateToolEntity> tools,
  }) async {
    if (!skill.isUserSkill) return await _appSummary(skill);

    final access = <String, SkillToolAccessStatus>{};
    final dependencies = <SkillToolAccess>[];
    for (final tool in tools) {
      final definitionId =
          tool.credentialDefinitionId ?? skill.credentialDefinitionId;
      final status = await _toolStatus(tool, definitionId, access);
      dependencies.add(
        SkillToolAccess(
          id: tool.id,
          title: tool.title,
          status: status,
          credentialDefinitionId: definitionId,
        ),
      );
    }
    final definitionId = skill.credentialDefinitionId;
    final parent = definitionId == null || definitionId.isEmpty
        ? SkillToolAccessStatus.available
        : await _definitionAccess(definitionId, access);

    return await _summary(skill, dependencies, parent, access.isNotEmpty);
  }

  Future<SkillToolAccessStatus> _toolStatus(
    SkillTemplateToolEntity tool,
    String? definitionId,
    Map<String, SkillToolAccessStatus> cache,
  ) async {
    if (!tool.isEnabled) return .disabled;
    if (!tool.requiresCredential) return .available;

    return await _definitionAccess(definitionId, cache);
  }

  Future<SkillToolAccessStatus> _definitionAccess(
    String? id,
    Map<String, SkillToolAccessStatus> cache,
  ) async {
    if (id == null || id.isEmpty) return .missing;
    if (cache[id] case final cached?) return cached;
    final result = await _readAccess(() => hasCredential(id));
    cache[id] = result;

    return result;
  }

  Future<SkillToolAccessStatus> _readAccess(
    Future<bool> Function() read,
  ) async {
    try {
      return await read() ? .available : .missing;
    } on Object {
      return .unknown;
    }
  }

  Future<SkillAccessSummary> _appSummary(SkillDetail skill) async {
    final requiresParent = requiresAppCredential?.call(skill.id) ?? false;
    final requiresAccess =
        requiresParent || skill.appTools.any((tool) => tool.requiresCredential);
    final access = requiresAccess
        ? await _readAccess(() => hasAppCredential(skill.id))
        : SkillToolAccessStatus.available;
    final tools = [
      for (final tool in skill.appTools)
        SkillToolAccess(
          id: tool.slug,
          title: tool.title,
          status: tool.requiresCredential ? access : .available,
        ),
    ];

    return await _summary(
      skill,
      tools,
      requiresParent ? access : .available,
      requiresAccess,
    );
  }

  Future<SkillAccessSummary> _summary(
    SkillDetail skill,
    List<SkillToolAccess> tools,
    SkillToolAccessStatus parent,
    bool hasRequirements,
  ) async {
    final cloudInstructions = await _cloudInstructions(skill);
    final instructionsAvailable = skill.isUserSkill
        ? skill.isCredentialOptional || parent == .available
        : tools.isEmpty || tools.any((tool) => tool.status == .available);
    final statuses = [parent, ...tools.map((tool) => tool.status)];
    final canLoadInstructions = cloudInstructions == null
        ? instructionsAvailable
        : cloudInstructions == .available;
    if (cloudInstructions == .unknown) statuses.add(.unknown);
    final status = _status(statuses, canLoadInstructions, hasRequirements);

    return SkillAccessSummary(
      status: status,
      instructionsAvailable: canLoadInstructions,
      tools: tools,
      credentialDefinitionId: skill.credentialDefinitionId,
    );
  }

  Future<SkillToolAccessStatus?> _cloudInstructions(SkillDetail skill) async {
    final cloud = cloudStore;
    if (cloud == null || !skill.isUserSkill) return null;

    return await _readAccess(() async {
      final persisted = await cloud.skill(skill.id);
      if (persisted == null) throw StateError('Skill metadata unavailable');

      return await cloud.userSkillReady(persisted);
    });
  }

  SkillAccessStatus _status(
    List<SkillToolAccessStatus> statuses,
    bool instructionsAvailable,
    bool hasRequirements,
  ) {
    if (statuses.contains(SkillToolAccessStatus.unknown)) return .unknown;
    if (statuses.contains(SkillToolAccessStatus.missing)) {
      return instructionsAvailable ? .partial : .missing;
    }

    return hasRequirements ? .saved : .notRequired;
  }
}
