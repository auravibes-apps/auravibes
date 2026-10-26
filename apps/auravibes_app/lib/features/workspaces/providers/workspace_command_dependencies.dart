import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class const WorkspaceCommandDependencies(
  final Ref ref,
  final String workspaceId,
) {
  Future<WorkspaceConversationCommandUsecase> load() async {
    final table = _tables();
    final folder = _folders();
    final view = _views();

    return .new(tables: await table, folders: await folder, views: await view);
  }

  Future<OrganizeWorkspaceTablesUsecase> _tables() =>
      ref.watch(workspaceTableUsecaseProvider(workspaceId).future);
  Future<OrganizeWorkspaceFoldersUsecase> _folders() =>
      ref.watch(workspaceFolderUsecaseProvider(workspaceId).future);
  Future<ManageWorkspaceViewsUsecase> _views() =>
      ref.watch(workspaceViewUsecaseProvider(workspaceId).future);
}
