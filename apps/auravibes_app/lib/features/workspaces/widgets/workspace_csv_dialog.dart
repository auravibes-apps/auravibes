import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_csv_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_csv_mapping.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_csv_preview_content.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceCsvDialog({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final bool importing,
  super.key,
}) extends HookConsumerWidget {
  static Future<void> openImport(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    WorkspaceTable table,
  ) async {
    await _open(context, workspaceId, table, true);
    if (!context.mounted) return;
    ref
      ..invalidate(workspaceRecordQueryUsecaseProvider(workspaceId))
      ..invalidate(workspaceTableRecordsProvider(workspaceId, table.id));
  }

  static Future<void> openExport(
    BuildContext context,
    String workspaceId,
    WorkspaceTable table,
  ) => _open(context, workspaceId, table, false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _useDraft();
    final usecase = ref.watch(workspaceCsvUsecaseProvider(workspaceId));
    final runtime = (
      draft: draft,
      action: WorkspaceTableActions.use(context),
      flow: _CsvFlow(context, this, draft, usecase.value),
      failure: usecase.error,
    );

    return _CsvFrame(owner: this, runtime: runtime);
  }
}

typedef _CsvDraft = ({
  ValueNotifier<WorkspaceCsvInput?> input,
  ValueNotifier<Map<int, String>> mapping,
  ValueNotifier<WorkspaceCsvPreview?> preview,
  ValueNotifier<bool> completed,
});
typedef _CsvRuntime = ({
  _CsvDraft draft,
  WorkspaceTableAction action,
  _CsvFlow flow,
  Object? failure,
});

_CsvDraft _useDraft() => (
  input: useState<WorkspaceCsvInput?>(null),
  mapping: useState<Map<int, String>>({}),
  preview: useState<WorkspaceCsvPreview?>(null),
  completed: useState(false),
);

class const _CsvFrame({
  required final WorkspaceCsvDialog owner,
  required final _CsvRuntime runtime,
}) extends StatelessWidget {
  String get _title =>
      owner.importing ? 'workspace_csv.import' : 'workspace_csv.export';

  @override
  Widget build(BuildContext context) => PopScope(
    child: AlertDialog(
      title: TextLocale(_title),
      content: _CsvContent(owner: owner, runtime: runtime),
      actions: [
        _CloseCsvButton(pending: runtime.action.pending),
        if (!runtime.draft.completed.value)
          _ContinueCsvButton(owner: owner, runtime: runtime),
      ],
    ),
    canPop: !runtime.action.pending,
  );
}

class const _CloseCsvButton({required final bool pending})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale('common.close'),
    disabled: pending,
  );
}

class const _ContinueCsvButton({
  required final WorkspaceCsvDialog owner,
  required final _CsvRuntime runtime,
}) extends StatelessWidget {
  bool get _disabled =>
      runtime.flow.usecase == null ||
      runtime.action.pending ||
      runtime.draft.preview.value?.errors.isNotEmpty == true;
  String get _label {
    if (!owner.importing) return 'workspace_csv.save';
    if (runtime.draft.input.value == null) return 'workspace_csv.choose';

    return runtime.draft.preview.value == null
        ? 'workspace_csv.validate'
        : 'workspace_csv.commit';
  }

  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(runtime.action.run(runtime.flow.run)),
    child: TextLocale(_label),
    isLoading: runtime.action.pending,
    disabled: _disabled,
    identifier: 'workspace_csv_continue',
  );
}

class const _CsvFlow(
  final BuildContext context,
  final WorkspaceCsvDialog owner,
  final _CsvDraft draft,
  final WorkspaceCsvUsecase? usecase,
) {
  Future<void> run() async {
    final ready = usecase;
    if (ready == null) return;
    if (!owner.importing) return await _export(ready);
    await _import(ready);
  }

  Future<void> _import(WorkspaceCsvUsecase ready) async {
    final selected = draft.input.value;
    if (selected == null) return await _pick(ready);
    final validated = draft.preview.value;
    if (validated == null) return await _preview(ready, selected);
    if (validated.errors.isEmpty) await _commit(ready, validated);
  }

  Future<void> _export(WorkspaceCsvUsecase ready) async {
    final saved = await ready.exportFile(owner.table.id);
    if (context.mounted) draft.completed.value = saved;
  }

  Future<void> _pick(WorkspaceCsvUsecase ready) async {
    final selected = await ready.pick();
    if (context.mounted) draft.input.value = selected;
  }

  Future<void> _preview(
    WorkspaceCsvUsecase ready,
    WorkspaceCsvInput input,
  ) async {
    final result = await ready.preview(
      table: owner.table,
      input: input,
      mapping: draft.mapping.value,
    );
    if (context.mounted) draft.preview.value = result;
  }

  Future<void> _commit(
    WorkspaceCsvUsecase ready,
    WorkspaceCsvPreview preview,
  ) async {
    await ready.commit(preview);
    if (context.mounted) draft.completed.value = true;
  }
}

class const _CsvContent({
  required final WorkspaceCsvDialog owner,
  required final _CsvRuntime runtime,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 560,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text(owner.table.name),
          const _CsvFormat(),
          _CsvMapping(owner: owner, runtime: runtime),
          if (runtime.draft.preview.value case final preview?)
            _CsvReview(preview: preview),
          _CsvOutcome(runtime: runtime),
        ],
      ),
    ),
  );
}

class const _CsvMapping({
  required final WorkspaceCsvDialog owner,
  required final _CsvRuntime runtime,
}) extends StatelessWidget {
  bool get _enabled =>
      !runtime.action.pending && !runtime.draft.completed.value;

  @override
  Widget build(BuildContext context) => switch (runtime.draft.input.value) {
    final WorkspaceCsvInput input => WorkspaceCsvMapping(
      input: input,
      table: owner.table,
      mapping: runtime.draft.mapping.value,
      onChanged: _changed,
      enabled: _enabled,
    ),
    null => const SizedBox.shrink(),
  };
  void _changed(Map<int, String> mapping) {
    runtime.draft.mapping.value = mapping;
    runtime.draft.preview.value = null;
  }
}

class const _CsvReview({required final WorkspaceCsvPreview preview})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      TextLocale('workspace_csv.rows', args: ['${preview.values.length}']),
      WorkspaceCsvPreviewContent(preview: preview),
      _CsvValidation(preview: preview),
    ],
  );
}

class const _CsvValidation({required final WorkspaceCsvPreview preview})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (final error in preview.errors)
        TextLocale(error.localizationKey, args: ['${error.row}']),
      if (preview.errors.isEmpty) const TextLocale('workspace_csv.validated'),
    ],
  );
}

class const _CsvOutcome({required final _CsvRuntime runtime})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      if (runtime.draft.completed.value)
        const TextLocale('workspace_csv.completed'),
      if (runtime.action.error case final error?)
        WorkspaceItemFailure(error: error),
      if (runtime.failure case final error?) WorkspaceItemFailure(error: error),
    ],
  );
}

Future<void> _open(
  BuildContext context,
  String workspaceId,
  WorkspaceTable table,
  bool importing,
) => showDialog<void>(
  context: context,
  builder: (context) => WorkspaceCsvDialog(
    workspaceId: workspaceId,
    table: table,
    importing: importing,
  ),
  barrierDismissible: false,
);

class const _CsvFormat() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ExpansionTile(
    title: TextLocale('workspace_csv.format'),
    children: [TextLocale('workspace_csv.help')],
  );
}
