// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/domain/entities/agent_visibility.dart';
import 'package:auravibes_app/features/agents/providers/agent_list_notifier.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/delete_agent_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/duplicate_agent_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _AgentActionContext = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
});

typedef _AgentVisibilityChanged = Future<void> Function(
  AgentListItem agent,
  AgentVisibility visibility,
);

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
    return AuraAppBarWithDrawer(
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
    final action = (context: context, ref: ref, workspaceId: workspaceId);
    if (state.agents.isEmpty && !state.hasFilters) {
      return _AgentsEmptyState(onCreate: _agentCreateCallback(action));
    }

    return _AgentsSearchList(
      state: state,
      workspaceId: workspaceId,
      onTap: _agentOpenCallback(action),
      onSelection: _agentMenuCallback(action),
      onVisibilityChanged: _agentVisibilityCallback(action),
    );
  }
}

VoidCallback _agentCreateCallback(_AgentActionContext action) =>
    () => _openAgent(action, 'new');

ValueChanged<AgentListItem> _agentOpenCallback(_AgentActionContext action) =>
    (agent) => _openAgent(action, agent.id);

void Function(String value, AgentListItem agent) _agentMenuCallback(
  _AgentActionContext action,
) =>
    (value, agent) => _handleSelection(action, value, agent.id);

_AgentVisibilityChanged _agentVisibilityCallback(_AgentActionContext action) =>
    (agent, visibility) => _updateVisibility(action, agent.id, visibility);

void _openAgent(_AgentActionContext action, String agentId) {
  unawaited(_openAndRefresh(action, agentId));
}

void _handleSelection(
  _AgentActionContext action,
  String value,
  String agentId,
) {
  switch (value) {
    case 'edit':
      _openAgent(action, agentId);
    case 'duplicate':
      unawaited(_duplicateAgent(action, agentId));
    case 'delete':
      unawaited(_confirmDelete(action, agentId));
    case _:
      break;
  }
}

Future<void> _duplicateAgent(_AgentActionContext action, String agentId) async {
  try {
    final _ = await action.ref
        .read(duplicateAgentUsecaseProvider(action.workspaceId))
        .call(agentId);
  } on Object {
    if (!action.context.mounted) return;
    _showDuplicateError(action.context);

    return;
  }

  await _refreshAgents(action);
}

Future<void> _confirmDelete(_AgentActionContext action, String agentId) async {
  final shouldDelete = await showDialog<bool>(
    context: action.context,
    builder: (_) => const _DeleteAgentDialog(),
  );
  if (shouldDelete != true) return;

  await _deleteAgent(action, agentId);
}

Future<void> _deleteAgent(_AgentActionContext action, String agentId) async {
  final _ = await action.ref
      .read(deleteAgentUsecaseProvider(action.workspaceId))
      .call(agentId);
  await _refreshAgents(action);
}

Future<void> _updateVisibility(
  _AgentActionContext action,
  String agentId,
  AgentVisibility visibility,
) async {
  try {
    final _ = await action.ref
        .read(saveAgentUsecaseProvider(action.workspaceId))
        .updateVisibility(agentId, visibility);
  } on Object {
    if (!action.context.mounted) return;
    _showVisibilityUpdateError(action.context);

    return;
  }

  await _refreshAgents(action);
}

Future<void> _openAndRefresh(_AgentActionContext action, String agentId) async {
  final changed = await action.context.push<bool>(
    '/workspaces/${action.workspaceId}/more/agents/$agentId',
  );
  if (changed != true) return;
  await _refreshAgents(action);
}

Future<void> _refreshAgents(_AgentActionContext action) async {
  final _ = action.ref.invalidate(agentsProvider(action.workspaceId));
  await action.ref
      .read(agentListProvider(action.workspaceId).notifier)
      .refresh();
}

void _showDuplicateError(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(LocaleKeys.agents_duplicate_error),
    variant: .error,
  );
}

void _showVisibilityUpdateError(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(LocaleKeys.agents_visibility_update_error),
    variant: .error,
  );
}

class const _AgentsSearchList({
  required final AgentListState state,
  required final String workspaceId,
  required final ValueChanged<AgentListItem> onTap,
  required final void Function(String value, AgentListItem agent) onSelection,
  required final _AgentVisibilityChanged onVisibilityChanged,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: state.search);
    final notifier = ref.read(agentListProvider(workspaceId).notifier);

    return _AgentSearchContent(
      state: state,
      notifier: notifier,
      controller: controller,
      interactions: (
        onTap: onTap,
        onSelection: onSelection,
        onVisibilityChanged: onVisibilityChanged,
      ),
    );
  }
}

typedef _AgentInteractions = ({
  ValueChanged<AgentListItem> onTap,
  void Function(String value, AgentListItem agent) onSelection,
  _AgentVisibilityChanged onVisibilityChanged,
});

