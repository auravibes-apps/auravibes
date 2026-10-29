import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class const WorkspaceCommandDependencies(
  final Ref ref,
  final String workspaceId,
) {
  Future<WorkspaceConversationCommandUsecase> load() async {
    final link = ref.keepAlive();
    try {
      return await _resolve();
    } finally {
      link.close();
    }
  }

  Future<WorkspaceConversationCommandUsecase> _resolve() async {
    final pending = (
      tables: _tables(),
      folders: _folders(),
      views: _views(),
      files: _files(),
      assets: _assets(),
    );

    return .new(
      tables: await pending.tables,
      folders: await pending.folders,
      views: await pending.views,
      files: await pending.files,
      assets: await pending.assets,
    );
  }

  Future<OrganizeWorkspaceFilesUsecase> _files() =>
      ref.watch(workspaceFilesUsecaseProvider(workspaceId).future);
  Future<ManageWorkspaceAssetsUsecase> _assets() =>
      ref.watch(workspaceAssetsUsecaseProvider(workspaceId).future);
  Future<OrganizeWorkspaceTablesUsecase> _tables() =>
      ref.watch(workspaceTableUsecaseProvider(workspaceId).future);
  Future<OrganizeWorkspaceFoldersUsecase> _folders() =>
      ref.watch(workspaceFolderUsecaseProvider(workspaceId).future);
  Future<ManageWorkspaceViewsUsecase> _views() =>
      ref.watch(workspaceViewUsecaseProvider(workspaceId).future);
}
