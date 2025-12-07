import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tool_extensions_widgets.dart';
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
    this.showDeleteButton = true,
    super.key,
  });

  /// The tool to display.
  final WorkspaceToolEntity tool;

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
        vertical: context.auraTheme.spacing.xs,
      ),
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row: icon, name, toggle, expand chevron
          AuraRow(
            children: [
              // Tool icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? context.auraColors.primary.withValues(alpha: 0.1)
                      : context.auraColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                    context.auraTheme.borderRadius.sm,
                  ),
                ),
                child: Center(
                  child: AuraText(
                    color: isEnabled
                        ? AuraColorVariant.primary
                        : AuraColorVariant.onSurfaceVariant,
                    child: tool.getIconWidget(),
                  ),
                ),
              ),
              SizedBox(width: context.auraTheme.spacing.sm),

              // Tool name and description
              Expanded(
                child: AuraColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AuraSpacing.xs,
                  children: [
                    AuraText(
                      child: tool.getNameWidget(),
                    ),
                    AuraText(
                      style: AuraTextStyle.bodySmall,
                      color: AuraColorVariant.onSurfaceVariant,
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: tool.getDescriptionWidget(),
                      ),
                    ),
                  ],
                ),
              ),

              // Enable toggle
              AuraSwitch(
                value: isEnabled,
                onChanged: (value) {
                  ref
                      .read(workspaceToolsProvider.notifier)
                      .setToolEnabled(
                        tool.id,
                        isEnabled: value,
                      );
                },
                size: AuraSwitchSize.sm,
              ),

              // Expand/collapse for options
              IconButton(
                onPressed: () => isExpanded.value = !isExpanded.value,
                icon: AnimatedRotation(
                  turns: isExpanded.value ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: AuraIcon(
                    Icons.keyboard_arrow_down,
                    size: AuraIconSize.small,
                    color: context.auraColors.onSurfaceVariant,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Expanded options
          if (isExpanded.value)
            Padding(
              padding: EdgeInsets.only(
                left: 36 + context.auraTheme.spacing.sm,
                top: context.auraTheme.spacing.sm,
              ),
              child: _ToolOptions(
                tool: tool,
                isEnabled: isEnabled,
                permissionMode: permissionMode,
                showDeleteButton: showDeleteButton,
              ),
            ),
        ],
      ),
    );
  }
}

/// Options section for an expanded tool item.
class _ToolOptions extends HookConsumerWidget {
  const _ToolOptions({
    required this.tool,
    required this.isEnabled,
    required this.permissionMode,
    required this.showDeleteButton,
  });

  final WorkspaceToolEntity tool;
  final bool isEnabled;
  final ToolPermissionMode permissionMode;
  final bool showDeleteButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceTool = tool;

    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.sm,
      children: [
        // Permission selector - only when enabled
        if (isEnabled)
          AuraRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AuraText(
                style: AuraTextStyle.bodySmall,
                child: TextLocale(LocaleKeys.tools_screen_permission_label),
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
                      .read(workspaceToolsProvider.notifier)
                      .setToolPermissionMode(
                        workspaceTool.id,
                        permissionMode: mode,
                      );
                },
                size: AuraButtonGroupSize.sm,
              ),
            ],
          ),

        // Delete button - only for built-in tools that can be removed
        if (showDeleteButton)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context, ref, workspaceTool),
              icon: AuraIcon(
                Icons.delete_outline,
                size: AuraIconSize.small,
                color: context.auraColors.error,
              ),
              label: AuraText(
                style: AuraTextStyle.bodySmall,
                child: Text(
                  'Remove',
                  style: TextStyle(color: context.auraColors.error),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WorkspaceToolEntity workspaceTool,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TextLocale(LocaleKeys.tools_screen_remove_tool_title),
        content: const TextLocale(LocaleKeys.tools_screen_remove_tool_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TextLocale(LocaleKeys.common_remove),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref
          .read(workspaceToolsProvider.notifier)
          .removeToolById(workspaceTool.id);
    }
  }
}
