import 'package:auravibes_app/data/repositories/cloud_workspace_record_batch_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_records_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_record_batch_provider.g.dart';

@riverpod
Future<EditWorkspaceRecordsUsecase> workspaceRecordBatchUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return EditWorkspaceRecordsUsecase(
      LocalWorkspaceRecordBatchRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }

  return await _cloud(ref, session);
}

Future<EditWorkspaceRecordsUsecase> _cloud(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException();

  return EditWorkspaceRecordsUsecase(
    CloudWorkspaceRecordBatchRepository(gateway),
  );
}
