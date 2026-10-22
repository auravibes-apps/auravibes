import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/connector_tool_reference_readiness.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_access_summary_provider.g.dart';

@riverpod
AssessSkillAccessUsecase assessSkillAccessUsecase(
  Ref ref,
  String workspaceId,
) => AssessSkillAccessUsecase(
  connectorReferencesReady: (toolIds) async =>
      await ConnectorToolReferenceReadiness.areReady(
        connectorToolIds: toolIds,
        workspaceId: workspaceId,
        credentialCandidates: ref.watch(
          listConnectorConnectionCandidatesUsecaseProvider,
        ),
      ),
);

@riverpod
Future<SkillAccessSummary?> skillAccessSummary(
  Ref ref,
  String workspaceId,
  String skillId,
) async {
  final skill = await ref.watch(
    skillDetailProvider(workspaceId, skillId).future,
  );
  if (skill == null) return null;

  return await ref
      .watch(assessSkillAccessUsecaseProvider(workspaceId))
      .call(skill: skill);
}
