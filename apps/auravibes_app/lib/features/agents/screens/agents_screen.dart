// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/domain/entities/agent_visibility.dart';
import 'package:auravibes_app/features/agents/providers/agent_list_notifier.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/delete_agent_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/duplicate_agent_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef _AgentSelection = ({
  BuildContext context,
  WidgetRef ref,
  String value,
  String agentId,
});

class const AgentsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentListProvider(workspaceId));

    return AuraScreen(
      child: _AgentsContent(agentsAsync: agentsAsync, workspaceId: workspaceId),
      appBar: _AgentsAppBar(onCreate: () => _openCreate(context, ref)),
    );
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    unawaited(_openAgentEditor(context, ref, 'new'));
  }

  Future<void> _openAgentEditor(
    BuildContext context,
    WidgetRef ref,
    String agentId,
  ) async {
    final changed = await context.push<bool>(
      '/workspaces/$workspaceId/more/agents/$agentId',
    );
    if (changed == true) {
      final _ = ref.invalidate(agentsProvider(workspaceId));
      await ref.read(agentListProvider(workspaceId).notifier).refresh();
    }
  }
}

class _AgentsContent extends StatelessWidget {
  new({required this.agentsAsync, required this.workspaceId})
    : _child = switch (agentsAsync) {
        AsyncData(:final value) => _AgentsList(
          state: value,
          workspaceId: workspaceId,
        ),
        AsyncLoading(:final value?) => _AgentsList(
          state: value,
          workspaceId: workspaceId,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: AuraText(child: TextLocale(LocaleKeys.agents_load_error)),
        ),
      };

  final AsyncValue<AgentListState> agentsAsync;
  final String workspaceId;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentsAppBar({required final VoidCallback onCreate})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: const TextLocale(LocaleKeys.agents_title),
      actions: [
        AuraIconButton(
          icon: Icons.add,
          onPressed: onCreate,
          tooltip: LocaleKeys.agents_create.tr(context: context),
        ),
      ],
      leading: const _AgentsBackButton(),
    );
  }
}

class const _AgentsBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class const _AgentsList({
  required final AgentListState state,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.agents.isEmpty && !state.hasFilters) {
      return _AgentsEmptyState(onCreate: () => _openCreate(context, ref));
    }

    return _AgentsSearchList(
      state: state,
      workspaceId: workspaceId,
      onTap: _openAgentCallback(context, ref),
      onSelection: _selectionCallback(context, ref),
    );
  }

  ValueChanged<AgentListItem> _openAgentCallback(
    BuildContext context,
    WidgetRef ref,
  ) {
    return (agent) => _openAgent(context, ref, agent.id);
  }

  void Function(String value, AgentListItem agent) _selectionCallback(
    BuildContext context,
    WidgetRef ref,
  ) {
    return (value, agent) => _handleSelection((
      context: context,
      ref: ref,
      value: value,
      agentId: agent.id,
    ));
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    unawaited(_openAndRefresh(context, ref, 'new'));
  }

  void _openAgent(BuildContext context, WidgetRef ref, String agentId) {
    unawaited(_openAndRefresh(context, ref, agentId));
  }

  void _handleSelection(_AgentSelection selection) {
    switch (selection.value) {
      case 'edit':
        _openAgent(selection.context, selection.ref, selection.agentId);
      case 'duplicate':
        unawaited(
          _duplicateAgent(selection.context, selection.ref, selection.agentId),
        );
      case 'delete':
        unawaited(
          _confirmDelete(selection.context, selection.ref, selection.agentId),
        );
      case _:
        break;
    }
  }

  Future<void> _duplicateAgent(
    BuildContext context,
    WidgetRef ref,
    String agentId,
  ) async {
    try {
      await _duplicateAndRefresh(ref, workspaceId, agentId);
    } on Object {
      if (!context.mounted) return;
      _showDuplicateError(context);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String agentId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAgentDialog(),
    );
    if (shouldDelete != true) return;

    await _deleteAgent(ref, agentId);
  }

  Future<void> _deleteAgent(WidgetRef ref, String agentId) async {
    final _ = await ref
        .read(deleteAgentUsecaseProvider(workspaceId))
        .call(agentId);
    final _ = ref.invalidate(agentsProvider(workspaceId));
    await ref.read(agentListProvider(workspaceId).notifier).refresh();
  }

  Future<void> _openAndRefresh(
    BuildContext context,
    WidgetRef ref,
    String agentId,
  ) async {
    final changed = await context.push<bool>(
      '/workspaces/$workspaceId/more/agents/$agentId',
    );
    if (changed != true) return;
    final _ = ref.invalidate(agentsProvider(workspaceId));
    await ref.read(agentListProvider(workspaceId).notifier).refresh();
  }
}

