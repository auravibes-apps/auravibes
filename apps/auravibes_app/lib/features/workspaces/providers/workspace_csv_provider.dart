import 'package:auravibes_app/data/repositories/cloud_workspace_csv_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_csv_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_csv_provider.g.dart';

@riverpod
Future<WorkspaceCsvUsecase> workspaceCsvUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return WorkspaceCsvUsecase(
      LocalWorkspaceCsvRepository(ref.watch(appDatabaseProvider), workspaceId),
    );
  }

  return await _cloud(ref, session);
}

Future<WorkspaceCsvUsecase> _cloud(Ref ref, WorkspaceSession session) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException();

  return WorkspaceCsvUsecase(CloudWorkspaceCsvRepository(gateway));
}
