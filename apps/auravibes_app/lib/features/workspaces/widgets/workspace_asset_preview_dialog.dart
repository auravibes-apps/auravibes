import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_panel.dart';
import 'package:material_ui/material_ui.dart';

abstract final class WorkspaceAssetPreviewDialog {
  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    required String assetId,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _Content(workspaceId, assetId),
    );
  }
}

class const _Content(final String workspaceId, final String assetId)
    extends StatelessWidget {
  static const _width = 640.0;
  static const _height = 600.0;
  static const _padding = EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) => Dialog(
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
  );
}
