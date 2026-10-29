import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

class const WorkflowNodeDraft({
  required final WorkflowNodeKind kind,
  required final String targetId,
  required final String label,
  required final String defaultInputLabel,
  required final String defaultOutputLabel,
  final List<WorkflowPort>? inputs,
  final List<WorkflowPort>? outputs,
});
