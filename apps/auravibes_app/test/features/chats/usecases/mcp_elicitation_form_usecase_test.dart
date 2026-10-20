import 'package:auravibes_app/features/chats/usecases/mcp_elicitation_form_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void _expectInvalidForm(Object? Function() validate) {
  expect(
    validate,
    throwsA(
      isA<McpElicitationFormValidationException>().having(
        (error) => error.localizationKey,
        'localizationKey',
        LocaleKeys.mcp_elicitation_invalid,
      ),
    ),
  );
}

void main() {
  const usecase = McpElicitationFormUsecase();

  test('rejects required fields missing from the schema properties', () {
    final form = usecase.parse({
      'type': 'object',
      'properties': <String, Object?>{},
      'required': ['name'],
    });

    expect(form, isNull);
  });

  test('rejects oversized form and enum schemas', () {
    final manyProperties = <String, Object?>{
      for (var index = 0; index < 65; index++)
        'field$index': {'type': 'string'},
    };
    final manyOptions = List<String>.generate(65, (index) => 'option$index');
    final manyTitledOptions = List<Map<String, Object?>>.generate(
      65,
      (index) => {'const': 'option$index', 'title': 'Option $index'},
    );

    expect(
      usecase.parse({'type': 'object', 'properties': manyProperties}),
      isNull,
    );
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'enum': manyOptions},
        },
      }),
      isNull,
    );
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'oneOf': manyTitledOptions},
        },
      }),
      isNull,
    );
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string'},
        },
        'required': List<String>.filled(65, 'value'),
      }),
      isNull,
    );
  });

  test('rejects unsupported arrays and enum values with wrong field types', () {
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'roles': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['reader'],
            },
          },
        },
      }),
      isNull,
    );
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'enum': [7],
          },
        },
      }),
      isNull,
    );
  });

  test('rejects regex patterns with unsafe backtracking', () {
    for (final pattern in ['^(a*|b)*c', r'^\w*(b)?\w*(c)?\w*-\d$']) {
      expect(
        usecase.parse({
          'type': 'object',
          'properties': {
            'value': {'type': 'string', 'pattern': pattern},
          },
        }),
        isNull,
      );
    }
  });

  test('matches patterns with MCP Unicode regex semantics', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'value': {'type': 'string', 'pattern': r'^.$'},
          },
        }) ??
        (throw StateError('Expected supported form.'));

    final emoji = String.fromCharCode(0x1F600);
    expect(usecase.validate(form, {'value': emoji}), {'value': emoji});
  });

  test('validates patterned supplementary Unicode within input limit', () {
    final emoji = String.fromCharCode(0x1F600);
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'value': {'type': 'string', 'pattern': '^[$emoji]{129}\$'},
          },
        }) ??
        (throw StateError('Expected supported form.'));

    final value = String.fromCharCode(0x1F600) * 129;
    expect(usecase.validate(form, {'value': value}), {'value': value});
  });

  test('rejects regex patterns invalid in MCP Unicode mode', () {
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'pattern': r'^\q$'},
        },
      }),
      isNull,
    );
  });

  test('rejects a non-string pattern schema', () {
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'pattern': null},
        },
      }),
      isNull,
    );
  });

  test('rejects patterned values above bounded input length', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'value': {'type': 'string', 'pattern': r'^[a-z]+$'},
          },
        }) ??
        (throw StateError('Expected supported form.'));

    _expectInvalidForm(() => usecase.validate(form, {'value': 'a' * 257}));
  });

  test('rejects patterned schemas with minimum length above input limit', () {
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'pattern': r'^.+$', 'minLength': 257},
        },
      }),
      isNull,
    );
    expect(
      usecase.parse({
        'type': 'object',
        'properties': {
          'value': {'type': 'string', 'pattern': r'^[a-z]{256}b$'},
        },
      }),
      isNull,
    );
  });

  test('validates string length in Unicode code points', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'value': {'type': 'string', 'maxLength': 1},
          },
        }) ??
        (throw StateError('Expected supported form.'));

    final emoji = String.fromCharCode(0x1F600);
    expect(usecase.validate(form, {'value': emoji}), {'value': emoji});
  });

  test('normalizes titled oneOf choices to selectable enum values', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'theme': {
              'oneOf': [
                {'const': 'light', 'title': 'Light theme'},
                {'const': 'dark', 'title': 'Dark theme'},
              ],
            },
          },
          'required': ['theme'],
        }) ??
        (throw StateError('Expected supported form.'));

    expect(form.properties['theme'], containsPair('type', 'string'));
    expect(form.properties['theme'], containsPair('enum', ['light', 'dark']));
    expect(usecase.validate(form, {'theme': 'dark'}), {'theme': 'dark'});
    _expectInvalidForm(() => usecase.validate(form, {'theme': 'other'}));
  });

  test('rejects duplicate titled oneOf const values', () {
    for (final choices in <List<Map<String, Object?>>>[
      [
        {'const': 'light', 'title': 'Light theme'},
        {'const': 'light', 'title': 'Light option'},
      ],
      [
        {'const': 2, 'title': 'Two'},
        {'const': 2.0, 'title': 'Two point zero'},
      ],
    ]) {
      expect(
        usecase.parse({
          'type': 'object',
          'properties': {
            'theme': {'oneOf': choices},
          },
        }),
        isNull,
      );
    }
  });

  test('initializes required maxLength zero strings as empty', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'maxLength': 0, 'default': 'invalid'},
          },
          'required': ['name'],
        }) ??
        (throw StateError('Expected supported form.'));

    expect(form.initialValues(), {'name': ''});
    expect(usecase.validate(form, form.initialValues()), {'name': ''});
  });

  test('omits cleared optional numbers', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'count': {'type': 'integer'},
          },
        }) ??
        (throw StateError('Expected supported form.'));

    expect(usecase.validate(form, {'count': ''}), isEmpty);
  });

  test('omits cleared optional strings with validation constraints', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'minLength': 2, 'pattern': r'^[A-Z]+$'},
          },
        }) ??
        (throw StateError('Expected supported form.'));

    expect(usecase.validate(form, {'name': 'ADA'}), {'name': 'ADA'});
    expect(usecase.validate(form, {'name': ''}), isEmpty);
  });

  test('normalizes integral numeric enum values', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'count': {
              'type': 'integer',
              'enum': [2.0],
            },
          },
        }) ??
        (throw StateError('Expected supported form.'));

    expect(usecase.validate(form, {'count': 2.0}), {'count': 2});
  });

  test('rejects normalized invalid date-times', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'createdAt': {'type': 'string', 'format': 'date-time'},
          },
          'required': ['createdAt'],
        }) ??
        (throw StateError('Expected supported form.'));

    _expectInvalidForm(
      () => usecase.validate(form, {'createdAt': '2024-02-30T09:00:00Z'}),
    );
    expect(usecase.validate(form, {'createdAt': '2024-02-29T09:00:00Z'}), {
      'createdAt': '2024-02-29T09:00:00Z',
    });
    expect(usecase.validate(form, {'createdAt': '2024-02-29t09:00:00z'}), {
      'createdAt': '2024-02-29t09:00:00z',
    });
  });

  test('validates leap-second date-times against UTC insertion dates', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'createdAt': {'type': 'string', 'format': 'date-time'},
          },
          'required': ['createdAt'],
        }) ??
        (throw StateError('Expected supported form.'));

    expect(usecase.validate(form, {'createdAt': '2017-01-01T00:59:60+01:00'}), {
      'createdAt': '2017-01-01T00:59:60+01:00',
    });
    _expectInvalidForm(
      () => usecase.validate(form, {'createdAt': '2016-12-30T23:59:60Z'}),
    );
  });

  test('rejects malformed email domains', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'email': {'type': 'string', 'format': 'email'},
          },
          'required': ['email'],
        }) ??
        (throw StateError('Expected supported form.'));

    _expectInvalidForm(() => usecase.validate(form, {'email': 'a@b..com'}));
    expect(usecase.validate(form, {'email': 'a@example.com'}), {
      'email': 'a@example.com',
    });
    expect(usecase.validate(form, {'email': '"a b"@example.com'}), {
      'email': '"a b"@example.com',
    });
    expect(usecase.validate(form, {'email': 'a@[127.0.0.1]'}), {
      'email': 'a@[127.0.0.1]',
    });
  });

  test('rejects malformed RFC 3986 URI escapes', () {
    final form =
        usecase.parse({
          'type': 'object',
          'properties': {
            'website': {'type': 'string', 'format': 'uri'},
          },
          'required': ['website'],
        }) ??
        (throw StateError('Expected supported form.'));

    _expectInvalidForm(
      () => usecase.validate(form, {'website': 'https://example.com/%'}),
    );
  });
}
