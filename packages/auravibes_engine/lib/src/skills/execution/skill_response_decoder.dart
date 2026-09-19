import 'dart:convert';

import 'package:auravibes_engine/src/skills/models/url_response.dart';

/// Converts standard server-sent event responses into tool-readable text.
///
/// Non-SSE responses pass through unchanged. The decoder understands common
/// delta shapes used by OpenAI Responses, Chat Completions, and Anthropic-like
/// event streams, while preserving unknown event streams for callers that
/// need the raw protocol.
class const SkillResponseDecoder() {
  UrlResponse call(UrlResponse response) {
    if (!_isEventStream(response)) return response;

    final body = _SseTextAccumulator.decode(response.body);
    if (body == null) return response;

    return UrlResponse(
      statusCode: response.statusCode,
      body: body,
      headers: response.headers,
      elapsed: response.elapsed,
    );
  }
}

bool _isEventStream(UrlResponse response) {
  final contentType = response.headers.entries
      .where((entry) => entry.key.toLowerCase() == 'content-type')
      .expand((entry) => entry.value)
      .join(';')
      .toLowerCase();
  if (contentType.contains('text/event-stream')) return true;

  final body = response.body.trimLeft();
  if (!body.startsWith('event:') && !body.startsWith('data:')) return false;

  return RegExp(r'\r?\n\r?\n').hasMatch(body) ||
      const LineSplitter()
              .convert(body)
              .where((line) => line.isNotEmpty && !line.startsWith(':'))
              .length >
          1;
}

final class _SseTextAccumulator {
  final StringBuffer _text = StringBuffer();
  final Map<String, String> _citations = {};

  static String? decode(String body) {
    final accumulator = _SseTextAccumulator();
    _SseEventParser(accumulator).parse(body);

    return accumulator.result();
  }

  String? result() {
    if (_text.isEmpty) return null;
    if (_citations.isEmpty) return _text.toString();

    final sources = _citations.entries
        .map((entry) => '- [${entry.value}](${entry.key})')
        .join('\n');
    return '$_text\n\nSources:\n$sources';
  }

  void consume(String? eventType, String rawData) {
    final data = rawData.trim();
    if (data.isEmpty || data == '[DONE]') return;

    final decoded = _decodeJson(data);
    if (decoded is String) {
      _appendDelta(decoded);

      return;
    }
    if (decoded is! Map) return;

    final event = Map<String, dynamic>.from(decoded);
    final type = '${event['type'] ?? eventType ?? ''}'.toLowerCase();
    _collectCitations(event);
    final delta = _deltaText(event, type);
    if (delta != null) _appendDelta(delta);

    final finalText = _finalText(event, type);
    if (finalText != null) _reconcile(finalText);
  }

  String? _finalText(Map<String, dynamic> event, String type) {
    final responseText = _extractText(event['response']);
    if (responseText.isNotEmpty) return responseText;
    if (!_isFinalEvent(type)) return null;

    final eventText = _extractText(event);
    return eventText.isEmpty ? null : eventText;
  }

  String? _deltaText(Map<String, dynamic> event, String type) {
    return _directDelta(event) ??
        _choiceDelta(event) ??
        _typedDelta(event, type);
  }

  String? _directDelta(Map<String, dynamic> event) {
    final delta = event['delta'];
    if (delta is String) return delta;

    return delta is Map ? _nonEmptyText(delta) : null;
  }

  String? _choiceDelta(Map<String, dynamic> event) {
    final choices = event['choices'];
    if (choices is! List) return null;

    for (final choice in choices.whereType<Map<Object?, Object?>>()) {
      final delta = _choiceDeltaValue(choice);
      if (delta != null) return delta;
    }

    return null;
  }

  String? _choiceDeltaValue(Map<Object?, Object?> choice) {
    final delta = choice['delta'];
    if (delta is String) return delta;
    if (delta is Map) {
      final text = _nonEmptyText(delta);
      if (text != null) return text;
    }

    final text = choice['text'];
    return text is String && text.isNotEmpty ? text : null;
  }

  String? _typedDelta(Map<String, dynamic> event, String type) {
    if (!type.contains('delta') && !type.contains('chunk')) return null;

    return _nonEmptyText(event);
  }

  String? _nonEmptyText(Object value) {
    final text = _extractText(value);
    return text.isEmpty ? null : text;
  }

  void _appendDelta(String value) {
    if (value.isEmpty) return;
    _text.write(value);
  }

  void _collectCitations(Object value) {
    if (value is List) {
      value.whereType<Object>().forEach(_collectCitations);

      return;
    }
    if (value is! Map) return;

    final type = '${value['type'] ?? ''}'.toLowerCase();
    final url = value['url'];
    if (url is String && url.isNotEmpty && type.contains('citation')) {
      final title = value['title'];
      _citations[url] = title is String && title.isNotEmpty ? title : url;
    }
    value.values.whereType<Object>().forEach(_collectCitations);
  }

  void _reconcile(String value) {
    if (value.isEmpty) return;
    final current = _text.toString();
    if (current.isEmpty) {
      _text.write(value);

      return;
    }
    if (value.startsWith(current)) {
      _text.write(value.substring(current.length));

      return;
    }
    if (current.startsWith(value)) return;

    _text
      ..clear()
      ..write(value);
  }
}

final class _SseEventParser(final _SseTextAccumulator _accumulator) {
  String? _eventType;
  final StringBuffer _data = StringBuffer();

  void parse(String body) {
    const LineSplitter().convert(body).forEach(_consumeLine);
    _consumeEvent();
  }

  void _consumeLine(String line) {
    if (line.isEmpty) {
      _consumeEvent();

      return;
    }
    if (line.startsWith(':')) return;
    if (line.startsWith('event:')) {
      _consumeEventBeforeNewField();
      _eventType = _fieldValue(line);

      return;
    }
    if (line.startsWith('data:')) _consumeDataField(line);
  }

  void _consumeEventBeforeNewField() {
    if (_data.isNotEmpty && _isJson(_data.toString())) _consumeEvent();
  }

  void _consumeDataField(String line) {
    _consumeEventBeforeNewField();
    if (_data.isNotEmpty) _data.write('\n');
    _data.write(_fieldValue(line));
  }

  void _consumeEvent() {
    if (_data.isEmpty) {
      _eventType = null;

      return;
    }
    _accumulator.consume(_eventType, _data.toString());
    _data.clear();
    _eventType = null;
  }
}

bool _isJson(String value) {
  try {
    jsonDecode(value);

    return true;
  } on FormatException {
    return false;
  }
}

String _fieldValue(String line) {
  final value = line.substring(line.indexOf(':') + 1);
  return value.startsWith(' ') ? value.substring(1) : value;
}

Object? _decodeJson(String value) {
  try {
    return jsonDecode(value);
  } on FormatException {
    return value;
  }
}

bool _isFinalEvent(String type) =>
    type.contains('completed') ||
    type.contains('complete') ||
    type.endsWith('.done') ||
    type.contains('message_stop') ||
    type.contains('finished');

String _extractText(Object? value) {
  if (value is String) return value;
  if (value is List) return value.map(_extractText).join();
  if (value is! Map) return '';

  for (final key in const [
    'output_text',
    'text',
    'completion',
    'content',
    'output',
    'choices',
    'message',
  ]) {
    final text = _extractText(value[key]);
    if (text.isNotEmpty) return text;
  }

  return '';
}
