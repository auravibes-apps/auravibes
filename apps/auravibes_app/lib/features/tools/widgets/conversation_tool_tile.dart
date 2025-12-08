import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tool_extensions_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Tile widget for a single conversation tool.
///
/// Shows:
/// - Tool icon with enabled/disabled styling
/// - Tool name and description
/// - Toggle indicator (check circle / empty circle / blocked)
/// - Permission selector when tool is enabled
class ConversationToolTile extends HookConsumerWidget {
  const ConversationToolTile({
    required this.toolState,
    required this.workspaceId,
    this.conversationId,
    super.key,
  });

  final ConversationToolState toolState;
  final String workspaceId;
  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onToggle = useCallback(() async {
      final notifier = ref.read(
        conversationToolsProvider(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ).notifier,
      );
      await notifier.toggleTool(toolState.tool.id);
    }, [conversationId, workspaceId, toolState.tool]);

    final onPermissionChanged = useCallback((ToolPermissionMode? mode) async {
      if (mode == null) return;
      final notifier = ref.read(
        conversationToolsProvider(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ).notifier,
      );
      await notifier.setToolPermission(
        toolState.tool.id,
        permissionMode: mode,
      );
    }, [conversationId, workspaceId, toolState.tool]);

    final isEnabled = toolState.isEnabled;
    final isWorkspaceEnabled = toolState.isWorkspaceEnabled;

    return AuraCard(
      padding: .none,
      style: AuraCardStyle.border,
      onTap: isWorkspaceEnabled ? onToggle : null,
      child: AuraColumn(
        spacing: AuraSpacing.none,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main tool row
          AuraPadding(
            padding: .medium,
            child: AuraRow(
              spacing: AuraSpacing.md,
              children: [
                // Tool icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isEnabled && isWorkspaceEnabled
                        ? context.auraColors.primary.withValues(alpha: 0.1)
                        : context.auraColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                      DesignBorderRadius.md,
                    ),
                  ),
                  child: toolState.tool.getIconWidget(),
                ),

                // Tool name and description
                Expanded(
                  child: AuraColumn(
                    spacing: AuraSpacing.xs,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuraText(
                        color: isWorkspaceEnabled
                            ? AuraColorVariant.onSurface
                            : AuraColorVariant.onSurfaceVariant,
                        child: toolState.tool.getNameWidget(),
                      ),
                      if (!isWorkspaceEnabled)
                        AuraText(
                          style: AuraTextStyle.bodySmall,
                          color: AuraColorVariant.onSurfaceVariant,
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                            child: const Text('Disabled in workspace'),
                          ),
                        )
                      else
                        AuraText(
                          style: AuraTextStyle.bodySmall,
                          color: AuraColorVariant.onSurfaceVariant,
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: toolState.tool.getDescriptionWidget(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Toggle indicator
                if (isWorkspaceEnabled)
                  AuraIcon(
                    isEnabled ? Icons.check_circle : Icons.circle_outlined,
                    color: isEnabled
                        ? context.auraColors.primary
                        : context.auraColors.onSurfaceVariant,
                  )
                else
                  AuraIcon(
                    Icons.block,
                    size: AuraIconSize.small,
                    color: context.auraColors.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
              ],
            ),
          ),

          // Permission selector - always visible when tool is enabled
          if (isEnabled && isWorkspaceEnabled) ...[
            const AuraDivider(),
            AuraPadding(
              padding: .medium,
              child: AuraColumn(
                spacing: AuraSpacing.sm,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuraText(
                    style: AuraTextStyle.bodySmall,
                    color: AuraColorVariant.onSurfaceVariant,
                    child: TextLocale(LocaleKeys.tools_screen_permission_label),
                  ),
                  ToolPermissionSelector(
                    value: toolState.permissionMode,
                    onChanged: onPermissionChanged,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Permission mode selector widget.
///
/// Displays a button group for selecting between
/// "Always Ask" and "Always Allow".
class ToolPermissionSelector extends StatelessWidget {
  const ToolPermissionSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ToolPermissionMode value;
  final void Function(ToolPermissionMode?) onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraButtonGroup<ToolPermissionMode>.single(
      items: const [
        AuraButtonGroupItem(
          value: ToolPermissionMode.alwaysAsk,
          child: TextLocale(LocaleKeys.tools_screen_permission_always_ask),
        ),
        AuraButtonGroupItem(
          value: ToolPermissionMode.alwaysAllow,
          child: TextLocale(LocaleKeys.tools_screen_permission_always_allow),
        ),
      ],
      selectedValue: value,
      onChanged: onChanged,
      size: AuraButtonGroupSize.sm,
    );
  }
}
