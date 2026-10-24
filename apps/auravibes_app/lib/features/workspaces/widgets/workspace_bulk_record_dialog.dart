import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_record_change.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_batch_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_fields.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkspaceBulkRecordDialog({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final List<WorkspaceRecord> records,
  final ConversationToolAccessMode mode = .defaultMode,
  super.key,
}) extends HookConsumerWidget {
  static Future<bool> open(
    BuildContext context,
    String workspaceId,
    WorkspaceTable table,
    List<WorkspaceRecord> records,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: WorkspaceBulkRecordDialog(
            workspaceId: workspaceId,
            table: table,
            records: .unmodifiable(records),
          ),
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = _BulkDrafts.use(records);
    final action = WorkspaceTableActions.use(context);
    final requestId = useMemoized(() => const UuidV7().generate());

    return _BulkFrame((
      owner: this,
      drafts: drafts,
      action: action,
      save: () => _save(context, ref, drafts, requestId),
    ));
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    List<ValueNotifier<Map<String, Object?>>> drafts,
    String requestId,
  ) async {
    final usecase = await ref.read(
      workspaceRecordBatchUsecaseProvider(workspaceId).future,
    );
    if (!context.mounted) return;
    final applied = await usecase.apply(
      _changes(drafts),
      requestId: requestId,
      mode: mode,
      approve: (_) => _approve(context),
    );
    if (!context.mounted) return;
    _complete(context, applied);
  }

  void _complete(BuildContext context, bool applied) {
    if (context.mounted && applied) Navigator.of(context).pop(true);
  }

  List<WorkspaceRecordChange> _changes(
    List<ValueNotifier<Map<String, Object?>>> drafts,
  ) => [
    for (var i = 0; i < records.length; i++)
      WorkspaceRecordChange(
        table: table,
        record: records[i],
        values: drafts[i].value,
      ),
  ];

  Future<bool> _approve(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => _BulkApproval(records.length),
      ) ??
      false;
}

class const _BulkRecord({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceRecord record,
  required final ValueNotifier<Map<String, Object?>> draft,
  required final bool disabled,
}) extends HookWidget {
  String get _label => record.values[table.labelColumnId]?.toString() ?? '';
  @override
  Widget build(BuildContext context) {
    final _ = useValueListenable(draft);

    return ExpansionTile(
      key: ValueKey('workspace_bulk_record_${record.id}'),
      title: Text(_label),
      children: [_BulkRecordFields(this)],
    );
  }
}

typedef _BulkForm = ({
  WorkspaceBulkRecordDialog owner,
  List<ValueNotifier<Map<String, Object?>>> drafts,
  WorkspaceTableAction action,
  Future<void> Function() save,
});

class const _BulkFrame(final _BulkForm form) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 720,
    height: 620,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _ScopeText(form.owner.records.length),
        ),
        Expanded(child: _BulkRecords(form)),
        if (form.action.error case final error?)
          WorkspaceItemFailure(error: error),
        _BulkButtons(form),
      ],
    ),
  );
}

class const _ScopeText(final int count) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workspace_items_bulk_scope.tr(namedArgs: {'count': '$count'}),
  );
}

class const _BulkRecords(final _BulkForm form) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (var i = 0; i < form.owner.records.length; i++)
        _BulkIndexedRecord(form, i),
    ],
  );
}

class const _BulkIndexedRecord(final _BulkForm form, final int index)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final owner = form.owner;

    return _BulkRecord(
      workspaceId: owner.workspaceId,
      table: owner.table,
      record: owner.records[index],
      draft: form.drafts[index],
      disabled: form.action.pending,
    );
  }
}

class const _BulkButtons(final _BulkForm form) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(
      spacing: 12,
      children: [
        _CancelBulkButton(pending: form.action.pending),
        _SaveBulkButton(form),
      ],
    ),
  );
}

class const _CancelBulkButton({required final bool pending})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: const TextLocale(LocaleKeys.common_cancel),
    disabled: pending,
  );
}

class const _SaveBulkButton(final _BulkForm form) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(form.action.run(form.save)),
    child: const TextLocale(LocaleKeys.common_save),
    isLoading: form.action.pending,
    disabled: form.action.pending,
    identifier: 'workspace_bulk_save',
  );
}

class const _BulkApproval(final int count) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: _ScopeText(count),
    content: const TextLocale(LocaleKeys.workspace_items_bulk_approval),
    actions: const [
      _ApprovalButton(approved: false),
      _ApprovalButton(approved: true),
    ],
  );
}

class const _ApprovalButton({required final bool approved})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    key: approved ? const ValueKey('workspace_bulk_approve') : null,
    onPressed: () => Navigator.of(context).pop(approved),
    child: TextLocale(
      approved ? LocaleKeys.common_save : LocaleKeys.common_cancel,
    ),
  );
}

abstract final class _BulkDrafts {
  static List<ValueNotifier<Map<String, Object?>>> use(
    List<WorkspaceRecord> records,
  ) {
    final drafts = useMemoized(() => records.map(_draft).toList());
    useEffect(
      () =>
          () => _dispose(drafts),
      [drafts],
    );

    return drafts;
  }

  static ValueNotifier<Map<String, Object?>> _draft(WorkspaceRecord record) =>
      .new({...record.values});
  static void _dispose(List<ValueNotifier<Map<String, Object?>>> drafts) {
    for (final draft in drafts) {
      draft.dispose();
    }
  }
}

class const _BulkRecordFields(final _BulkRecord row) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: WorkspaceRecordFields(
      table: row.table,
      workspaceId: row.workspaceId,
      restricted: row.record.restrictedReferenceColumns,
      draft: row.draft,
      disabled: row.disabled,
    ),
  );
}
