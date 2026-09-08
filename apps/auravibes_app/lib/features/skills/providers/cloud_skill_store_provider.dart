import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_skill_store_provider.g.dart';

@riverpod
CloudSkillStore? cloudSkillStore(Ref ref, String workspaceId) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .requireValue;
  final cloud = session.cloud;
  if (cloud == null) return null;

  return CloudSkillStore(
    CloudWorkspaceResourceStore.deferred(
      ref.watch(cloudWorkspaceStateGatewayProvider(session).future),
    ),
    cloud.localWorkspaceId,
  );
}
