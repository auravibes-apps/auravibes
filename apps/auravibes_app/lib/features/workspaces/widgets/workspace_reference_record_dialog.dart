import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    builder: (_) =>
        _ReferenceRecordModal(workspaceId: workspaceId, input: input),
  );

  @override
  Widget build(BuildContext context) =>
      _ReferenceEditor(workspaceId: workspaceId, input: input);
}

class const _ReferenceRecordModal({
  required final String workspaceId,
  required final WorkspaceReferenceRecordInput input,
}) extends StatelessWidget {
  static const _maximumWidth = 680.0;
  static const _maximumHeight = 560.0;
  static const _insetsPerAxis = 2;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final inset = size.width < 600 ? 8.0 : 40.0;
    final dimensions = _dimensions(size, inset);

    return Dialog(
      insetPadding: .all(inset),
      child: SizedBox(
        width: dimensions.width,
        height: dimensions.height,
        child: WorkspaceReferenceRecordDialog(
          workspaceId: workspaceId,
          input: input,
        ),
      ),
    );
  }

  ({double width, double height}) _dimensions(Size size, double inset) => (
    width: (size.width - inset * _insetsPerAxis).clamp(0.0, _maximumWidth),
    height: (size.height - inset * _insetsPerAxis).clamp(0.0, _maximumHeight),
  );
}

class const _ReferenceEditor({
  required final String workspaceId,
  required final WorkspaceReferenceRecordInput input,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkspaceRecordEditor(
    workspaceId: workspaceId,
    table: input.table,
    record: input.record,
    onBack: () => Navigator.of(context).pop(),
    onSaved: (record) => _saved(ref, record),
  );
  void _saved(WidgetRef ref, WorkspaceRecord record) {
    ref
      ..invalidate(workspaceReferencesUsecaseProvider(workspaceId))
      ..invalidate(workspaceRecordQueryUsecaseProvider(workspaceId))
      ..invalidate(workspaceTableRecordsProvider(workspaceId, input.table.id));
    input.onSaved?.call(record);
  }
}
