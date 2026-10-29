import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceHistoryPolicySummary({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(workspaceHistoryPolicyProvider(workspaceId))) {
        AsyncData(:final value) =>
          value.days == null
              ? const TextLocale(LocaleKeys.workspace_items_history_retention)
              : TextLocale(
                  LocaleKeys.workspace_items_history_policy_summary,
                  args: ['${value.days}'],
                ),
        AsyncError(:final error) => WorkspaceItemFailure(error: error),
        AsyncLoading() => const SizedBox.shrink(),
      };
}
