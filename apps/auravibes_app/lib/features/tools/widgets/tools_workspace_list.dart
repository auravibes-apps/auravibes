import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tool_description.dart';
import 'package:auravibes_app/features/tools/widgets/tool_icon.dart';
import 'package:auravibes_app/features/tools/widgets/tool_name.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToolsWorkspaceListWidget extends HookConsumerWidget {
  const ToolsWorkspaceListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceToolsAsync = ref.watch(
      workspaceToolsProvider.select(
        (asyncValue) => asyncValue.whenData((value) => value.length),
      ),
    );

    return switch (workspaceToolsAsync) {
      AsyncLoading() => const AuraSpinner(),

      AsyncData(:final value) when value == 0 => _EmptyToolsState(),

      AsyncData(:final value) => ListView.builder(
        itemCount: value,
        itemBuilder: (context, index) {
          return ProviderScope(
            overrides: [workspaceToolIndexProvider.overrideWithValue(index)],
            child: const WorkspaceToolCard(),
          );
        },
      ),

      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}

class _EmptyToolsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.auraTheme.spacing.xl),
        child: AuraColumn(
          mainAxisSize: MainAxisSize.min,
          spacing: AuraSpacing.md,
          children: [
            AuraIcon(
              Icons.build_circle_outlined,
              size: AuraIconSize.extraLarge,
              color: context.auraColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const AuraText(
              style: AuraTextStyle.heading6,
              color: AuraColorVariant.onSurfaceVariant,
              textAlign: TextAlign.center,
              child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
            ),
            const AuraText(
              style: AuraTextStyle.bodySmall,
              color: AuraColorVariant.onSurfaceVariant,
              textAlign: TextAlign.center,
              child: TextLocale(LocaleKeys.tools_screen_add_tools_hint),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceToolCard extends HookConsumerWidget {
  const WorkspaceToolCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceToolRow = ref.watch(workspaceToolRowProvider);
    final isExpanded = useState(false);

    final onToggle = useCallback((bool value) {
      final toolType = workspaceToolRow?.$1;
      if (toolType == null) return;
      ref
          .read(workspaceToolsProvider.notifier)
          .setToolEnabled(toolType.value, isEnabled: value);
    }, []);

    final onRemove = useCallback(() async {
      final toolType = workspaceToolRow?.$1;
      final toolEntity = workspaceToolRow?.$2;
      if (toolType == null || toolEntity == null) return;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const TextLocale(LocaleKeys.tools_screen_remove_tool_title),
          content: const TextLocale(
            LocaleKeys.tools_screen_remove_tool_confirm,
          ),
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
            .removeToolById(toolEntity.id, toolType);
      }
    }, []);

    final onPermissionChanged = useCallback((ToolPermissionMode? mode) {
      final toolEntity = workspaceToolRow?.$2;
      if (toolEntity == null || mode == null) return;
      ref
          .read(workspaceToolsProvider.notifier)
          .setToolPermissionMode(toolEntity.id, permissionMode: mode);
    }, []);

    if (workspaceToolRow == null) return const SizedBox.shrink();
    final (toolType, workspaceTool) = workspaceToolRow;
    final isEnabled = workspaceTool?.isEnabled ?? false;
    final hasConfig = workspaceTool?.hasConfig ?? false;
    final permissionMode =
        workspaceTool?.permissionMode ?? ToolPermissionMode.alwaysAsk;

    return Padding(
      padding: EdgeInsets.only(bottom: context.auraTheme.spacing.md),
      child: AuraCard(
        child: AuraColumn(
          spacing: AuraSpacing.sm,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuraRow(
              children: [
                // Tool icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? context.auraColors.primary.withValues(alpha: 0.1)
                        : context.auraColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                      context.auraTheme.borderRadius.lg,
                    ),
                  ),
                  child: AuraText(
                    color: isEnabled
                        ? AuraColorVariant.onPrimary
                        : AuraColorVariant.onSurfaceVariant,
                    child: ToolIconWidget(toolType: toolType),
                  ),
                ),

                // Tool info
                Expanded(
                  child: AuraColumn(
                    spacing: AuraSpacing.xs,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuraText(
                        style: AuraTextStyle.heading6,
                        child: ToolNameWidget(toolType: toolType),
                      ),
                      AuraText(
                        style: AuraTextStyle.bodySmall,
                        color: AuraColorVariant.onPrimary,
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          child: ToolDescriptionWidget(toolType: toolType),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand/collapse arrow
                IconButton(
                  onPressed: () => isExpanded.value = !isExpanded.value,
                  icon: AnimatedRotation(
                    turns: isExpanded.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AuraIcon(
                      Icons.keyboard_arrow_down,
                      color: context.auraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            // Expandable options section - only show when expanded
            if (isExpanded.value) ...[
              const AuraDivider(),
              _ToolOptionsSection(
                isEnabled: isEnabled,
                permissionMode: permissionMode,
                hasConfig: hasConfig,
                onToggle: onToggle,
                onPermissionChanged: onPermissionChanged,
                onRemove: onRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolOptionsSection extends StatelessWidget {
  const _ToolOptionsSection({
    required this.isEnabled,
    required this.permissionMode,
    required this.hasConfig,
    required this.onToggle,
    required this.onPermissionChanged,
    required this.onRemove,
  });

  final bool isEnabled;
  final ToolPermissionMode permissionMode;
  final bool hasConfig;
  final void Function(bool value) onToggle;
  final void Function(ToolPermissionMode?) onPermissionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      spacing: AuraSpacing.md,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enabled/Disabled toggle row
        AuraRow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AuraText(
              child: TextLocale(LocaleKeys.tools_screen_enabled_label),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: context.auraColors.primary,
                activeTrackColor: context.auraColors.primary.withValues(
                  alpha: 0.3,
                ),
                inactiveThumbColor: context.auraColors.onSurfaceVariant,
                inactiveTrackColor: context.auraColors.outline,
              ),
            ),
          ],
        ),

        // Permission selector - only show when enabled
        if (isEnabled)
          AuraRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AuraText(
                child: TextLocale(LocaleKeys.tools_screen_permission_label),
              ),
              _PermissionSelector(
                value: permissionMode,
                onChanged: onPermissionChanged,
              ),
            ],
          ),

        // Config badge if has config
        if (hasConfig)
          AuraBadge.text(
            variant: AuraBadgeVariant.warning,
            size: AuraBadgeSize.small,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuraIcon(
                  Icons.settings,
                  size: AuraIconSize.extraSmall,
                ),
                SizedBox(width: context.auraTheme.spacing.xs),
                const TextLocale(LocaleKeys.tools_screen_configured),
              ],
            ),
          ),

        // Delete button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRemove,
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
}

class _PermissionSelector extends StatelessWidget {
  const _PermissionSelector({
    required this.value,
    required this.onChanged,
  });

  final ToolPermissionMode value;
  final void Function(ToolPermissionMode?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ToolPermissionMode>(
      segments: const [
        ButtonSegment(
          value: ToolPermissionMode.alwaysAsk,
          label: TextLocale(LocaleKeys.tools_screen_permission_always_ask),
        ),
        ButtonSegment(
          value: ToolPermissionMode.alwaysAllow,
          label: TextLocale(LocaleKeys.tools_screen_permission_always_allow),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
