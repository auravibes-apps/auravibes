import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
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
    final toolsNotifier = ref.read(
      conversationToolsProvider(
        workspaceId: workspaceId,
        conversationId: conversationId,
      ).notifier,
    );
    final toolId = toolState.tool.id;

    final onToggle = useCallback(
      () async {
        await toolsNotifier.toggleTool(toolId);
      },
      [toolsNotifier, toolId],
    );

    final onPermissionChanged =
        useCallback<Future<void> Function(ToolPermissionMode?)>(
          (mode) async {
            if (mode == null) return;
            await toolsNotifier.setToolPermission(
              toolId,
              permissionMode: mode,
            );
          },
          [toolsNotifier, toolId],
        );

    final isEnabled = toolState.isEnabled;
    final isWorkspaceEnabled = toolState.isWorkspaceEnabled;

    return AuraCard(
      child: AuraColumn(
        children: [
          _ToolSummaryRow(
            toolState: toolState,
            isEnabled: isEnabled,
            isWorkspaceEnabled: isWorkspaceEnabled,
          ),
          if (isEnabled && isWorkspaceEnabled)
            _ToolPermissionSection(
              value: toolState.permissionMode,
              onChanged: onPermissionChanged,
            ),
        ],
        spacing: AuraSpacing.none,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      padding: .none,
      onTap: isWorkspaceEnabled ? onToggle : null,
      style: AuraCardStyle.border,
    );
  }
}

class _ToolSummaryRow extends StatelessWidget {
  const _ToolSummaryRow({
    required this.toolState,
    required this.isEnabled,
    required this.isWorkspaceEnabled,
  });

  final ConversationToolState toolState;
  final bool isEnabled;
  final bool isWorkspaceEnabled;

  @override
  Widget build(BuildContext context) {
    return AuraPadding(
      child: AuraRow(
        children: [
          _ToolIcon(
            toolState: toolState,
            isEnabled: isEnabled,
            isWorkspaceEnabled: isWorkspaceEnabled,
          ),
          Expanded(
            child: _ToolDescription(
              toolState: toolState,
              isWorkspaceEnabled: isWorkspaceEnabled,
            ),
          ),
          _ToolToggleIcon(
            isEnabled: isEnabled,
            isWorkspaceEnabled: isWorkspaceEnabled,
          ),
        ],
        spacing: AuraSpacing.md,
      ),
      padding: .medium,
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.toolState,
    required this.isEnabled,
    required this.isWorkspaceEnabled,
  });

  final ConversationToolState toolState;
  final bool isEnabled;
  final bool isWorkspaceEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled && isWorkspaceEnabled
            ? context.auraColors.primary.withValues(alpha: 0.1)
            : context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignBorderRadius.md),
      ),
      width: 40,
      height: 40,
      child: toolState.tool.getIconWidget(),
    );
  }
}

class _ToolDescription extends StatelessWidget {
  const _ToolDescription({
    required this.toolState,
    required this.isWorkspaceEnabled,
  });

  final ConversationToolState toolState;
  final bool isWorkspaceEnabled;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(
          child: toolState.tool.getNameWidget(),
          color: isWorkspaceEnabled
              ? AuraColorVariant.onSurface
              : AuraColorVariant.onSurfaceVariant,
        ),
        if (isWorkspaceEnabled)
          AuraText(
            child: DefaultTextStyle.merge(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              child: toolState.tool.getDescriptionWidget(),
            ),
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
          )
        else
          AuraText(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontStyle: FontStyle.italic),
              child: const TextLocale(
                LocaleKeys.tools_screen_disabled_in_workspace,
              ),
            ),
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
          ),
      ],
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _ToolToggleIcon extends StatelessWidget {
  const _ToolToggleIcon({
    required this.isEnabled,
    required this.isWorkspaceEnabled,
  });

  final bool isEnabled;
  final bool isWorkspaceEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isWorkspaceEnabled) {
      return const Opacity(
        opacity: 0.5,
        child: AuraIcon(
          Icons.block,
          size: AuraIconSize.small,
          color: AuraColorVariant.onSurfaceVariant,
        ),
      );
    }

    return AuraIcon(
      isEnabled ? Icons.check_circle : Icons.circle_outlined,
      color: isEnabled
          ? AuraColorVariant.primary
          : AuraColorVariant.onSurfaceVariant,
    );
  }
}

class _ToolPermissionSection extends StatelessWidget {
  const _ToolPermissionSection({
    required this.value,
    required this.onChanged,
  });

  final ToolPermissionMode value;
  final void Function(ToolPermissionMode?) onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const AuraDivider(),
        AuraPadding(
          child: AuraColumn(
            children: [
              const AuraText(
                child: TextLocale(LocaleKeys.tools_screen_permission_label),
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
              ),
              ToolPermissionSelector(value: value, onChanged: onChanged),
            ],
            spacing: AuraSpacing.sm,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          padding: .medium,
        ),
      ],
      spacing: AuraSpacing.none,
      crossAxisAlignment: CrossAxisAlignment.start,
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
