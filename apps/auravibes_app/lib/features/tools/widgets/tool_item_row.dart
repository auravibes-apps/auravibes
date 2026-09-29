// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_permission_selector.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _kToolItemIconSize = 36.0;

typedef ToolItemSelection = ({
  bool isSelected,
  bool isWorking,
  ValueChanged<bool> onChanged,
});

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
  final bool isSelected = false,
  final bool isSelectionEnabled = false,
  final bool isWorking = false,
  final ValueChanged<bool>? onSelectionChanged,
  super.key,
}) extends HookConsumerWidget {
  new selectable({
    required WorkspaceToolEntity tool,
    required String workspaceId,
    required ToolItemSelection selection,
    bool showDeleteButton = true,
    Key? key,
  }) : this(
         tool: tool,
         workspaceId: workspaceId,
         showDeleteButton: showDeleteButton,
         isSelected: selection.isSelected,
         isSelectionEnabled: true,
         isWorking: selection.isWorking,
         onSelectionChanged: selection.onChanged,
         key: key,
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    return _ToolItemBody(
      tool: tool,
      workspaceId: workspaceId,
      showDeleteButton: showDeleteButton,
      isSelected: isSelected,
      isSelectionEnabled: isSelectionEnabled,
      isWorking: isWorking,
      onSelectionChanged: onSelectionChanged,
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
  required final bool isSelected,
  required final bool isSelectionEnabled,
  required final bool isWorking,
  required final ValueChanged<bool>? onSelectionChanged,
  required final bool isExpanded,
  required final ValueChanged<bool> onEnabledChanged,
  required final VoidCallback onToggleExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPadding(
      child: _ToolItemColumn(body: this),
      padding: const .symmetric(vertical: .xs),
    );
  }
}

class const _ToolItemColumn({required final _ToolItemBody body})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _ToolItemHeader(body: body),
        _OptionalExpandedToolOptions(body: body),
      ],
      crossAxisAlignment: .start,
    );
  }
}

class const _OptionalExpandedToolOptions({required final _ToolItemBody body})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!body.isExpanded || body.isWorking) return const SizedBox.shrink();

    return _ExpandedToolOptions(
      tool: body.tool,
      workspaceId: body.workspaceId,
      isEnabled: body.tool.isEnabled,
      permissionMode: body.tool.permissionMode,
      showDeleteButton: body.showDeleteButton,
    );
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
      padding: _toolOptionsPadding(context),
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

EdgeInsets _toolOptionsPadding(BuildContext context) => EdgeInsets.only(
  left: _kToolItemIconSize + context.auraTheme.fromSpacing(.sm),
  top: context.auraTheme.fromSpacing(.sm),
);

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

class const _ToolItemHeader({required final _ToolItemBody body})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        _OptionalToolSelection(body: body),
        _ToolItemIcon(tool: body.tool, isEnabled: body.tool.isEnabled),
        const AuraSizedBox(width: .sm),
        Expanded(child: _ToolItemDescription(tool: body.tool)),
        _ToolItemActions(body: body),
      ],
    );
  }
}

class const _OptionalToolSelection({required final _ToolItemBody body})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!body.isSelectionEnabled) return const SizedBox.shrink();

    return AuraCheckbox(
      value: body.isSelected,
      onChanged: body.isWorking ? null : body.onSelectionChanged,
      key: ValueKey('tool-selection-${body.tool.id}'),
      disabled: body.isWorking,
      semanticLabel: _toolSelectionLabel(body.tool, body.isSelected),
    );
  }
}

String _toolSelectionLabel(WorkspaceToolEntity tool, bool isSelected) =>
    (isSelected
            ? LocaleKeys.tools_screen_deselect_tool
            : LocaleKeys.tools_screen_select_tool)
        .tr(args: [tool.toolId.toHumanReadable()]);

class const _ToolItemIcon({
  required final WorkspaceToolEntity tool,
  required final bool isEnabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _toolIconDecoration(context),
      width: _kToolItemIconSize,
      height: _kToolItemIconSize,
      child: _ToolIconContent(tool: tool, isEnabled: isEnabled),
    );
  }

  BoxDecoration _toolIconDecoration(BuildContext context) => BoxDecoration(
    color: isEnabled
        ? context.auraColors.primary.withValues(alpha: 0.1)
        : context.auraColors.surfaceVariant,
    borderRadius: BorderRadius.all(
      .circular(context.auraTheme.fromBorderRadius(.sm)),
    ),
  );
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
        _ToolDescriptionText(tool: tool),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _ToolDescriptionText({required final WorkspaceToolEntity tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: DefaultTextStyle.merge(
        overflow: .ellipsis,
        maxLines: 1,
        child: tool.getDescriptionWidget(),
      ),
      style: .bodySmall,
    );
  }
}

class const _ToolItemActions({required final _ToolItemBody body})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraSwitch(
          value: body.tool.isEnabled,
          onChanged: body.isWorking ? null : body.onEnabledChanged,
          size: .sm,
          disabled: body.isWorking,
        ),
        _ToolExpandButton(
          isExpanded: body.isExpanded,
          onPressed: body.onToggleExpanded,
        ),
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
        child: const _RemoveToolLabel(),
        variant: .text,
        tint: .error,
        size: .small,
      ),
    );
  }
}

class const _RemoveToolLabel() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraRow(
      children: [
        AuraIcon(Icons.delete_outline, size: .small, tint: .error),
        TextLocale(LocaleKeys.common_remove),
      ],
      spacing: .xs,
      mainAxisSize: .min,
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
