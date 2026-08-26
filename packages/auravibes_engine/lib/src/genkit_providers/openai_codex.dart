// Required: Private workspace package API mirrors existing provider surface.
// Required: Parser helpers keep compact return flow.
// Required: Protocol parsing uses fixed SSE and JSON offsets.

import 'dart:convert';

import 'package:auravibes_engine/src/genkit_providers/chat_completions_provider.dart';
import 'package:genkit/plugin.dart';

class OpenAICodexCodec {
  const OpenAICodexCodec();

  Future<ModelResponse> complete(
    ProviderTransport transport,
    Map<String, dynamic> body,
  ) async {
    final response = await transport(body);
    final responseBody = await response.body.transform(utf8.decoder).join();
    throwIfRawError(response.statusCode, responseBody);
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    return _modelResponseFromJson(json);
  }

  Future<ModelResponse> stream(
    ProviderTransport transport,
    Map<String, dynamic> body,
    void Function(ModelResponseChunk) sendChunk,
  ) async {
    final response = await transport(body);
    final accumulator = _CodexStreamAccumulator();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = await response.body.transform(utf8.decoder).join();
      throwIfRawError(response.statusCode, responseBody);
    }

    await for (final line
        in response.body
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (!line.startsWith(_dataUrlPrefix)) continue;
      final data = line.replaceFirst(_dataUrlPrefix, '').trim();
      if (data.isEmpty || data == '[DONE]') continue;

      final event = _decodeStreamEvent(data);
      final parts = accumulator.addEvent(event);
      if (parts.isNotEmpty) {
        sendChunk(ModelResponseChunk(index: 0, content: parts));
      }
    }

    return accumulator.toResponse();
  }

  Map<String, dynamic> buildRequestBody({
    required String modelName,
    required ModelRequest request,
    required bool stream,
  }) {
    return {
      'model': modelName,
      'input': request.messages.expand(_messageToInput).toList(),
      'instructions': _codexInstructions,
      'stream': stream,
      'store': false,
      'reasoning': const {'effort': 'medium', 'summary': 'auto'},
      'text': const {'verbosity': 'low'},
      'include': const ['reasoning.encrypted_content'],
      'tools': ?request.tools?.map(_toolToJson).toList(),
    };
  }

  void throwIfRawError(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;

    throw GenkitException(
      'OpenAI Codex API error: $body',
      status: StatusCodes.fromHttpStatus(statusCode),
      details: body,
    );
  }
}

Map<String, dynamic> _decodeStreamEvent(String data) {
  try {
    return jsonDecode(data) as Map<String, dynamic>;
  } on Object catch (error, stackTrace) {
    Error.throwWithStackTrace(
      GenkitException(
        'OpenAI Codex stream parse error.',
        status: StatusCodes.INTERNAL,
        details: data,
        underlyingException: error,
        stackTrace: stackTrace,
      ),
      stackTrace,
    );
  }
}

ModelRef<Object?> openAICodexModel(String name) {
  return modelRef('openai_codex/$name');
}

const _codexInstructions =
    'You are a coding assistant. '
    'Answer clearly and use tools when appropriate.';
const _dataUrlPrefix = 'data:';

List<Map<String, dynamic>> _messageToInput(Message message) {
  if (message.role == Role.tool) {
    return message.content
        .map((part) {
          final response = part.toolResponse;
          if (response == null) return null;

          return {
            'type': 'function_call_output',
            'call_id': response.ref,
            'output': jsonEncode(response.output),
          };
        })
        .nonNulls
        .toList();
  }

  final role = message.role == Role.model ? 'assistant' : message.role.value;

  return [
    {'role': role, 'content': _contentToInput(message.content)},
    if (message.role == Role.model) ..._toolCallsToInput(message.content),
  ];
}

List<Map<String, dynamic>> _toolCallsToInput(List<Part> parts) {
  return [
    for (final part in parts)
      if (part.toolRequest case final request?)
        {
          'type': 'function_call',
          'call_id': request.ref,
          'name': request.name,
          'arguments': jsonEncode(request.input ?? const <String, dynamic>{}),
        },
  ];
}

Object _contentToInput(List<Part> parts) {
  final content = <Map<String, dynamic>>[];
  final text = StringBuffer();

  for (final part in parts) {
    if (part.isText) {
      text.write(part.text);
    } else if (part.isMedia) {
      final media = part.media;
      if (media == null) continue;
      content.add(_mediaToInput(part, media));
    }
  }

  if (content.isEmpty) return text.toString();
  if (text.isNotEmpty) {
    content.insert(0, {'type': 'input_text', 'text': '$text'});
  }

  return content;
}

Map<String, dynamic> _mediaToInput(Part part, Media media) {
  final contentType = media.contentType ?? '';
  if (contentType.startsWith('image/')) {
    return {'type': 'input_image', 'image_url': media.url};
  }

  final data = _dataUrlPayload(media.url);
  if (data == null) {
    throw GenkitException(
      'OpenAI Responses media inputs require a data URL for files and audio.',
      status: StatusCodes.INVALID_ARGUMENT,
    );
  }
  if (contentType.startsWith('audio/')) {
    final format = _audioFormat(contentType, 'OpenAI Responses');

    return {
      'type': 'input_audio',
      'input_audio': {'data': data, 'format': format},
    };
  }

  return {
    'type': 'input_file',
    'file_data': media.url,
    if (part.metadata?['filename'] case final String filename)
      'filename': filename,
  };
}

String? _dataUrlPayload(String url) {
  final comma = url.indexOf(',');
  if (!url.startsWith(_dataUrlPrefix) || comma < 0) return null;
  final header = url.replaceRange(comma, url.length, '');
  if (!header.contains(';base64')) return null;

  final payload = url.replaceRange(0, comma + 1, '');
  try {
    final _ = base64Decode(payload);
  } on FormatException {
    return null;
  }

  return payload;
}

