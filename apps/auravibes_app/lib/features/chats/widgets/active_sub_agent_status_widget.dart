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

class const ActiveSubAgentStatusWidget({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childIds = ref.watch(
      activeSubAgentRuntimeProvider.select(
        (state) => state[conversationId] ?? const <String>{},
      ),
    );
    if (childIds.isEmpty) return const SizedBox.shrink();

    return _ActiveSubAgentStatusButton(
      workspaceId: workspaceId,
      conversationId: conversationId,
      childIds: childIds.toList()..sort(),
    );
  }
}

String _activeSubAgentSemanticLabel(int count) {
  final countLabel = LocaleKeys
      .chats_screens_chat_conversation_active_sub_agents_count
      .plural(count);

  return LocaleKeys
      .chats_screens_chat_conversation_active_sub_agents_accessible_label
      .tr(namedArgs: {'count': countLabel});
}

class const _ActiveSubAgentStatusButton({
  required final String workspaceId,
  required final String conversationId,
  required final List<String> childIds,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = childIds.length;

    final navigation = (
      context: context,
      workspaceId: workspaceId,
      conversationId: conversationId,
    );

    return _ActiveSubAgentButtonSurface(
      count: count,
      onTap: () => _openActiveChildren(navigation, childIds),
    );
  }
}

class const _ActiveSubAgentButtonSurface({
  required final int count,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(right: context.auraTheme.fromSpacing(.xs)),
    child: _ActiveSubAgentButtonSemantics(count: count, onTap: onTap),
  );
}

class const _ActiveSubAgentButtonSemantics({
  required final int count,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('chat_active_sub_agents'),
    child: _ActiveSubAgentTapTarget(count: count, onTap: onTap),
    container: true,
    button: true,
    label: _activeSubAgentSemanticLabel(count),
    onTap: onTap,
  );
}

class const _ActiveSubAgentTapTarget({
  required final int count,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: InkWell(
      child: _ActiveSubAgentBadge(count: count),
      onTap: onTap,
      borderRadius: .circular(context.auraTheme.fromBorderRadius(.full)),
    ),
  );
}

class const _ActiveSubAgentBadge({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraContainer(
    child: _ActiveSubAgentBadgeContents(count: count),
    padding: const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .sm,
      vertical: .xs,
    ),
    variant: .surfaceVariant,
    borderRadius: context.auraTheme.fromBorderRadius(.full),
    border: .fromBorderSide(.new(color: context.auraColors.outlineVariant)),
  );
}

class const _ActiveSubAgentBadgeContents({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      const AuraIcon(Icons.smart_toy_outlined, size: .extraSmall, tint: .info),
      AuraBadge.count(count: count, variant: .info, size: .small),
    ],
  );
}

typedef _ActiveSubAgentNavigation = ({
  BuildContext context,
  String workspaceId,
  String conversationId,
});

void _openActiveChildren(
  _ActiveSubAgentNavigation navigation,
  List<String> childIds,
) {
  if (childIds.length == 1) {
    _openChild(
      navigation.context,
      navigation.workspaceId,
      navigation.conversationId,
      childIds.single,
    );

    return;
  }

  _showActiveSubAgentChooser(navigation, childIds);
}

void _showActiveSubAgentChooser(
  _ActiveSubAgentNavigation navigation,
  List<String> childIds,
) {
  final _ = showModalBottomSheet<void>(
    context: navigation.context,
    builder: _activeSubAgentChooserBuilder(navigation, childIds),
    isScrollControlled: true,
    useSafeArea: true,
  );
}

WidgetBuilder _activeSubAgentChooserBuilder(
  _ActiveSubAgentNavigation navigation,
  List<String> childIds,
) =>
    (sheetContext) => _ActiveSubAgentChooser(
      workspaceId: navigation.workspaceId,
      conversationId: navigation.conversationId,
      childIds: childIds,
      onOpenChild: (childId) =>
          _openChildFromChooser(sheetContext, navigation, childId),
    );

