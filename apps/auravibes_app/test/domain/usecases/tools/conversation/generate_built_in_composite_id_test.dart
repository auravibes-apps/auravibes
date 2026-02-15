import 'package:auravibes_app/domain/usecases/tools/conversation/generate_built_in_composite_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds composite id with built_in prefix', () {
    final id = generateBuiltInCompositeId(
      tableId: 'tool_1',
      toolIdentifier: 'calculator',
    );

    expect(id, 'built_in_tool_1_calculator');
  });
}
