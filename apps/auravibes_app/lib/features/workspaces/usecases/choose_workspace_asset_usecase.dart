import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_input.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_asset_file_service.dart';

class const ChooseWorkspaceAssetUsecase(final WorkspaceAssetFileService files) {
  Future<WorkspaceAssetDraft?> call() async {
    final selected = await files.pick();
    if (selected == null) return null;
    final _ = WorkspaceAssetInput.validate(selected.name, selected.bytes);

    return selected;
  }
}
