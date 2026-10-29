import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';

class const CreateWorkspaceFileUsecase(
  final ManageWorkspaceAssetsUsecase assets,
  final OrganizeWorkspaceFilesUsecase files,
) {
  Future<WorkspaceFile> call(WorkspaceFileUpload request) async {
    _validate(request);
    final source = request.source;
    final asset =
        request.uploaded ?? await assets.upload(source.name, source.bytes);

    return await _create(request, asset);
  }

  Future<WorkspaceFile> _create(
    WorkspaceFileUpload request,
    WorkspaceAsset asset,
  ) async {
    try {
      return await files.create(_draft(request, asset));
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        WorkspaceFileCreationFailure(asset, error),
        stackTrace,
      );
    }
  }

  static WorkspaceFileDraft _draft(
    WorkspaceFileUpload request,
    WorkspaceAsset asset,
  ) => WorkspaceFileDraft(
    id: request.id,
    name: request.name,
    assetId: asset.id,
    parentId: request.parentId,
  );

  static void _validate(WorkspaceFileUpload request) {
    final id = request.id;
    final name = request.name.trim();
    if (id.isEmpty || id.length > 128 || name.isEmpty || name.length > 200) {
      throw const WorkspaceAssetException(.invalid);
    }
  }
}

class const WorkspaceFileUpload({
  required final String id,
  required final String name,
  required final WorkspaceAssetDraft source,
  required final String? parentId,
  final WorkspaceAsset? uploaded,
});

/// A retry reuses the completed upload instead of storing the same bytes again.
class const WorkspaceFileCreationFailure(
  final WorkspaceAsset uploaded,
  final Object cause,
) implements Exception;
