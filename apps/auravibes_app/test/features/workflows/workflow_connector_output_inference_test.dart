import 'package:auravibes_app/features/workflows/models/workflow_connector_output_inference.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('infers top-level fields and preserves nested values', () {
    final ports = WorkflowConnectorOutputInference.merge(
      current: const [],
      sample: '{"title":"Page","metadata":{"id":4},"items":[true]}',
      hasSampledOutputs: false,
    );

    expect(ports.map((port) => port.name), ['title', 'metadata', 'items']);
    expect(ports.map((port) => port.type), [
      WorkflowValueType.string,
      WorkflowValueType.object,
      WorkflowValueType.array,
    ]);
    expect(ports.every((port) => port.isRequired), isTrue);
  });

  test(
    'merges missing and new fields as optional and type conflicts as any',
    () {
      final first = WorkflowConnectorOutputInference.merge(
        current: const [],
        sample: {'name': 'Page', 'count': 1},
        hasSampledOutputs: false,
      );
      final merged = WorkflowConnectorOutputInference.merge(
        current: first,
        sample: {'name': 2, 'extra': true},
        hasSampledOutputs: true,
      );
      final byName = {for (final port in merged) port.name: port};

      expect(byName['name']?.type, WorkflowValueType.any);
      expect(byName['name']?.isRequired, isTrue);
      expect(byName['count']?.isRequired, isFalse);
      expect(byName['extra']?.type, WorkflowValueType.boolean);
      expect(byName['extra']?.isRequired, isFalse);
      expect(
        byName['name']?.id,
        {for (final port in first) port.name: port.id}['name'],
      );
    },
  );

  test('uses a Result string port for non-JSON text', () {
    final ports = WorkflowConnectorOutputInference.merge(
      current: const [],
      sample: 'not JSON',
      hasSampledOutputs: false,
    );

    expect(ports.single.name, 'Result');
    expect(ports.single.type, WorkflowValueType.string);
  });

  test('uses a Result port for JSON scalars and arrays', () {
    final scalar = WorkflowConnectorOutputInference.merge(
      current: const [],
      sample: '7',
      hasSampledOutputs: false,
    );
    final array = WorkflowConnectorOutputInference.merge(
      current: const [],
      sample: '[{"id":1}]',
      hasSampledOutputs: false,
    );

    expect(scalar.single.name, 'Result');
    expect(scalar.single.type, WorkflowValueType.integer);
    expect(array.single.name, 'Result');
    expect(array.single.type, WorkflowValueType.array);
  });

  test('handles an empty first object before later samples', () {
    final first = WorkflowConnectorOutputInference.merge(
      current: const [],
      sample: const <String, Object?>{},
      hasSampledOutputs: false,
    );
    final next = WorkflowConnectorOutputInference.merge(
      current: first,
      sample: {'name': 'Page'},
      hasSampledOutputs: true,
    );

    expect(next.single.name, 'name');
    expect(next.single.isRequired, isFalse);
  });
}
