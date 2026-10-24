import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_panel.dart';
import 'package:material_ui/material_ui.dart';

const _width = 640.0;
const _height = 600.0;
const _padding = EdgeInsets.all(16);

Future<void> showWorkspaceAssetPreviewDialog(
  BuildContext context, {
  required String workspaceId,
  required String assetId,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: SizedBox(
        width: _width,
        height: _height,
        child: SingleChildScrollView(
          padding: _padding,
          child: WorkspaceAssetPreviewPanel(
            workspaceId: workspaceId,
            assetId: assetId,
          ),
        ),
      ),
    ),
  );
}
