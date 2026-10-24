import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkspaceViewHistory({
  required final String workspaceId,
  required final WorkspaceView current,
  required final VoidCallback onDone,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) =>
      _History(this, WorkspaceTableActions.use(context));
}

class const _History(
  final WorkspaceViewHistory owner,
  final WorkspaceTableAction action,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.arrow_back),
        title: const TextLocale(LocaleKeys.workspace_views_history),
        onTap: owner.onDone,
      ),
      Expanded(child: _Revisions(owner, action)),
      if (action.error case final error?) WorkspaceItemFailure(error: error),
    ],
  );
}

class const _Revisions(
  final WorkspaceViewHistory owner,
  final WorkspaceTableAction action,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceViewHistoryProvider(owner.workspaceId, owner.current.id),
  )) {
    AsyncData(:final value) => ListView(
      children: [
        for (final revision in value.reversed)
          _Revision(owner, action, revision),
      ],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _Revision(
  final WorkspaceViewHistory owner,
  final WorkspaceTableAction action,
  final WorkspaceView revision,
) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operationId = useMemoized(const UuidV7().generate);

    return ListTile(
      title: Text('${revision.name} (${revision.revision})'),
      subtitle: const TextLocale(LocaleKeys.workspace_views_restore),
      enabled: !action.pending,
      onTap: () => _submit(context, ref, operationId),
    );
  }

  void _submit(BuildContext context, WidgetRef ref, String operationId) =>
      unawaited(action.run(() => _restore(context, ref, operationId)));

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    String operationId,
  ) async {
    final usecase = await ref.read(
      workspaceViewUsecaseProvider(owner.workspaceId).future,
    );
    final _ = await usecase.restore(
      owner.current,
      revision,
      requestId: operationId,
    );
    if (context.mounted) owner.onDone();
  }
}
