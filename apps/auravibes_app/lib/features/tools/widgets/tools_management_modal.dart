import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/features/tools/providers/conversation_tools_provider.dart';
import 'package:auravibes_app/features/tools/widgets/tool_description.dart';
import 'package:auravibes_app/features/tools/widgets/tool_icon.dart';
import 'package:auravibes_app/features/tools/widgets/tool_name.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for managing conversation tools
///
/// Shows ALL workspace tools (enabled and disabled at workspace level)
/// and allows toggling and permission changes at conversation level.
class ToolsManagementModal extends HookConsumerWidget {
  const ToolsManagementModal({
    required this.workspaceId,
    super.key,
    this.conversationId,
  });

  final String? conversationId;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationToolsAsync = ref.watch(
      conversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(DesignSpacing.md),
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
                    child: Text('Manage Tools'),
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

            // Tools list
            Flexible(
              child: switch (conversationToolsAsync) {
                AsyncLoading() => const Center(child: AuraSpinner()),
                AsyncData(:final value) => _ToolsList(
                  toolsState: value,
                  conversationId: conversationId,
                  workspaceId: workspaceId,
                ),
                AsyncError(:final error) => Center(
                  child: AuraText(
                    color: AuraColorVariant.error,
                    child: Text('Error loading tools: $error'),
                  ),
                ),
              },
            ),

            // Bottom padding
            const SizedBox(height: DesignSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ToolsList extends StatelessWidget {
  const _ToolsList({
    required this.toolsState,
    required this.workspaceId,
    this.conversationId,
  });

  final List<ConversationToolState> toolsState;
  final String? conversationId;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    if (toolsState.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(DesignSpacing.lg),
        child: Center(
          child: AuraColumn(
            mainAxisSize: MainAxisSize.min,
            spacing: AuraSpacing.md,
            children: [
              AuraIcon(
                Icons.build_circle_outlined,
                size: AuraIconSize.extraLarge,
                color: context.auraColors.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
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

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(DesignSpacing.md),
      itemCount: toolsState.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: DesignSpacing.sm),
      itemBuilder: (context, index) {
        final toolState = toolsState[index];

        return _ToolTile(
          toolState: toolState,
          conversationId: conversationId,
          workspaceId: workspaceId,
        );
      },
    );
  }
}

class _ToolTile extends HookConsumerWidget {
  const _ToolTile({
    required this.toolState,
    required this.conversationId,
    required this.workspaceId,
  });

  final ConversationToolState toolState;
  final String? conversationId;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onToggle = useCallback(() async {
      final notifier = ref.read(
        conversationToolsProvider(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ).notifier,
      );
      await notifier.toggleTool(toolState.toolType.value);
    }, [conversationId, workspaceId, toolState.toolType]);

    final onPermissionChanged = useCallback((ToolPermissionMode? mode) async {
      if (mode == null) return;
      final notifier = ref.read(
        conversationToolsProvider(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ).notifier,
      );
      await notifier.setToolPermission(
        toolState.toolType.value,
        permissionMode: mode,
      );
    }, [conversationId, workspaceId, toolState.toolType]);

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
                  child: ToolIconWidget(toolType: toolState.toolType),
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
                        child: ToolNameWidget(toolType: toolState.toolType),
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
                            child: ToolDescriptionWidget(
                              toolType: toolState.toolType,
                            ),
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
                  _PermissionSelector(
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

class _PermissionSelector extends StatelessWidget {
  const _PermissionSelector({
    required this.value,
    required this.onChanged,
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
