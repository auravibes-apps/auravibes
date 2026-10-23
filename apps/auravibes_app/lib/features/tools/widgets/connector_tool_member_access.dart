import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_access_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

class const ConnectorToolMemberAccess({
  required final WorkspaceToolEntity tool,
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workspaceSessionForRouteProvider(workspaceId));
    if (session.value?.cloud == null) return const SizedBox.shrink();
    final config = _memberConfig(tool.config);

    return _MemberAccessSelector(
      tool: tool,
      config: config,
      enabled: ref.watch(canManageWorkspaceProvider(workspaceId)),
      onChanged: _changed(context, ref, config),
    );
  }

  ValueChanged<String?> _changed(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> config,
  ) =>
      (value) => unawaited(
        _setAccess((context: context, ref: ref, value: value, config: config)),
      );

  Future<void> _setAccess(_MemberAccessChange change) async {
    final (:context, :ref, :value, :config) = change;
    if (value == null) return;
    try {
      await ref
          .read(workspaceToolsProvider(workspaceId).notifier)
          .updateToolConfig(
            tool.id,
            jsonEncode({...config, 'memberAccess': value}),
          );
    } on Object catch (error, stackTrace) {
      if (!context.mounted) return;
      _showAccessError(context, error, stackTrace);
    }
  }
}

const List<AuraDropdownOption<String>> _memberAccessOptions = [
  AuraDropdownOption(
    value: 'none',
    child: TextLocale(LocaleKeys.service_connections_member_tool_access_none),
  ),
  AuraDropdownOption(
    value: 'read',
    child: TextLocale(LocaleKeys.service_connections_member_tool_access_read),
  ),
  AuraDropdownOption(
    value: 'readWrite',
    child: TextLocale(
      LocaleKeys.service_connections_member_tool_access_read_write,
    ),
  ),
];

typedef _MemberAccessChange = ({
  BuildContext context,
  WidgetRef ref,
  String? value,
  Map<String, dynamic> config,
});
Map<String, dynamic> _memberConfig(String? raw) =>
    raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
void _showAccessError(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
) {
  Logger('ConnectorToolMemberAccess').warning(
    'Failed to update member tool access',
    error.runtimeType,
    stackTrace,
  );
  if (!context.mounted) return;
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(LocaleKeys.service_connections_save_error),
    variant: .error,
  );
}

class const _MemberAccessSelector({
  required final WorkspaceToolEntity tool,
  required final Map<String, dynamic> config,
  required final bool enabled,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: _memberAccessOptions,
    key: ValueKey('connector-member-access-${tool.toolId}'),
    value: config['memberAccess'] as String? ?? 'none',
    onChanged: onChanged,
    label: const TextLocale(
      LocaleKeys.service_connections_member_tool_access_title,
    ),
    isEnabled: enabled,
  );
}
