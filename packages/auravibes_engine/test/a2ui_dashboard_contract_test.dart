import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

A2uiIssueCode? validate(Map<String, Object?> component) =>
    A2uiChatContract.validateMessage({
      'version': a2uiChatWireVersion,
      'updateComponents': {
        'surfaceId': 'dashboard',
        'components': [component],
      },
    });

Map<String, Object?> example(String name, Map<String, Object?> overrides) => {
  ...a2uiChatComponentExamples[name]!,
  ...overrides,
};

void main() {
  test('all catalog examples validate', () {
    for (final entry in a2uiChatComponentExamples.entries) {
      expect(validate(entry.value), isNull, reason: entry.key);
    }
  });

  test(
    'negotiation filters both schemas and examples without mutating catalogs',
    () {
      for (final supported in [
        baselineA2uiChatComponents,
        {'Table', 'Chart'},
        {'Text', 'unknown'},
      ]) {
        final prompt = A2uiChatContract.systemPromptForComponents(supported);
        final schemas = jsonDecode(
          prompt
              .split('CATALOG_SCHEMA_START\n')
              .last
              .split('\nCATALOG_EXAMPLES_START')
              .first,
        ) as Map;
        final examples = jsonDecode(
          prompt
              .split('CATALOG_EXAMPLES_START\n')
              .last
              .split('\nCATALOG_END')
              .first,
        ) as Map;
        final expected = supported.intersection(supportedA2uiChatComponents);
        expect(schemas.keys.toSet(), expected);
        expect(examples.keys.toSet(), expected);
        if (!supported.contains('Text')) {
          expect(prompt, isNot(contains('"component":"Text"')));
        }
      }
      expect(baselineA2uiChatComponents, hasLength(16));
      expect(
        () => baselineA2uiChatComponents.add('Chart'),
        throwsUnsupportedError,
      );
      expect(A2uiChatContract.systemPromptForComponents({}), isEmpty);
      expect(A2uiChatContract.systemPromptForComponents({'unknown'}), isEmpty);
      expect(supportedA2uiChatComponents, hasLength(45));
    },
  );

  test('complete static and bound tabs prompt examples validate', () {
    final prompt = A2uiChatContract.systemPrompt;
    for (final section in ['COMPLETE_SURFACE', 'BOUND_TABS']) {
      final messages = prompt
          .split('${section}_EXAMPLE_START\n')
          .last
          .split('\n${section}_EXAMPLE_END')
          .first
          .split('\n')
          .map((line) => jsonDecode(line) as Map)
          .toList();
      for (final message in messages) {
        expect(A2uiChatContract.isValidEnvelope(message), isTrue);
      }
      final create = (messages.first['message'] as Map)['createSurface'] as Map;
      expect(create['sendDataModel'], isFalse);
      final update =
          (messages.last['message'] as Map)['updateComponents'] as Map;
      expect(
        A2uiChatContract.isRenderableComponentGraph({
          for (final component in update['components'] as List)
            (component as Map)['id'] as String: Map<String, Object?>.from(
              component,
            ),
        }),
        isTrue,
      );
    }
  });

  test(
    'dashboard data accepts root bindings and rejects malformed bindings',
    () {
      final fields = {
        'Progress': ['value', 'label'],
        'Badge': ['label'],
        'Avatar': ['name', 'url'],
        'AvatarGroup': ['avatars'],
        'Table': ['columns', 'rows', 'caption'],
        'Chart': ['labels', 'series', 'label'],
        'EmptyState': ['title', 'description'],
        'LoadingIndicator': ['label'],
      };
      for (final entry in fields.entries) {
        for (final field in entry.value) {
          expect(
            validate(
              example(entry.key, {
                field: {'path': '/data'},
              }),
            ),
            isNull,
            reason: '${entry.key}.$field',
          );
          for (final binding in [
            <String, Object?>{},
            {'path': ''},
            {'path': 'relative'},
            {'path': 1},
            {'path': '/data', 'extra': true},
          ]) {
            expect(
              validate(example(entry.key, {field: binding})),
              A2uiIssueCode.malformedPayload,
              reason: '${entry.key}.$field',
            );
          }
        }
      }
    },
  );

  test('resolved dashboard values reject invalid shapes, ranges and enums', () {
    final invalid = <String, List<Map<String, Object?>>>{
      'Progress': [
        {'value': -0.1},
        {'value': 1.1},
        {'value': double.nan},
        {'value': double.infinity},
        {'tone': 'bad'},
        {'variant': 'circular'},
      ],
      'Badge': [
        {'label': 2},
        {'tone': 'bad'},
        {'size': 'huge'},
      ],
      'Avatar': [
        {'name': 1},
        {'url': 'http://example.com/a.png'},
        {'url': 'https://127.0.0.1/a.png'},
        {'size': 'huge'},
      ],
      'AvatarGroup': [
        {
          'avatars': [<String, Object?>{}],
        },
        {
          'avatars': [
            {'name': 2},
          ],
        },
        {
          'avatars': [
            {'name': 'Ada', 'url': 'https://localhost/a.png'},
          ],
        },
        {'maxVisible': 0},
        {'maxVisible': 21},
        {'maxVisible': 1.5},
      ],
      'Table': [
        {'columns': []},
        {
          'columns': [1],
        },
        {
          'rows': [
            ['short'],
          ],
        },
        {
          'rows': [
            ['too', 'many', 'cells'],
          ],
        },
        {
          'rows': [
            [<String, Object?>{}, 1],
          ],
        },
        {
          'rows': [
            [
              [1],
              1,
            ],
          ],
        },
        {
          'rows': [
            ['Ada', double.infinity],
          ],
        },
      ],
      'Chart': [
        {'labels': []},
        {'series': []},
        {
          'variant': 'pie',
          'series': [
            {
              'label': 'A',
              'values': [1, 2],
            },
            {
              'label': 'B',
              'values': [3, 4],
            },
          ],
        },
        {
          'series': [
            {
              'label': 'A',
              'values': [1],
            },
          ],
        },
        {
          'series': [
            {
              'label': 'A',
              'values': [1, 2, 3],
            },
          ],
        },
        {
          'series': [
            {
              'values': [1, 2],
            },
          ],
        },
        {
          'series': [
            {
              'label': 'A',
              'values': [1, '2'],
            },
          ],
        },
        {
          'series': [
            {
              'label': 'A',
              'values': [1, double.nan],
            },
          ],
        },
        {
          'series': [
            {
              'label': 'A',
              'values': [1, 2],
              'tone': 'bad',
            },
          ],
        },
      ],
      'EmptyState': [
        {'title': 1},
        {'icon': 'bad'},
      ],
      'LoadingIndicator': [
        {'label': 1},
      ],
      'AnimatedContent': [
        {'child': ''},
        {'child': 1},
      ],
    };
    for (final entry in invalid.entries) {
      for (final overrides in entry.value) {
        expect(
          validate(example(entry.key, overrides)),
          A2uiIssueCode.malformedPayload,
          reason: '${entry.key}: $overrides',
        );
      }
    }
    for (final value in [0, 1]) {
      expect(validate(example('Progress', {'value': value})), isNull);
    }
    for (final transition in ['fade', 'slide', 'scale']) {
      expect(
        validate(example('AnimatedContent', {'transition': transition})),
        isNull,
      );
    }
    for (final limit in [1, 20]) {
      expect(validate(example('AvatarGroup', {'maxVisible': limit})), isNull);
    }
    expect(
      validate(
        example('Table', {
          'columns': ['a', 'b', 'c', 'd'],
          'rows': [
            ['text', 1.5, false, null],
          ],
        }),
      ),
      isNull,
    );
    expect(validate(example('Table', {'rows': []})), isNull);
    expect(validate(example('AvatarGroup', {'avatars': []})), isNull);
    expect(
      validate(
        example('Chart', {
          'series': [
            {
              'label': 'A',
              'values': [-1, 2.5],
              'tone': 'success',
            },
          ],
        }),
      ),
      isNull,
    );
  });

  test('existing text and control labels accept bindings in both catalogs', () {
    for (final name in [
      'Text',
      'TextField',
      'DateTimeInput',
      'CheckBox',
      'ChoicePicker',
      'Slider',
    ]) {
      final field = name == 'Text' ? 'text' : 'label';
      for (final mode in ['passive', 'requiresUserAction']) {
        for (final binding in [
          {'path': '/label'},
        ]) {
          expect(
            A2uiChatContract.validateMessage({
              'version': a2uiChatWireVersion,
              'updateComponents': {
                'surfaceId': 'form',
                'components': [
                  example(name, {field: binding}),
                ],
              },
            }, interactionMode: mode),
            isNull,
            reason: '$name $mode',
          );
        }
        expect(
          A2uiChatContract.validateMessage({
            'version': a2uiChatWireVersion,
            'updateComponents': {
              'surfaceId': 'form',
              'components': [
                example(name, {
                  field: {'path': 'historical.label'},
                }),
              ],
            },
          }, interactionMode: mode),
          A2uiIssueCode.malformedPayload,
          reason: '$name $mode rejects new dotted binding',
        );
        expect(
          A2uiChatContract.validateMessage(
            {
              'version': a2uiChatWireVersion,
              'updateComponents': {
                'surfaceId': 'form',
                'components': [
                  example(name, {
                    field: {'path': 'historical.label'},
                  }),
                ],
              },
            },
            interactionMode: mode,
            allowLegacyBindings: true,
          ),
          isNull,
          reason: '$name $mode replays dotted binding',
        );
      }
      for (final invalid in [
        1,
        <String, Object?>{},
        {'path': ''},
      ]) {
        expect(
          validate(example(name, {field: invalid})),
          A2uiIssueCode.malformedPayload,
        );
      }
    }
  });

  test('date, time, and dateTime values use their documented wire formats', () {
    for (final time in ['09:30', '23:59']) {
      expect(
        validate(example('DateTimeInput', {'variant': 'time', 'value': time})),
        isNull,
      );
    }
    for (final invalid in [
      '09:30:00',
      '2026-09-05',
      '2026-09-05T09:30:00Z',
      '',
      'not-a-date',
    ]) {
      expect(
        validate(
          example('DateTimeInput', {'variant': 'time', 'value': invalid}),
        ),
        A2uiIssueCode.malformedPayload,
        reason: invalid,
      );
    }
    expect(
      validate(
        example('DateTimeInput', {
          'variant': 'time',
          'value': {'path': '/time'},
        }),
      ),
      isNull,
    );
    expect(
      validate(
        example('DateTimeInput', {'variant': 'date', 'value': '2026-09-05'}),
      ),
      isNull,
    );
    expect(
      validate(
        example('DateTimeInput', {
          'variant': 'dateTime',
          'value': '2026-09-05T09:30:00-05:00',
        }),
      ),
      isNull,
    );
    expect(A2uiChatContract.systemPrompt, contains('"HH:mm" for time'));
  });

  test('new payloads reject unsupported enum values', () {
    for (final name in ['Text', 'TextField', 'DateTimeInput', 'ChoicePicker']) {
      expect(
        validate(example(name, {'variant': 'legacy-variant'})),
        A2uiIssueCode.malformedPayload,
      );
    }
    expect(
      validate(example('Divider', {'axis': 'legacy-axis'})),
      A2uiIssueCode.malformedPayload,
    );
    expect(
      validate(example('Image', {'fit': 'legacy-fit'})),
      A2uiIssueCode.malformedPayload,
    );
    for (final name in ['Row', 'Column']) {
      expect(
        validate(
          example(name, {'align': 'legacy-align', 'justify': 'legacy-justify'}),
        ),
        A2uiIssueCode.malformedPayload,
      );
    }
    expect(
      validate(
        example('List', {
          'direction': 'legacy-direction',
          'align': 'legacy-align',
        }),
      ),
      A2uiIssueCode.malformedPayload,
    );
  });

  test('model data containing protocol-like keys is never a component', () {
    final message = {
      'version': a2uiChatWireVersion,
      'updateDataModel': {
        'surfaceId': 'business',
        'value': {
          'component': 'business-record',
          'action': 'approve',
          'updateComponents': {
            'components': [
              {
                'component': 'Unknown',
                'action': {'name': 'submit'},
              },
            ],
          },
        },
      },
    };
    final envelope = jsonDecode(A2uiChatContract.encodeEnvelope(message));
    expect(A2uiChatContract.validateMessage(message), isNull);
    expect(activeA2uiWireCodec.decode(envelope).issue, isNull);
    expect(A2uiChatContract.containsAgentAction(message), isFalse);
    expect(A2uiChatContract.containsAgentAction(envelope), isFalse);
    final component = example('Button', {
      'action': {'name': 'submit'},
    });
    expect(A2uiChatContract.containsAgentAction(component), isTrue);
    expect(
      A2uiChatContract.containsAgentAction({
        'message': {
          'updateComponents': {
            'components': [component],
          },
        },
      }),
      isTrue,
    );
    expect(
      validate({'id': 'root', 'component': 'Unknown'}),
      A2uiIssueCode.unsupportedComponent,
    );
    expect(validate({'id': 'root'}), A2uiIssueCode.malformedPayload);
  });

  test('animated child refs use existing graph validation', () {
    for (final child in ['content', 'missing', 'root']) {
      expect(
        A2uiChatContract.isRenderableComponentGraph({
          'root': example('AnimatedContent', {'id': 'root', 'child': child}),
          'content': {'id': 'content', 'component': 'Text', 'text': 'Ready'},
        }),
        child == 'content',
      );
    }
  });

  test('canonical buttons, historical icons and borderless remain valid', () {
    for (final variant in ['primary', 'outlined', 'text', 'borderless']) {
      expect(validate(example('Button', {'variant': variant})), isNull);
    }
    expect(
      validate(example('Button', {'variant': 'bad'})),
      A2uiIssueCode.malformedPayload,
    );
    expect(
      validate(example('Icon', {'name': 'historical-custom-icon'})),
      isNull,
    );
    expect(
      a2uiChatIconNames,
      containsAll(['speed', 'pending', 'merge', 'rocketLaunch', 'comment']),
    );
  });

  test('replays only known legacy image variants without advertising them', () {
    const legacyVariants = [
      'icon',
      'smallFeature',
      'mediumFeature',
      'largeFeature',
      'header',
    ];
    for (final variant in [...legacyVariants, 'unknownFeature']) {
      final payload = A2uiChatContract.encodeEnvelope({
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': 'historical-image',
          'components': [
            example('Image', {'id': 'root', 'variant': variant}),
          ],
        },
      });
      final replay = activeA2uiWireCodec.decode(jsonDecode(payload));
      final history = appendA2uiSurfacesToPrompt('', {
        'a2uiMessages': [payload],
      });
      if (variant == 'unknownFeature') {
        expect(replay.issue, A2uiIssueCode.malformedPayload);
        expect(history, isEmpty);
      } else {
        expect(replay.issue, isNull, reason: variant);
        expect(history, contains('"variant":"$variant"'));
      }
    }
    final properties = a2uiChatComponentSchemas['Image']!['properties']! as Map;
    expect((properties['variant'] as Map)['enum'], [
      'normal',
      'circle',
      'avatar',
    ]);
    final prompt = A2uiChatContract.systemPromptForComponents({'Image'});
    for (final variant in legacyVariants) {
      expect(prompt, isNot(contains('"$variant"')));
    }
    expect(
      validate(
        example('Image', {
          'variant': 'mediumFeature',
          'url': 'https://127.0.0.1/image.png',
        }),
      ),
      A2uiIssueCode.malformedPayload,
    );
  });

  test('choice presentation and image additions validate', () {
    for (final presentation in ['list', 'chips']) {
      expect(
        validate(example('ChoicePicker', {'presentation': presentation})),
        isNull,
      );
    }
    expect(
      validate(example('ChoicePicker', {'presentation': 'bad'})),
      A2uiIssueCode.malformedPayload,
    );
    for (final variant in ['normal', 'circle', 'avatar']) {
      expect(
        validate(
          example('Image', {
            'variant': variant,
            'width': 1,
            'height': 1024,
            'label': {'path': '/label'},
          }),
        ),
        isNull,
      );
    }
    for (final field in ['width', 'height']) {
      for (final value in [0, 1025, double.infinity, 'wide']) {
        expect(
          validate(example('Image', {field: value})),
          A2uiIssueCode.malformedPayload,
        );
      }
    }
  });
}
