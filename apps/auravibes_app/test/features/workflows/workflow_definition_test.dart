import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects a non-map definition with a format error', () {
    expect(
      () => WorkflowDefinition.fromJson({'definition': null}),
      throwsFormatException,
    );
  });
}
