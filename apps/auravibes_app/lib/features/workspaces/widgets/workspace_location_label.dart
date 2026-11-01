import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Displays a workspace location label with its semantic description.
class const WorkspaceLocationLabel({required final String labelKey, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      child: TextLocale(labelKey),
      container: true,
      excludeSemantics: true,
      identifier: 'workspace_location_status',
      label: labelKey.tr(context: context),
    ),
  );
}
