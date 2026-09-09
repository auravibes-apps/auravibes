import 'dart:convert';

import 'package:auravibes_engine/src/a2ui/a2ui_chat_contract.dart';
import 'package:auravibes_engine/src/a2ui/a2ui_validation.dart';
import 'package:auravibes_engine/src/a2ui/a2ui_wire_codec.dart';

sealed class A2uiStreamEvent {
  const new();
}

final class A2uiTextEvent extends A2uiStreamEvent {
  const new(this.text);

  final String text;
}

final class A2uiEnvelopeEvent extends A2uiStreamEvent {
  const new(this.envelope);

  final A2uiEnvelope envelope;
}

final class A2uiInvalidEvent extends A2uiStreamEvent {
  const new(this.issue, {this.wireSurfaceId, this.diagnosticPayloadJson});

  final A2uiIssueCode issue;
  final String? wireSurfaceId;
  final String? diagnosticPayloadJson;
}

// ignore: unused-code, public engine API consumed by app and server packages.
/// Separates text and A2UI envelopes from an incrementally streamed response.
class A2uiStreamDecoder {
  new({this.codec = activeA2uiWireCodec});

  final A2uiWireCodec codec;
  String _buffer = '';

  List<A2uiStreamEvent> add(String chunk) {
    _buffer += chunk;
    if (utf8.encode(_buffer).length > maxA2uiChatPayloadBytes &&
        _looksLikeCandidate(_buffer)) {
      final event = A2uiInvalidEvent(
        .oversizedPayload,
        wireSurfaceId: _recoverSurfaceId(_buffer),
      );
      _buffer = '';
      return [event];
    }
    return _drain(complete: false);
  }

  List<A2uiStreamEvent> close() => _drain(complete: true);

  List<A2uiStreamEvent> _drain({required bool complete}) {
    final events = <A2uiStreamEvent>[];
    while (_buffer.isNotEmpty) {
      final open = _buffer.indexOf('```');
      if (open > 0) {
        events.add(A2uiTextEvent(_buffer.substring(0, open)));
        _buffer = _buffer.substring(open);
        continue;
      }
      if (open == 0) {
        final close = _buffer.indexOf('```', open + 3);
        if (close < 0) break;
        final candidate = _buffer
            .substring(open + 3, close)
            .replaceFirst(RegExp(r'^\s*json\s*'), '');
        _emitCandidate(
          candidate,
          events,
          fallbackText: _buffer.substring(0, close + 3),
        );
        _buffer = _buffer.substring(close + 3);
        continue;
      }

      final start = _buffer.indexOf('{');
      if (start < 0) {
        events.add(A2uiTextEvent(_buffer));
        _buffer = '';
        break;
      }
      if (start > 0) {
        events.add(A2uiTextEvent(_buffer.substring(0, start)));
        _buffer = _buffer.substring(start);
        continue;
      }
      final end = _balancedEnd(_buffer);
      if (end == null) break;
      final candidate = _buffer.substring(0, end);
      _emitCandidate(candidate, events, fallbackText: candidate);
      _buffer = _buffer.substring(end);
    }

    _flushRemainingBuffer(events, complete: complete);
    return events;
  }

  void _flushRemainingBuffer(
    List<A2uiStreamEvent> events, {
    required bool complete,
  }) {
    if (!complete || _buffer.isEmpty) return;

    if (_looksLikeCandidate(_buffer)) {
      events.add(
        A2uiInvalidEvent(
          .malformedPayload,
          wireSurfaceId: _recoverSurfaceId(_buffer),
          diagnosticPayloadJson: _diagnosticPayload(_buffer),
        ),
      );
    } else {
      events.add(A2uiTextEvent(_buffer));
    }
    _buffer = '';
  }

  void _emitCandidate(
    String candidate,
    List<A2uiStreamEvent> events, {
    required String fallbackText,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(candidate);
    } on Object catch (_) {
      if (_looksLikeCandidate(candidate)) {
        events.add(
          A2uiInvalidEvent(
            .malformedPayload,
            wireSurfaceId: _recoverSurfaceId(candidate),
            diagnosticPayloadJson: _diagnosticPayload(candidate),
          ),
        );
      } else {
        events.add(A2uiTextEvent(fallbackText));
      }
      return;
    }
    final results = codec.decodeAll(decoded).toList(growable: false);
    final envelopes = results
        .map((result) => result.envelope)
        .whereType<A2uiEnvelope>()
        .toList(growable: false);
    if (envelopes.isNotEmpty) {
      events.addAll(envelopes.map(A2uiEnvelopeEvent.new));
    } else if (codec.looksLikeCandidate(decoded) ||
        _looksLikeCandidate(candidate)) {
      final result = results.first;
      events.add(
        A2uiInvalidEvent(
          result.issue ?? A2uiIssueCode.malformedPayload,
          wireSurfaceId: result.wireSurfaceId,
          diagnosticPayloadJson: result.diagnosticPayloadJson,
        ),
      );
    } else {
      events.add(A2uiTextEvent(fallbackText));
    }
  }

  bool _looksLikeCandidate(String value) {
    final trimmed = value.trimLeft();
    return (trimmed.startsWith('```') || trimmed.startsWith('{')) &&
        RegExp(
          r'"(?:createSurface|updateComponents|updateDataModel|deleteSurface|initialSurface)"\s*:',
        ).hasMatch(trimmed);
  }

  String? _recoverSurfaceId(String value) =>
      RegExp(r'"surfaceId"\s*:\s*"([^"\\]{1,200})"')
          .firstMatch(value)
          ?.group(1);

  String _diagnosticPayload(String value) {
    try {
      return jsonEncode(jsonDecode(value));
    } on Object catch (_) {
      return jsonEncode({'rawPayload': value});
    }
  }

  int? _balancedEnd(String value) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = 0; index < value.length; index++) {
      final char = value[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
      } else if (char == '"') {
        inString = true;
      } else if (char == '{') {
        depth++;
      } else if (char == '}' && --depth == 0) {
        return index + 1;
      }
    }
    return null;
  }
}
