import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart' as shared;
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:test/test.dart';

void main() {
  for (final component in shared.supportedA2uiChatComponents.difference(
    shared.baselineA2uiChatComponents,
  )) {
    for (final capable in [false, true]) {
      test(
        '$component publishes only for capable clients ($capable)',
        () async {
          final publisher = _RecordingConversationA2uiPublisher();
          final response = ConversationResponseAccumulator(
            publisher: publisher,
            a2uiSupportedComponents: capable
                ? shared.supportedA2uiChatComponents
                : shared.baselineA2uiChatComponents,
          );
          final form = component == 'Form';
          final interactionMode = form ? 'requiresUserAction' : 'passive';
          final catalogId = form
              ? shared.a2uiChatFormCatalogId
              : shared.a2uiChatCatalogId;
          final create = shared.A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'main',
              'catalogId': catalogId,
            },
          }, interactionMode: interactionMode);
          final update = shared.A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'updateComponents': {
              'surfaceId': 'main',
              'components': [shared.a2uiChatComponentExamples[component]],
            },
          }, interactionMode: interactionMode);
          response.addA2uiMessage(create);
          response.addA2uiMessage(update);
          await response.close();

          expect(response.a2uiMessages.contains(update), capable);
          expect(publisher.events.contains('a2ui:$update'), capable);
          if (!capable) {
            expect(response.a2uiIssuesBySurface['main'], [
              'unsupportedComponent',
            ]);
          }
        },
      );
    }
  }

  test('unsupported diagnostics cannot bypass capability gating', () async {
    final publisher = _RecordingConversationA2uiPublisher();
    final response = ConversationResponseAccumulator(publisher: publisher);
    final payload = jsonEncode({
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'main',
        'components': [
          {'id': 'root', 'component': 'Badge'},
        ],
      },
    });
    response.addA2uiMessage(payload);
    response.addA2uiIssue(
      shared.A2uiIssueCode.malformedPayload,
      wireSurfaceId: 'main',
      diagnosticPayloadJson: payload,
    );
    await response.close();

    expect(response.a2uiMessages, isEmpty);
    expect(publisher.events, isEmpty);
    expect(response.requiresUserAction, isFalse);
  });

  test('child policy suppresses all A2UI including diagnostics', () async {
    final publisher = _RecordingConversationA2uiPublisher();
    final response = ConversationResponseAccumulator(
      publisher: publisher,
      a2uiSupportedComponents: const {},
    );
    final payload = shared.A2uiChatContract.encodeEnvelope({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': shared.a2uiChatFormCatalogId,
      },
    }, interactionMode: 'requiresUserAction');
    response.addA2uiMessage(payload);
    response.addA2uiIssue(
      shared.A2uiIssueCode.malformedPayload,
      diagnosticPayloadJson: payload,
    );
    response.addText('Child result');
    await response.close();

    expect(response.a2uiMessages, isEmpty);
    expect(response.a2uiMessageIssues, isEmpty);
    expect(response.requiresUserAction, isFalse);
    expect(publisher.events, ['text:Child result']);
  });

  test('retains text in memory and publishes each chunk in order', () async {
    final publisher = _RecordingConversationProgressPublisher();
    final response = ConversationResponseAccumulator(publisher: publisher);

    response.addText('Hello');
    response.addText(' world');
    await response.close();

    expect(response.content, 'Hello world');
    expect(publisher.events, ['Hello', ' world']);
  });

  test('does not publish empty provider chunks', () async {
    final publisher = _RecordingConversationProgressPublisher();
    final response = ConversationResponseAccumulator(publisher: publisher);

    response.addText('');
    await response.close();

    expect(response.content, isEmpty);
    expect(publisher.events, isEmpty);
  });

  test('keeps A2UI events separate and publishes them in order', () async {
    final publisher = _RecordingConversationA2uiPublisher();
    final response = ConversationResponseAccumulator(publisher: publisher);
    const payload =
        '{"protocolVersion":"v1","interactionMode":"passive",'
        '"message":{"version":"v0.9","createSurface":{'
        '"surfaceId":"main","catalogId":"urn:auravibes:a2ui:chat:v1",'
        '"sendDataModel":true}}}';
    const canonicalPayload =
        '{"protocolVersion":"v1","interactionMode":"passive",'
        '"message":{"version":"v0.9","createSurface":{'
        '"surfaceId":"main","catalogId":"urn:auravibes:a2ui:chat:v1",'
        '"sendDataModel":false}}}';
    const update =
        '{"protocolVersion":"v1","interactionMode":"passive",'
        '"message":{"version":"v0.9","updateComponents":{'
        '"surfaceId":"main","components":[{"id":"root",'
        '"component":"Text","text":"Shown"}]}}}';

    response.addText('Before ');
    response.addA2uiMessage(payload);
    response.addA2uiMessage(update);
    response.addText('after');
    await response.close();

    expect(response.content, 'Before after');
    expect(response.a2uiMessages, hasLength(2));
    expect(response.requiresUserAction, isFalse);
    expect(publisher.events, [
      'text:Before ',
      'a2ui:$canonicalPayload',
      'a2ui:$update',
      'text:after',
    ]);
  });

  test('blocks a valid required-action form without a model action', () {
    final response = ConversationResponseAccumulator(
      publisher: _RecordingConversationProgressPublisher(),
    );

    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"requiresUserAction",'
      '"message":{"version":"v0.9","createSurface":{"surfaceId":"main",'
      '"catalogId":"urn:auravibes:a2ui:chat:form:v1"}}}',
    );
    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"requiresUserAction",'
      '"message":{"version":"v0.9","updateComponents":{'
      '"surfaceId":"main","components":[{"id":"root",'
      '"component":"Text","text":"Form"}]}}}',
    );

    expect(response.requiresUserAction, isTrue);
  });

  test('does not block for an invalid form component graph', () {
    final response = ConversationResponseAccumulator(
      publisher: _RecordingConversationProgressPublisher(),
    );

    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"requiresUserAction",'
      '"message":{"version":"v0.9","createSurface":{"surfaceId":"main",'
      '"catalogId":"urn:auravibes:a2ui:chat:form:v1"}}}',
    );
    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"requiresUserAction",'
      '"message":{"version":"v0.9","updateComponents":{'
      '"surfaceId":"main","components":[{"id":"root",'
      '"component":"Column","children":["missing"]}]}}}',
    );

    expect(response.requiresUserAction, isFalse);
  });

  test('rejects a surface update whose interaction mode changed', () {
    final response = ConversationResponseAccumulator(
      publisher: _RecordingConversationProgressPublisher(),
    );

    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"requiresUserAction",'
      '"message":{"version":"v0.9","createSurface":{"surfaceId":"main",'
      '"catalogId":"urn:auravibes:a2ui:chat:form:v1"}}}',
    );
    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"passive",'
      '"message":{"version":"v0.9","updateComponents":{'
      '"surfaceId":"main","components":[{"id":"root",'
      '"component":"Text","text":"Form"}]}}}',
    );

    expect(response.requiresUserAction, isFalse);
    expect(response.a2uiIssuesBySurface['main'], ['invalidInteractionMode']);
  });

  test('drops model-defined component actions', () {
    final response = ConversationResponseAccumulator(
      publisher: _RecordingConversationProgressPublisher(),
    );

    response.addA2uiMessage(
      '{"protocolVersion":"v1","interactionMode":"passive",'
      '"message":{"version":"v0.9","updateComponents":{'
      '"surfaceId":"main","components":[{"id":"root",'
      '"component":"Button","child":"Continue",'
      '"action":{"event":{"name":"continue"}}}]}}}',
    );

    expect(response.a2uiMessages, isEmpty);
    expect(response.requiresUserAction, isFalse);
  });

  test(
    'retains rejected UI only as a development diagnostic',
    () async {
      final publisher = _RecordingConversationA2uiPublisher();
      final response = ConversationResponseAccumulator(publisher: publisher);
      const payload =
          '{"protocolVersion":"v1","interactionMode":"passive",'
          '"message":{"version":"v0.9","createSurface":{'
          '"surfaceId":"main",'
          '"catalogId":"urn:auravibes:a2ui:chat:form:v1"}}}';

      response.addA2uiMessage(payload);
      await response.close();

      expect(response.a2uiMessages, isEmpty);
      expect(response.a2uiIssuesBySurface['main'], ['invalidInteractionMode']);
      expect(response.a2uiDiagnosticPayloads.single, contains('"catalogId"'));
      expect(publisher.events, isEmpty);
    },
  );

  test('wraps malformed A2UI in a development diagnostic', () {
    final response = ConversationResponseAccumulator(
      publisher: _RecordingConversationA2uiPublisher(),
    );

    response.addA2uiMessage('{');

    expect(
      jsonDecode(response.a2uiDiagnosticPayloads.single),
      {'rawPayload': '{'},
    );
  });
}

class _RecordingConversationProgressPublisher
    implements ConversationProgressPublisher {
  final events = <String>[];

  @override
  Future<void> queued() async {}

  @override
  Future<void> running() async {}

  @override
  Future<void> text(String text) async {
    events.add(text);
  }

  @override
  Future<void> flush() async {}
}

class _RecordingConversationA2uiPublisher
    implements
        ConversationProgressPublisher,
        ConversationA2uiProgressPublisher {
  final events = <String>[];

  @override
  bool get includeA2uiDiagnostics => true;

  @override
  Future<void> queued() async {}

  @override
  Future<void> running() async {}

  @override
  Future<void> text(String text) async => events.add('text:$text');

  @override
  Future<void> a2uiMessage(String payloadJson) async =>
      events.add('a2ui:$payloadJson');

  @override
  Future<void> flush() async {}
}
