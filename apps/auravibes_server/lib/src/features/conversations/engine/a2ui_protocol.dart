import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart' as shared;

const a2uiChatCatalogId = shared.a2uiChatCatalogId;
const a2uiChatFormCatalogId = shared.a2uiChatFormCatalogId;
const maxA2uiMessageBytes = shared.maxA2uiChatPayloadBytes;
const maxA2uiNestingDepth = shared.maxA2uiChatNestingDepth;
const supportedA2uiComponents = shared.supportedA2uiChatComponents;

String get a2uiChatCatalogPrompt =>
    shared.A2uiChatContract.systemPromptForComponents(
      shared.baselineA2uiChatComponents,
    );

Set<String> cloudA2uiSupportedComponents(
  String? payloadJson, {
  required bool isChildConversation,
}) {
  if (isChildConversation) return const {};
  if (payloadJson == null) return shared.baselineA2uiChatComponents;
  try {
    final payload = jsonDecode(payloadJson);
    final components = payload is Map
        ? payload['a2uiSupportedComponents']
        : null;
    return cloudA2uiComponentsForClient(
      components,
      isChildConversation: isChildConversation,
    );
  } on FormatException {
    return shared.baselineA2uiChatComponents;
  }
}

Set<String> cloudA2uiComponentsForClient(
  Object? components, {
  required bool isChildConversation,
}) {
  if (isChildConversation) return const {};
  if (components is! List || components.any((value) => value is! String)) {
    return shared.baselineA2uiChatComponents;
  }
  return shared.supportedA2uiChatComponents.intersection(
    components.cast<String>().toSet(),
  );
}

bool isCloudA2uiPayloadSupported(String source, Set<String> components) {
  try {
    return isA2uiPayloadSupported(jsonDecode(source), components);
  } on FormatException {
    return false;
  }
}

String? cloudA2uiMetadataForClient(String? source, Set<String> components) {
  if (source == null) return null;
  final Object? metadata;
  try {
    metadata = jsonDecode(source);
  } on FormatException {
    return source;
  }
  if (metadata is! Map<String, dynamic>) return source;
  if (components.isEmpty) {
    metadata.removeWhere((key, _) => key.startsWith('a2ui'));
    final modelMetadata = metadata['modelMetadata'];
    if (modelMetadata is Map<String, dynamic>) {
      modelMetadata.removeWhere((key, _) => key.startsWith('a2ui'));
    }
    return jsonEncode(metadata);
  }
  final messages = metadata['a2uiMessages'];
  if (messages is! List) return source;
  final history = <({String? source, String? surfaceId, bool supported})>[];
  final unsupportedSurfaces = <String>{};
  final requiredActionFormSurfaces = <String>{};
  var unscopedIssue = false;
  for (final message in messages) {
    Object? payload;
    if (message is String) {
      try {
        payload = jsonDecode(message);
      } on FormatException {
        // No recoverable surface; retain a message-level warning instead.
      }
    }
    final surfaceId = payload is Map
        ? shared.activeA2uiWireCodec.recoverSurfaceId(payload)
        : null;
    if (_isRequiredActionForm(payload) && surfaceId != null) {
      requiredActionFormSurfaces.add(surfaceId);
    }
    final supported = isA2uiPayloadSupported(
      payload,
      components,
      allowLegacyBindings: true,
    );
    history.add((
      source: message is String ? message : null,
      surfaceId: surfaceId,
      supported: supported,
    ));
    if (supported) continue;
    if (surfaceId == null) {
      unscopedIssue = true;
    } else {
      unsupportedSurfaces.add(surfaceId);
    }
  }
  if (unsupportedSurfaces.isEmpty && !unscopedIssue) return source;
  final retained = [
    for (final entry in history)
      if (entry.supported && !unsupportedSurfaces.contains(entry.surfaceId))
        entry.source!,
  ];
  if (retained.isEmpty) {
    metadata.remove('a2uiMessages');
  } else {
    metadata['a2uiMessages'] = retained;
  }
  if (unsupportedSurfaces.isNotEmpty) {
    final existing = metadata['a2uiIssuesBySurface'];
    final issues = existing is Map<String, dynamic>
        ? existing
        : <String, dynamic>{};
    for (final surfaceId in unsupportedSurfaces) {
      final previous = issues[surfaceId];
      issues[surfaceId] = {
        if (previous is List) ...previous.whereType<String>(),
        shared.A2uiIssueCode.unsupportedComponent.name,
      }.toList();
    }
    metadata['a2uiIssuesBySurface'] = issues;
  }
  if (unscopedIssue) {
    final previous = metadata['a2uiMessageIssues'];
    metadata['a2uiMessageIssues'] = {
      if (previous is List) ...previous.whereType<String>(),
      shared.A2uiIssueCode.unsupportedComponent.name,
    }.toList();
  }
  if (unsupportedSurfaces.any(requiredActionFormSurfaces.contains)) {
    metadata.remove('a2uiRequiresUserAction');
  }
  return jsonEncode(metadata);
}

