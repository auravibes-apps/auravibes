import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

/// Opens the access details action for a workspace location.
class const WorkspaceLocationAccessAction({
  required final bool canViewMembers,
  required final VoidCallback onPressed,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labelKey = canViewMembers
        ? 'workspace_location.view_members'
        : 'workspace_location.view_access';

    return AuraButton(
      onPressed: onPressed,
      child: TextLocale(labelKey),
      key: const ValueKey<String>('workspace_location_access'),
      variant: .outlined,
      size: .small,
    );
  }
}
