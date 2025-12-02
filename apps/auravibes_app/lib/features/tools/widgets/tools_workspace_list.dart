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
              color: AuraTextColor.onSurfaceVariant,
              textAlign: TextAlign.center,
              child: TextLocale(LocaleKeys.tools_screen_no_tools_added),
            ),
            const AuraText(
              style: AuraTextStyle.bodySmall,
              color: AuraTextColor.onSurfaceVariant,
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

    if (workspaceToolRow == null) return const SizedBox.shrink();
    final (toolType, workspaceTool) = workspaceToolRow;
    final isEnabled = workspaceTool?.isEnabled ?? false;
    final hasConfig = workspaceTool?.hasConfig ?? false;

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
                        ? AuraTextColor.onPrimary
                        : AuraTextColor.onSurfaceVariant,

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
                        color: AuraTextColor.onPrimary,
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          child: ToolDescriptionidget(toolType: toolType),
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggle switch
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

                // Remove button
                IconButton(
                  onPressed: onRemove,
                  icon: AuraIcon(
                    Icons.delete_outline,
                    color: context.auraColors.error,
                  ),
                  tooltip: LocaleKeys.tools_screen_remove_tool_tooltip,
                ),
              ],
            ),

            // Additional info
            if (hasConfig) ...[
              SizedBox(height: context.auraTheme.spacing.sm),
              AuraRow(
                spacing: AuraSpacing.sm,
                children: [
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
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
