import 'package:auravibes_app/features/workspaces/models/workspace_location_info.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Displays the active workspace location and optional access details action.
class const WorkspaceLocationStatus({
  /// The location and sharing details to show.
  required final WorkspaceLocationInfo info,

  super.key,

  /// Opens details for a cloud workspace when available.
  final VoidCallback? onViewAccess,
}) extends StatelessWidget {
  String get _labelKey => switch (info.kind) {
    .onDevice => 'workspace_location.on_device',
    .personalCloud => 'workspace_location.personal_cloud',
    .teamWorkspace => 'workspace_location.team_workspace',
    .cloud => 'workspace_location.cloud_workspace',
  };

  String get _accessLabelKey => info.canViewMembers
      ? 'workspace_location.view_members'
      : 'workspace_location.view_access';

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
        Expanded(
          child: Semantics(
            child: TextLocale(_labelKey),
            container: true,
            excludeSemantics: true,
            identifier: 'workspace_location_status',
            label: _labelKey.tr(context: context),
          ),
        ),
        if (onViewAccess case final callback?) ...[
          const AuraSizedBox(width: .xs),
          AuraButton(
            onPressed: callback,
            child: TextLocale(_accessLabelKey),
            key: const ValueKey<String>('workspace_location_access'),
            variant: .outlined,
            size: .small,
          ),
        ],
      ],
    ),
    padding: const .horizontal(.sm),
  );
}
