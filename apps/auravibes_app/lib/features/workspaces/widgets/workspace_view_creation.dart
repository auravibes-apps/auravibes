import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_form_state.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_source_picker.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewCreation({
  required final String workspaceId,
  required final String? parentId,
  required final ValueChanged<String> onOpenView,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) =>
      _Form(this, .use(), useState<WorkspaceTable?>(null));
}

class const _Form(
  final WorkspaceViewCreation owner,
  final WorkspaceItemFormState state,
  final ValueNotifier<WorkspaceTable?> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _Name(state),
      const TextLocale(LocaleKeys.workspace_views_bindings),
      _Source(owner, selected),
      _Create(owner, state, selected),
      if (state.error.value case final error?)
        WorkspaceItemFailure(error: error),
    ],
  );
}

class const _Name(final WorkspaceItemFormState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: state.name,
    label: const TextLocale(LocaleKeys.workspace_views_name),
    identifier: 'workspace_view_name',
  );
}

class const _Source(
  final WorkspaceViewCreation owner,
  final ValueNotifier<WorkspaceTable?> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceViewSourcePicker(
    workspaceId: owner.workspaceId,
    selected: selected.value,
    onSelected: (table) => selected.value = table,
  );
}

class const _Create(
  final WorkspaceViewCreation owner,
  final WorkspaceItemFormState state,
  final ValueNotifier<WorkspaceTable?> selected,
) extends HookConsumerWidget {
  bool get _disabled => selected.value == null || state.pending.value;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = useState<WorkspaceView?>(null);
    return AuraButton(
      onPressed: () =>
          unawaited(state.run(context, () => _save(context, ref, draft))),
      child: const TextLocale(LocaleKeys.workspace_views_create),
      isLoading: state.pending.value,
      disabled: _disabled,
      identifier: 'workspace_view_create',
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<WorkspaceView?> draft,
  ) async {
    final table = selected.value;
    if (table == null) return;
    final view = _draft(table, draft.value);
    draft.value = view;
    final id = await _create(ref, view);
    if (!context.mounted) return;
    ref.invalidate(workspaceViewsProvider(owner.workspaceId, owner.parentId));
    owner.onOpenView(id);
  }

  WorkspaceView _draft(WorkspaceTable table, WorkspaceView? previous) {
    if (previous != null &&
        previous.name == state.name.text &&
        previous.tableId == table.id)
      return previous;
    return WorkspaceView.create(
      name: state.name.text,
      table: table,
      columnIds: [table.labelColumnId],
      parentId: owner.parentId,
    );
  }

  Future<String> _create(WidgetRef ref, WorkspaceView view) async {
    final usecase = await ref.read(
      workspaceViewUsecaseProvider(owner.workspaceId).future,
    );
    final created = await usecase.save(view, requestId: view.id);
    return created.id;
  }
}
