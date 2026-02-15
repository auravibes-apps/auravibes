import 'package:auravibes_app/features/tools/providers/grouped_tools_controller.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget that displays workspace tools organized by groups.
///
/// Shows:
/// - "Built-in Tools" default group for tools without a group
/// - MCP groups with connection status indicators
/// - Custom tool groups
///
/// Groups are sorted with:
/// 1. Default group first
/// 2. MCP groups with errors/issues
/// 3. Other groups by creation date (newest first)
class ToolsWorkspaceListWidget extends ConsumerWidget {
  const ToolsWorkspaceListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedToolsAsync = ref.watch(groupedToolsControllerProvider);

    return switch (groupedToolsAsync) {
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncData(value: final groups) when groups.isEmpty => _EmptyToolsState(),
      AsyncData(value: final groups) => ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: context.auraTheme.spacing.sm,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return ToolsGroupCard(groupWithTools: groups[index]);
        },
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}

/// Empty state when no tools are configured.
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
