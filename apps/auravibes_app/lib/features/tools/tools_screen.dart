import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/add_mcp_modal.dart';
import 'package:auravibes_app/features/tools/widgets/add_tool_modal.dart';
import 'package:auravibes_app/features/tools/widgets/tool_count_enabled.dart';
import 'package:auravibes_app/features/tools/widgets/tools_workspace_list.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraScreen(
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.tools_screen_title),
        actions: [
          // Add MCP Server button
          AuraIconButton(
            icon: Icons.extension,
            onPressed: () => AddMcpModal.show(context),
            tooltip: LocaleKeys.mcp_modal_add_mcp_tooltip.tr(context: context),
          ),
          AuraIconButton(
            icon: Icons.refresh,
            onPressed: () {
              ref.invalidate(workspaceToolsProvider);
            },
            tooltip: LocaleKeys.tools_screen_refresh_tooltip.tr(
              context: context,
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AuraColumn(
              children: [
                // Header section
                AuraCard(
                  child: AuraColumn(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AuraSpacing.sm,
                    children: [
                      const AuraRow(
                        children: [
                          AuraText(
                            style: AuraTextStyle.heading3,
                            color: AuraColorVariant.primary,
                            child: Icon(Icons.build_circle_outlined),
                          ),
                          AuraText(
                            style: AuraTextStyle.heading4,
                            child: TextLocale(
                              LocaleKeys.tools_screen_workspace_ai_tools,
                            ),
                          ),
                        ],
                      ),
                      const AuraText(
                        color: AuraColorVariant.onSurfaceVariant,
                        child: TextLocale(
                          LocaleKeys.tools_screen_enable_configure_description,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
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
                                const ToolCountEnabledWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tools list
                const Expanded(child: ToolsWorkspaceListWidget()),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            right: context.auraTheme.spacing.md,
            bottom: context.auraTheme.spacing.md,
            child: AuraFloatingActionButton(
              icon: Icons.add,
              onPressed: () => AddToolModal.show(context),
              tooltip: LocaleKeys.tools_screen_add_tool_tooltip.tr(
                context: context,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
