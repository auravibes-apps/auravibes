class const SkillAccessSummary({
  required final SkillAccessStatus status,
  required final bool instructionsAvailable,
  final List<SkillToolAccess> tools = const [],
  final String? credentialDefinitionId,
});

enum SkillAccessStatus { notRequired, saved, missing, partial, unknown }

enum SkillToolAccessStatus { available, disabled, missing, unknown }

class const SkillToolAccess({
  required final String id,
  required final String title,
  required final SkillToolAccessStatus status,
  final String? credentialDefinitionId,
});
