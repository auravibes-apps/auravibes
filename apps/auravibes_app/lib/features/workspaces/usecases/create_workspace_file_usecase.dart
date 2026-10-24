import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';

class const CreateWorkspaceFileUsecase(
  final ManageWorkspaceAssetsUsecase assets,
  final OrganizeWorkspaceFilesUsecase files,
) {
  Future<WorkspaceFile> call({
    required String id,
    required String name,
    required WorkspaceAssetDraft source,
    required String? parentId,
    WorkspaceAsset? uploaded,
  }) async {
    if (id.isEmpty ||
        id.length > 128 ||
        name.trim().isEmpty ||
        name.trim().length > 200) {
      throw const WorkspaceAssetException(.invalid);
    }
    final asset = uploaded ?? await assets.upload(source.name, source.bytes);
    try {
      return await files.create(
        id: id,
        name: name,
        assetId: asset.id,
        parentId: parentId,
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        WorkspaceFileCreationFailure(asset, error),
        stackTrace,
      );
    }
  }
}

/// A retry reuses the completed upload instead of storing the same bytes again.
class const WorkspaceFileCreationFailure(
  final WorkspaceAsset uploaded,
  final Object cause,
) implements Exception;
