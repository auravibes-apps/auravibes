// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_permission_selector.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kToolItemIconSize = 36.0;

/// A simplified tool row widget for display inside tool groups.
///
/// This is a more compact version of the full WorkspaceToolCard,
/// designed for use within collapsible group cards.
class const ToolItemRow({
  /// The tool to display.
  required final WorkspaceToolEntity tool,
  required final String workspaceId,

  /// Whether to show the delete button.
  /// Should be false for MCP tools (they can't be individually deleted).
  final bool showDeleteButton = true,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    return _ToolItemBody(
      tool: tool,
      workspaceId: workspaceId,
      showDeleteButton: showDeleteButton,
      isExpanded: isExpanded.value,
      onEnabledChanged: _enabledChanged(ref),
      onToggleExpanded: _toggleExpanded(isExpanded),
    );
  }

  ValueChanged<bool> _enabledChanged(WidgetRef ref) =>
      (value) => _setToolEnabled(ref, value);

  VoidCallback _toggleExpanded(ValueNotifier<bool> isExpanded) =>
      () => isExpanded.value = !isExpanded.value;

  void _setToolEnabled(WidgetRef ref, bool value) {
    ref
        .read(workspaceToolsProvider(workspaceId).notifier)
        .setToolEnabled(tool.id, isEnabled: value);
  }
}

class const _ToolItemBody({
  required final WorkspaceToolEntity tool,
  required final String workspaceId,
  required final bool showDeleteButton,
  required final bool isExpanded,
  required final ValueChanged<bool> onEnabledChanged,
  required final VoidCallback onToggleExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPadding(
      padding: const .symmetric(vertical: .xs),
      child: _ToolItemColumn(
        tool: tool,
        workspaceId: workspaceId,
        showDeleteButton: showDeleteButton,
        isExpanded: isExpanded,
        onEnabledChanged: onEnabledChanged,
        onToggleExpanded: onToggleExpanded,
      ),
    );
  }
}

class const _ToolItemColumn({
  required final WorkspaceToolEntity tool,
  required final String workspaceId,
  required final bool showDeleteButton,
  required final bool isExpanded,
  required final ValueChanged<bool> onEnabledChanged,
  required final VoidCallback onToggleExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: _children(),
      crossAxisAlignment: .start,
    );
  }

  List<Widget> _children() {
    final isEnabled = tool.isEnabled;
    return [
      _ToolItemHeader(
        tool: tool,
        isEnabled: isEnabled,
        isExpanded: isExpanded,
        onEnabledChanged: onEnabledChanged,
        onToggleExpanded: onToggleExpanded,
      ),
      if (isExpanded)
        _ExpandedToolOptions(
          tool: tool,
          workspaceId: workspaceId,
          isEnabled: isEnabled,
          permissionMode: tool.permissionMode,
          showDeleteButton: showDeleteButton,
        ),
    ];
  }
}

class const _ExpandedToolOptions({
  required final WorkspaceToolEntity tool,
  required final String workspaceId,
  required final bool isEnabled,
  required final ToolPermissionMode permissionMode,
  required final bool showDeleteButton,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: _kToolItemIconSize + context.auraTheme.fromSpacing(.sm),
        top: context.auraTheme.fromSpacing(.sm),
      ),
      child: _ToolOptions(
        tool: tool,
        workspaceId: workspaceId,
        isEnabled: isEnabled,
        permissionMode: permissionMode,
        showDeleteButton: showDeleteButton,
      ),
    );
  }
}

