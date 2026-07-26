import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('adds credential options and keeps first duplicate tool', () {
    final schema = materializeSkillToolSchema(
      {'type': 'object', 'properties': {}},
      requiresCredential: true,
      credentialIds: ['a', 'a', 'b'],
    );
    expect((schema['properties']! as Map)['credentialId'], isNotNull);
    expect(schema['required']! as List, contains('credentialId'));
    final first = ToolSpec(name: 'x', description: 'one', inputJsonSchema: {});
    final second = ToolSpec(name: 'x', description: 'two', inputJsonSchema: {});
    expect(uniqueToolSpecs([first, second]).single.description, 'one');
  });
}
