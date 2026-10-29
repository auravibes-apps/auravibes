import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewDetail({
  required final WorkspaceViewData data,
  required final ValueNotifier<String?> selected,
  required final String workspaceId,
  super.key,
}) extends StatelessWidget {
  WorkspaceRecord? get _record =>
      data.records.where((record) => record.id == selected.value).firstOrNull ??
      data.records.firstOrNull;
  @override
  Widget build(BuildContext context) {
    final record = _record;
    if (record == null) {
      return const TextLocale(LocaleKeys.workspace_views_empty);
    }

    return _DetailContent(data, record, selected, workspaceId);
  }
}

class const _DetailContent(
  final WorkspaceViewData data,
  final WorkspaceRecord record,
  final ValueNotifier<String?> selected,
  final String workspaceId,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _RecordSelector(data, record, selected),
      WorkspaceViewSurface(
        data: _detailData(data, record),
        workspaceId: workspaceId,
        recordId: record.id,
      ),
    ],
  );
}

class const _RecordSelector(
  final WorkspaceViewData data,
  final WorkspaceRecord record,
  final ValueNotifier<String?> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      for (final row in data.records)
        _RecordOption(row, data.table.labelColumnId),
    ],
    value: record.id,
    onChanged: (id) => selected.value = id,
    label: const TextLocale(LocaleKeys.workspace_relational_record),
    identifier: 'workspace_view_detail_record',
  );
}

class _RecordOption extends AuraDropdownOption<String> {
  new(WorkspaceRecord row, String labelId)
    : super(value: row.id, child: Text(row.values[labelId]?.toString() ?? '-'));
}

WorkspaceViewData _detailData(WorkspaceViewData data, WorkspaceRecord record) =>
    .new(
      view: data.view,
      table: data.table,
      records: [record],
      needsRepair: data.needsRepair,
    );
