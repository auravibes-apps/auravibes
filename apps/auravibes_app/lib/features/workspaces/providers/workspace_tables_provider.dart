import 'package:auravibes_app/data/repositories/cloud_workspace_table_access_repository.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_table_access_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_tables_provider.g.dart';

@riverpod
Future<OrganizeWorkspaceTablesUsecase> workspaceTableUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) {
    throw const WorkspaceTableException();
  }
  if (session.cloud == null) {
    return OrganizeWorkspaceTablesUsecase(
      LocalWorkspaceTableRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }

  return await _cloudUsecase(ref, session);
}

Future<OrganizeWorkspaceTablesUsecase> _cloudUsecase(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) {
    throw const WorkspaceTableException();
  }

  return OrganizeWorkspaceTablesUsecase(
    CloudWorkspaceTableRepository(.new(gateway)),
  );
}

@riverpod
Future<List<WorkspaceTable>> workspaceTables(
  Ref ref,
  String workspaceId,
  String? parentId,
) async {
  final folders = await ref.watch(
    workspaceTableUsecaseProvider(workspaceId).future,
  );

  return await folders.list(parentId: parentId);
}

@riverpod
Future<WorkspaceTable> workspaceTable(
  Ref ref,
  String workspaceId,
  String tableId,
) async {
  final tables = await ref.watch(
    workspaceTableUsecaseProvider(workspaceId).future,
  );

  return await tables.table(tableId);
}

@riverpod
Future<List<WorkspaceRecord>> workspaceTableRecords(
  Ref ref,
  String workspaceId,
  String tableId,
) async {
  final tables = await ref.watch(
    workspaceTableUsecaseProvider(workspaceId).future,
  );

  return await tables.records(tableId);
}

@riverpod
Future<ManageWorkspaceTableAccessUsecase> workspaceTableAccessUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) {
    throw const WorkspaceTableException(denied: true);
  }
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) {
    throw const WorkspaceTableException(denied: true);
  }

  return ManageWorkspaceTableAccessUsecase(
    CloudWorkspaceTableAccessRepository(.new(gateway)),
  );
}
