import 'dart:async';

import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for adding new tools to the workspace
class AddToolModal extends HookConsumerWidget {
  const AddToolModal({required this.workspaceId, super.key});

  final String workspaceId;

  /// Shows the add tool modal as a dialog
  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddToolModal(workspaceId: workspaceId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final availableToolsAsync = ref.watch(
      availableToolsToAddProvider(workspaceId),
    );

    useEffect(
      () {
        void listener() => searchQuery.value = searchController.text;
        searchController.addListener(listener);
        return () => searchController.removeListener(listener);
      },
      [searchController],
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: AuraColumn(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(context.auraTheme.spacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.auraColors.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const AuraText(
                    child: TextLocale(LocaleKeys.tools_screen_add_tool_title),
                    style: AuraTextStyle.heading6,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: context.auraColors.onSurfaceVariant,
                    ),
                    icon: const AuraIcon(Icons.close),
                  ),
                ],
              ),
            ),

            // Search input
            Padding(
              padding: EdgeInsets.all(context.auraTheme.spacing.md),
              child: AuraInput(
                controller: searchController,
                placeholder: const TextLocale(
                  LocaleKeys.tools_screen_search_tools,
                ),
                prefixIcon: const AuraIcon(
                  Icons.search,
                  color: AuraColorVariant.onSurfaceVariant,
                ),
                size: AuraInputSize.small,
              ),
            ),

            // Tools list
            Flexible(
              child: switch (availableToolsAsync) {
                AsyncLoading() => const Center(child: AuraSpinner()),
                AsyncData(:final value) => _AvailableToolsList(
                  workspaceId: workspaceId,
                  tools: value,
                  searchQuery: searchQuery.value,
                ),
                AsyncError(:final error, :final stackTrace) => AppErrorWidget(
                  error: error,
                  stackTrace: stackTrace,
                ),
              },
            ),

            // Bottom padding
            SizedBox(height: context.auraTheme.spacing.md),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }
}

class _AvailableToolsList extends StatelessWidget {
  const _AvailableToolsList({
    required this.workspaceId,
    required this.tools,
    required this.searchQuery,
  });

  final String workspaceId;
  final List<UserToolType> tools;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    // Filter tools based on search query
    final filteredTools = searchQuery.isEmpty
        ? tools
        : tools.where((tool) {
            final name = tool.value.toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

    if (filteredTools.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(context.auraTheme.spacing.lg),
        child: Center(
          child: AuraColumn(
            children: [
              AuraIcon(
                tools.isEmpty ? Icons.check_circle_outline : Icons.search_off,
                size: AuraIconSize.large,
                color: AuraColorVariant.onSurfaceVariant,
              ),
              AuraText(
                child: TextLocale(
                  tools.isEmpty
                      ? LocaleKeys.tools_screen_all_tools_added
                      : LocaleKeys.tools_screen_no_tools_found,
                ),
                textAlign: TextAlign.center,
                color: AuraColorVariant.onSurfaceVariant,
              ),
            ],
            spacing: AuraSpacing.sm,
            mainAxisSize: MainAxisSize.min,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.md,
      ),
      itemBuilder: (context, index) {
        final toolType = filteredTools[index];
        return _AvailableToolTile(
          toolType: toolType,
          workspaceId: workspaceId,
        );
      },
      separatorBuilder: (context, index) =>
          SizedBox(height: context.auraTheme.spacing.sm),
      itemCount: filteredTools.length,
    );
  }
}

class _AvailableToolTile extends ConsumerWidget {
  const _AvailableToolTile({required this.toolType, required this.workspaceId});

  final UserToolType toolType;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraTile(
      child: AuraColumn(
        children: [
          AuraText(child: toolType.getNameWidget()),
          AuraText(
            child: DefaultTextStyle.merge(
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              child: toolType.getDescriptionWidget(),
            ),
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
          ),
        ],
        spacing: AuraSpacing.xs,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      onTap: () {
        unawaited(
          ref
              .read(workspaceToolsProvider(workspaceId).notifier)
              .addTool(toolType)
              .then((_) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }),
        );
      },
      variant: AuraTileVariant.surface,
      leading: Container(
        decoration: BoxDecoration(
          color: context.auraColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            context.auraTheme.borderRadius.md,
          ),
        ),
        width: 40,
        height: 40,
        child: toolType.getIconWidget(),
      ),
      trailing: const AuraIcon(
        Icons.add_circle_outline,
        color: AuraColorVariant.primary,
      ),
    );
  }
}
