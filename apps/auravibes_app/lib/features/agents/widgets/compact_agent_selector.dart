import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    if (sheetMode) {
      return switch (agentsAsync) {
        AsyncLoading() => const Center(
          child: AuraSpinner(size: AuraSpinnerSize.small),
        ),
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

    if (compactMode) {
      return switch (agentsAsync) {
        AsyncLoading() => const _AgentChip(
          label: AuraSpinner(size: AuraSpinnerSize.small),
        ),
        AsyncError() => const _AgentChip(
          label: TextLocale(LocaleKeys.agents_selector_placeholder),
        ),
        AsyncData(:final value) => _AgentChip(
          label: switch (_selectedAgentName(value, agentId)) {
            null => const TextLocale(
              LocaleKeys.agents_selector_none,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            final name => Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          },
        ),
      };
    }

    return SizedBox(
      width: 180,
      child: switch (agentsAsync) {
        AsyncLoading() => const AuraDropdownSelector<String>(
          options: [],
          placeholder: AuraSpinner(size: AuraSpinnerSize.small),
          isEnabled: false,
        ),
        AsyncError() => const AuraDropdownSelector<String>(
          options: [],
          placeholder: TextLocale(LocaleKeys.agents_selector_placeholder),
          isEnabled: false,
        ),
        AsyncData(:final value) => AuraDropdownSelector<String>(
          options: [
            const AuraDropdownOption(
              value: '',
              child: TextLocale(LocaleKeys.agents_selector_none),
            ),
            for (final agent in value.where(
              (agent) => agent.appearsInChatSelector,
            ))
              AuraDropdownOption(value: agent.id, child: Text(agent.name)),
          ],
          value: agentId ?? '',
          onChanged: (value) =>
              onChanged(value?.isEmpty ?? true ? null : value),
          placeholder: const TextLocale(LocaleKeys.agents_selector_placeholder),
        ),
      },
    );
  }
}

class const _AgentChip({required final Widget label}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: label,
      variant: AuraTileVariant.selected,
      size: AuraTileSize.small,
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
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final searchValue = useState<String>('');
    final searchTerm = searchValue.value.trim().toLowerCase();
    final filteredAgents = searchTerm.isEmpty
        ? agents
        : agents
              .where((agent) => agent.name.toLowerCase().contains(searchTerm))
              .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraInput(
          controller: controller,
          prefixIcon: const AuraIcon(Icons.search),
          onChanged: (value) => searchValue.value = value,
        ),
        const AuraSizedBox(height: .sm),
        Flexible(
          child: ListView.separated(
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AgentSheetTile(
                  isSelected: agentId == null,
                  onTap: () => _select(context, null),
                  child: const TextLocale(LocaleKeys.agents_selector_none),
                );
              }

              final agent = filteredAgents[index - 1];

              return _AgentSheetTile(
                isSelected: agent.id == agentId,
                onTap: () => _select(context, agent.id),
                child: Text(agent.name, overflow: TextOverflow.ellipsis),
              );
            },
            separatorBuilder: (context, index) =>
                const AuraSizedBox(height: .sm),
            itemCount: filteredAgents.length + 1,
          ),
        ),
      ],
    );
  }

  void _select(BuildContext context, String? value) {
    onChanged(value);
    final _ = Navigator.maybePop(context);
  }
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
      trailing: isSelected
          ? const AuraIcon(Icons.check, tint: AuraTint.primary)
          : null,
    );
  }
}
