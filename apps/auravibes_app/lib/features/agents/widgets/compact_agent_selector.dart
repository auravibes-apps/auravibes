import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CompactAgentSelector extends ConsumerWidget {
  const CompactAgentSelector({
    required this.workspaceId,
    required this.agentId,
    required this.onChanged,
    super.key,
  });

  final String workspaceId;
  final String? agentId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider(workspaceId));

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
            for (final agent in value)
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
