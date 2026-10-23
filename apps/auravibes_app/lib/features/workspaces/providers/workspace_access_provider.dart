import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_access_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_access_provider.g.dart';

@riverpod
Future<WorkspaceAccess> workspaceAccess(Ref ref, String workspaceId) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) return (role: 'member');
  final cloud = session.cloud;
  if (cloud == null) return (role: 'owner');

  return await _cloudAccess(ref, cloud);
}

Future<WorkspaceAccess> _cloudAccess(Ref ref, CloudWorkspaceRef cloud) async {
  final state = await ref.watch(
    cloudWorkspaceDetailProvider((
      serverUrl: cloud.serverUrl,
      accountId: cloud.accountId,
      workspaceId: cloud.cloudWorkspaceId,
    )).future,
  );

  return (role: state?.detail.workspace.role ?? 'member');
}

@riverpod
bool canManageWorkspace(Ref ref, String workspaceId) =>
    switch (ref.watch(workspaceAccessProvider(workspaceId))) {
      AsyncData(:final value) => value.canManage,
      AsyncLoading() || AsyncError() => false,
    };