bool _isRequiredActionForm(Object? payload) {
  if (payload is! Map || payload['interactionMode'] != 'requiresUserAction') {
    return false;
  }
  final message = payload['message'];
  if (message is! Map) return false;
  final createSurface = message['createSurface'];
  return createSurface is Map &&
      createSurface['catalogId'] == a2uiChatFormCatalogId;
}

bool isA2uiPayloadSupported(
  Object? payload,
  Set<String> components, {
  bool allowLegacyBindings = false,
}) {
  if (components.isEmpty) return false;
  final results = shared.activeA2uiWireCodec
      .decodeAll(payload, allowLegacyBindings: allowLegacyBindings)
      .toList();
  if (results.isEmpty || results.any((result) => result.envelope == null)) {
    return false;
  }
  return results.every((result) {
    final operation = result.envelope!.operation;
    if (operation.kind != shared.A2uiOperationKind.updateComponents) {
      return true;
    }
    return operation.components.every(
      (component) => components.contains(component['component']),
    );
  });
}

class A2uiProtocolMessage {
  const A2uiProtocolMessage({
    required this.envelope,
  });

  final shared.A2uiEnvelope envelope;

  String get payloadJson => envelope.payloadJson;
  String get interactionMode => envelope.interactionMode;
  shared.A2uiOperation get operation => envelope.operation;
}

class A2uiProtocolParseResult {
  const A2uiProtocolParseResult.valid(this.message)
    : issue = null,
      wireSurfaceId = null,
      diagnosticPayloadJson = null;

  const A2uiProtocolParseResult.invalid(
    this.issue, {
    this.wireSurfaceId,
    this.diagnosticPayloadJson,
  }) : message = null;

  final A2uiProtocolMessage? message;
  final shared.A2uiIssueCode? issue;
  final String? wireSurfaceId;
  final String? diagnosticPayloadJson;
}

A2uiProtocolMessage? parseA2uiProtocolMessage(Object? value) {
  return parseA2uiProtocolMessageResult(value).message;
}

A2uiProtocolParseResult parseA2uiProtocolMessageResult(Object? value) {
  return parseA2uiProtocolMessageResults(value).first;
}

/// Normalizes every operation in an envelope, including `initialSurface`.
///
/// The server only emits and persists canonical A2UI v0.9 operations.
Iterable<A2uiProtocolParseResult> parseA2uiProtocolMessageResults(
  Object? value,
) sync* {
  for (final result in shared.activeA2uiWireCodec.decodeAll(value)) {
    final envelope = result.envelope;
    if (envelope == null) {
      yield A2uiProtocolParseResult.invalid(
        result.issue,
        wireSurfaceId: result.wireSurfaceId,
        diagnosticPayloadJson: result.diagnosticPayloadJson,
      );
      continue;
    }
    yield A2uiProtocolParseResult.valid(
      A2uiProtocolMessage(envelope: envelope),
    );
  }
}

bool looksLikeA2ui(Object? value) {
  return shared.activeA2uiWireCodec.looksLikeCandidate(value);
}

bool isValidA2uiActionPayload(
  String source, {
  required String conversationId,
}) {
  if (utf8.encode(source).length > 64 * 1024) return false;
  try {
    return shared.A2uiChatContract.isValidAction(
      jsonDecode(source),
      conversationId: conversationId,
    );
  } on Object catch (_) {
    return false;
  }
}

class A2uiTextDecoder {
  final shared.A2uiStreamDecoder _decoder = shared.A2uiStreamDecoder();

  void add(
    String chunk, {
    required void Function(String text) onText,
    required void Function(A2uiProtocolMessage message) onMessage,
    void Function(A2uiProtocolParseResult result)? onInvalid,
  }) {
    _dispatch(
      _decoder.add(chunk),
      onText: onText,
      onMessage: onMessage,
      onInvalid: onInvalid,
    );
  }

  void close({
    required void Function(String text) onText,
    void Function(A2uiProtocolParseResult result)? onInvalid,
  }) {
    _dispatch(
      _decoder.close(),
      onText: onText,
      onMessage: (_) {},
      onInvalid: onInvalid,
    );
  }

  void _dispatch(
    Iterable<shared.A2uiStreamEvent> events, {
    required void Function(String text) onText,
    required void Function(A2uiProtocolMessage message) onMessage,
    void Function(A2uiProtocolParseResult result)? onInvalid,
  }) {
    for (final event in events) {
      switch (event) {
        case shared.A2uiTextEvent(:final text):
          onText(text);
        case shared.A2uiEnvelopeEvent(:final envelope):
          onMessage(A2uiProtocolMessage(envelope: envelope));
        case shared.A2uiInvalidEvent(
          :final issue,
          :final wireSurfaceId,
          :final diagnosticPayloadJson,
        ):
          onInvalid?.call(
            A2uiProtocolParseResult.invalid(
              issue,
              wireSurfaceId: wireSurfaceId,
              diagnosticPayloadJson: diagnosticPayloadJson,
            ),
          );
      }
    }
  }
}
