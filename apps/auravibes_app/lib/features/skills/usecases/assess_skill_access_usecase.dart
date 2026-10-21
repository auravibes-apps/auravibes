import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';

class const AssessSkillAccessUsecase({
  required final Future<bool> Function(List<String> toolIds)
  connectorReferencesReady,
}) {
  Future<SkillAccessSummary> call({required SkillDetail skill}) async {
    final tools = <SkillToolAccess>[];
    for (final id in skill.connectorToolIds) {
      final status = await _readAccess(id);
      tools.add(SkillToolAccess(id: id, title: id, status: status));
    }

    return _summary(tools);
  }

  Future<SkillToolAccessStatus> _readAccess(String toolId) async {
    try {
      return await connectorReferencesReady([toolId])
          ? SkillToolAccessStatus.available
          : SkillToolAccessStatus.missing;
    } on Object {
      return SkillToolAccessStatus.unknown;
    }
  }

  SkillAccessSummary _summary(List<SkillToolAccess> tools) {
    if (tools.isEmpty) {
      return const SkillAccessSummary(
        status: SkillAccessStatus.notRequired,
        instructionsAvailable: true,
      );
    }
    final statuses = tools.map((tool) => tool.status);
    final status = statuses.contains(SkillToolAccessStatus.unknown)
        ? SkillAccessStatus.unknown
        : statuses.contains(SkillToolAccessStatus.missing)
        ? statuses.contains(SkillToolAccessStatus.available)
              ? SkillAccessStatus.partial
              : SkillAccessStatus.missing
        : SkillAccessStatus.saved;

    return SkillAccessSummary(
      status: status,
      instructionsAvailable: status == SkillAccessStatus.saved,
      tools: tools,
    );
  }
}
