// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
import 'dart:async';

import 'package:auravibes_app/features/tools/models/tools_group_mixin.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/add_mcp_modal.dart';
import 'package:auravibes_app/features/tools/widgets/add_tool_modal.dart';
import 'package:auravibes_app/features/tools/widgets/tool_count_enabled_widget.dart';
import 'package:auravibes_app/features/tools/widgets/tools_workspace_list_widget.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ToolsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue
        .capabilities;

    return _ToolsScreenView(
      workspaceId: workspaceId,
      showAddToolButton: capabilities.nativeTools,
      onRefresh: () => ref.invalidate(workspaceToolsProvider(workspaceId)),
      onReset: () =>
          unawaited(_resetWorkspaceToolPermissions(context, ref, workspaceId)),
    );
  }
}

class const _ToolsScreenView({
  required final String workspaceId,
  required final bool showAddToolButton,
  required final VoidCallback onRefresh,
  required final VoidCallback onReset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ToolsScreenStack(
        workspaceId: workspaceId,
        showAddToolButton: showAddToolButton,
      ),
      appBar: _ToolsScreenAppBar(
        workspaceId: workspaceId,
        onRefresh: onRefresh,
        onReset: onReset,
      ),
    );
  }
}

class const _ToolsScreenStack({
  required final String workspaceId,
  required final bool showAddToolButton,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ToolsScreenMainContent(workspaceId: workspaceId),
        _ToolsScreenAddToolButton(
          workspaceId: workspaceId,
          visible: showAddToolButton,
        ),
      ],
    );
  }
}

class const _ToolsScreenMainContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _ToolsScreenContent(workspaceId: workspaceId),
    );
  }
}

class const _ToolsScreenAddToolButton({
  required final String workspaceId,
  required final bool visible,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: context.auraTheme.fromSpacing(.md),
      bottom: context.auraTheme.fromSpacing(.md),
      child: Visibility(
        child: _AddToolButton(workspaceId: workspaceId),
        visible: visible,
      ),
    );
  }
}

class const _ToolsScreenContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _ToolsOverviewCard(workspaceId: workspaceId),
        Expanded(child: ToolsWorkspaceListWidget(workspaceId: workspaceId)),
      ],
    );
  }
}

class const _ToolsOverviewCard({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(child: _ToolsOverviewContent(workspaceId: workspaceId));
  }
}

class const _ToolsOverviewContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const _ToolsOverviewText(),
        _EnabledToolsBadge(workspaceId: workspaceId),
        _ReconnectFailedMcpsButton(workspaceId: workspaceId),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _ToolsOverviewText() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraColumn(
      children: [
        _ToolsOverviewHeader(),
        AuraText(
          child: TextLocale(
            LocaleKeys.tools_screen_enable_configure_description,
          ),
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _ToolsOverviewHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraRow(
      children: [
        AuraText(
          child: Icon(Icons.build_circle_outlined),
          style: .heading3,
          tint: .primary,
        ),
        AuraText(
          child: TextLocale(LocaleKeys.tools_screen_workspace_ai_tools),
          style: .heading4,
        ),
      ],
    );
  }
}

class const _EnabledToolsBadge({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [_EnabledToolsBadgeContent(workspaceId: workspaceId)]);
  }
}

class const _EnabledToolsBadgeContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraBadge(
      child: _EnabledToolsBadgeLabel(workspaceId: workspaceId),
      variant: .success,
    );
  }
}

class const _EnabledToolsBadgeLabel({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        Icon(Icons.check_circle, size: 16, color: context.auraColors.onSuccess),
        ToolCountEnabledWidget(workspaceId: workspaceId),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    );
  }
}

class const _ReconnectFailedMcpsButton({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReconnecting = useState(false);

    return _ReconnectFailedMcpsButtonContent(
      workspaceId: workspaceId,
      isReconnecting: isReconnecting.value,
      onPressed: () => unawaited(
        _reconnectFailedMcps(
          context: context,
          isReconnecting: isReconnecting,
          reconnect: ref
              .read(groupedToolsProvider(workspaceId).notifier)
              .reconnectFailedMcps,
        ),
      ),
    );
  }
}

