import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

class WorkflowNodeDraft {
  const WorkflowNodeDraft({
    required this.kind,
    required this.targetId,
    required this.canonicalName,
    required this.label,
    required this.defaultInputLabel,
    required this.defaultOutputLabel,
    this.inputs,
    this.outputs,
    this.sourceNodeId,
    this.conditionBranch,
    this.conditionRules = const [],
    this.transformOutputs = const [],
  });

  final WorkflowNodeKind kind;
  final String targetId;
  final String canonicalName;
  final String label;
  final String defaultInputLabel;
  final String defaultOutputLabel;
  final List<WorkflowField>? inputs;
  final List<WorkflowField>? outputs;
  final String? sourceNodeId;
  final WorkflowConditionBranch? conditionBranch;
  final List<WorkflowConditionRule> conditionRules;
  final List<WorkflowTransformOutput> transformOutputs;

  WorkflowNodeDraft copyWith({
    String? sourceNodeId,
    WorkflowConditionBranch? conditionBranch,
  }) => WorkflowNodeDraft(
    kind: kind,
    targetId: targetId,
    canonicalName: canonicalName,
    label: label,
    defaultInputLabel: defaultInputLabel,
    defaultOutputLabel: defaultOutputLabel,
    inputs: inputs,
    outputs: outputs,
    sourceNodeId: sourceNodeId ?? this.sourceNodeId,
    conditionBranch: conditionBranch ?? this.conditionBranch,
    conditionRules: conditionRules,
    transformOutputs: transformOutputs,
  );
}
