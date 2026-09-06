import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('advertises canonical icons in the shared prompt', () {
    final properties = a2uiChatComponentSchemas['Icon']!['properties']! as Map;
    expect((properties['name'] as Map)['enum'], a2uiChatIconNames);
    expect(a2uiChatIconNames.toSet(), hasLength(a2uiChatIconNames.length));
    for (final name in a2uiChatIconNames) {
      expect(A2uiChatContract.systemPrompt, contains('"$name"'));
    }
  });

  test('v0.9 codec returns canonical operations', () {
    final result = activeA2uiWireCodec.decode({
      'protocolVersion': 'v1',
      'interactionMode': 'passive',
      'message': {
        'version': 'v0.9',
        'createSurface': {'surfaceId': 'main', 'catalogId': a2uiChatCatalogId},
      },
    });

    expect(result.issue, isNull);
    expect(result.envelope?.wireVersion, 'v0.9');
    expect(result.envelope?.operation.kind, A2uiOperationKind.createSurface);
    expect(result.envelope?.operation.surfaceId, 'main');
    expect(result.envelope?.operation.catalogId, a2uiChatCatalogId);
  });

  test('normalizes an initial surface envelope before persistence', () {
    final results = activeA2uiWireCodec.decodeAll({
      'protocolVersion': a2uiChatProtocolVersion,
      'interactionMode': 'passive',
      'initialSurface': {
        'surfaceId': 'main',
        'catalogId': a2uiChatCatalogId,
        'dataModel': {'title': 'Hello'},
        'components': [
          {
            'id': 'root',
            'component': 'Text',
            'text': {'path': '/title'},
          },
        ],
      },
    }).toList();

    expect(results.map((result) => result.issue), everyElement(isNull));
    expect(results.map((result) => result.envelope!.operation.kind), [
      A2uiOperationKind.createSurface,
      A2uiOperationKind.updateDataModel,
      A2uiOperationKind.updateComponents,
    ]);
    expect(
      results
          .map((result) => jsonDecode(result.envelope!.payloadJson) as Map)
          .every((payload) => !payload.containsKey('initialSurface')),
      isTrue,
    );
  });

  test('validates required fields and tracks untouched optional values', () {
    final result = A2uiChatContract.validateFormValues(
      components: [
        {
          'id': 'name',
          'component': 'TextField',
          'value': {'path': '/name'},
          'required': true,
          'minLength': 2,
        },
        {
          'id': 'note',
          'component': 'TextField',
          'value': {'path': '/note'},
        },
        {
          'id': 'accepted',
          'component': 'CheckBox',
          'label': 'Accept',
          'value': {'path': '/accepted'},
          'required': true,
        },
      ],
      values: {'name': 'A', 'note': '', 'accepted': false},
    );

    expect(result.errorsByPath, {'/name': 'length', '/accepted': 'required'});
    expect(result.unansweredPaths, ['/note']);
  });

  test('normalizes sliders before validating form answers', () {
    const components = [
      {
        'id': 'amount',
        'component': 'Slider',
        'value': {'path': '/amount'},
        'min': 0,
        'max': 100,
        'step': 5,
        'precision': 0,
      },
    ];
    final normalized = A2uiChatContract.normalizeFormValues(
      components: components,
      values: {'amount': 26.768964602623456},
    );

    expect(normalized, {'amount': 25.0});
    expect(
      A2uiChatContract.validateFormValues(
        components: components,
        values: normalized,
      ).isValid,
      isTrue,
    );
  });

  test('rejects invalid calendar and clock values', () {
    expect(
      A2uiChatContract.isValidDateTimeValue('date', '2026-02-29'),
      isFalse,
    );
    expect(A2uiChatContract.isValidDateTimeValue('date', '2028-02-29'), isTrue);
    expect(A2uiChatContract.isValidDateTimeValue('time', '24:00'), isFalse);
    expect(A2uiChatContract.isValidDateTimeValue('time', '23:59'), isTrue);
    expect(
      A2uiChatContract.isValidDateTimeValue('dateTime', '2026-09-05T10:00:00'),
      isFalse,
    );
    expect(
      A2uiChatContract.isValidDateTimeValue('dateTime', '2026-09-05T10:00:00Z'),
      isTrue,
    );
  });

  test('rejects operations without a non-empty surface ID', () {
    for (final operation in const [
      'createSurface',
      'updateComponents',
      'updateDataModel',
      'deleteSurface',
    ]) {
      final body = <String, Object?>{};
      if (operation == 'createSurface') body['catalogId'] = a2uiChatCatalogId;
      final result = activeA2uiWireCodec.decode({
        'protocolVersion': a2uiChatProtocolVersion,
        'interactionMode': 'passive',
        'message': {'version': a2uiChatWireVersion, operation: body},
      });

      expect(result.issue, A2uiIssueCode.malformedPayload, reason: operation);
    }
  });

  test('publishes schemas and examples for every chat component', () {
    expect(
      a2uiChatComponentSchemas.keys,
      containsAll(supportedA2uiChatComponents),
    );
    expect(
      a2uiChatComponentSchemas,
      hasLength(supportedA2uiChatComponents.length),
    );
    expect(
      a2uiChatComponentExamples.keys,
      containsAll(supportedA2uiChatComponents),
    );
    expect(
      a2uiChatComponentExamples,
      hasLength(supportedA2uiChatComponents.length),
    );
    for (final schema in a2uiChatComponentSchemas.values) {
      expect(schema['type'], 'object');
      expect(schema['properties'], isA<Map<String, Object?>>());
      expect(schema['required'], isA<List<Object?>>());
    }
    expect(A2uiChatContract.systemPrompt, contains('CATALOG_SCHEMA_START'));
    expect(A2uiChatContract.systemPrompt, contains('CATALOG_EXAMPLES_START'));
    expect(
      A2uiChatContract.systemPrompt,
      contains('Never stop after createSurface'),
    );
    expect(
      A2uiChatContract.systemPrompt,
      contains('COMPLETE_SURFACE_EXAMPLE_START'),
    );
  });

  test('validates the catalog envelope and component names', () {
    final valid = {
      'version': a2uiChatWireVersion,
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': a2uiChatCatalogId,
        'sendDataModel': false,
      },
    };

    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(A2uiChatContract.encodeEnvelope(valid)),
      ),
      isTrue,
    );
    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(
          A2uiChatContract.encodeEnvelope({
            'version': a2uiChatWireVersion,
            'createSurface': {
              'surfaceId': 'legacy',
              'catalogId': a2uiChatCatalogId,
              'sendDataModel': true,
            },
          }),
        ),
        allowLegacyBindings: true,
      ),
      isTrue,
    );
    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(
          A2uiChatContract.encodeEnvelope({
            'version': a2uiChatWireVersion,
            'updateComponents': {
              'surfaceId': 'main',
              'components': [
                {'id': 'root', 'component': 'Unknown'},
              ],
            },
          }),
        ),
      ),
      isFalse,
    );
    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(
          A2uiChatContract.encodeEnvelope({
            'version': a2uiChatWireVersion,
            'updateComponents': {
              'surfaceId': 'main',
              'components': [
                {'id': 'root', 'component': 'Text'},
              ],
            },
          }),
        ),
      ),
      isFalse,
    );
  });

  test('enforces catalog and interaction mode pairing', () {
    final form = {
      'version': a2uiChatWireVersion,
      'createSurface': {
        'surfaceId': 'form',
        'catalogId': a2uiChatFormCatalogId,
      },
    };

    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(
          A2uiChatContract.encodeEnvelope(
            form,
            interactionMode: 'requiresUserAction',
          ),
        ),
      ),
      isTrue,
    );
    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(A2uiChatContract.encodeEnvelope(form)),
      ),
      isFalse,
    );
    expect(
      A2uiChatContract.isCatalogAllowedForMode(a2uiChatCatalogId, 'passive'),
      isTrue,
    );
    expect(
      A2uiChatContract.isValidEnvelope(
        jsonDecode(
          A2uiChatContract.encodeEnvelope({
            'version': a2uiChatWireVersion,
            'updateComponents': {
              'surfaceId': 'response',
              'components': [
                {'id': 'root', 'component': 'Button', 'child': 'label'},
              ],
            },
          }),
        ),
      ),
      isTrue,
    );
  });

  test('does not treat data-model fields named action as agent actions', () {
    expect(
      A2uiChatContract.containsAgentAction({
        'updateDataModel': {
          'surfaceId': 'form',
          'value': {'action': 'email'},
        },
      }),
      isFalse,
    );
    expect(
      A2uiChatContract.containsAgentAction({
        'components': [
          {
            'id': 'submit',
            'component': 'Button',
            'action': {'name': 'submit'},
          },
        ],
      }),
      isTrue,
    );
  });

  test('validates component references and cycles', () {
    expect(
      A2uiChatContract.isRenderableComponentGraph({
        'root': {
          'id': 'root',
          'component': 'Column',
          'children': ['label'],
        },
        'label': {'id': 'label', 'component': 'Text', 'text': 'Ready'},
      }),
      isTrue,
    );
    expect(
      A2uiChatContract.isRenderableComponentGraph({
        'root': {
          'id': 'root',
          'component': 'Column',
          'children': ['missing'],
        },
      }),
      isFalse,
    );
    expect(
      A2uiChatContract.isRenderableComponentGraph({
        'root': {
          'id': 'root',
          'component': 'Column',
          'children': ['root'],
        },
      }),
      isFalse,
    );
  });

  test('rejects deeply nested input without recursive traversal', () {
    Object? nested = 'value';
    for (var index = 0; index < 10000; index++) {
      nested = <String, Object?>{'child': nested};
    }

    expect(
      A2uiChatContract.isValidAction(nested, conversationId: 'conversation'),
      isFalse,
    );
  });

  test('projects only validated A2UI into provider history', () {
    final valid = A2uiChatContract.encodeEnvelope({
      'version': a2uiChatWireVersion,
      'createSurface': {'surfaceId': 'main', 'catalogId': a2uiChatCatalogId},
    });

    final result = appendA2uiSurfacesToPrompt('', {
      'a2uiMessages': [valid, '{bad json'],
    });

    expect(result, startsWith('The assistant presented this interface:'));
    expect(result, contains('"createSurface"'));
    expect(result, isNot(contains('{bad json')));
  });

  test('validates slider step and decimal-place precision', () {
    Object? envelope({Object? step = 1, Object? precision = 2}) => jsonDecode(
      A2uiChatContract.encodeEnvelope({
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Slider',
              'value': {'path': '/amount'},
              'min': 0,
              'max': 100,
              'step': step,
              'precision': precision,
            },
          ],
        },
      }),
    );

    expect(A2uiChatContract.isValidEnvelope(envelope()), isTrue);
    expect(A2uiChatContract.isValidEnvelope(envelope(step: 0)), isFalse);
    expect(A2uiChatContract.isValidEnvelope(envelope(precision: 0)), isTrue);
    expect(A2uiChatContract.isValidEnvelope(envelope(precision: -1)), isFalse);
    expect(A2uiChatContract.isValidEnvelope(envelope(precision: 21)), isFalse);
    expect(
      A2uiChatContract.isValidEnvelope(envelope(precision: 0.01)),
      isFalse,
    );
  });

  test('allows passive literals but requires form bindings', () {
    Object? envelope(String mode, Object value) => jsonDecode(
      A2uiChatContract.encodeEnvelope({
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Slider',
              'value': value,
              'min': 0,
              'max': 100,
              'precision': 0,
            },
          ],
        },
      }, interactionMode: mode),
    );

    expect(A2uiChatContract.isValidEnvelope(envelope('passive', 74)), isTrue);
    expect(
      A2uiChatContract.isValidEnvelope(envelope('requiresUserAction', 74)),
      isFalse,
    );
    expect(
      A2uiChatContract.isValidEnvelope(
        envelope('requiresUserAction', {'path': '/amount'}),
      ),
      isTrue,
    );
  });

  test('accepts literal values for every passive control', () {
    final envelope = jsonDecode(
      A2uiChatContract.encodeEnvelope({
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['check', 'choice', 'date', 'slider', 'tabs', 'text'],
            },
            {
              'id': 'check',
              'component': 'CheckBox',
              'label': 'Done',
              'value': true,
            },
            {
              'id': 'choice',
              'component': 'ChoicePicker',
              'options': [
                {'label': 'Email', 'value': 'email'},
              ],
              'value': ['email'],
            },
            {
              'id': 'date',
              'component': 'DateTimeInput',
              'value': '2026-09-15T09:00:00Z',
            },
            {
              'id': 'slider',
              'component': 'Slider',
              'value': 74,
              'min': 0,
              'max': 100,
              'precision': 0,
            },
            {
              'id': 'tabs',
              'component': 'Tabs',
              'tabs': [
                {'label': 'One', 'content': 'text'},
              ],
              'activeTab': 0,
            },
            {'id': 'text', 'component': 'TextField', 'value': 'Read only'},
          ],
        },
      }),
    );

    expect(A2uiChatContract.isValidEnvelope(envelope), isTrue);
  });

  test('defaults passive tabs but requires a form binding', () {
    Object? envelope(String mode) => jsonDecode(
      A2uiChatContract.encodeEnvelope({
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Tabs',
              'tabs': [
                {'label': 'Overview', 'content': 'content'},
              ],
            },
            {'id': 'content', 'component': 'Text', 'text': 'Overview'},
          ],
        },
      }, interactionMode: mode),
    );

    expect(A2uiChatContract.isValidEnvelope(envelope('passive')), isTrue);
    expect(
      A2uiChatContract.isValidEnvelope(envelope('requiresUserAction')),
      isFalse,
    );
  });

  test('encodes and validates typed human actions', () {
    const action = A2uiChatAction(
      protocolVersion: a2uiChatProtocolVersion,
      conversationId: 'conversation-1',
      turnId: 'assistant-1',
      surfaceId: 'assistant-1:main',
      wireSurfaceId: 'main',
      componentId: 'submit',
      actionName: 'submit',
      context: {'value': 'yes'},
      messageText: 'Submit this form.',
      answers: {'name': 'Ada', 'age': 37},
    );

    final decoded = A2uiChatContract.decodeAction(
      jsonDecode(action.metadataJson),
      conversationId: 'conversation-1',
    );
    expect(decoded?.surfaceId, action.surfaceId);
    expect(decoded?.wireSurfaceId, action.wireSurfaceId);
    expect(decoded?.context, action.context);
    expect(decoded?.answers, action.answers);
    expect(
      A2uiChatContract.appendAnswersToPrompt('Submit', decoded),
      contains('{"name":"Ada","age":37}'),
    );
  });

  test('rejects bindings for catalog fields whose renderers require text', () {
    expect(
      A2uiChatContract.validateMessage({
        'version': a2uiChatWireVersion,
        'updateComponents': {
          'surfaceId': 'surface',
          'components': [
            {
              'id': 'root',
              'component': 'Form',
              'child': 'content',
              'submitLabel': {'path': '/submitLabel'},
            },
            {'id': 'content', 'component': 'Text', 'text': 'Form content'},
          ],
        },
      }),
      A2uiIssueCode.malformedPayload,
    );
  });
}
