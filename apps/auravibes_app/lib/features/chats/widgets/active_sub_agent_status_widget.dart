import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ActiveSubAgentStatusWidget extends ConsumerWidget {
  const ActiveSubAgentStatusWidget({
    required this.workspaceId,
    required this.conversationId,
    super.key,
  });

  final String workspaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childIds = ref.watch(
      activeSubAgentRuntimeProvider.select(
        (state) => state[conversationId] ?? const <String>{},
      ),
    );
    if (childIds.isEmpty) return const SizedBox.shrink();

    final activeChildIds = childIds.toList()..sort();
    final countLabel = LocaleKeys
        .chats_screens_chat_conversation_active_sub_agents_count
        .plural(activeChildIds.length);
    final semanticLabel = LocaleKeys
        .chats_screens_chat_conversation_active_sub_agents_accessible_label
        .tr(namedArgs: {'count': countLabel});

    void openActiveChildren() {
      if (activeChildIds.length == 1) {
        _openChild(context, workspaceId, conversationId, activeChildIds.single);
        return;
      }

      final _ = showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => _ActiveSubAgentChooser(
          workspaceId: workspaceId,
          conversationId: conversationId,
          childIds: activeChildIds,
          onOpenChild: (childId) {
            Navigator.of(sheetContext).pop();
            _openChild(context, workspaceId, conversationId, childId);
          },
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(right: context.auraTheme.fromSpacing(.xs)),
      child: Semantics(
        key: const ValueKey<String>('chat_active_sub_agents'),
        button: true,
        container: true,
        label: semanticLabel,
        onTap: openActiveChildren,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: openActiveChildren,
            borderRadius: BorderRadius.circular(
              context.auraTheme.fromBorderRadius(.full),
            ),
            child: AuraContainer(
              padding: const AuraEdgeInsetsGeometry.symmetric(
                horizontal: .sm,
                vertical: .xs,
              ),
              variant: .surfaceVariant,
              borderRadius: context.auraTheme.fromBorderRadius(.full),
              border: .fromBorderSide(
                .new(color: context.auraColors.outlineVariant),
              ),
              child: AuraRow(
                children: [
                  const AuraIcon(
                    Icons.smart_toy_outlined,
                    size: .extraSmall,
                    tint: .info,
                  ),
                  AuraBadge.count(
                    count: activeChildIds.length,
                    variant: .info,
                    size: .small,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveSubAgentChooser extends ConsumerWidget {
  const _ActiveSubAgentChooser({
    required this.workspaceId,
    required this.conversationId,
    required this.childIds,
    required this.onOpenChild,
  });

  final String workspaceId;
  final String conversationId;
  final List<String> childIds;
  final ValueChanged<String> onOpenChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(activeSubAgentRuntimeProvider);
    final runtime = ref.read(activeSubAgentRuntimeProvider.notifier);
    final children =
        ref
            .watch(
              childConversationsStreamProvider(
                workspaceId,
                parentConversationId: conversationId,
              ),
            )
            .value ??
        const <ConversationEntity>[];
    final titles = {for (final child in children) child.id: child.title};

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                LocaleKeys
                    .chats_screens_chat_conversation_active_sub_agents_title
                    .tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final childId in childIds)
              ListTile(
                key: ValueKey<String>('active_sub_agent_$childId'),
                title: Text(titles[childId] ?? childId),
                subtitle: _ActiveSubAgentStatusDetails(
                  status: runtime.statusOf(childId),
                  error: runtime.failure(childId)?.error,
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => onOpenChild(childId),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSubAgentStatusDetails extends StatelessWidget {
  const _ActiveSubAgentStatusDetails({
    required this.status,
    required this.error,
  });

  final ActiveSubAgentStatus status;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final safeError = error == null ? null : LogRedaction.redact(error);

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Text(_statusLabel(status)),
        if (safeError != null && safeError.isNotEmpty)
          Text(
            LocaleKeys.chats_screens_chat_conversation_sub_agent_error_detail
                .tr(namedArgs: {'error': safeError}),
          ),
      ],
    );
  }
}

String _statusLabel(ActiveSubAgentStatus status) => switch (status) {
  .running =>
    LocaleKeys.chats_screens_chat_conversation_sub_agent_status_running.tr(),
  .awaitingApproval =>
    LocaleKeys
        .chats_screens_chat_conversation_sub_agent_status_awaiting_approval
        .tr(),
  .completed =>
    LocaleKeys.chats_screens_chat_conversation_sub_agent_status_completed.tr(),
  .failed =>
    LocaleKeys.chats_screens_chat_conversation_sub_agent_status_failed.tr(),
  .stopped =>
    LocaleKeys.chats_screens_chat_conversation_sub_agent_status_stopped.tr(),
};

void _openChild(
  BuildContext context,
  String workspaceId,
  String conversationId,
  String childId,
) {
  final _ = SubAgentConversationRoute(
    workspaceId: workspaceId,
    chatId: conversationId,
    subAgentConversationId: childId,
  ).push(context);
}
