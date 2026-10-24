import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_record_query_provider.g.dart';

@riverpod
Future<QueryWorkspaceRecordsUsecase> workspaceRecordQueryUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return QueryWorkspaceRecordsUsecase(
      LocalWorkspaceRecordQueryRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }

  return await _cloud(ref, session);
}

Future<QueryWorkspaceRecordsUsecase> _cloud(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException();

  return QueryWorkspaceRecordsUsecase(
    CloudWorkspaceRecordQueryRepository(gateway),
  );
}

@riverpod
Future<WorkspaceRecordPage> workspaceRecordQuery(
  Ref ref,
  String workspaceId,
  String tableId,
  WorkspaceRecordQuery query,
) async {
  final usecase = await ref.watch(
    workspaceRecordQueryUsecaseProvider(workspaceId).future,
  );

  return await usecase(tableId, query);
}
