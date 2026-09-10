import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef _AgentSheetHookState = ({
  TextEditingController controller,
  List<AgentEntity> agents,
  ValueChanged<String> onSearchChanged,
});

_AgentSheetHookState _useAgentSheetState(List<AgentEntity> agents) {
  final controller = useTextEditingController();
  final searchValue = useState<String>('');

  return (
    controller: controller,
    agents: _filterAgents(agents, searchValue.value),
    onSearchChanged: (value) => searchValue.value = value,
  );
}

class const CompactAgentSelector({
  required final String workspaceId,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
  final bool compactMode = false,
  final bool sheetMode = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider(workspaceId));

    return _CompactAgentSelectorContent(
      agentsAsync: agentsAsync,
      agentId: agentId,
      compactMode: compactMode,
      sheetMode: sheetMode,
      onChanged: onChanged,
    );
  }
}

class _CompactAgentSelectorContent extends StatelessWidget {
  const new({
    required this.agentsAsync,
    required this.agentId,
    required this.onChanged,
    required this.compactMode,
    required this.sheetMode,
  });

  final AsyncValue<List<AgentEntity>> agentsAsync;
  final String? agentId;
  final ValueChanged<String?> onChanged;
  final bool compactMode;
  final bool sheetMode;

  @override
  Widget build(BuildContext _) => sheetMode
      ? _AgentSheetMode(
          agentsAsync: agentsAsync,
          agentId: agentId,
          onChanged: onChanged,
        )
      : compactMode
      ? _AgentCompactMode(agentsAsync: agentsAsync, agentId: agentId)
      : _AgentDropdownMode(
          agentsAsync: agentsAsync,
          agentId: agentId,
          onChanged: onChanged,
        );
}

class const _AgentSheetMode({
  required final AsyncValue<List<AgentEntity>> agentsAsync,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (agentsAsync) {
    AsyncLoading() => const Center(child: AuraSpinner(size: .small)),
    AsyncError() => const Center(
      child: TextLocale(LocaleKeys.agents_selector_placeholder),
    ),
    AsyncData(:final value) => _AgentSheetSelector(
      agents: value,
      agentId: agentId,
      onChanged: onChanged,
    ),
  };
}

class _AgentCompactMode extends StatelessWidget {
  _AgentCompactMode({required this.agentsAsync, required this.agentId})
    : _child = switch (agentsAsync) {
        AsyncLoading() => const _AgentChip(label: AuraSpinner(size: .small)),
        AsyncError() => const _AgentChip(
          label: TextLocale(LocaleKeys.agents_selector_placeholder),
        ),
        AsyncData(:final value) => _AgentChip(
          label: switch (_selectedAgentName(value, agentId)) {
            null => const TextLocale(
              LocaleKeys.agents_selector_none,
              softWrap: false,
              overflow: .ellipsis,
              maxLines: 1,
            ),
            final name => Text(name, overflow: .ellipsis, maxLines: 1),
          },
        ),
      };

  final AsyncValue<List<AgentEntity>> agentsAsync;
  final String? agentId;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentDropdownMode({
  required final AsyncValue<List<AgentEntity>> agentsAsync,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: _AgentDropdownStateView(
      agentsAsync: agentsAsync,
      agentId: agentId,
      onChanged: onChanged,
    ),
  );
}

class _AgentDropdownStateView extends StatelessWidget {
  _AgentDropdownStateView({
    required this.agentsAsync,
    required this.agentId,
    required this.onChanged,
  }) : _child = switch (agentsAsync) {
         AsyncLoading() => const _DisabledAgentDropdown(
           placeholder: AuraSpinner(size: .small),
         ),
         AsyncError() => const _DisabledAgentDropdown(
           placeholder: TextLocale(LocaleKeys.agents_selector_placeholder),
         ),
         AsyncData(:final value) => _AgentDropdownOptions(
           agents: value,
           agentId: agentId,
           onValueChanged: (value) =>
               onChanged(value?.isEmpty ?? true ? null : value),
         ),
       };

  final AsyncValue<List<AgentEntity>> agentsAsync;
  final String? agentId;
  final ValueChanged<String?> onChanged;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _DisabledAgentDropdown({required final Widget placeholder})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: const [],
    placeholder: placeholder,
    isEnabled: false,
  );
}

class _AgentDropdownOptions extends StatelessWidget {
  _AgentDropdownOptions({
    required this.agents,
    required this.agentId,
    required this.onValueChanged,
  }) : _options = [
         const AuraDropdownOption(
           value: '',
           child: TextLocale(LocaleKeys.agents_selector_none),
         ),
         for (final agent in agents.where(
           (agent) => agent.appearsInChatSelector,
         ))
           AuraDropdownOption(value: agent.id, child: Text(agent.name)),
       ];

  final List<AgentEntity> agents;
  final String? agentId;
  final ValueChanged<String?> onValueChanged;
  final List<AuraDropdownOption<String>> _options;

  @override
  Widget build(BuildContext _) => AuraDropdownSelector<String>(
    options: _options,
    value: agentId ?? '',
    onChanged: onValueChanged,
    placeholder: const TextLocale(LocaleKeys.agents_selector_placeholder),
  );
}

class const _AgentChip({required final Widget label}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: label,
      variant: .selected,
      size: .small,
      leading: const AuraIcon(Icons.smart_toy_outlined),
    );
  }
}

