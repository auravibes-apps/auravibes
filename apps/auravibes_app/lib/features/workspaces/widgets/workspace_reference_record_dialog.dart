import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:material_ui/material_ui.dart';

const _dialogWidth = 680.0;
const _dialogHeight = 560.0;

typedef WorkspaceReferenceRecordInput = ({
  WorkspaceTable table,
  WorkspaceRecord? record,
  ValueChanged<WorkspaceRecord>? onSaved,
});

class const WorkspaceReferenceRecordDialog({
  required final String workspaceId,
  required final WorkspaceReferenceRecordInput input,
  super.key,
}) extends StatelessWidget {
  static Future<void> open(
    BuildContext context,
    String workspaceId,
    WorkspaceReferenceRecordInput input,
  ) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: WorkspaceReferenceRecordDialog(
        workspaceId: workspaceId,
        input: input,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _dialogWidth,
    height: _dialogHeight,
    child: _ReferenceEditor(workspaceId: workspaceId, input: input),
  );
}

class const _ReferenceEditor({
  required final String workspaceId,
  required final WorkspaceReferenceRecordInput input,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceRecordEditor(
    workspaceId: workspaceId,
    table: input.table,
    record: input.record,
    onBack: () => Navigator.of(context).pop(),
    onSaved: input.onSaved,
  );
}
