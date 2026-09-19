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
    String? eventType;
    final data = StringBuffer();

    void consumeEvent() {
      if (data.isEmpty) {
        eventType = null;

        return;
      }
      accumulator.consume(eventType, data.toString());
      data.clear();
      eventType = null;
    }

    for (final line in const LineSplitter().convert(body)) {
      if (line.isEmpty) {
        consumeEvent();

        continue;
      }
      if (line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        if (data.isNotEmpty && _isJson(data.toString())) consumeEvent();
        eventType = _fieldValue(line);

        continue;
      }
      if (line.startsWith('data:')) {
        if (data.isNotEmpty && _isJson(data.toString())) consumeEvent();
        if (data.isNotEmpty) data.write('\n');
        data.write(_fieldValue(line));
      }
    }
    consumeEvent();

    if (accumulator._text.isEmpty) return null;
    if (accumulator._citations.isEmpty) return accumulator._text.toString();

    final sources = accumulator._citations.entries
        .map((entry) => '- [${entry.value}](${entry.key})')
        .join('\n');
    return '${accumulator._text}\n\nSources:\n$sources';
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
    final delta = event['delta'];
    if (delta is String) return delta;
    if (delta is Map) {
      final text = _extractText(delta);
      if (text.isNotEmpty) return text;
    }

    final choices = event['choices'];
    if (choices is List) {
      for (final choice in choices.whereType<Map<Object?, Object?>>()) {
        final choiceDelta = choice['delta'];
        if (choiceDelta is String) return choiceDelta;
        if (choiceDelta is Map) {
          final text = _extractText(choiceDelta);
          if (text.isNotEmpty) return text;
        }
        final choiceText = choice['text'];
        if (choiceText is String && choiceText.isNotEmpty) return choiceText;
      }
    }

    if (type.contains('delta') || type.contains('chunk')) {
      final text = _extractText(event);
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  void _appendDelta(String value) {
    if (value.isEmpty) return;
    _text.write(value);
  }

  void _collectCitations(Object? value) {
    if (value is List) {
      value.forEach(_collectCitations);

      return;
    }
    if (value is! Map) return;

    final type = '${value['type'] ?? ''}'.toLowerCase();
    final url = value['url'];
    if (url is String && url.isNotEmpty && type.contains('citation')) {
      final title = value['title'];
      _citations[url] = title is String && title.isNotEmpty ? title : url;
    }
    value.values.forEach(_collectCitations);
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
