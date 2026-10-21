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
        status: .notRequired,
        instructionsAvailable: true,
      );
    }
    final statuses = tools.map((tool) => tool.status).toSet();
    final status = _summaryStatus(statuses);

    return SkillAccessSummary(
      status: status,
      instructionsAvailable: status == SkillAccessStatus.saved,
      tools: tools,
    );
  }

  SkillAccessStatus _summaryStatus(Set<SkillToolAccessStatus> statuses) {
    if (statuses.contains(SkillToolAccessStatus.unknown)) return .unknown;
    if (!statuses.contains(SkillToolAccessStatus.missing)) return .saved;

    return statuses.contains(SkillToolAccessStatus.available)
        ? .partial
        : .missing;
  }
}
