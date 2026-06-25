// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A simplified tool row widget for display inside tool groups.
///
/// This is a more compact version of the full WorkspaceToolCard,
/// designed for use within collapsible group cards.
class ToolItemRow extends HookConsumerWidget {
  const ToolItemRow({
    required this.tool,
    required this.workspaceId,
    this.showDeleteButton = true,
    super.key,
  });

  /// The tool to display.
  final WorkspaceToolEntity tool;
  final String workspaceId;

  /// Whether to show the delete button.
  /// Should be false for MCP tools (they can't be individually deleted).
  final bool showDeleteButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final isEnabled = tool.isEnabled;
    final permissionMode = tool.permissionMode;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.xs),
      ),
      child: AuraColumn(
        children: [
          AuraRow(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isEnabled
                      ? context.auraColors.primary.withValues(alpha: 0.1)
                      : context.auraColors.surfaceVariant,
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      context.auraTheme.fromBorderRadius(.sm),
                    ),
                  ),
                ),
                width: 36,
                height: 36,
                child: Center(
                  child: AuraText(
                    child: tool.getIconWidget(),
                    color: isEnabled
                        ? AuraColorVariant.primary
                        : AuraColorVariant.onSurfaceVariant,
                  ),
                ),
              ),
              const AuraSizedBox(width: .sm),
              Expanded(
                child: AuraColumn(
                  children: [
                    AuraText(child: tool.getNameWidget()),
                    AuraText(
                      child: DefaultTextStyle.merge(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        child: tool.getDescriptionWidget(),
                      ),
                      style: AuraTextStyle.bodySmall,
                      color: AuraColorVariant.onSurfaceVariant,
                    ),
                  ],
                  spacing: .xs,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
              ),
              AuraSwitch(
                value: isEnabled,
                onChanged: (value) {
                  ref
                      .read(workspaceToolsProvider(workspaceId).notifier)
                      .setToolEnabled(tool.id, isEnabled: value);
                },
                size: AuraSwitchSize.sm,
              ),
              AuraIconButton.custom(
                child: AnimatedRotation(
                  child: const AuraIcon(
                    Icons.keyboard_arrow_down,
                    size: AuraIconSize.small,
                    color: AuraColorVariant.onSurfaceVariant,
                  ),
                  turns: isExpanded.value ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                ),
                onPressed: () => isExpanded.value = !isExpanded.value,
                size: AuraIconSize.small,
              ),
            ],
          ),
          if (isExpanded.value)
            Padding(
              padding: EdgeInsets.only(
                left: 36 + context.auraTheme.fromSpacing(.sm),
                top: context.auraTheme.fromSpacing(.sm),
              ),
              child: _ToolOptions(
                tool: tool,
                workspaceId: workspaceId,
                isEnabled: isEnabled,
                permissionMode: permissionMode,
                showDeleteButton: showDeleteButton,
              ),
            ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

/// Options section for an expanded tool item.
class _ToolOptions extends HookConsumerWidget {
  const _ToolOptions({
    required this.tool,
    required this.workspaceId,
    required this.isEnabled,
    required this.permissionMode,
    required this.showDeleteButton,
  });

  final WorkspaceToolEntity tool;
  final String workspaceId;
  final bool isEnabled;
  final ToolPermissionMode permissionMode;
  final bool showDeleteButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceTool = tool;

    return AuraColumn(
      children: [
        if (isEnabled)
          AuraRow(
            children: [
              const AuraText(
                child: TextLocale(LocaleKeys.tools_screen_permission_label),
                style: AuraTextStyle.bodySmall,
              ),
              AuraButtonGroup<ToolPermissionMode>.single(
                items: const [
                  AuraButtonGroupItem(
                    value: ToolPermissionMode.alwaysAsk,
                    child: TextLocale(
                      LocaleKeys.tools_screen_permission_always_ask,
                    ),
                  ),
                  AuraButtonGroupItem(
                    value: ToolPermissionMode.alwaysAllow,
                    child: TextLocale(
                      LocaleKeys.tools_screen_permission_always_allow,
                    ),
                  ),
                ],
                selectedValue: permissionMode,
                onChanged: (mode) {
                  ref
                      .read(workspaceToolsProvider(workspaceId).notifier)
                      .setToolPermissionMode(
                        workspaceTool.id,
                        permissionMode: mode,
                      );
                },
                size: AuraButtonGroupSize.sm,
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        if (showDeleteButton && !workspaceTool.isNative)
          Align(
            alignment: Alignment.centerRight,
            child: AuraButton(
              onPressed: () => _confirmDelete(context, ref, workspaceTool),
              child: const AuraRow(
                children: [
                  AuraIcon(
                    Icons.delete_outline,
                    size: AuraIconSize.small,
                    color: AuraColorVariant.error,
                  ),
                  TextLocale(LocaleKeys.common_remove),
                ],
                spacing: .xs,
                mainAxisSize: MainAxisSize.min,
              ),
              variant: AuraButtonVariant.text,
              colorVariant: AuraColorVariant.error,
              size: AuraButtonSize.small,
            ),
          ),
      ],
      spacing: .sm,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkspaceToolEntity workspaceTool,
  ) async {
    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: const TextLocale(LocaleKeys.tools_screen_remove_tool_title),
      message: const TextLocale(LocaleKeys.tools_screen_remove_tool_confirm),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_remove),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );

    if (confirmed ?? false) {
      final _ = await ref
          .read(workspaceToolsProvider(workspaceId).notifier)
          .removeToolById(workspaceTool.id);
    }
  }
}
