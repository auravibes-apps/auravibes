// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// ignore_for_file: prefer-extracting-callbacks
// Required: UI callbacks stay local to their widgets.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/add_mcp_modal.dart';
import 'package:auravibes_app/features/tools/widgets/add_tool_modal.dart';
import 'package:auravibes_app/features/tools/widgets/tool_count_enabled_widget.dart';
import 'package:auravibes_app/features/tools/widgets/tools_workspace_list_widget.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraScreen(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AuraColumn(
              children: [
                AuraCard(
                  child: AuraColumn(
                    children: [
                      const AuraRow(
                        children: [
                          AuraText(
                            child: Icon(Icons.build_circle_outlined),
                            style: AuraTextStyle.heading3,
                            color: AuraColorVariant.primary,
                          ),
                          AuraText(
                            child: TextLocale(
                              LocaleKeys.tools_screen_workspace_ai_tools,
                            ),
                            style: AuraTextStyle.heading4,
                          ),
                        ],
                      ),
                      const AuraText(
                        child: TextLocale(
                          LocaleKeys.tools_screen_enable_configure_description,
                        ),
                        color: AuraColorVariant.onSurfaceVariant,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: const BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                ToolCountEnabledWidget(
                                  workspaceId: workspaceId,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    spacing: AuraSpacing.sm,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
                Expanded(
                  child: ToolsWorkspaceListWidget(workspaceId: workspaceId),
                ),
              ],
            ),
          ),
          Positioned(
            right: context.auraTheme.spacing.md,
            bottom: context.auraTheme.spacing.md,
            child: AuraFloatingActionButton(
              onPressed: () =>
                  AddToolModal.show(context, workspaceId: workspaceId),
              icon: Icons.add,
              heroTag: const ValueKey<String>('tools_add_tool_fab'),
              tooltip: LocaleKeys.tools_screen_add_tool_tooltip.tr(
                context: context,
              ),
            ),
          ),
        ],
      ),
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.tools_screen_title),
        actions: [
          AuraIconButton(
            icon: Icons.extension,
            onPressed: () =>
                AddMcpModal.show(context, workspaceId: workspaceId),
            tooltip: LocaleKeys.mcp_modal_add_mcp_tooltip.tr(context: context),
          ),
          AuraIconButton(
            icon: Icons.refresh,
            onPressed: () {
              ref.invalidate(workspaceToolsProvider(workspaceId));
            },
            tooltip: LocaleKeys.tools_screen_refresh_tooltip.tr(
              context: context,
            ),
          ),
        ],
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