Future<void> _duplicateAndRefresh(
  WidgetRef ref,
  String workspaceId,
  String agentId,
) async {
  final _ = await ref
      .read(duplicateAgentUsecaseProvider(workspaceId))
      .call(agentId);
  final _ = ref.invalidate(agentsProvider(workspaceId));
  await ref.read(agentListProvider(workspaceId).notifier).refresh();
}

void _showDuplicateError(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(LocaleKeys.agents_duplicate_error),
    variant: .error,
  );
}

class const _AgentsSearchList({
  required final AgentListState state,
  required final String workspaceId,
  required final ValueChanged<AgentListItem> onTap,
  required final void Function(String value, AgentListItem agent) onSelection,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: state.search);
    final notifier = ref.read(agentListProvider(workspaceId).notifier);

    return _AgentSearchContent(
      state: state,
      notifier: notifier,
      controller: controller,
      interactions: (onTap: onTap, onSelection: onSelection),
    );
  }
}

typedef _AgentInteractions = ({
  ValueChanged<AgentListItem> onTap,
  void Function(String value, AgentListItem agent) onSelection,
});

class const _AgentSearchContent({
  required final AgentListState state,
  required final AgentListNotifier notifier,
  required final TextEditingController controller,
  required final _AgentInteractions interactions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _AgentSearchBody(
    controls: _AgentSearchControls(
      controller: controller,
      notifier: notifier,
      state: state,
    ),
    status: _AgentRetryStatus(state: state, notifier: notifier),
    results: _AgentSearchResults(
      agents: state.agents,
      onTap: interactions.onTap,
      onSelection: interactions.onSelection,
    ),
    pagination: _AgentPagination(state: state, onPressed: notifier.loadMore),
  );
}

class const _AgentRetryStatus({
  required final AgentListState state,
  required final AgentListNotifier notifier,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      _AgentListStatus(state: state, onRetry: notifier.retry);
}

class const _AgentSearchBody({
  required final Widget controls,
  required final Widget status,
  required final Widget results,
  required final Widget pagination,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      controls,
      status,
      Expanded(child: results),
      pagination,
    ],
  );
}

class const _AgentListStatus({
  required final AgentListState state,
  required final Future<void> Function() onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),
      if (state.refreshFailed)
        _AgentLoadError(onRetry: () => unawaited(onRetry())),
    ],
  );
}

class const _AgentSearchResults({
  required final List<AgentListItem> agents,
  required final ValueChanged<AgentListItem> onTap,
  required final void Function(String value, AgentListItem agent) onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => agents.isEmpty
      ? const _AgentsSearchEmptyState()
      : _AgentsListView(agents: agents, onTap: onTap, onSelection: onSelection);
}

class const _AgentPagination({
  required final AgentListState state,
  required final Future<void> Function() onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => state.nextCursor == null
      ? const SizedBox.shrink()
      : _LoadMore(
          failed: state.loadMoreFailed,
          isLoading: state.isLoadingMore,
          onPressed: () => unawaited(onPressed()),
        );
}

class const _AgentSearchControls({
  required final TextEditingController controller,
  required final AgentListNotifier notifier,
  required final AgentListState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing, right: spacing),
      child: AuraColumn(
        children: [
          _AgentSearchInput(
            controller: controller,
            onChanged: notifier.setSearch,
          ),
          _AgentFilters(state: state, notifier: notifier),
        ],
        spacing: .sm,
      ),
    );
  }
}