String _audioFormat(String contentType, String providerName) {
  if (contentType == 'audio/mpeg' || contentType == 'audio/mp3') return 'mp3';
  if (contentType == 'audio/wav' || contentType == 'audio/x-wav') return 'wav';

  throw GenkitException(
    '$providerName audio input supports only mp3 and wav.',
    status: StatusCodes.INVALID_ARGUMENT,
  );
}

Map<String, dynamic> _toolToJson(ToolDefinition tool) {
  return {
    'type': 'function',
    'name': tool.name,
    'description': tool.description,
    'parameters':
        tool.inputSchema ??
        <String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}},
  };
}

ModelResponse _modelResponseFromJson(Map<String, dynamic> json) {
  final text = _responseText(json);

  return ModelResponse(
    message: Message(
      role: Role.model,
      content: [
        if (text.isNotEmpty) TextPart(text: text),
        ..._toolRequestsFromResponse(json),
      ],
    ),
    finishReason: _finishReason(json['status'] as String?),
    usage: _usageFromJson(json['usage'] as Map<String, dynamic>?),
    raw: json,
  );
}

String _responseText(Map<String, dynamic> json) {
  final outputText = json['output_text'];
  if (outputText is String) return outputText;

  final output = json['output'] as List? ?? const [];
  final buffer = StringBuffer();
  for (final item in output.cast<Map<String, dynamic>>()) {
    final content = item['content'] as List? ?? const [];
    for (final part in content.cast<Map<String, dynamic>>()) {
      final text = part['text'] ?? part['output_text'];
      if (text is String) buffer.write(text);
    }
  }

  return buffer.toString();
}

List<ToolRequestPart> _toolRequestsFromResponse(Map<String, dynamic> json) {
  final output = json['output'] as List? ?? const [];

  return [
    for (final item in output.cast<Map<String, dynamic>>())
      if (item['type'] == 'function_call')
        ToolRequestPart(
          toolRequest: ToolRequest(
            ref: item['call_id'] as String? ?? item['id'] as String?,
            name: item['name'] as String? ?? '',
            input: _decodeArguments(item['arguments']),
          ),
        ),
  ];
}

Map<String, dynamic>? _decodeArguments(Object? arguments) {
  if (arguments is! String || arguments.isEmpty) return null;

  return jsonDecode(arguments) as Map<String, dynamic>?;
}

GenerationUsage? _usageFromJson(Map<String, dynamic>? usage) {
  if (usage == null) return null;

  return GenerationUsage(
    inputTokens: (usage['input_tokens'] as num?)?.toDouble(),
    outputTokens: (usage['output_tokens'] as num?)?.toDouble(),
    totalTokens: (usage['total_tokens'] as num?)?.toDouble(),
  );
}

FinishReason _finishReason(String? status) {
  return switch (status) {
    'completed' => FinishReason.stop,
    'incomplete' => FinishReason.length,
    'failed' => FinishReason.blocked,
    _ => FinishReason.unknown,
  };
}

class _CodexStreamAccumulator {
  final StringBuffer _text = StringBuffer();
  final List<ToolRequestPart> _tools = [];
  FinishReason _finishReasonValue = FinishReason.unknown;
  GenerationUsage? _usage;

  List<Part> addEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'response.failed') {
      _throwFailedEvent(event);
    }
    if (type == 'response.completed') {
      _complete(event);

      return const [];
    }
    if (type == 'response.output_item.done') {
      _addTool(event);

      return const [];
    }

    return type == 'response.output_text.delta' ? _addText(event) : const [];
  }

  Never _throwFailedEvent(Map<String, dynamic> event) {
    final details = _failedEventDetails(event);
    throw GenkitException(
      'OpenAI Codex API error: ${jsonEncode(details['error'])}',
      status: StatusCodes.INTERNAL,
      details: jsonEncode(details),
      stackTrace: StackTrace.current,
    );
  }

  void _complete(Map<String, dynamic> event) {
    final response = event['response'] as Map<String, dynamic>?;
    _usage = _usageFromJson(response?['usage'] as Map<String, dynamic>?);
    _finishReasonValue = FinishReason.stop;
  }

  void _addTool(Map<String, dynamic> event) {
    final item = event['item'] as Map<String, dynamic>?;
    if (item?['type'] != 'function_call') return;

    _tools.addAll(
      _toolRequestsFromResponse({
        'output': [item],
      }),
    );
  }

  List<Part> _addText(Map<String, dynamic> event) {
    final delta = event['delta'];
    if (delta is! String || delta.isEmpty) return const [];

    _text.write(delta);

    return [TextPart(text: delta)];
  }

  ModelResponse toResponse() {
    return ModelResponse(
      message: Message(
        role: Role.model,
        content: [
          if (_text.isNotEmpty) TextPart(text: _text.toString()),
          ..._tools,
        ],
      ),
      finishReason: _finishReasonValue,
      usage: _usage,
    );
  }
}

Map<String, dynamic> _failedEventDetails(Map<String, dynamic> event) {
  final response = event['response'] as Map<String, dynamic>?;
  final error = event['error'] ?? response?['error'] ?? event;

  return {
    'type': event['type'],
    if (response?['id'] != null) 'response_id': response?['id'],
    if (response?['status'] != null) 'status': response?['status'],
    if (response?['model'] != null) 'model': response?['model'],
    'error': error,
  };
}

bool isRetryableCodexError(GenkitException error) {
  return error.status == StatusCodes.INTERNAL &&
      '${error.details}'.contains('server_error');
}
