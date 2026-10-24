import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceTrashRestoreButton({
  required final String workspaceId,
  required final String batchId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return _RestoreControls(
      action: action,
      batchId: batchId,
      onPressed: () => unawaited(
        action.run(() => _restore(context, ref, workspaceId, batchId)),
      ),
    );
  }
}

class const _RestoreControls({
  required final WorkspaceTableAction action,
  required final String batchId,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _RestoreButton(action: action, batchId: batchId, onPressed: onPressed),
      if (action.error case final Object error)
        WorkspaceItemFailure(error: error),
    ],
  );
}

class const _RestoreButton({
  required final WorkspaceTableAction action,
  required final String batchId,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.workspace_items_trash_restore),
    isLoading: action.pending,
    disabled: action.pending,
    identifier: 'workspace_trash_restore_$batchId',
  );
}

Future<void> _restore(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String batchId,
) async {
  final result = await WorkspaceTrashActions.restore(ref, workspaceId, batchId);
  if (!context.mounted || !_needsNotice(result)) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _RestorationNotice(result: result),
  );
}

bool _needsNotice(WorkspaceTrashRestoration result) =>
    result.movedToRoot || result.unresolvedDependencies;

class const _RestorationNotice({
  required final WorkspaceTrashRestoration result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _RestorationContent(result: result),
      ),
    ),
  );
}

class const _RestorationContent({
  required final WorkspaceTrashRestoration result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      if (result.movedToRoot)
        const TextLocale(LocaleKeys.workspace_items_trash_root_fallback),
      if (result.unresolvedDependencies)
        const TextLocale(LocaleKeys.workspace_items_trash_unresolved),
      const _RestorationClose(),
    ],
  );
}

class const _RestorationClose() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.workspace_items_trash_close),
  );
}
