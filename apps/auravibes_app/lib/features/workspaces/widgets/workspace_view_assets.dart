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
          ExpansionTile(
            title: Text(
              record.values[data.table.labelColumnId]?.toString() ?? '',
            ),
            children: [
              for (final column in columns)
                WorkspaceAttachmentField(
                  workspaceId: workspaceId,
                  label: column.name,
                  value: record.values[column.id],
                  present: record.values.containsKey(column.id),
                  disabled: true,
                  restricted: record.restrictedReferenceColumns.contains(
                    column.id,
                  ),
                  onChanged: (_) => _denied(),
                  onUnset: _denied,
                ),
            ],
          ),
      ],
    );
  }
}

Never _denied() => throw const WorkspaceAssetException(.denied);