class const _ReconnectFailedMcpsButtonContent({
  required final String workspaceId,
  required final bool isReconnecting,
  required final VoidCallback onPressed,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFailedMcp =
        ref
            .watch(groupedToolsProvider(workspaceId))
            .value
            ?.any((group) => group.isMcpGroup && group.needsAttention) ??
        false;

    return _ReconnectFailedMcpsButtonView(
      isReconnecting: isReconnecting,
      hasFailedMcp: hasFailedMcp,
      onPressed: onPressed,
    );
  }
}

class const _ReconnectFailedMcpsButtonView({
  required final bool isReconnecting,
  required final bool hasFailedMcp,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!hasFailedMcp && !isReconnecting) return const SizedBox.shrink();

    return AuraButton(
      onPressed: onPressed,
      child: const TextLocale(LocaleKeys.tools_screen_mcp_reconnect_all),
      variant: .outlined,
      size: .small,
      isLoading: isReconnecting,
      disabled: isReconnecting || !hasFailedMcp,
      semanticLabel: LocaleKeys.tools_screen_mcp_reconnect_all.tr(),
    );
  }
}

Future<void> _reconnectFailedMcps({
  required BuildContext context,
  required ValueNotifier<bool> isReconnecting,
  required Future<List<String>> Function() reconnect,
}) async {
  isReconnecting.value = true;
  try {
    final failedMcpServerIds = await reconnect();
    if (!context.mounted) return;

    _showReconnectPartialFailure(context, failedMcpServerIds);
  } finally {
    if (context.mounted) isReconnecting.value = false;
  }
}

void _showReconnectPartialFailure(
  BuildContext context,
  List<String> failedMcpServerIds,
) {
  if (failedMcpServerIds.isEmpty) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: Text(
      LocaleKeys.tools_screen_mcp_reconnect_partial_failure.plural(
        failedMcpServerIds.length,
      ),
    ),
    variant: .error,
  );
}

class const _AddToolButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraFloatingActionButton(
      onPressed: () => AddToolModal.show(context, workspaceId: workspaceId),
      icon: Icons.add,
      heroTag: const ValueKey<String>('tools_add_tool_fab'),
      tooltip: LocaleKeys.tools_screen_add_tool_tooltip.tr(context: context),
    );
  }
}

class const _ToolsScreenAppBar({
  required final String workspaceId,
  required final VoidCallback onRefresh,
  required final VoidCallback onReset,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBarWithDrawer(
      title: const TextLocale(LocaleKeys.tools_screen_title),
      actions: [
        _AddMcpButton(workspaceId: workspaceId),
        _ResetToolsButton(onPressed: onReset),
        _RefreshToolsButton(onPressed: onRefresh),
      ],
      leading: const _BackButton(),
    );
  }
}

class const _ResetToolsButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.restore,
      onPressed: onPressed,
      tooltip: LocaleKeys.tools_screen_reset_tool_permissions_tooltip.tr(
        context: context,
      ),
    );
  }
}

class const _AddMcpButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.extension,
      onPressed: () => AddMcpModal.show(context, workspaceId: workspaceId),
      tooltip: LocaleKeys.mcp_modal_add_mcp_tooltip.tr(context: context),
    );
  }
}

class const _RefreshToolsButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.refresh,
      onPressed: onPressed,
      tooltip: LocaleKeys.tools_screen_refresh_tooltip.tr(context: context),
    );
  }
}

Future<void> _resetWorkspaceToolPermissions(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  if (!await _confirmResetWorkspaceToolPermissions(context)) return;

  await ref
      .read(workspaceToolsProvider(workspaceId).notifier)
      .resetToolPermissions();
  if (!context.mounted) return;

  ref
    ..invalidate(workspaceToolsProvider(workspaceId))
    ..invalidate(groupedToolsProvider(workspaceId));
}

Future<bool> _confirmResetWorkspaceToolPermissions(BuildContext context) async {
  final confirmed = await AuraDialogs.confirm(
    context: context,
    title: const TextLocale(
      LocaleKeys.tools_screen_reset_tool_permissions_title,
    ),
    message: const TextLocale(
      LocaleKeys.tools_screen_reset_tool_permissions_confirm,
    ),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.common_confirm),
      cancelLabel: TextLocale(LocaleKeys.common_cancel),
    ),
    isDestructive: true,
  );

  return confirmed ?? false;
}

class const _BackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