class _AgentSearchContent extends StatelessWidget {
  new({
    required AgentListState state,
    required AgentListNotifier notifier,
    required TextEditingController controller,
    required _AgentInteractions interactions,
  }) : _child = _AgentSearchBody(
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
           onVisibilityChanged: interactions.onVisibilityChanged,
         ),
         pagination: _AgentPagination(
           state: state,
           onPressed: notifier.loadMore,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
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
  required final _AgentVisibilityChanged onVisibilityChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => agents.isEmpty
      ? const _AgentsSearchEmptyState()
      : _AgentsListView(
          agents: agents,
          onTap: onTap,
          onSelection: onSelection,
          onVisibilityChanged: onVisibilityChanged,
        );
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
  required final _AgentVisibilityChanged onVisibilityChanged,
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
      onVisibilityChanged: onVisibilityChanged,
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
  required final Future<void> Function(AgentVisibility visibility)
  onVisibilityChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => LayoutBuilder(
    builder: (context, constraints) => _AgentListItemLayout(
      agent: agent,
      isCompact: constraints.maxWidth < DesignBreakpoints.sm,
      onTap: onTap,
      onSelection: onSelection,
      onVisibilityChanged: onVisibilityChanged,
    ),
  );
}

class const _AgentListItemLayout({
  required final AgentListItem agent,
  required final bool isCompact,
  required final VoidCallback onTap,
  required final ValueChanged<String> onSelection,
  required final Future<void> Function(AgentVisibility visibility)
  onVisibilityChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraTile(
    child: _AgentListItemSurface(
      agent: agent,
      isCompact: isCompact,
      onTap: onTap,
      onVisibilityChanged: onVisibilityChanged,
    ),
    variant: .ghost,
    trailing: _AgentMenu(onSelected: onSelection),
  );
}

class _AgentListItemSurface extends StatelessWidget {
  new({
    required AgentListItem agent,
    required bool isCompact,
    required VoidCallback onTap,
    required Future<void> Function(AgentVisibility visibility)
    onVisibilityChanged,
  }) : _child = isCompact
           ? AuraColumn(
               children: [
                 _AgentEditButton(agent: agent, onPressed: onTap),
                 _AgentVisibilityControl(
                   value: agent.visibility,
                   compact: true,
                   onChanged: onVisibilityChanged,
                   key: ValueKey('agent-visibility-${agent.id}'),
                 ),
               ],
               spacing: .sm,
               crossAxisAlignment: .stretch,
               mainAxisSize: .min,
             )
           : Row(
               children: [
                 Expanded(
                   child: _AgentEditButton(agent: agent, onPressed: onTap),
                 ),
                 const AuraSizedBox(width: .sm),
                 _AgentVisibilityControl(
                   value: agent.visibility,
                   compact: false,
                   onChanged: onVisibilityChanged,
                   key: ValueKey('agent-visibility-${agent.id}'),
                 ),
               ],
             );

  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentEditButton({
  required final AgentListItem agent,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: Row(
      children: [
        const AuraIcon(Icons.smart_toy_outlined),
        const AuraSizedBox(width: .sm),
        Expanded(child: _AgentListItemDetails(agent: agent)),
      ],
    ),
    variant: .ghost,
    isFullWidth: true,
    semanticLabel: agent.name,
  );
}

class const _AgentListItemDetails({required final AgentListItem agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _AgentNameRow(agent: agent),
        _AgentSkillCount(agent: agent),
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

class _AgentVisibilityControl extends StatefulWidget {
  const new({
    required this.value,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final AgentVisibility value;
  final bool compact;
  final Future<void> Function(AgentVisibility visibility) onChanged;

  @override
  State<_AgentVisibilityControl> createState() =>
      _AgentVisibilityControlState();
}

class _AgentVisibilityControlState extends State<_AgentVisibilityControl> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _AgentCompactVisibilityControl(
        value: widget.value,
        isLoading: _isSaving,
        onPressed: () => unawaited(_openSheet()),
      );
    }

    return _AgentWideVisibilityControl(
      value: widget.value,
      isLoading: _isSaving,
      onChanged: (value) => unawaited(_save(value)),
    );
  }

  Future<void> _openSheet() async {
    if (_isSaving) return;

    final selected = await _showSheet();
    if (!mounted || selected == null || selected == widget.value) return;

    await _save(selected);
  }

  Future<AgentVisibility?> _showSheet() =>
      showModalBottomSheet<AgentVisibility>(
        context: context,
        builder: (context) => _AgentVisibilitySheet(value: widget.value),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
      );

  Future<void> _save(AgentVisibility value) async {
    if (_isSaving || value == widget.value) return;
    setState(() => _isSaving = true);
    try {
      await widget.onChanged(value);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class const _AgentWideVisibilityControl({
  required final AgentVisibility value,
  required final bool isLoading,
  required final ValueChanged<AgentVisibility> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.agents_visibility_label),
        style: .bodySmall,
      ),
      AuraButtonGroup<AgentVisibility>.single(
        items: _visibilityButtonItems(context),
        selectedValue: value,
        onChanged: onChanged,
        size: .sm,
        isLoading: isLoading,
      ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _AgentCompactVisibilityControl({
  required final AgentVisibility value,
  required final bool isLoading,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = _visibilitySummary(context, value);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: AuraButton(
        onPressed: onPressed,
        child: _AgentCompactVisibilityButtonContent(summary: summary),
        variant: .outlined,
        size: .small,
        isLoading: isLoading,
        semanticLabel: summary,
      ),
    );
  }
}

String _visibilitySummary(BuildContext context, AgentVisibility value) {
  final label = LocaleKeys.agents_visibility_label.tr(context: context);
  final visibility = value.localizedLabel(context);

  return '$label: $visibility';
}

class const _AgentCompactVisibilityButtonContent({
  required final String summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    mainAxisSize: .min,
    children: [
      Flexible(child: Text(summary, overflow: .ellipsis, maxLines: 1)),
      const AuraSizedBox(width: .xs),
      const AuraIcon(Icons.keyboard_arrow_down, size: .small),
    ],
  );
}

class _AgentVisibilitySheet extends StatefulWidget {
  const new({required this.value});

  final AgentVisibility value;

  @override
  State<_AgentVisibilitySheet> createState() => _AgentVisibilitySheetState();
}

class _AgentVisibilitySheetState extends State<_AgentVisibilitySheet> {
  AgentVisibility? _value;

  AgentVisibility get _selectedValue => _value ?? widget.value;

  @override
  Widget build(BuildContext context) => _AgentVisibilitySheetSurface(
    selectedValue: _selectedValue,
    onChanged: _setValue,
    onDone: () => Navigator.of(context).pop(_value),
  );

  void _setValue(List<AgentVisibility> values) {
    final selected = values.firstOrNull;
    if (selected == null) return;
    setState(() => _value = selected);
  }
}

class const _AgentVisibilitySheetSurface({
  required final AgentVisibility selectedValue,
  required final ValueChanged<List<AgentVisibility>> onChanged,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentVisibilitySheetFrame(
    maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    color: context.auraColors.surface,
    borderRadius: .vertical(
      top: .circular(context.auraTheme.fromBorderRadius(.xl)),
    ),
    child: _AgentVisibilitySheetContent(
      selectedValue: selectedValue,
      onChanged: onChanged,
      onDone: onDone,
    ),
  );
}

class const _AgentVisibilitySheetFrame({
  required final double maxHeight,
  required final Color color,
  required final BorderRadius borderRadius,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ConstrainedBox(
    constraints: .new(maxHeight: maxHeight),
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: child,
    ),
  );
}

class const _AgentVisibilitySheetContent({
  required final AgentVisibility selectedValue,
  required final ValueChanged<List<AgentVisibility>> onChanged,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => SingleChildScrollView(
    child: AuraColumn(
      children: [
        const _AgentVisibilitySheetTitle(),
        const AuraSizedBox(height: .md),
        _AgentVisibilitySheetPicker(
          selectedValue: selectedValue,
          onChanged: onChanged,
        ),
        const AuraSizedBox(height: .md),
        _AgentVisibilitySheetDoneButton(onPressed: onDone),
      ],
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
    ),
  );
}

class const _AgentVisibilitySheetTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const AuraText(
    child: TextLocale(LocaleKeys.agents_visibility_label),
    style: .heading5,
  );
}

class const _AgentVisibilitySheetPicker({
  required final AgentVisibility selectedValue,
  required final ValueChanged<List<AgentVisibility>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraChoicePicker<AgentVisibility>(
    options: _visibilityChoiceOptions(context),
    value: [selectedValue],
    onChanged: onChanged,
    semanticLabel: LocaleKeys.agents_visibility_label.tr(context: context),
  );
}

class const _AgentVisibilitySheetDoneButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.agents_visibility_done),
    key: const ValueKey('agent-visibility-done'),
    isFullWidth: true,
  );
}

List<AuraButtonGroupItem<AgentVisibility>> _visibilityButtonItems(
  BuildContext context,
) => [
  for (final value in AgentVisibility.values)
    AuraButtonGroupItem(
      value: value,
      child: TextLocale(_visibilityLabelKey(value)),
      semanticLabel: _visibilityLabelKey(value).tr(context: context),
    ),
];

List<AuraChoiceOption<AgentVisibility>> _visibilityChoiceOptions(
  BuildContext context,
) => [
  for (final value in AgentVisibility.values)
    AuraChoiceOption(
      value: value,
      label: TextLocale(_visibilityLabelKey(value)),
      semanticLabel: _visibilityLabelKey(value).tr(context: context),
    ),
];

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
  required final _AgentVisibilityChanged onVisibilityChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return _AgentListItem(
      agent: agent,
      onTap: () => onTap(agent),
      onSelection: (value) => onSelection(value, agent),
      onVisibilityChanged: (visibility) =>
          onVisibilityChanged(agent, visibility),
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
    return _visibilityLabelKey(this).tr(context: context);
  }
}

String _visibilityLabelKey(AgentVisibility value) => switch (value) {
  .chatSelector => LocaleKeys.agents_visibility_chat_selector,
  .subAgentList => LocaleKeys.agents_visibility_sub_agent_list,
  .both => LocaleKeys.agents_visibility_both,
};
