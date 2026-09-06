import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart' as shared;
import 'package:auravibes_server/src/features/conversations/conversation_stream_service.dart';
import 'package:auravibes_server/src/features/conversations/engine/a2ui_protocol.dart';
import 'package:auravibes_server/src/features/conversations/repositories/conversation_repository.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('capability checks inspect only protocol component declarations', () {
    final data = {
      'component': 'business-record',
      'nested': {
        'updateComponents': {
          'components': [
            {'component': 'Badge'},
          ],
        },
      },
    };
    final update = {
      'version': 'v0.9',
      'updateDataModel': {'surfaceId': 'main', 'value': data},
    };
    for (final payload in [
      update,
      {'message': update},
    ]) {
      expect(
        isA2uiPayloadSupported(payload, shared.baselineA2uiChatComponents),
        isTrue,
      );
      final history = jsonEncode({
        'a2uiMessages': [jsonEncode(payload)],
      });
      expect(
        cloudA2uiMetadataForClient(history, shared.baselineA2uiChatComponents),
        history,
      );
    }
    final components = {
      'updateComponents': {
        'surfaceId': 'main',
        'components': [
          {'id': 'root', 'component': 'Text', 'text': data},
        ],
      },
    };
    // Capability negotiation includes the shared strict component validation.
    expect(
      isA2uiPayloadSupported(components, shared.baselineA2uiChatComponents),
      isFalse,
    );
    (components['updateComponents']! as Map)['components'] = [
      {'id': 'root', 'component': 'Badge', 'label': 'Ready'},
    ];
    expect(
      isA2uiPayloadSupported(components, shared.baselineA2uiChatComponents),
      isFalse,
    );
    expect(
      isA2uiPayloadSupported({
        'message': components,
      }, shared.baselineA2uiChatComponents),
      isFalse,
    );
  });

  test(
    'history removes only unsupported wire surfaces and retains warnings',
    () {
      String operation(
        String kind,
        String id, [
        Map<String, Object?> body = const {},
      ]) => shared.A2uiChatContract.encodeEnvelope({
        'version': 'v0.9',
        kind: {'surfaceId': id, ...body},
      });
      final sibling = [
        operation('createSurface', 'text', {'catalogId': a2uiChatCatalogId}),
        operation('updateComponents', 'text', {
          'components': [
            {'id': 'root', 'component': 'Text', 'text': 'Kept'},
          ],
        }),
      ];
      final blocked = [
        operation('createSurface', 'dashboard', {
          'catalogId': a2uiChatCatalogId,
        }),
        operation('updateDataModel', 'dashboard', {
          'value': {'count': 1},
        }),
        operation('updateComponents', 'dashboard', {
          'components': [
            {'id': 'root', 'component': 'Badge', 'label': 'Ready'},
          ],
        }),
        operation('deleteSurface', 'dashboard'),
      ];
      final metadata = jsonEncode({
        'a2uiMessages': [
          blocked[0],
          sibling[0],
          blocked[1],
          blocked[2],
          sibling[1],
          blocked[3],
        ],
        'a2uiIssuesBySurface': {
          'text': ['malformedPayload'],
          'dashboard': ['invalidInteractionMode', 'unsupportedComponent'],
        },
        'a2uiMessageIssues': ['oversizedPayload'],
        'other': 'preserved',
      });
      final filtered = cloudA2uiMetadataForClient(
        metadata,
        shared.baselineA2uiChatComponents,
      )!;
      expect(jsonDecode(filtered), {
        'a2uiMessages': sibling,
        'a2uiIssuesBySurface': {
          'text': ['malformedPayload'],
          'dashboard': ['invalidInteractionMode', 'unsupportedComponent'],
        },
        'a2uiMessageIssues': ['oversizedPayload'],
        'other': 'preserved',
      });
      expect(
        cloudA2uiMetadataForClient(filtered, shared.baselineA2uiChatComponents),
        filtered,
      );
      expect(
        cloudA2uiMetadataForClient(
          metadata,
          shared.supportedA2uiChatComponents,
        ),
        metadata,
      );
    },
  );

  test('removes required action when its form is filtered', () {
    final create = shared.A2uiChatContract.encodeEnvelope(
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'form',
          'catalogId': a2uiChatFormCatalogId,
        },
      },
      interactionMode: 'requiresUserAction',
    );
    final update = shared.A2uiChatContract.encodeEnvelope(
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'form',
          'components': [
            {'id': 'root', 'component': 'Form', 'child': 'content'},
            {'id': 'content', 'component': 'Text', 'text': 'Continue'},
          ],
        },
      },
      interactionMode: 'requiresUserAction',
    );
    final filtered = jsonDecode(
      cloudA2uiMetadataForClient(
        jsonEncode({
          'a2uiRequiresUserAction': true,
          'a2uiMessages': [create, update],
        }),
        shared.baselineA2uiChatComponents,
      )!,
    ) as Map<String, dynamic>;

    expect(filtered, {
      'a2uiIssuesBySurface': {
        'form': [shared.A2uiIssueCode.unsupportedComponent.name],
      },
    });
  });

  test('child filtering strips A2UI even without history', () {
    for (final messages in [
      null,
      <String>[],
      ['diagnostic payload'],
    ]) {
      final metadata = jsonEncode({
        'a2uiMessages': ?messages,
        'a2uiIssuesBySurface': {
          'main': ['unsupportedComponent'],
        },
        'a2uiMessageIssues': ['malformedPayload'],
        'a2uiRequiresUserAction': true,
        'a2uiDiagnosticPayloads': ['diagnostic payload'],
        'modelMetadata': {
          'a2uiAction': {'surfaceId': 'main'},
          'keep': 1,
        },
        'other': 'preserved',
      });
      expect(jsonDecode(cloudA2uiMetadataForClient(metadata, const {})!), {
        'modelMetadata': {'keep': 1},
        'other': 'preserved',
      });
    }
  });

  test('snapshot history and stream replay respect receiver capabilities', () {
    final payload = shared.A2uiChatContract.encodeEnvelope({
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'main',
        'components': [
          {'id': 'root', 'component': 'Badge', 'label': 'Ready'},
        ],
      },
    });
    final metadata = jsonEncode({
      'a2uiMessages': [payload],
      'unrelated': {'keep': true},
    });
    final event = ConversationStreamEvent(
      workspaceId: 1,
      conversationId: 'conversation',
      sequence: 4,
      actorUserId: 'user',
      kind: ConversationEventType.a2uiMessage,
      payloadJson: payload,
      createdAt: DateTime.utc(2026),
    );
    for (final components in [shared.baselineA2uiChatComponents, <String>{}]) {
      expect(jsonDecode(cloudA2uiMetadataForClient(metadata, components)!), {
        if (components.isNotEmpty)
          'a2uiIssuesBySurface': {
            'main': ['unsupportedComponent'],
          },
        'unrelated': {'keep': true},
      });
      expect(ConversationStreamService.canDeliver(event, components), isFalse);
      expect(
        ConversationStreamService.canDeliver(
          event.copyWith(
            kind: ConversationEventType.executionCompleted,
            payloadJson: '{}',
          ),
          components,
        ),
        isTrue,
      );
    }
    expect(
      cloudA2uiMetadataForClient(metadata, shared.supportedA2uiChatComponents),
      metadata,
    );
    expect(
      ConversationStreamService.canDeliver(
        event,
        shared.supportedA2uiChatComponents,
      ),
      isTrue,
    );
  });

  test('old and malformed job capabilities retain baseline prompt', () {
    for (final payload in <String?>[
      null,
      conversationTurnJobPayload('user'),
      '{',
      '{"a2uiSupportedComponents":"Badge"}',
      '{"a2uiSupportedComponents":[1]}',
    ]) {
      final components = cloudA2uiSupportedComponents(
        payload,
        isChildConversation: false,
      );
      expect(components, shared.baselineA2uiChatComponents);
      expect(
        shared.A2uiChatContract.systemPromptForComponents(components),
        a2uiChatCatalogPrompt,
      );
    }
    for (final component in shared.supportedA2uiChatComponents.difference(
      shared.baselineA2uiChatComponents,
    )) {
      expect(a2uiChatCatalogPrompt, isNot(contains('"$component"')));
    }
  });

  test('job capabilities intersect supported names and survive JSON', () {
    final payload = conversationTurnJobPayload(
      'user',
      executionId: 'execution',
      a2uiSupportedComponents: ['Text', 'Badge', 'FutureComponent'],
    );
    final components = cloudA2uiSupportedComponents(
      payload,
      isChildConversation: false,
    );
    expect(components, {'Text', 'Badge'});
    final prompt = shared.A2uiChatContract.systemPromptForComponents(
      components,
    );
    expect(prompt, contains('"Badge"'));
    expect(prompt, isNot(contains('"Chart"')));
    expect(prompt, contains(a2uiChatCatalogId));
    expect(prompt, contains(a2uiChatFormCatalogId));
    expect(
      cloudA2uiSupportedComponents(payload, isChildConversation: true),
      isEmpty,
    );
    expect(
      cloudA2uiSupportedComponents(null, isChildConversation: true),
      isEmpty,
    );
  });

  test('empty and unknown-only client lists do not enable components', () {
    for (final names in <List<String>>[
      [],
      ['FutureComponent'],
    ]) {
      expect(
        cloudA2uiSupportedComponents(
          conversationTurnJobPayload('user', a2uiSupportedComponents: names),
          isChildConversation: false,
        ),
        isEmpty,
      );
    }
  });

  test('accepts the chat catalog and wraps the message', () {
    final parsed = parseA2uiProtocolMessage({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': a2uiChatCatalogId,
      },
    });

    expect(parsed, isNotNull);
    expect(jsonDecode(parsed!.payloadJson), {
      'protocolVersion': 'v1',
      'interactionMode': 'passive',
      'message': {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': a2uiChatCatalogId,
          'sendDataModel': false,
        },
      },
    });
  });

  test('normalizes an initial surface before cloud persistence', () {
    final results = parseA2uiProtocolMessageResults({
      'protocolVersion': shared.a2uiChatProtocolVersion,
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

    expect(results.map((result) => result.message?.operation.kind), [
      shared.A2uiOperationKind.createSurface,
      shared.A2uiOperationKind.updateDataModel,
      shared.A2uiOperationKind.updateComponents,
    ]);
    expect(
      results
          .map((result) => result.message!.payloadJson)
          .every((payload) => !payload.contains('initialSurface')),
      isTrue,
    );
  });

  test('rejects unsupported catalog and component', () {
    expect(
      parseA2uiProtocolMessage({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': 'other',
        },
      }),
      isNull,
    );
    expect(
      parseA2uiProtocolMessage({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {'id': 'root', 'component': 'Unknown'},
          ],
        },
      }),
      isNull,
    );
  });

  test('decodes chunked A2UI without leaking protocol text', () {
    final decoder = A2uiTextDecoder();
    final text = <String>[];
    final messages = <A2uiProtocolMessage>[];
    const source =
        '''hello {"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$a2uiChatCatalogId"}} bye''';

    decoder.add(
      source.substring(0, 40),
      onText: text.add,
      onMessage: messages.add,
    );
    decoder.add(
      source.substring(40),
      onText: text.add,
      onMessage: messages.add,
    );
    decoder.close(onText: text.add);

    expect(messages, hasLength(1));
    expect(text.join(), 'hello  bye');
  });

  test('drops malformed A2UI candidates at stream close', () {
    final decoder = A2uiTextDecoder();
    final text = <String>[];

    decoder.add(
      '{"version":"v0.9","createSurface":',
      onText: text.add,
      onMessage: (_) {},
    );
    decoder.close(onText: text.add);

    expect(text, isEmpty);
  });

  test('keeps ordinary message JSON as text', () {
    final decoder = A2uiTextDecoder();
    final text = <String>[];

    decoder.add(
      'before {"message":"hello"} after',
      onText: text.add,
      onMessage: (_) {},
    );
    decoder.close(onText: text.add);

    expect(text.join(), 'before {"message":"hello"} after');
  });

  test('validates typed action payloads', () {
    final valid = jsonEncode({
      'protocolVersion': 'v1',
      'conversationId': 'conversation-1',
      'turnId': 'message-1',
      'surfaceId': 'main',
      'componentId': 'submit',
      'actionName': 'submit',
      'context': {'value': 'yes'},
      'messageText': 'Submit selection',
      'answers': {'choice': 'yes'},
    });

    expect(
      isValidA2uiActionPayload(valid, conversationId: 'conversation-1'),
      isTrue,
    );
    expect(
      isValidA2uiActionPayload(valid, conversationId: 'conversation-2'),
      isFalse,
    );
  });

  test('identifies model-defined component actions', () {
    expect(
      parseA2uiProtocolMessage({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Button',
              'child': 'Continue',
              'action': {
                'event': {'name': 'continue'},
              },
            },
          ],
        },
      }),
      isNotNull,
    );
    expect(
      shared.A2uiChatContract.containsAgentAction({
        'component': 'Button',
        'action': const {},
      }),
      isTrue,
    );
  });
}