String? _selectedAgentName(List<AgentEntity> agents, String? agentId) {
  for (final agent in agents) {
    if (agent.id == agentId) return agent.name;
  }

  return null;
}

class const _AgentSheetSelector({
  required final List<AgentEntity> agents,
  required final String? agentId,
  required final ValueChanged<String?> onChanged,
}) extends HookWidget {
  @override
  Widget build(BuildContext _) {
    final sheetState = _useAgentSheetState(agents);

    return _AgentSheetBody(
      controller: sheetState.controller,
      agents: sheetState.agents,
      agentId: agentId,
      onSearchChanged: sheetState.onSearchChanged,
      onSelect: _select,
    );
  }

  void _select(BuildContext context, String? value) {
    onChanged(value);
    final _ = Navigator.maybePop(context);
  }
}

List<AgentEntity> _filterAgents(List<AgentEntity> agents, String searchValue) {
  final searchTerm = searchValue.trim().toLowerCase();
  if (searchTerm.isEmpty) return agents;

  return agents
      .where((agent) => agent.name.toLowerCase().contains(searchTerm))
      .toList();
}

class _AgentSheetBody extends StatelessWidget {
  _AgentSheetBody({
    required this.controller,
    required this.agents,
    required this.agentId,
    required this.onSearchChanged,
    required this.onSelect,
  }) : _child = Column(
         mainAxisSize: .min,
         children: [
           AuraInput(
             controller: controller,
             prefixIcon: const AuraIcon(Icons.search),
             onChanged: onSearchChanged,
           ),
           const AuraSizedBox(height: .sm),
           Flexible(
             child: _AgentSheetList(
               agents: agents,
               agentId: agentId,
               onSelect: onSelect,
             ),
           ),
         ],
       );

  final TextEditingController controller;
  final List<AgentEntity> agents;
  final String? agentId;
  final ValueChanged<String> onSearchChanged;
  final void Function(BuildContext, String?) onSelect;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class _AgentSheetList extends StatelessWidget {
  _AgentSheetList({
    required this.agents,
    required this.agentId,
    required this.onSelect,
  }) : _child = ListView.separated(
         itemBuilder: (context, index) => _AgentSheetListItem(
           agents: agents,
           agentId: agentId,
           index: index,
           onSelect: onSelect,
         ),
         separatorBuilder: (context, index) => const AuraSizedBox(height: .sm),
         itemCount: agents.length + 1,
       );

  final List<AgentEntity> agents;
  final String? agentId;
  final void Function(BuildContext, String?) onSelect;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentSheetListItem({
  required final List<AgentEntity> agents,
  required final String? agentId,
  required final int index,
  required final void Function(BuildContext, String?) onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      return _AgentSheetNoneItem(
        isSelected: agentId == null,
        onSelect: onSelect,
      );
    }

    final agent = agents[index - 1];
    return _AgentSheetAgentItem(
      agent: agent,
      isSelected: agent.id == agentId,
      onSelect: onSelect,
    );
  }
}

class const _AgentSheetNoneItem({
  required final bool isSelected,
  required final void Function(BuildContext, String?) onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentSheetTile(
    isSelected: isSelected,
    onTap: () => onSelect(context, null),
    child: const TextLocale(LocaleKeys.agents_selector_none),
  );
}

class const _AgentSheetAgentItem({
  required final AgentEntity agent,
  required final bool isSelected,
  required final void Function(BuildContext, String?) onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentSheetTile(
    isSelected: isSelected,
    onTap: () => onSelect(context, agent.id),
    child: Text(agent.name, overflow: .ellipsis),
  );
}

class const _AgentSheetTile({
  required final bool isSelected,
  required final VoidCallback onTap,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: child,
      onTap: onTap,
      variant: isSelected ? AuraTileVariant.selected : AuraTileVariant.surface,
      trailing: isSelected ? const AuraIcon(Icons.check, tint: .primary) : null,
    );
  }
}
