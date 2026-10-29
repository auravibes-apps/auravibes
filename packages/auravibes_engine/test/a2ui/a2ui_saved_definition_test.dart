import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('saved surfaces reject executable and external destinations', () {
    final definition = A2uiSavedDefinition.fromJson({
      'version': 1,
      'components': [
        {
          'id': 'root',
          'component': 'Text',
          'text': {'path': '/title'},
        },
      ],
    });
    expect(definition.components.single['id'], 'root');
    if (definition.components.single['text']
        case final Map<String, Object?> path) {
      expect(() => path['path'] = '/other', throwsUnsupportedError);
    } else {
      fail('Expected immutable path map');
    }
    for (final component in [
      {
        'id': 'root',
        'component': 'Text',
        'text': 'safe',
        'expression': 'evil()',
      },
      {'id': 'root', 'component': 'Image', 'url': 'https://example.com/image'},
      {'id': 'root', 'component': 'SkillSuggestion', 'slug': 'execute'},
    ]) {
      expect(
        () => A2uiSavedDefinition.fromJson({
          'version': 1,
          'components': [component],
        }),
        throwsFormatException,
      );
    }
  });

  test('saved form surfaces require the action catalog and reject events', () {
    final form = {
      'version': 1,
      'components': [
        {
          'id': 'root',
          'component': 'TextField',
          'label': 'Title',
          'value': {'path': '/answers/title'},
        },
      ],
    };
    expect(
      A2uiSavedDefinition.fromJson(
        form,
        requiresUserAction: true,
      ).components.single['id'],
      'root',
    );
    expect(
      () => A2uiSavedDefinition.fromJson({
        'version': 1,
        'components': [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Title',
            'value': {'path': '/answers/title'},
            'onSubmittedAction': {'actionName': 'execute'},
          },
        ],
      }, requiresUserAction: true),
      throwsFormatException,
    );
  });

  test('applyPatch updates, appends, and removes components safely', () {
    final base = A2uiSavedDefinition.fromJson({
      'version': 1,
      'components': [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['header', 'legacy'],
        },
        {'id': 'header', 'component': 'Text', 'text': 'Before'},
        {'id': 'legacy', 'component': 'Text', 'text': 'Remove me'},
      ],
    });
    final patched = base.applyPatch(
      updateComponents: [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['header', 'chart'],
        },
        {'id': 'header', 'component': 'Text', 'text': 'After'},
        {
          'id': 'chart',
          'component': 'Chart',
          'variant': 'bar',
          'labels': {'path': '/chartLabels'},
          'series': {'path': '/chartSeries'},
        },
      ],
      removeComponentIds: const ['legacy'],
    );

    expect(patched.components.map((component) => component['id']), [
      'root',
      'header',
      'chart',
    ]);
    expect(patched.components[1]['text'], 'After');
    expect(
      () => base.applyPatch(removeComponentIds: const ['header']),
      throwsFormatException,
    );
  });
}
