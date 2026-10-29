import 'package:auravibes_app/data/repositories/cloud_workspace_item_duplication_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_item_duplication_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/duplicate_workspace_item_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_item_duplication_provider.g.dart';

@riverpod
Future<DuplicateWorkspaceItemUsecase> workspaceItemDuplicationUsecase(
  Ref ref,
  String workspaceId,
) {
  final link = ref.keepAlive();

  return _usecase(ref, workspaceId).whenComplete(link.close);
}

Future<DuplicateWorkspaceItemUsecase> _usecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return DuplicateWorkspaceItemUsecase(
      LocalWorkspaceItemDuplicationRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }

  return await _cloud(ref, session);
}

Future<DuplicateWorkspaceItemUsecase> _cloud(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  final cloud = session.cloud;
  if (!ref.mounted || gateway == null || cloud == null) {
    throw const WorkspaceTableException(denied: true);
  }

  return DuplicateWorkspaceItemUsecase(
    CloudWorkspaceItemDuplicationRepository(
      gateway.client,
      cloud.cloudWorkspaceId,
    ),
  );
}
