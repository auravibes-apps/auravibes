import 'package:auravibes_app/data/repositories/cloud_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_folders_provider.g.dart';

@riverpod
Future<OrganizeWorkspaceFoldersUsecase> workspaceFolderUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceFolderException();
  if (session.cloud == null) {
    return OrganizeWorkspaceFoldersUsecase(
      LocalWorkspaceFolderRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }

  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceFolderException();

  return OrganizeWorkspaceFoldersUsecase(
    CloudWorkspaceFolderRepository(.new(gateway)),
  );
}

@riverpod
Future<List<WorkspaceFolder>> workspaceFolders(
  Ref ref,
  String workspaceId,
  String? parentId,
) async {
  final folders = await ref.watch(
    workspaceFolderUsecaseProvider(workspaceId).future,
  );

  return await folders.list(parentId: parentId);
}
