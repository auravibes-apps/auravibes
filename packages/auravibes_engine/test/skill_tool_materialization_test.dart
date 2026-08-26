import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('adds credential options and rejects duplicate tools', () {
    final schema = materializeSkillToolSchema(
      {'type': 'object', 'properties': {}},
      requiresCredential: true,
      credentialIds: ['a', 'a', 'b'],
    );
    expect((schema['properties']! as Map)['credentialId'], isNotNull);
    expect(schema['required']! as List, contains('credentialId'));
    final first = ToolSpec(name: 'x', description: 'one', inputJsonSchema: {});
    final second = ToolSpec(name: 'x', description: 'two', inputJsonSchema: {});
    expect(
      () => uniqueToolSpecs([first, second]),
      throwsStateError,
    );
  });

  test('keeps optional template inputs out of required fields', () {
    final schema = templateInputSchema([
      {'name': 'requiredValue', 'type': 'string'},
      {'name': 'optionalValue', 'type': 'string', 'isOptional': true},
    ], requiresCredential: false);

    expect(schema['required'], ['requiredValue']);
    expect(
      (schema['properties']! as Map<String, Object?>).keys,
      containsAll(['requiredValue', 'optionalValue']),
    );
  });
}
