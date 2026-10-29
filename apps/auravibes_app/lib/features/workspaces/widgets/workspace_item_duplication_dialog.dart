import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_item_duplication_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_form_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

abstract final class WorkspaceItemDuplicationDialog {
  static Future<String?> open(
    BuildContext context,
    String workspaceId,
    WorkspaceItemDuplication request,
  ) {
    final form = WorkspaceItemDuplicationForm(
      workspaceId: workspaceId,
      request: request,
    );

    return MediaQuery.sizeOf(context).width < 600
        ? _sheet(context, form)
        : _dialog(context, form);
  }
}

Future<String?> _sheet(BuildContext context, Widget form) =>
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(child: form),
      isScrollControlled: true,
    );
Future<String?> _dialog(BuildContext context, Widget form) =>
    showDialog<String>(
      context: context,
      builder: (_) => Dialog(child: SizedBox(width: 480, child: form)),
    );

class const WorkspaceItemDuplicationForm({
  required final String workspaceId,
  required final WorkspaceItemDuplication request,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) =>
      _Content(.new(this, .use(name: request.name), useState(false)));
}

class const _CopyState(
  final WorkspaceItemDuplicationForm owner,
  final WorkspaceItemFormState form,
  final ValueNotifier<bool> records,
) {
  Future<void> save(BuildContext context, WidgetRef ref) async {
    final usecase = await ref.read(
      workspaceItemDuplicationUsecaseProvider(owner.workspaceId).future,
    );
    final copied = await usecase(_input(), approve: () async => true);
    if (context.mounted && copied) _complete(context, ref);
  }

  WorkspaceItemDuplication _input() =>
      owner.request.withOptions(form.name.text, copyRecords: records.value);

  void _complete(BuildContext context, WidgetRef ref) {
    ref
      ..invalidate(workspaceTablesProvider)
      ..invalidate(workspaceViewsProvider);
    Navigator.of(context).pop(owner.request.targetId);
  }
}

class const _Content(final _CopyState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _Fields(state),
    ),
  );
}

class const _Fields(final _CopyState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    spacing: 8,
    children: [
      const TextLocale(LocaleKeys.workspace_items_duplicate),
      _Name(state),
      _Options(state),
      if (state.form.error.value case final error?)
        WorkspaceItemFailure(error: error),
      _Submit(state),
      _Cancel(state),
    ],
  );
}

class const _Name(final _CopyState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: state.form.name,
    label: const TextLocale(LocaleKeys.workspace_items_duplicate_name),
    enabled: !state.form.pending.value,
    identifier: 'workspace_duplicate_name',
  );
}

class const _Options(final _CopyState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => state.owner.request.kind == .table
      ? Column(
          children: [
            const TextLocale(LocaleKeys.workspace_items_duplicate_hint),
            _IncludeRecords(state),
            const TextLocale(
              LocaleKeys.workspace_items_duplicate_relationships,
            ),
          ],
        )
      : const TextLocale(LocaleKeys.workspace_items_duplicate_view_binding);
}

class const _IncludeRecords(final _CopyState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: state.records.value,
    onChanged: state.form.pending.value ? null : _changed,
    title: const TextLocale(LocaleKeys.workspace_items_duplicate_records),
  );
  void _changed(bool? value) => state.records.value = value ?? false;
}

class const _Submit(final _CopyState state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => _submit(context, ref),
    child: const TextLocale(LocaleKeys.workspace_items_duplicate),
    isLoading: state.form.pending.value,
    disabled: state.form.pending.value,
    identifier: 'workspace_duplicate_submit',
  );
  void _submit(BuildContext context, WidgetRef ref) =>
      unawaited(state.form.run(context, () => state.save(context, ref)));
}

class const _Cancel(final _CopyState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
    variant: .ghost,
    disabled: state.form.pending.value,
  );
}
