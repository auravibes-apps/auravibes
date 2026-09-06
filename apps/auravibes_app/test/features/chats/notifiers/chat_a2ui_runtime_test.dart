// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/chat_a2ui_genui_adapter.dart';
import 'package:auravibes_app/features/chats/models/chat_a2ui_message_state.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  test('turns the trusted form submit into typed metadata', () async {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );
    final actions = <ChatUiAction>[];
    final subscription = runtime.actions.listen(actions.add);
    runtime.bindMessage('assistant-1');
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatFormCatalogId,
          },
        },
      }),
    );
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Text', 'text': 'Form'},
            ],
          },
        },
      }),
    );
    runtime.commitCurrentMessage();
    expect(runtime.requiresUserAction, isTrue);
    expect(
      runtime.isInteractiveSurface('assistant-1', 'assistant-1:main'),
      isTrue,
    );
    runtime.controller
        .contextFor('assistant-1:main')
        .dataModel
        .update(DataPath('/name'), 'Ada');
    runtime.submitForm(
      'assistant-1:main',
      messageText: 'Form answers submitted',
    );
    await Future<void>.delayed(Duration.zero);

    expect(actions, hasLength(1));
    expect(actions.single.conversationId, 'conversation-1');
    expect(actions.single.turnId, 'assistant-1');
    expect(actions.single.surfaceId, 'assistant-1:main');
    expect(actions.single.componentId, '__aura_form_submit__');
    expect(actions.single.actionName, 'submit');
    expect(actions.single.answers, {'name': 'Ada'});
    expect(runtime.messagesFor('assistant-1'), hasLength(3));
    expect(jsonDecode(runtime.messagesFor('assistant-1').last), {
      'protocolVersion': 'v1',
      'interactionMode': 'requiresUserAction',
      'message': {
        'version': 'v0.9',
        'updateDataModel': {
          'surfaceId': 'main',
          'path': '/',
          'value': {'name': 'Ada'},
        },
      },
    });
    final metadata = jsonDecode(actions.single.metadataJson) as Map;
    expect(metadata, containsPair('protocolVersion', 'v1'));
    expect(metadata, containsPair('conversationId', 'conversation-1'));
    expect(metadata, containsPair('turnId', 'assistant-1'));
    expect(metadata, containsPair('assistantMessageId', 'assistant-1'));
    expect(metadata, containsPair('surfaceId', 'assistant-1:main'));
    expect(metadata, containsPair('wireSurfaceId', 'main'));
    expect(metadata, containsPair('componentId', '__aura_form_submit__'));
    expect(metadata, containsPair('actionName', 'submit'));
    expect(metadata, containsPair('context', <String, Object?>{}));
    expect(metadata, containsPair('messageText', 'Form answers submitted'));
    expect(metadata, containsPair('answers', {'name': 'Ada'}));
    expect(metadata, containsPair('touchedPaths', <Object?>[]));
    expect(metadata, containsPair('unansweredPaths', <Object?>[]));
    expect(DateTime.tryParse(metadata['submittedAtUtc'] as String), isNotNull);
    expect(runtime.currentMessageId, isNull);
    expect(runtime.requiresUserAction, isFalse);

    await subscription.cancel();
    runtime.dispose();
  });

  test('scopes reused wire surface IDs to each assistant message', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );

    void createSurface(String messageId) {
      runtime.bindMessage(messageId);
      runtime.addMessageJson(
        jsonEncode({
          'protocolVersion': 'v1',
          'message': {
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'main',
              'catalogId': auraChatCatalogId,
            },
          },
        }),
      );
      runtime.commitCurrentMessage();
    }

    createSurface('assistant-1');
    createSurface('assistant-2');

    expect(runtime.surfaceIdsFor('assistant-1'), ['assistant-1:main']);
    expect(runtime.surfaceIdsFor('assistant-2'), ['assistant-2:main']);
    expect(runtime.controller.activeSurfaceIds, [
      'assistant-1:main',
      'assistant-2:main',
    ]);

    runtime.dispose();
  });

  test('does not block an incomplete required form', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatFormCatalogId,
          },
        },
      }),
    );
    runtime.commitCurrentMessage();

    expect(runtime.requiresUserAction, isFalse);
    expect(
      runtime.isInteractiveSurface('assistant-1', 'assistant-1:main'),
      isFalse,
    );
    expect(runtime.surfaceSlotsFor('assistant-1'), ['assistant-1:main']);
    expect(runtime.issuesForSurface('assistant-1:main'), [
      ChatA2uiSurfaceIssue.emptySurface,
    ]);
    runtime.beginGeneration();
    expect(runtime.currentMessageId, isNull);
    expect(runtime.requiresUserAction, isFalse);
    runtime.dispose();
  });

  test('rejects incomplete component updates without a root', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );
    runtime.bindMessage('assistant-1');
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'joke', 'component': 'Text', 'text': 'A joke'},
            ],
          },
        },
      }),
    );
    runtime.commitCurrentMessage();

    expect(runtime.isReadySurface('assistant-1', 'assistant-1:main'), isFalse);
    expect(runtime.hasSurfaceIssue('assistant-1'), isTrue);
    runtime.dispose();
  });

  test('commits each create block once for an inline turn', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );
    runtime.bindMessage('assistant-1');

    void add(Map<String, Object?> message) {
      runtime.addMessageJson(
        jsonEncode({'protocolVersion': 'v1', 'message': message}),
      );
    }

    add({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'catalog-surface',
        'catalogId': auraChatCatalogId,
      },
    });
    add({
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'catalog-surface',
        'components': [
          {'id': 'root', 'component': 'Text', 'text': 'catalog'},
        ],
      },
    });
    add({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'answer-surface',
        'catalogId': auraChatCatalogId,
      },
    });
    add({
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'answer-surface',
        'components': [
          {'id': 'root', 'component': 'Text', 'text': 'answer'},
        ],
      },
    });

    expect(runtime.surfaceIdsFor('assistant-1'), isEmpty);
    runtime.commitCurrentMessage();

    expect(runtime.surfaceIdsFor('assistant-1'), [
      'assistant-1:catalog-surface',
      'assistant-1:answer-surface',
    ]);
    expect(runtime.controller.activeSurfaceIds, [
      'assistant-1:catalog-surface',
      'assistant-1:answer-surface',
    ]);
    expect(runtime.messagesFor('assistant-1'), hasLength(4));
    runtime.dispose();
  });

  test('updates repeated wire IDs within one turn', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );
    runtime.bindMessage('assistant-1');

    for (final text in ['first', 'second']) {
      runtime.addMessageJson(
        jsonEncode({
          'protocolVersion': 'v1',
          'message': {
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'main',
              'catalogId': auraChatCatalogId,
            },
          },
        }),
      );
      runtime.addMessageJson(
        jsonEncode({
          'protocolVersion': 'v1',
          'message': {
            'version': 'v0.9',
            'updateComponents': {
              'surfaceId': 'main',
              'components': [
                {'id': 'root', 'component': 'Text', 'text': text},
              ],
            },
          },
        }),
      );
    }
    runtime.commitCurrentMessage();

    expect(runtime.surfaceIdsFor('assistant-1'), ['assistant-1:main']);
    expect(
      runtime.controller
          .contextFor('assistant-1:main')
          .definition
          .value
          ?.components['root']
          ?.properties['text'],
      'second',
    );
    runtime.dispose();
  });

  test('keeps interleaved surfaces in their original ownership', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');

    void add(String surfaceId, String text, {bool create = false}) {
      runtime.addMessageJson(
        jsonEncode({
          'protocolVersion': 'v1',
          'message': {
            'version': 'v0.9',
            if (create)
              'createSurface': {
                'surfaceId': surfaceId,
                'catalogId': auraChatCatalogId,
              }
            else
              'updateComponents': {
                'surfaceId': surfaceId,
                'components': [
                  {'id': 'root', 'component': 'Text', 'text': text},
                ],
              },
          },
        }),
      );
    }

    add('main', '', create: true);
    add('other', '', create: true);
    add('main', 'main-final');
    add('other', 'other-final');
    runtime.commitCurrentMessage();

    expect(runtime.surfaceIdsFor('assistant-1'), [
      'assistant-1:main',
      'assistant-1:other',
    ]);
    expect(
      runtime.controller
          .contextFor('assistant-1:main')
          .definition
          .value
          ?.components['root']
          ?.properties['text'],
      'main-final',
    );
    expect(
      runtime.controller
          .contextFor('assistant-1:other')
          .definition
          .value
          ?.components['root']
          ?.properties['text'],
      'other-final',
    );
    runtime.dispose();
  });

  test('closed turns ignore new protocol messages', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    runtime.closeMessage('assistant-1');
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatCatalogId,
          },
        },
      }),
    );

    expect(runtime.surfaceIdsFor('assistant-1'), isEmpty);
    runtime.dispose();
  });

  test('stores A2UI payloads separately for each assistant message', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );

    void createSurface(String messageId) {
      runtime.bindMessage(messageId);
      runtime.addMessageJson(
        jsonEncode({
          'protocolVersion': 'v1',
          'message': {
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'main',
              'catalogId': auraChatCatalogId,
            },
          },
        }),
      );
      runtime.commitCurrentMessage();
    }

    createSurface('assistant-1');
    createSurface('assistant-2');

    expect(runtime.messagesFor('assistant-1'), hasLength(1));
    expect(runtime.messagesFor('assistant-2'), hasLength(1));
    runtime.dispose();
  });

  test('preserves a valid surface when a later update is unsupported', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    addTearDown(runtime.dispose);

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatCatalogId,
          },
        },
      }),
    );
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Text', 'text': 'valid'},
            ],
          },
        },
      }),
    );
    runtime.commitCurrentMessage();

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Unknown'},
            ],
          },
        },
      }),
    );
    runtime.commitCurrentMessage();

    expect(runtime.hasSurfaceIssue('assistant-1'), isTrue);
    expect(
      runtime.controller
          .contextFor('assistant-1:main')
          .definition
          .value
          ?.components['root']
          ?.properties['text'],
      'valid',
    );
  });

  test('invalid required-action forms do not block the conversation', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    addTearDown(runtime.dispose);

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatFormCatalogId,
          },
        },
      }),
    );
    runtime.commitCurrentMessage();

    expect(runtime.hasSurfaceIssue('assistant-1'), isTrue);
    expect(runtime.requiresUserAction, isFalse);
    expect(
      runtime.isInteractiveSurface('assistant-1', 'assistant-1:main'),
      isFalse,
    );
  });

  test('invalidates a form surface without leaving the composer blocked', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    addTearDown(runtime.dispose);

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatFormCatalogId,
          },
        },
      }),
    );
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Text', 'text': 'valid'},
            ],
          },
        },
      }),
    );
    runtime.commitCurrentMessage();
    expect(runtime.requiresUserAction, isTrue);

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Unknown'},
            ],
          },
        },
      }),
    );

    expect(runtime.requiresUserAction, isFalse);
    expect(
      runtime.isInteractiveSurface('assistant-1', 'assistant-1:main'),
      isFalse,
    );
    expect(
      runtime.controller
          .contextFor('assistant-1:main')
          .definition
          .value
          ?.components['root']
          ?.properties['text'],
      'valid',
    );
  });

  test(
    'parser reports invalid A2UI candidates without returning text',
    () async {
      final events = await Stream<String>.fromIterable([
        '{"version":"v0.9","updateComponents":{"surfaceId":"main",'
            '"components":[{"id":"root","component":"Unknown"}]}}',
      ]).transform(const ChatA2uiParserTransformer()).toList();

      expect(events, hasLength(1));
      expect(events.single, isA<ChatA2uiInvalidEvent>());
      expect(
        (events.single as ChatA2uiInvalidEvent).issue,
        ChatA2uiSurfaceIssue.unsupportedComponent,
      );
      expect(
        (events.single as ChatA2uiInvalidEvent).diagnosticPayloadJson,
        contains('"component":"Unknown"'),
      );
      final event = events.single as ChatA2uiInvalidEvent;
      final runtime = ChatA2uiRuntime(
        conversationId: 'conversation-1',
        enabled: true,
      );
      addTearDown(runtime.dispose);
      runtime.recordIssue(
        event.issue,
        surfaceId: event.wireSurfaceId,
        diagnosticPayloadJson: event.diagnosticPayloadJson,
      );
      runtime.bindMessage('assistant-1');

      expect(
        runtime.diagnosticPayloadsFor('assistant-1').single,
        contains('"component":"Unknown"'),
      );
    },
  );

  test('parser retains malformed A2UI payloads for diagnostics', () async {
    const payload =
        '{"protocolVersion":"v1","interactionMode":"requiresUserAction",'
        '"message":{"version":"v0.9","createSurface":{'
        '"surfaceId":"form","catalogId":"urn:auravibes:a2ui:chat:form:v1"}}';
    final events = await Stream<String>.value(payload)
        .transform(const ChatA2uiParserTransformer())
        .toList();

    final event = events.single as ChatA2uiInvalidEvent;
    expect(event.issue, ChatA2uiSurfaceIssue.malformedPayload);
    expect(jsonDecode(event.diagnosticPayloadJson!), {'rawPayload': payload});

    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );
    addTearDown(runtime.dispose);
    runtime.recordIssue(
      event.issue,
      surfaceId: event.wireSurfaceId,
      diagnosticPayloadJson: event.diagnosticPayloadJson,
    );
    runtime.bindMessage('assistant-1');

    expect(jsonDecode(runtime.diagnosticPayloadsFor('assistant-1').single), {
      'rawPayload': payload,
    });
  });

  test('stores malformed direct payloads for diagnostics', () {
    const payload = '{"createSurface":{"surfaceId":"main"';
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    addTearDown(runtime.dispose);

    runtime.addMessageJson(payload);

    expect(jsonDecode(runtime.diagnosticPayloadsFor('assistant-1').single), {
      'rawPayload': payload,
    });
  });

  test('restores developer diagnostic payloads', () {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    );
    addTearDown(runtime.dispose);
    const payload = '{"rawPayload":"{"}';

    runtime.restoreMessage(
      'assistant-1',
      const [],
      a2uiMessageIssues: const ['malformedPayload'],
      diagnosticPayloads: const [payload],
    );

    expect(runtime.diagnosticPayloadsFor('assistant-1'), [payload]);
  });

  test('parser keeps ordinary message JSON as text', () async {
    final events = await Stream<String>.value(
      'before {"message":"hello"} after',
    ).transform(const ChatA2uiParserTransformer()).toList();

    expect(
      events.whereType<ChatA2uiTextEvent>().map((event) => event.text).join(),
      'before {"message":"hello"} after',
    );
    expect(events.whereType<ChatA2uiInvalidEvent>(), isEmpty);
  });
}