class const _AgentSearchInput({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraInput(
    controller: controller,
    placeholder: const TextLocale(LocaleKeys.agents_search_placeholder),
    prefixIcon: const AuraIcon(Icons.search),
    size: .small,
    onChanged: onChanged,
  );
}

class const _AgentFilters({
  required final AgentListState state,
  required final AgentListNotifier notifier,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    children: [
      Expanded(
        child: _AgentFilter(
          labelKey: LocaleKeys.agents_filter_type,
          onChanged: _setType,
          options: _typeOptions,
          value: _typeFilterValue(state.type),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _AgentFilter(
          labelKey: LocaleKeys.agents_filter_status,
          onChanged: _setStatus,
          options: _statusOptions,
          value: _statusFilterValue(state.status),
        ),
      ),
    ],
  );

  void _setType(String? value) => notifier.setType(switch (value) {
    'chat' => .chatSelector,
    'sub' => .subAgentList,
    _ => null,
  });

  void _setStatus(String? value) => notifier.setStatus(switch (value) {
    'enabled' => .enabled,
    'disabled' => .disabled,
    _ => null,
  });
}

String _typeFilterValue(AgentListType? type) => switch (type) {
  null => 'all',
  .chatSelector => 'chat',
  .subAgentList => 'sub',
};

String _statusFilterValue(AgentListStatus? status) => switch (status) {
  null => 'all',
  .enabled => 'enabled',
  .disabled => 'disabled',
};

class const _AgentFilter({
  required final String labelKey,
  required final ValueChanged<String?> onChanged,
  required final List<AuraDropdownOption<String>> options,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraDropdownSelector<String>(
    options: options,
    value: value,
    onChanged: onChanged,
    label: TextLocale(labelKey),
  );
}

const _typeOptions = <AuraDropdownOption<String>>[
  AuraDropdownOption(
    value: 'all',
    child: TextLocale(LocaleKeys.agents_filter_all),
  ),
  AuraDropdownOption(
    value: 'chat',
    child: TextLocale(LocaleKeys.agents_visibility_chat_selector),
  ),
  AuraDropdownOption(
    value: 'sub',
    child: TextLocale(LocaleKeys.agents_visibility_sub_agent_list),
  ),
];

const _statusOptions = <AuraDropdownOption<String>>[
  AuraDropdownOption(
    value: 'all',
    child: TextLocale(LocaleKeys.agents_filter_all),
  ),
  AuraDropdownOption(
    value: 'enabled',
    child: TextLocale(LocaleKeys.agents_enabled_label),
  ),
  AuraDropdownOption(
    value: 'disabled',
    child: TextLocale(LocaleKeys.agents_disabled_label),
  ),
];

class const _AgentLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Padding(
    padding: const EdgeInsets.all(8),
    child: AuraButton(
      onPressed: onRetry,
      child: const TextLocale(LocaleKeys.common_reload),
      variant: .outlined,
    ),
  );
}

class const _LoadMore({
  required final bool failed,
  required final bool isLoading,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Padding(
    padding: const EdgeInsets.all(8),
    child: AuraColumn(
      children: [
        if (failed)
          const AuraText(
            child: TextLocale(LocaleKeys.agents_load_more_error),
            style: .bodySmall,
          ),
        AuraButton(
          onPressed: onPressed,
          child: const TextLocale(LocaleKeys.common_show_more),
          variant: .outlined,
          isLoading: isLoading,
        ),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
  );
}

class const _AgentsSearchEmptyState() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const Center(
    child: AuraColumn(
      children: [
        AuraIcon(Icons.search_off, size: .large),
        AuraText(
          child: TextLocale(LocaleKeys.agents_search_no_results),
          textAlign: .center,
        ),
      ],
      spacing: .sm,
      mainAxisSize: .min,
    ),
  );
}

class const _AgentsListView({
  required final List<AgentListItem> agents,
  required final ValueChanged<AgentListItem> onTap,
  required final void Function(String value, AgentListItem agent) onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemBuilder: _itemBuilder,
      separatorBuilder: _separatorBuilder,
      itemCount: agents.length,
    );
  }

  Widget _itemBuilder(BuildContext _, int index) {
    return _AgentListItemBuilder(
      agent: agents[index],
      onTap: onTap,
      onSelection: onSelection,
    );
  }

  Widget _separatorBuilder(BuildContext _, _) {
    return const SizedBox(height: 8);
  }
}

class _AgentsEmptyState extends StatelessWidget {
  const new({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext _) =>
      Center(child: _AgentsEmptyContent(onCreate: onCreate));
}

class _AgentsEmptyContent extends StatelessWidget {
  new({required this.onCreate})
    : _child = AuraColumn(
        children: [
          const Icon(Icons.smart_toy_outlined, size: 48),
          const AuraText(
            child: TextLocale(LocaleKeys.agents_empty_title),
            style: .heading4,
          ),
          const AuraText(child: TextLocale(LocaleKeys.agents_empty_subtitle)),
          AuraButton(
            onPressed: onCreate,
            child: const TextLocale(LocaleKeys.agents_create),
          ),
        ],
        mainAxisSize: .min,
      );

  final VoidCallback onCreate;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentListItem({
  required final AgentListItem agent,
  required final VoidCallback onTap,
  required final ValueChanged<String> onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: _AgentListItemDetails(agent: agent),
      onTap: onTap,
      variant: .ghost,
      leading: const AuraIcon(Icons.smart_toy_outlined),
      trailing: _AgentMenu(onSelected: onSelection),
    );
  }
}

class const _AgentListItemDetails({required final AgentListItem agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _AgentNameRow(agent: agent),
        _AgentSkillCount(agent: agent),
        _AgentVisibility(agent: agent),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _AgentNameRow({required final AgentListItem agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        Expanded(child: Text(agent.name)),
        if (!agent.isEnabled)
          AuraBadge.text(
            child: const TextLocale(LocaleKeys.agents_disabled_label),
            variant: .neutral,
          ),
      ],
    );
  }
}

class const _AgentSkillCount({required final AgentListItem agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(
        LocaleKeys.agents_skill_count.plural(
          agent.skillCount,
          context: context,
        ),
      ),
      style: .bodySmall,
    );
  }
}

class const _AgentVisibility({required final AgentListItem agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(agent.visibility.localizedLabel(context)),
      style: .bodySmall,
    );
  }
}

class const _AgentMenu({required final ValueChanged<String> onSelected})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return PopupMenuButton<String>(itemBuilder: _items, onSelected: onSelected);
  }

  List<PopupMenuEntry<String>> _items(BuildContext _) => const [
    PopupMenuItem(value: 'edit', child: TextLocale(LocaleKeys.common_edit)),
    PopupMenuItem(
      value: 'duplicate',
      child: TextLocale(LocaleKeys.agents_duplicate),
    ),
    PopupMenuItem(value: 'delete', child: TextLocale(LocaleKeys.common_delete)),
  ];
}

class const _AgentListItemBuilder({
  required final AgentListItem agent,
  required final ValueChanged<AgentListItem> onTap,
  required final void Function(String value, AgentListItem agent) onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return _AgentListItem(
      agent: agent,
      onTap: () => onTap(agent),
      onSelection: (value) => onSelection(value, agent),
    );
  }
}

class const _DeleteAgentDialog() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(LocaleKeys.agents_delete_title),
      message: const TextLocale(LocaleKeys.agents_delete_message),
      confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
      cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
      isDestructive: true,
    );
  }
}

extension _AgentVisibilityLabel on AgentVisibility {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      .chatSelector => LocaleKeys.agents_visibility_chat_selector.tr(
        context: context,
      ),
      .subAgentList => LocaleKeys.agents_visibility_sub_agent_list.tr(
        context: context,
      ),
      .both => LocaleKeys.agents_visibility_both.tr(context: context),
    };
  }
}
