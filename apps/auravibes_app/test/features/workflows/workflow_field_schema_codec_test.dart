import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_field_schema_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Connector schema JSON round trips nested types and defaults', () {
    final fields = [
      const WorkflowField(
        id: 'name',
        name: 'name',
        type: .string,
        description: 'Display name',
        hasDefaultValue: true,
        defaultValue: 'Ada',
      ),
      const WorkflowField(
        id: 'records',
        name: 'records',
        type: .array,
        isRequired: false,
        items: WorkflowField(
          id: 'record',
          name: 'item',
          type: .object,
          properties: [
            WorkflowField(
              id: 'code',
              name: 'code',
              type: .integer,
              isRequired: false,
              nullable: true,
            ),
          ],
        ),
      ),
    ];

    final encoded = WorkflowFieldSchemaCodec.encode(fields);
    final decoded = WorkflowFieldSchemaCodec.parse(encoded)!;

    expect(WorkflowFieldSchemaCodec.encode(decoded), encoded);
    expect(decoded.first.defaultValue, 'Ada');
    expect(decoded.last.items!.properties.single.nullable, isTrue);
  });
}
