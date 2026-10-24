import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceCsvPreviewContent({
  required final WorkspaceCsvPreview preview,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      for (var index = 0; index < preview.values.length; index++)
        _PreviewRow(preview: preview, index: index),
    ],
  );
}

class const _PreviewRow({
  required final WorkspaceCsvPreview preview,
  required final int index,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: TextLocale('workspace_csv.row', args: ['${index + 2}']),
    children: [
      for (final column in preview.table.columns)
        ListTile(title: Text(column.name), subtitle: Text(_value(column.id))),
    ],
  );
  String _value(String id) => preview.values[index].containsKey(id)
      ? jsonEncode(preview.values[index][id])
      : '--';
}
