import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:uuid/v7.dart';

abstract final class WorkflowConnectorOutputInference {
  static List<WorkflowPort> merge({
    required List<WorkflowPort> current,
    required Object? sample,
    required bool hasSampledOutputs,
  }) {
    final incoming = _ports(sample);
    final incomingByName = {for (final port in incoming) port.name: port};
    final currentNames = current.map((port) => port.name).toSet();

    return [
      for (final port in current)
        port.copyWith(
          type: switch (incomingByName[port.name]) {
            final next? => _mergeType(port.type, next.type),
            null => port.type,
          },
          isRequired: port.isRequired && incomingByName.containsKey(port.name),
        ),
      for (final port in incoming)
        if (!currentNames.contains(port.name))
          port.copyWith(isRequired: !hasSampledOutputs),
    ];
  }

  static List<WorkflowPort> _ports(Object? sample) {
    var value = sample;
    if (value case final String source) {
      try {
        value = jsonDecode(source);
      } on FormatException {
        value = source;
      }
    }
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) return [_result(value)];

      return [
        for (final entry in value.entries)
          WorkflowPort(
            id: const UuidV7().generate(),
            name: entry.key as String,
            type: _type(entry.value),
          ),
      ];
    }

    return [_result(value)];
  }

  static WorkflowPort _result(Object? value) => WorkflowPort(
    id: const UuidV7().generate(),
    name: 'Result',
    type: _type(value),
  );

  static WorkflowValueType _type(Object? value) => switch (value) {
    bool() => .boolean,
    int() => .integer,
    num() => .number,
    String() => .string,
    Map() => .object,
    List() => .array,
    _ => .any,
  };

  static WorkflowValueType _mergeType(
    WorkflowValueType current,
    WorkflowValueType next,
  ) => current == next ? current : .any;
}
