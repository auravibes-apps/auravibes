import 'package:auravibes_app/data/repositories/cloud_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
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

  return await _usecase(ref, workspaceId, repository);
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
) async {
  _requireMounted(ref);
  final tables = ref.watch(workspaceTableUsecaseProvider(workspaceId).future);
  final query = ref.watch(
    workspaceRecordQueryUsecaseProvider(workspaceId).future,
  );
  final references = ref.watch(
    workspaceReferencesUsecaseProvider(workspaceId).future,
  );

  return ManageWorkspaceViewsUsecase(
    repository,
    await tables,
    await query,
    await references,
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
  String viewId,
) async {
  // Record edits invalidate the table providers.
  // Cloud reads always reauthorize.
  final usecase = await ref.watch(
    workspaceViewUsecaseProvider(workspaceId).future,
  );
  final data = await usecase.open(viewId);
  final _ = ref.watch(
    workspaceRecordQueryProvider(
      workspaceId,
      data.table.id,
      const WorkspaceRecordQuery(limit: 100),
    ),
  );
  final _ = ref.watch(workspaceTableProvider(workspaceId, data.table.id));

  return data;
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
