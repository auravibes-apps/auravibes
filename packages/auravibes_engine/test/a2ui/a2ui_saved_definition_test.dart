import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('saved surfaces reject executable and external destinations', () {
    final definition = A2uiSavedDefinition.fromJson({
      'version': 1,
      'components': [
        {'id': 'root', 'component': 'Text', 'text': {'path': '/title'}},
      ],
    });
    expect(definition.components.single['id'], 'root');
    for (final component in [
      {'id': 'root', 'component': 'Text', 'text': 'safe', 'expression': 'evil()'},
      {'id': 'root', 'component': 'Image', 'url': 'https://example.com/image'},
      {'id': 'root', 'component': 'SkillSuggestion', 'slug': 'execute'},
    ]) {
      expect(
        () => A2uiSavedDefinition.fromJson({'version': 1, 'components': [component]}),
        throwsFormatException,
      );
    }
  });
}
