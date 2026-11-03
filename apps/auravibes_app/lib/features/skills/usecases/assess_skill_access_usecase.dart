import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';

class const AssessSkillAccessUsecase({
  required final Future<List<SkillToolAccessStatus>> Function(
    List<String> toolIds,
  )
  connectorReferenceStatuses,
}) {
  Future<SkillAccessSummary> call({required SkillDetail skill}) async {
    final connectorToolIds = skill.connectorToolIds.toList(growable: false);
    if (connectorToolIds.isEmpty) {
      return const SkillAccessSummary(
        status: .notRequired,
        instructionsAvailable: true,
      );
    }

    final statuses = await _readStatuses(connectorToolIds);
    final tools = [
      for (var index = 0; index < connectorToolIds.length; index++)
        SkillToolAccess(
          id: connectorToolIds[index],
          title: connectorToolIds[index],
          status: statuses[index],
        ),
    ];

    return _summary(tools);
  }

  Future<List<SkillToolAccessStatus>> _readStatuses(
    List<String> connectorToolIds,
  ) async {
    try {
      final statuses = await connectorReferenceStatuses(connectorToolIds);
      if (statuses.length != connectorToolIds.length) {
        throw StateError('Readiness must return one status per connector tool.');
      }

      return statuses;
    } on Object {
      return List.filled(
        connectorToolIds.length,
        SkillToolAccessStatus.unknown,
      );
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