void _openChildFromChooser(
  BuildContext sheetContext,
  _ActiveSubAgentNavigation navigation,
  String childId,
) {
  Navigator.of(sheetContext).pop();
  _openChild(
    navigation.context,
    navigation.workspaceId,
    navigation.conversationId,
    childId,
  );
}

class const _ActiveSubAgentChooser({
  required final String workspaceId,
  required final String conversationId,
  required final List<String> childIds,
  required final ValueChanged<String> onOpenChild,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chooserData = _activeSubAgentChooserData(
      ref,
      workspaceId,
      conversationId,
    );

    return _ActiveSubAgentChooserContents(
      childIds: childIds,
      titles: chooserData.titles,
      runtime: chooserData.runtime,
      onOpenChild: onOpenChild,
    );
  }
}

({ActiveSubAgentRuntime runtime, Map<String, String> titles})
_activeSubAgentChooserData(
  WidgetRef ref,
  String workspaceId,
  String conversationId,
) {
  final _ = ref.watch(activeSubAgentRuntimeProvider);
  final runtime = ref.watch(activeSubAgentRuntimeProvider.notifier);
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

  return (runtime: runtime, titles: _subAgentTitlesById(children));
}

Map<String, String> _subAgentTitlesById(List<ConversationEntity> children) => {
  for (final child in children) child.id: child.title,
};

class const _ActiveSubAgentChooserContents({
  required final List<String> childIds,
  required final Map<String, String> titles,
  required final ActiveSubAgentRuntime runtime,
  required final ValueChanged<String> onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    child: _ActiveSubAgentChooserList(
      childIds: childIds,
      titles: titles,
      runtime: runtime,
      onOpenChild: onOpenChild,
    ),
  );
}

class const _ActiveSubAgentChooserList({
  required final List<String> childIds,
  required final Map<String, String> titles,
  required final ActiveSubAgentRuntime runtime,
  required final ValueChanged<String> onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        const _ActiveSubAgentChooserTitle(),
        _ActiveSubAgentChildRows(
          childIds: childIds,
          titles: titles,
          runtime: runtime,
          onOpenChild: onOpenChild,
        ),
      ],
    ),
  );
}

class const _ActiveSubAgentChooserTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_active_sub_agents_title.tr(),
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

class const _ActiveSubAgentChildRows({
  required final List<String> childIds,
  required final Map<String, String> titles,
  required final ActiveSubAgentRuntime runtime,
  required final ValueChanged<String> onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (final childId in childIds)
        _ActiveSubAgentChildTile(
          childId: childId,
          title: titles[childId] ?? childId,
          runtime: runtime,
          onTap: () => onOpenChild(childId),
        ),
    ],
  );
}

class const _ActiveSubAgentChildTile({
  required final String childId,
  required final String title,
  required final ActiveSubAgentRuntime runtime,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('active_sub_agent_$childId'),
    title: Text(title),
    subtitle: _ActiveSubAgentStatusDetails(
      status: runtime.statusOf(childId),
      error: _redactedSubAgentError(runtime, childId),
    ),
    trailing: const Icon(Icons.open_in_new_rounded),
    onTap: onTap,
  );
}

String? _redactedSubAgentError(ActiveSubAgentRuntime runtime, String childId) =>
    switch (runtime.failure(childId)?.error) {
      final failureError? => LogRedaction.redact(failureError),
      _ => null,
    };

class const _ActiveSubAgentStatusDetails({
  required final ActiveSubAgentStatus status,
  required final String? error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorText = error;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Text(_statusLabel(status)),
        if (errorText != null && errorText.isNotEmpty)
          Text(
            LocaleKeys.chats_screens_chat_conversation_sub_agent_error_detail
                .tr(namedArgs: {'error': errorText}),
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
  ).push<void>(context);
}
