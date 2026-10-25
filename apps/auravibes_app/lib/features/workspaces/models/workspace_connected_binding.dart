class const WorkspaceConnectedBinding({
  required final String toolId,
  required final String revision,
  required final Map<String, Object?> inputs,
  final String? connectionId,
}) {
  factory fromJson(Map<String, dynamic> value) => .new(
    toolId: value['toolId'] as String,
    revision: value['revision'] as String,
    inputs: Map<String, Object?>.from(value['inputs'] as Map),
    connectionId: value['connectionId'] as String?,
  );

  Map<String, Object?> toJson() => {
    'toolId': toolId,
    'revision': revision,
    'inputs': inputs,
    if (connectionId != null) 'connectionId': connectionId,
  };

  Map<String, dynamic> executionArguments() => {
    'toolId': toolId,
    'revision': revision,
    'args': inputs,
    if (connectionId != null) 'connectionId': connectionId,
  };
}
