import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_record_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceLabel({
  required final String workspaceId,
  required final String targetTableId,
  required final String recordId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(workspaceTableProvider(workspaceId, targetTableId));
    final rows = ref.watch(
      workspaceReferencedRecordProvider(workspaceId, targetTableId, recordId),
    );

    return _ResolvedLabel(
      workspaceId: workspaceId,
      state: (table: table, record: rows),
    );
  }
}

typedef _ReferenceLabelState = ({
  AsyncValue<WorkspaceTable> table,
  AsyncValue<WorkspaceRecord> record,
});

class const _ResolvedLabel({
  required final String workspaceId,
  required final _ReferenceLabelState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    (
      table: AsyncData(value: final table),
      record: AsyncData(value: final records),
    ) =>
      _RecordLink(workspaceId: workspaceId, table: table, record: records),
    (table: AsyncError(), record: _) || (table: _, record: AsyncError()) =>
      const TextLocale(LocaleKeys.workspace_items_reference_unavailable),
    _ => const CircularProgressIndicator(),
  };
}

class const _RecordLink({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceRecord record,
}) extends StatelessWidget {
  String get _label =>
      record.values[table.labelColumnId]?.toString() ??
      LocaleKeys.workspace_items_reference_unavailable.tr();
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => WorkspaceReferenceRecordDialog.open(context, workspaceId, (
      table: table,
      record: record,
      onSaved: null,
    )),
    child: Text(_label),
    variant: .ghost,
  );
}
