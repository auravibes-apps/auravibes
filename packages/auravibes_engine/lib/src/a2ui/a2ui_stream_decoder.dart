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
  final _buffer = StringBuffer();
  _A2uiStreamMode _mode = .text;
  int _bytes = 0;
  int _ticks = 0;
  int _depth = 0;
  bool _inString = false;
  bool _escaped = false;
  bool _highSurrogate = false;
  bool _ordinary = false;

  List<A2uiStreamEvent> add(String chunk) {
    final events = <A2uiStreamEvent>[];
    final text = StringBuffer();
    for (final unit in chunk.codeUnits) {
      _read(unit, events, text);
      // A pending high surrogate can save two bytes when its pair completes.
      if (_bytes > maxA2uiChatPayloadBytes + (_highSurrogate ? 2 : 0)) {
        _releaseOversized(events, text);
      }
    }
    _flushText(events, text);
    return events;
  }

  List<A2uiStreamEvent> close() {
    final events = <A2uiStreamEvent>[];
    final text = StringBuffer();
    if (_mode == .text) {
      text.write('`' * _ticks);
    } else if (!_ordinary) {
      final value = _buffer.toString();
      if (_bytes > maxA2uiChatPayloadBytes && _looksLikeCandidate(value)) {
        events.add(
          A2uiInvalidEvent(
            .oversizedPayload,
            wireSurfaceId: _recoverSurfaceId(value),
          ),
        );
      } else if (_looksLikeCandidate(value)) {
        events.add(
          A2uiInvalidEvent(
            .malformedPayload,
            wireSurfaceId: _recoverSurfaceId(value),
            diagnosticPayloadJson: _diagnosticPayload(value),
          ),
        );
      } else {
        text.write(value);
      }
    }
    _reset();
    _flushText(events, text);
    return events;
  }

  void _read(int unit, List<A2uiStreamEvent> events, StringBuffer text) {
    if (_mode == .text) {
      _readText(unit, text);
      return;
    }
    if (_ordinary) {
      text.writeCharCode(unit);
    } else {
      _append(unit);
    }
    if (_mode == .fence) {
      _ticks = unit == 0x60 ? _ticks + 1 : 0;
      if (_ticks == 3) _finish(events, text);
      return;
    }
    _ticks = unit == 0x60 && !_inString ? _ticks + 1 : 0;
    if (_ticks == 3 && !_ordinary) {
      final value = _buffer.toString();
      text.write(value.substring(0, value.length - 3));
      _reset();
      _mode = .fence;
      _buffer.write('```');
      _bytes = 3;
      return;
    }
    _scanObject(unit);
    if (_depth == 0) _finish(events, text);
  }

  void _readText(int unit, StringBuffer text) {
    if (unit == 0x60) {
      _ticks++;
      if (_ticks == 3) {
        _mode = .fence;
        _buffer.write('```');
        _bytes = 3;
        _ticks = 0;
      }
      return;
    }
    text.write('`' * _ticks);
    _ticks = 0;
    if (unit == 0x7b) {
      _mode = .object;
      _depth = 1;
      _append(unit);
    } else {
      text.writeCharCode(unit);
    }
  }

  void _append(int unit) {
    _buffer.writeCharCode(unit);
    _bytes += switch (unit) {
      <= 0x7f => 1,
      <= 0x7ff => 2,
      >= 0xdc00 && <= 0xdfff when _highSurrogate => 1,
      _ => 3,
    };
    _highSurrogate = unit >= 0xd800 && unit <= 0xdbff;
  }

  void _scanObject(int unit) {
    if (_inString) {
      if (_escaped) {
        _escaped = false;
      } else if (unit == 0x5c) {
        _escaped = true;
      } else if (unit == 0x22) {
        _inString = false;
      }
      return;
    }
    if (unit == 0x22) {
      _inString = true;
    } else if (unit == 0x7b) {
      _depth++;
    } else if (unit == 0x7d) {
      _depth--;
    }
  }

  void _finish(List<A2uiStreamEvent> events, StringBuffer text) {
    if (!_ordinary) {
      final value = _buffer.toString();
      final candidate = _mode == .fence
          ? value
                .substring(3, value.length - 3)
                .replaceFirst(RegExp(r'^\s*json\s*'), '')
          : value;
      _flushText(events, text);
      if (_bytes > maxA2uiChatPayloadBytes && _looksLikeCandidate(value)) {
        events.add(
          A2uiInvalidEvent(
            .oversizedPayload,
            wireSurfaceId: _recoverSurfaceId(value),
          ),
        );
      } else {
        _emitCandidate(candidate, events, fallbackText: value);
      }
    }
    _reset();
  }

  void _releaseOversized(List<A2uiStreamEvent> events, StringBuffer text) {
    final value = _buffer.toString();
    if (_looksLikeCandidate(value)) {
      _flushText(events, text);
      events.add(
        A2uiInvalidEvent(
          .oversizedPayload,
          wireSurfaceId: _recoverSurfaceId(value),
        ),
      );
      _reset();
      return;
    }
    // Classification stops at the payload limit. Later markers stay literal.
    text.write(value);
    _buffer.clear();
    _bytes = 0;
    _ordinary = true;
  }

  void _reset() {
    _buffer.clear();
    _mode = .text;
    _bytes = 0;
    _ticks = 0;
    _depth = 0;
    _inString = false;
    _escaped = false;
    _highSurrogate = false;
    _ordinary = false;
  }

  void _flushText(List<A2uiStreamEvent> events, StringBuffer text) {
    if (text.isEmpty) return;
    events.add(A2uiTextEvent(text.toString()));
    text.clear();
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
}

enum _A2uiStreamMode { text, fence, object }
