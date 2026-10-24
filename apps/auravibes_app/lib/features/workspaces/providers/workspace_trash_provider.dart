import 'package:auravibes_app/data/repositories/cloud_workspace_trash_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_trash_provider.g.dart';

@riverpod
Future<ManageWorkspaceTrashUsecase> workspaceTrashUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return ManageWorkspaceTrashUsecase(
      LocalWorkspaceTrashRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }

  return await _cloudTrash(ref, session);
}

Future<ManageWorkspaceTrashUsecase> _cloudTrash(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException();

  return ManageWorkspaceTrashUsecase(
    CloudWorkspaceTrashRepository(.new(gateway)),
  );
}

@riverpod
Future<List<WorkspaceTrashBatch>> workspaceTrash(
  Ref ref,
  String workspaceId,
) async {
  final usecase = await ref.watch(
    workspaceTrashUsecaseProvider(workspaceId).future,
  );

  return await usecase.list();
}

@riverpod
Future<WorkspaceDeletedReference?> workspaceDeletedReference(
  Ref ref,
  String workspaceId,
  String tableId,
  String recordId,
) async {
  final usecase = await ref.watch(
    workspaceTrashUsecaseProvider(workspaceId).future,
  );

  return await usecase.deletedReference(tableId, recordId);
}
