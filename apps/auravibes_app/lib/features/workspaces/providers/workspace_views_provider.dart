import 'package:auravibes_app/data/repositories/cloud_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_access_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/read_connected_workspace_view_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_views_provider.g.dart';

@riverpod
Future<ManageWorkspaceViewsUsecase> workspaceViewUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  _requireMounted(ref);
  final repository = session.cloud == null
      ? LocalWorkspaceViewRepository(
          ref.watch(appDatabaseProvider),
          workspaceId,
        )
      : await _cloudRepository(ref, session);

  return await _usecase(ref, workspaceId, repository, session);
}

Future<WorkspaceViewRepository> _cloudRepository(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  _requireMounted(ref);
  final cloud = session.cloud;
  if (gateway == null || cloud == null) {
    throw const WorkspaceTableException(denied: true);
  }

  return CloudWorkspaceViewRepository(gateway.client, cloud.cloudWorkspaceId);
}

Future<ManageWorkspaceViewsUsecase> _usecase(
  Ref ref,
  String workspaceId,
  WorkspaceViewRepository repository,
  WorkspaceSession session,
) async {
  _requireMounted(ref);
  final services = _services(ref, workspaceId);
  final management = await _management(ref, workspaceId, session);
  final owned = await services;

  return ManageWorkspaceViewsUsecase(
    repository,
    owned.tables,
    owned.query,
    owned.references,
    canManageConnected: management.canManage,
    validateConnected: management.validate,
  );
}

typedef _ViewServices = ({
  OrganizeWorkspaceTablesUsecase tables,
  QueryWorkspaceRecordsUsecase query,
  BrowseWorkspaceReferencesUsecase references,
});
Future<_ViewServices> _services(Ref ref, String workspaceId) async {
  final tables = ref.watch(workspaceTableUsecaseProvider(workspaceId).future);
  final query = ref.watch(
    workspaceRecordQueryUsecaseProvider(workspaceId).future,
  );
  final references = ref.watch(
    workspaceReferencesUsecaseProvider(workspaceId).future,
  );

  return (
    tables: await tables,
    query: await query,
    references: await references,
  );
}

typedef _Management = ({
  bool canManage,
  Future<void> Function(WorkspaceConnectedBinding) validate,
});
Future<_Management> _management(
  Ref ref,
  String workspaceId,
  WorkspaceSession session,
) async {
  final access = ref.watch(workspaceAccessProvider(workspaceId).future);
  final validate = _connectedValidator(ref, workspaceId, session);

  return (canManage: (await access).role == 'owner', validate: validate);
}

Future<void> Function(WorkspaceConnectedBinding) _connectedValidator(
  Ref ref,
  String workspaceId,
  WorkspaceSession session,
) {
  // Cloud saves validate bindings inside the authenticated endpoint.
  if (session.cloud != null) return (_) => Future<void>.value();
  final run = ref.watch(runConnectorToolUsecaseProvider);

  return (binding) => run.requireCurrent(
    ReadConnectedWorkspaceViewUsecase.accessRequest(workspaceId, binding),
  );
}

void _requireMounted(Ref ref) {
  if (!ref.mounted) throw const WorkspaceTableException(denied: true);
}

@riverpod
Future<List<WorkspaceView>> workspaceViews(
  Ref ref,
  String workspaceId,
  String? parentId,
) async =>
    await (await ref.watch(workspaceViewUsecaseProvider(workspaceId).future))
        .list(parentId: parentId);

@riverpod
Future<WorkspaceViewData> workspaceViewData(
  Ref ref,
  String workspaceId,
  String viewId, {
  int offset = 0,
}) async {
  // Record edits invalidate the table providers.
  // Cloud reads always reauthorize.
  final usecase = await ref.watch(
    workspaceViewUsecaseProvider(workspaceId).future,
  );
  final data = await usecase.open(viewId, offset: offset);
  if (!data.view.isConnectedOnly) _observeViewSource(ref, workspaceId, data);

  return data;
}

void _observeViewSource(Ref ref, String workspaceId, WorkspaceViewData data) {
  final _ = ref.watch(
    workspaceRecordQueryProvider(
      workspaceId,
      data.table.id,
      data.view.query.change(offset: data.offset),
    ),
  );
  final _ = ref.watch(workspaceTableProvider(workspaceId, data.table.id));
}

@riverpod
Future<List<WorkspaceView>> workspaceViewChoices(
  Ref ref,
  String workspaceId,
) async =>
    await (await ref.watch(workspaceViewUsecaseProvider(workspaceId).future))
        .list(allFolders: true);

@riverpod
Future<List<WorkspaceView>> workspaceViewHistory(
  Ref ref,
  String workspaceId,
  String viewId,
) async =>
    await (await ref.watch(workspaceViewUsecaseProvider(workspaceId).future))
        .history(viewId);
