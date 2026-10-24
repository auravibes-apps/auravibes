import 'package:auravibes_app/data/repositories/cloud_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_views_provider.g.dart';

@riverpod
Future<ManageWorkspaceViewsUsecase> workspaceViewUsecase(Ref ref,String workspaceId) async {
  final session = await ref.watch(workspaceSessionForRouteProvider(workspaceId).future);
  final tables = await ref.watch(workspaceTableUsecaseProvider(workspaceId).future);
  if (!ref.mounted) throw const WorkspaceTableException(denied:true);
  if (session.cloud == null) return ManageWorkspaceViewsUsecase(LocalWorkspaceViewRepository(ref.watch(appDatabaseProvider),workspaceId),tables);
  final gateway = await ref.watch(cloudWorkspaceStateGatewayProvider(session).future);
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException(denied:true);
  return ManageWorkspaceViewsUsecase(CloudWorkspaceViewRepository(gateway.client,session.cloud!.cloudWorkspaceId),tables);
}
@riverpod
Future<List<WorkspaceView>> workspaceViews(Ref ref,String workspaceId,String? parentId) async =>
  (await ref.watch(workspaceViewUsecaseProvider(workspaceId).future)).list(parentId:parentId);

@riverpod
Future<WorkspaceViewData> workspaceViewData(Ref ref,String workspaceId,String viewId) async {
  // Table providers invalidate on ordinary record edits; cloud reads always reauthorize.
  final usecase = await ref.watch(workspaceViewUsecaseProvider(workspaceId).future);
  final data = await usecase.open(viewId);
  final _ = ref.watch(workspaceTableRecordsProvider(workspaceId,data.table.id));
  final _ = ref.watch(workspaceTableProvider(workspaceId,data.table.id));
  return data;
}
