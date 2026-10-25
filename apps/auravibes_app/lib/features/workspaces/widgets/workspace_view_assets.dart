import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_attachment_field.dart';
import 'package:material_ui/material_ui.dart';

/// Assets remain host widgets; generated definitions never receive URLs or IDs.
class const WorkspaceViewAssets({
  required final String workspaceId,
  required final WorkspaceViewData data,
  super.key,
}) extends StatelessWidget {
  List<WorkspaceColumn> get _columns => data.table.columns
      .where(
        (column) =>
            column.type == .attachment &&
            data.view.bindings.containsValue(column.id),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    if (data.needsRepair || columns.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final record in data.records)
          _Record(workspaceId, record, columns, data.table.labelColumnId),
      ],
    );
  }
}

class const _Record(
  final String workspaceId,
  final WorkspaceRecord record,
  final List<WorkspaceColumn> columns,
  final String labelColumnId,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(record.values[labelColumnId]?.toString() ?? ''),
    children: [
      for (final column in columns) _Field(workspaceId, record, column),
    ],
  );
}

class const _Field(
  final String workspaceId,
  final WorkspaceRecord record,
  final WorkspaceColumn column,
) extends StatelessWidget {
  bool get _present => record.values.containsKey(column.id);
  bool get _restricted => record.restrictedReferenceColumns.contains(column.id);

  @override
  Widget build(BuildContext context) => WorkspaceAttachmentField(
    workspaceId: workspaceId,
    label: column.name,
    value: record.values[column.id],
    present: _present,
    disabled: true,
    restricted: _restricted,
    onChanged: (_) => _denied(),
    onUnset: _denied,
  );
}

Never _denied() => throw const WorkspaceAssetException(.denied);