/// Options section for an expanded tool item.
class const _ToolOptions({
  required final WorkspaceToolEntity tool,
  required final String workspaceId,
  required final bool isEnabled,
  required final ToolPermissionMode permissionMode,
  required final bool showDeleteButton,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraColumn(
      children: [
        if (isEnabled)
          _ToolPermissionModeRow(
            permissionMode: permissionMode,
            onChanged: (mode) => _setPermissionMode(ref, mode),
          ),
        if (showDeleteButton && !tool.isNative)
          _RemoveToolButton(
            onPressed: () => _confirmDelete(context, ref, tool),
          ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }

  void _setPermissionMode(WidgetRef ref, ToolPermissionMode? mode) {
    if (mode == null) return;

    ref
        .read(workspaceToolsProvider(workspaceId).notifier)
        .setToolPermissionMode(tool.id, permissionMode: mode);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkspaceToolEntity workspaceTool,
  ) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed != true) return;

    final _ = await ref
        .read(workspaceToolsProvider(workspaceId).notifier)
        .removeToolById(workspaceTool.id);
  }
}

class const _ToolItemHeader({
  required final WorkspaceToolEntity tool,
  required final bool isEnabled,
  required final bool isExpanded,
  required final ValueChanged<bool> onEnabledChanged,
  required final VoidCallback onToggleExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        _ToolItemIcon(tool: tool, isEnabled: isEnabled),
        const AuraSizedBox(width: .sm),
        Expanded(child: _ToolItemDescription(tool: tool)),
        _ToolItemActions(
          isEnabled: isEnabled,
          isExpanded: isExpanded,
          onEnabledChanged: onEnabledChanged,
          onToggleExpanded: onToggleExpanded,
        ),
      ],
    );
  }
}

class const _ToolItemIcon({
  required final WorkspaceToolEntity tool,
  required final bool isEnabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.all(
          .circular(context.auraTheme.fromBorderRadius(.sm)),
        ),
      ),
      width: _kToolItemIconSize,
      height: _kToolItemIconSize,
      child: _ToolIconContent(tool: tool, isEnabled: isEnabled),
    );
  }
}

class const _ToolIconContent({
  required final WorkspaceToolEntity tool,
  required final bool isEnabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraText(
        child: tool.getIconWidget(),
        tint: isEnabled ? AuraTint.primary : null,
      ),
    );
  }
}

class const _ToolItemDescription({required final WorkspaceToolEntity tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(child: tool.getNameWidget()),
        AuraText(
          child: DefaultTextStyle.merge(
            overflow: .ellipsis,
            maxLines: 1,
            child: tool.getDescriptionWidget(),
          ),
          style: .bodySmall,
        ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _ToolItemActions({
  required final bool isEnabled,
  required final bool isExpanded,
  required final ValueChanged<bool> onEnabledChanged,
  required final VoidCallback onToggleExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraSwitch(value: isEnabled, onChanged: onEnabledChanged, size: .sm),
        _ToolExpandButton(isExpanded: isExpanded, onPressed: onToggleExpanded),
      ],
    );
  }
}

class const _ToolExpandButton({
  required final bool isExpanded,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton.custom(
      child: AnimatedRotation(
        child: const AuraIcon(Icons.keyboard_arrow_down, size: .small),
        turns: isExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
      ),
      onPressed: onPressed,
      size: .small,
    );
  }
}

class const _ToolPermissionModeRow({
  required final ToolPermissionMode permissionMode,
  required final ValueChanged<ToolPermissionMode?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.tools_screen_permission_label),
          style: .bodySmall,
        ),
        ToolPermissionSelector(value: permissionMode, onChanged: onChanged),
      ],
      mainAxisAlignment: .spaceBetween,
    );
  }
}

class const _RemoveToolButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AuraButton(
        onPressed: onPressed,
        child: const AuraRow(
          children: [
            AuraIcon(Icons.delete_outline, size: .small, tint: .error),
            TextLocale(LocaleKeys.common_remove),
          ],
          spacing: .xs,
          mainAxisSize: .min,
        ),
        variant: .text,
        tint: .error,
        size: .small,
      ),
    );
  }
}

Future<bool?> _showDeleteConfirmation(BuildContext context) {
  return AuraDialogs.confirm(
    context: context,
    title: const TextLocale(LocaleKeys.tools_screen_remove_tool_title),
    message: const TextLocale(LocaleKeys.tools_screen_remove_tool_confirm),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(LocaleKeys.common_remove),
      cancelLabel: TextLocale(LocaleKeys.common_cancel),
    ),
    isDestructive: true,
  );
}
