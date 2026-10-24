import 'package:auravibes_app/data/repositories/cloud_workspace_directory_move_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_directory_move_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/move_workspace_directory_items_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_directory_move_provider.g.dart';

@riverpod
Future<MoveWorkspaceDirectoryItemsUsecase> workspaceDirectoryMoveUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return _local(ref, workspaceId);
  }

  return await _cloud(ref, session);
}

Future<MoveWorkspaceDirectoryItemsUsecase> _cloud(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) {
    throw const WorkspaceTableException(denied: true);
  }

  return MoveWorkspaceDirectoryItemsUsecase(
    CloudWorkspaceDirectoryMoveRepository(gateway),
  );
}

MoveWorkspaceDirectoryItemsUsecase _local(Ref ref, String workspaceId) =>
    MoveWorkspaceDirectoryItemsUsecase(
      LocalWorkspaceDirectoryMoveRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
