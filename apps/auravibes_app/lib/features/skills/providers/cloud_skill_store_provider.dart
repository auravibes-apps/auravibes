import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([workspaceSession, cloudWorkspaceStateGateway])
final cloudSkillStoreProvider = Provider<CloudSkillStore?>(
  (ref) {
    final WorkspaceSession session;
    try {
      session = ref.watch(workspaceSessionProvider);
    } on Exception {
      return null;
    }
    final cloud = session.cloud;
    if (cloud == null) return null;

    return CloudSkillStore(
      CloudWorkspaceResourceStore.deferred(
        ref.watch(cloudWorkspaceStateGatewayProvider.future),
      ),
      cloud.localWorkspaceId,
    );
  },
  dependencies: [workspaceSessionProvider, cloudWorkspaceStateGatewayProvider],
);
