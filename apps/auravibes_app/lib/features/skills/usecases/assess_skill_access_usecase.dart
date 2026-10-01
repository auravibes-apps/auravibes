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

    return await _userSkillSummary(this, skill, tools);
  }

  Future<SkillAccessSummary> _appSummary(SkillDetail skill) async {
    final requirements = _appAccessRequirements(this, skill);
    final access = await _appCredentialAccess(
      this,
      skill,
      requirements.requiresAccess,
    );
    final tools = _appToolAccesses(skill, access);

    return await _summary(
      skill,
      tools,
      requirements.requiresParent ? access : .available,
      requirements.requiresAccess,
    );
  }

  List<SkillToolAccess> _appToolAccesses(
    SkillDetail skill,
    SkillToolAccessStatus access,
  ) => [
    for (final tool in skill.appTools)
      SkillToolAccess(
        id: tool.slug,
        title: tool.title,
        status: tool.requiresCredential ? access : .available,
      ),
  ];

  Future<SkillAccessSummary> _summary(
    SkillDetail skill,
    List<SkillToolAccess> tools,
    SkillToolAccessStatus parent,
    bool hasRequirements,
  ) async {
    final cloudInstructions = await _cloudInstructions(skill);
    final availability = _instructionsAvailability(
      skill,
      tools,
      parent,
      cloudInstructions,
    );
    final statuses = _statuses(parent, tools, cloudInstructions);
    final status = _status(statuses, availability, hasRequirements);

    return SkillAccessSummary(
      status: status,
      instructionsAvailable: availability,
      tools: tools,
      credentialDefinitionId: skill.credentialDefinitionId,
    );
  }

  bool _instructionsAvailability(
    SkillDetail skill,
    List<SkillToolAccess> tools,
    SkillToolAccessStatus parent,
    SkillToolAccessStatus? cloudInstructions,
  ) {
    if (cloudInstructions != null) return cloudInstructions == .available;
    if (skill.isUserSkill) {
      return skill.isCredentialOptional || parent == .available;
    }

    return tools.isEmpty || tools.any((tool) => tool.status == .available);
  }

  List<SkillToolAccessStatus> _statuses(
    SkillToolAccessStatus parent,
    List<SkillToolAccess> tools,
    SkillToolAccessStatus? cloudInstructions,
  ) => [
    parent,
    ...tools.map((tool) => tool.status),
    if (cloudInstructions == .unknown) SkillToolAccessStatus.unknown,
  ];

  Future<SkillToolAccessStatus?> _cloudInstructions(SkillDetail skill) {
    final cloud = cloudStore;
    if (cloud == null || !skill.isUserSkill) {
      return Future<SkillToolAccessStatus?>.value();
    }

    return _readSkillAccess(() => _cloudSkillIsReady(cloud, skill.id));
  }

  Future<bool> _cloudSkillIsReady(CloudSkillStore cloud, String skillId) async {
    final persisted = await cloud.skill(skillId);
    if (persisted == null) throw StateError('Skill metadata unavailable');

    return await cloud.userSkillReady(persisted);
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

Future<SkillAccessSummary> _userSkillSummary(
  AssessSkillAccessUsecase usecase,
  SkillDetail skill,
  List<SkillTemplateToolEntity> tools,
) async {
  final access = <String, SkillToolAccessStatus>{};
  final dependencies = await _toolAccesses(usecase, skill, tools, access);
  final parent = await _userParentAccess(usecase, skill, access);

  return await usecase._summary(skill, dependencies, parent, access.isNotEmpty);
}

Future<SkillToolAccessStatus> _userParentAccess(
  AssessSkillAccessUsecase usecase,
  SkillDetail skill,
  Map<String, SkillToolAccessStatus> access,
) async {
  final definitionId = skill.credentialDefinitionId;
  if (definitionId == null || definitionId.isEmpty) {
    return SkillToolAccessStatus.available;
  }

  return await _definitionAccess(usecase, definitionId, access);
}

Future<List<SkillToolAccess>> _toolAccesses(
  AssessSkillAccessUsecase usecase,
  SkillDetail skill,
  List<SkillTemplateToolEntity> tools,
  Map<String, SkillToolAccessStatus> access,
) async {
  final dependencies = <SkillToolAccess>[];
  for (final tool in tools) {
    final definitionId =
        tool.credentialDefinitionId ?? skill.credentialDefinitionId;
    dependencies.add(await _toolAccess(usecase, tool, definitionId, access));
  }

  return dependencies;
}

Future<SkillToolAccess> _toolAccess(
  AssessSkillAccessUsecase usecase,
  SkillTemplateToolEntity tool,
  String? definitionId,
  Map<String, SkillToolAccessStatus> access,
) async => SkillToolAccess(
  id: tool.id,
  title: tool.title,
  status: await _toolStatus(usecase, tool, definitionId, access),
  credentialDefinitionId: definitionId,
);

Future<SkillToolAccessStatus> _toolStatus(
  AssessSkillAccessUsecase usecase,
  SkillTemplateToolEntity tool,
  String? definitionId,
  Map<String, SkillToolAccessStatus> cache,
) async {
  if (!tool.isEnabled) return .disabled;
  if (!tool.requiresCredential) return .available;

  return await _definitionAccess(usecase, definitionId, cache);
}

Future<SkillToolAccessStatus> _definitionAccess(
  AssessSkillAccessUsecase usecase,
  String? id,
  Map<String, SkillToolAccessStatus> cache,
) async {
  if (id == null || id.isEmpty) return .missing;
  if (cache[id] case final cached?) return cached;
  final result = await _readSkillAccess(() => usecase.hasCredential(id));
  cache[id] = result;

  return result;
}

Future<SkillToolAccessStatus> _readSkillAccess(
  Future<bool> Function() read,
) async {
  try {
    return await read() ? .available : .missing;
  } on Object {
    return .unknown;
  }
}

Future<SkillToolAccessStatus> _appCredentialAccess(
  AssessSkillAccessUsecase usecase,
  SkillDetail skill,
  bool requiresAccess,
) async {
  if (!requiresAccess) return .available;

  return await _readSkillAccess(() => usecase.hasAppCredential(skill.id));
}

({bool requiresParent, bool requiresAccess}) _appAccessRequirements(
  AssessSkillAccessUsecase usecase,
  SkillDetail skill,
) {
  final requiresParent = usecase.requiresAppCredential?.call(skill.id) ?? false;

  return (
    requiresParent: requiresParent,
    requiresAccess:
        requiresParent || skill.appTools.any((tool) => tool.requiresCredential),
  );
}
