import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tool_extensions_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for adding new tools to the workspace
class AddToolModal extends HookConsumerWidget {
  const AddToolModal({super.key});

  /// Shows the add tool modal as a dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AddToolModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final availableToolsAsync = ref.watch(availableToolsToAddProvider);

    useEffect(() {
      void listener() => searchQuery.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: AuraColumn(
          mainAxisSize: MainAxisSize.min,
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
                    style: AuraTextStyle.heading6,
                    child: TextLocale(LocaleKeys.tools_screen_add_tool_title),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AuraIcon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: context.auraColors.onSurfaceVariant,
                    ),
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
                prefixIcon: AuraIcon(
                  Icons.search,
                  color: context.auraColors.onSurfaceVariant,
                ),
                size: AuraInputSize.small,
              ),
            ),

            // Tools list
            Flexible(
              child: switch (availableToolsAsync) {
                AsyncLoading() => const Center(child: AuraSpinner()),
                AsyncData(:final value) => _AvailableToolsList(
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
        ),
      ),
    );
  }
}

class _AvailableToolsList extends StatelessWidget {
  const _AvailableToolsList({
    required this.tools,
    required this.searchQuery,
  });

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
            mainAxisSize: MainAxisSize.min,
            spacing: AuraSpacing.sm,
            children: [
              AuraIcon(
                tools.isEmpty ? Icons.check_circle_outline : Icons.search_off,
                size: AuraIconSize.large,
                color: context.auraColors.onSurfaceVariant,
              ),
              AuraText(
                color: AuraColorVariant.onSurfaceVariant,
                textAlign: TextAlign.center,
                child: TextLocale(
                  tools.isEmpty
                      ? LocaleKeys.tools_screen_all_tools_added
                      : LocaleKeys.tools_screen_no_tools_found,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.md,
      ),
      shrinkWrap: true,
      itemCount: filteredTools.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: context.auraTheme.spacing.sm),
      itemBuilder: (context, index) {
        final toolType = filteredTools[index];
        return _AvailableToolTile(toolType: toolType);
      },
    );
  }
}

class _AvailableToolTile extends ConsumerWidget {
  const _AvailableToolTile({required this.toolType});

  final UserToolType toolType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraTile(
      variant: AuraTileVariant.surface,
      onTap: () async {
        await ref.read(workspaceToolsProvider.notifier).addTool(toolType);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.auraColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            context.auraTheme.borderRadius.md,
          ),
        ),
        child: toolType.getIconWidget(),
      ),
      trailing: AuraIcon(
        Icons.add_circle_outline,
        color: context.auraColors.primary,
      ),
      child: AuraColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AuraSpacing.xs,
        children: [
          AuraText(
            child: toolType.getNameWidget(),
          ),
          AuraText(
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
            child: DefaultTextStyle.merge(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              child: toolType.getDescriptionWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
