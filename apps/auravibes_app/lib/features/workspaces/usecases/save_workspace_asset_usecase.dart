import 'package:auravibes_app/features/workspaces/services/workspace_asset_file_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';

class const SaveWorkspaceAssetUsecase(
  final ManageWorkspaceAssetsUsecase assets,
  final WorkspaceAssetFileService files,
) {
  Future<bool> call(String assetId) async {
    final current = await assets.preview(assetId);

    return await files.save(current);
  }
}
