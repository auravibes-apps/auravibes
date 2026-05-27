// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tools_empty_state.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
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
  const ToolsWorkspaceListWidget({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedToolsAsync = ref.watch(groupedToolsProvider(workspaceId));

    return switch (groupedToolsAsync) {
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncData(value: final groups) when groups.isEmpty => ToolsEmptyState(
        padding: EdgeInsets.all(context.auraTheme.spacing.xl),
      ),
      AsyncData(value: final groups) => ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: context.auraTheme.spacing.sm,
        ),
        itemBuilder: (context, index) {
          return ToolsGroupCard(
            groupWithTools: groups[index],
            workspaceId: workspaceId,
          );
        },
        itemCount: groups.length,
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}
