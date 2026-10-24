import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_approval.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceHistoryPolicyButton({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = _manageable(
      ref.watch(workspaceHistoryPolicyProvider(workspaceId)).value,
    );
    if (policy == null) return const SizedBox.shrink();

    return AuraIconButton(
      icon: Icons.settings,
      onPressed: () => unawaited(_open(context, policy)),
      identifier: 'workspace_history_retention',
      tooltip: LocaleKeys.workspace_items_history_policy_title.tr(),
    );
  }

  Future<void> _open(BuildContext context, WorkspaceHistoryPolicy policy) =>
      showDialog<void>(
        context: context,
        builder: (_) => _PolicyDialog(workspaceId: workspaceId, policy: policy),
      );
}

class const _PolicyDialog({
  required final String workspaceId,
  required final WorkspaceHistoryPolicy policy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _PolicyForm(workspaceId: workspaceId, policy: policy),
        ),
      ),
    ),
  );
}

class const _PolicyForm({
  required final String workspaceId,
  required final WorkspaceHistoryPolicy policy,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = useTextEditingController(text: policy.days?.toString() ?? '');
    final action = WorkspaceTableActions.use(context);

    return _PolicyContent(
      controller: days,
      action: action,
      onSave: () => _submit(context, ref, action, days.text),
    );
  }

  void _submit(
    BuildContext context,
    WidgetRef ref,
    WorkspaceTableAction action,
    String text,
  ) => unawaited(
    action.run(
      () => _PolicySubmission(workspaceId, policy, text).call(context, ref),
    ),
  );
}

class const _PolicyContent({
  required final TextEditingController controller,
  required final WorkspaceTableAction action,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      const TextLocale(LocaleKeys.workspace_items_history_policy_title),
      const TextLocale(LocaleKeys.workspace_items_history_policy_hint),
      _PolicyDays(controller: controller, enabled: !action.pending),
      _PolicySave(action: action, onSave: onSave),
      if (action.error case final Object error)
        WorkspaceItemFailure(error: error),
      const _PolicyCancel(),
    ],
  );
}

class const _PolicySave({
  required final WorkspaceTableAction action,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onSave,
    child: const TextLocale(LocaleKeys.common_save),
    isLoading: action.pending,
    disabled: action.pending,
    identifier: 'workspace_history_policy_save',
  );
}

class const _PolicyCancel() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
    variant: .ghost,
  );
}

class const _PolicySubmission(
  final String workspaceId,
  final WorkspaceHistoryPolicy policy,
  final String text,
) {
  Future<void> call(BuildContext context, WidgetRef ref) async {
    final usecase = await ref.read(
      workspaceHistoryUsecaseProvider(workspaceId).future,
    );
    if (!context.mounted) return;
    final changed = await _apply(context, usecase);
    if (!context.mounted || !changed) return;
    ref.invalidate(workspaceHistoryPolicyProvider(workspaceId));
    Navigator.of(context).pop();
  }

  Future<bool> _apply(
    BuildContext context,
    ManageWorkspaceHistoryUsecase usecase,
  ) => usecase.configurePolicy(
    policy,
    WorkspaceHistoryPolicy.parse(text),
    approve: () => WorkspaceHistoryApproval.configure(context),
  );
}

class const _PolicyDays({
  required final TextEditingController controller,
  required final bool enabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: const TextLocale(LocaleKeys.workspace_items_history_policy_days),
    keyboardType: .number,
    enabled: enabled,
    identifier: 'workspace_history_policy_days',
  );
}

WorkspaceHistoryPolicy? _manageable(WorkspaceHistoryPolicy? policy) =>
    policy?.canManage == true ? policy : null;
