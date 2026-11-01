import 'package:auravibes_app/features/workspaces/models/workspace_location_info.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_location_access_action.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_location_label.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// Displays the active workspace location and optional access details action.
class const WorkspaceLocationStatus({
  /// The location and sharing details to show.
  required final WorkspaceLocationInfo info,

  super.key,

  /// Opens details for a cloud workspace when available.
  final VoidCallback? onViewAccess,
}) extends StatelessWidget {
  IconData get _icon => switch (info.kind) {
    .onDevice => Icons.devices_outlined,
    .personalCloud => Icons.cloud_outlined,
    .teamWorkspace => Icons.groups_outlined,
    .cloud => Icons.cloud_queue_outlined,
  };

  @override
  Widget build(BuildContext context) => AuraPadding(
    child: Row(
      children: [
        AuraIcon(_icon, size: .small),
        const AuraSizedBox(width: .xs),
        WorkspaceLocationLabel(labelKey: info.labelKey()),
        if (onViewAccess case final callback?) ...[
          const AuraSizedBox(width: .xs),
          WorkspaceLocationAccessAction(
            canViewMembers: info.canViewMembers,
            onPressed: callback,
          ),
        ],
      ],
    ),
    padding: const .horizontal(.sm),
  );
}
