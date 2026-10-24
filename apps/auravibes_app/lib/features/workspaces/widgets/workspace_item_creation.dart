import 'dart:async';

import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_form_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemCreation({
  required final String workspaceId,
  required final String? parentId,
  required final bool table,
  required final ValueChanged<String> onOpenTable,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => _Form(this, .use());

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    WorkspaceItemFormState state,
  ) async {
    final id = table
        ? await _table(ref, state.name.text)
        : await _folder(ref, state.name.text);
    if (!context.mounted) return;
    state.name.clear();
    _refresh(ref);
    if (id != null) onOpenTable(id);
  }

  Future<String?> _folder(WidgetRef ref, String name) async {
    final usecase = await ref.read(
      workspaceFolderUsecaseProvider(workspaceId).future,
    );
    final _ = await usecase.create(name: name, parentId: parentId);

    return null;
  }

  Future<String> _table(WidgetRef ref, String name) async {
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(workspaceId).future,
    );
    final created = await usecase.create(
      name: name,
      labelName: LocaleKeys.workspace_items_default_label.tr(),
      parentId: parentId,
    );

    return created.id;
  }

  void _refresh(WidgetRef ref) {
    if (table) {
      ref.invalidate(workspaceTablesProvider(workspaceId, parentId));
    } else {
      ref.invalidate(workspaceFoldersProvider(workspaceId, parentId));
    }
  }
}

class const _Form(
  final WorkspaceItemCreation creation,
  final WorkspaceItemFormState state,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> submit() =>
        state.run(context, () => creation._save(context, ref, state));

    return Column(
      children: [
        _Input(creation, state, submit),
        _Button(creation, state, submit),
        _Failure(state),
      ],
    );
  }
}

class const _Failure(final WorkspaceItemFormState state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state.error.value) {
    final Object error => WorkspaceItemFailure(error: error),
    null => const SizedBox.shrink(),
  };
}

class const _Input(
  final WorkspaceItemCreation creation,
  final WorkspaceItemFormState state,
  final Future<void> Function() submit,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: state.name,
    label: TextLocale(
      creation.table
          ? LocaleKeys.workspace_items_table_name
          : LocaleKeys.workspace_items_folder_name,
    ),
    enabled: !state.pending.value,
    onSubmitted: creation.table ? null : (_) => unawaited(submit()),
    identifier: creation.table
        ? 'workspace_table_name'
        : 'workspace_folder_name',
  );
}

class const _Button(
  final WorkspaceItemCreation creation,
  final WorkspaceItemFormState state,
  final Future<void> Function() save,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(save()),
    child: TextLocale(
      creation.table
          ? LocaleKeys.workspace_items_create_table
          : LocaleKeys.workspace_items_create_folder,
    ),
    isLoading: state.pending.value,
    disabled: state.pending.value,
    identifier: creation.table
        ? 'workspace_table_create'
        : 'workspace_folder_create',
  );
}
