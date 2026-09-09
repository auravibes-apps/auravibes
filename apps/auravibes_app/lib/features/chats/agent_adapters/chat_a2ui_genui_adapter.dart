// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:auravibes_app/features/chats/models/chat_a2ui_message_state.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as engine;
import 'package:flutter/foundation.dart';

ChatA2uiParseResult parseChatA2uiProtocolMessageResult(Object? value) =>
    parseChatA2uiProtocolMessageResults(value).first;

/// Adapts every normalized operation in a chat envelope.
///
/// The Aura `initialSurface` extension expands to create, data-model, and
/// component operations, so callers that persist or replay payloads must use
/// this plural boundary rather than dropping its latter operations.
Iterable<ChatA2uiParseResult> parseChatA2uiProtocolMessageResults(
  Object? value, {
  bool allowLegacyBindings = false,
}) sync* {
  for (final result in engine.activeA2uiWireCodec.decodeAll(
    value,
    allowLegacyBindings: allowLegacyBindings,
  )) {
    final envelope = result.envelope;
    if (envelope == null) {
      yield ChatA2uiParseResult.invalid(
        result.issue ?? ChatA2uiSurfaceIssue.malformedPayload,
        wireSurfaceId: result.wireSurfaceId,
      );
      continue;
    }
    try {
      yield ChatA2uiParseResult.valid(
        ChatA2uiProtocolMessage(
          envelope: envelope,
          message: core.A2uiMessage.fromJson(envelope.operation.json),
        ),
      );
    } on Object catch (_) {
      yield ChatA2uiParseResult.invalid(
        ChatA2uiSurfaceIssue.malformedPayload,
        wireSurfaceId: result.wireSurfaceId,
      );
    }
  }
}

core.A2uiMessage? scopeChatA2uiMessage(
  core.A2uiMessage message, {
  required String scopedSurfaceId,
}) {
  final surfaceId = chatA2uiSurfaceId(message);
  final bodyKey = switch (message) {
    core.CreateSurfaceMessage() => 'createSurface',
    core.UpdateComponentsMessage() => 'updateComponents',
    core.UpdateDataModelMessage() => 'updateDataModel',
    core.DeleteSurfaceMessage() => 'deleteSurface',
    _ => null,
  };
  if (surfaceId == null || bodyKey == null) return null;
  final json = Map<String, dynamic>.from(message.toJson());
  final body = json[bodyKey];
  if (body is! Map) return null;
  json[bodyKey] = Map<String, dynamic>.from(body)
    ..['surfaceId'] = scopedSurfaceId;
  try {
    return core.A2uiMessage.fromJson(json);
  } on Object catch (_) {
    return null;
  }
}

List<ChatA2uiProtocolMessage> scopeChatA2uiMessages(
  Iterable<ChatA2uiProtocolMessage> messages,
  String owner,
) {
  final scopedIds = <String, String>{};
  final deletedIds = <String>{};
  final result = <ChatA2uiProtocolMessage>[];
  for (final pending in messages) {
    final wireId = chatA2uiSurfaceId(pending.message);
    if (wireId == null) continue;
    final existingId = scopedIds[wireId];
    if (!_canScopeChatA2uiMessage(pending.message, existingId)) continue;
    final scopedId = existingId ?? '$owner:$wireId';
    scopedIds[wireId] = scopedId;
    if (deletedIds.contains(scopedId)) continue;
    final message = scopeChatA2uiMessage(
      pending.message,
      scopedSurfaceId: scopedId,
    );
    if (message == null) continue;
    result.add(
      ChatA2uiProtocolMessage(envelope: pending.envelope, message: message),
    );
    if (message is core.DeleteSurfaceMessage) {
      final _ = deletedIds.add(scopedId);
    }
  }

  return result;
}

bool _canScopeChatA2uiMessage(core.A2uiMessage message, String? existingId) {
  final isCreate = message is core.CreateSurfaceMessage;
  return isCreate ? existingId == null : existingId != null;
}

String? chatA2uiSurfaceId(core.A2uiMessage message) => switch (message) {
  core.CreateSurfaceMessage(:final surfaceId) => surfaceId,
  core.UpdateComponentsMessage(:final surfaceId) => surfaceId,
  core.UpdateDataModelMessage(:final surfaceId) => surfaceId,
  core.DeleteSurfaceMessage(:final surfaceId) => surfaceId,
  _ => null,
};

sealed class ChatA2uiGenerationEvent {
  const new();
}

final class ChatA2uiTextEvent extends ChatA2uiGenerationEvent {
  const new(this.text);
  final String text;
}

final class ChatA2uiMessageEvent extends ChatA2uiGenerationEvent {
  const new(this.message);
  final ChatA2uiProtocolMessage message;
}

final class ChatA2uiInvalidEvent extends ChatA2uiGenerationEvent {
  const new(this.issue, {this.wireSurfaceId, this.diagnosticPayloadJson});
  final ChatA2uiSurfaceIssue issue;
  final String? wireSurfaceId;
  final String? diagnosticPayloadJson;
}

class ChatA2uiParserTransformer
    extends StreamTransformerBase<String, ChatA2uiGenerationEvent> {
  const new();

  @override
  Stream<ChatA2uiGenerationEvent> bind(Stream<String> stream) async* {
    final decoder = engine.A2uiStreamDecoder();
    await for (final chunk in stream) {
      for (final event in _adapt(decoder.add(chunk))) {
        yield event;
      }
    }
    for (final event in _adapt(decoder.close())) {
      yield event;
    }
  }

  Iterable<ChatA2uiGenerationEvent> _adapt(
    Iterable<engine.A2uiStreamEvent> events,
  ) sync* {
    for (final event in events) {
      switch (event) {
        case engine.A2uiTextEvent(:final text):
          yield ChatA2uiTextEvent(text);
        case engine.A2uiEnvelopeEvent(:final envelope):
          final parsed = parseChatA2uiProtocolMessageResult(
            jsonDecode(envelope.payloadJson),
          );
          if (parsed.message != null) {
            yield ChatA2uiMessageEvent(parsed.message!);
          } else {
            yield ChatA2uiInvalidEvent(
              parsed.issue ?? ChatA2uiSurfaceIssue.malformedPayload,
              wireSurfaceId: parsed.wireSurfaceId,
              diagnosticPayloadJson: kReleaseMode ? null : envelope.payloadJson,
            );
          }
        case engine.A2uiInvalidEvent(
          :final issue,
          :final wireSurfaceId,
          :final diagnosticPayloadJson,
        ):
          yield ChatA2uiInvalidEvent(
            issue,
            wireSurfaceId: wireSurfaceId,
            diagnosticPayloadJson: kReleaseMode ? null : diagnosticPayloadJson,
          );
      }
    }
  }
}
