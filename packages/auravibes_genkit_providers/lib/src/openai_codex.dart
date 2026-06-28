// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: Parser helpers keep compact return flow.
// Required: Protocol parsing uses fixed SSE and JSON offsets.

import 'dart:async';
import 'dart:convert';

import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

typedef OpenAICodexAccessTokenProvider = FutureOr<String> Function();

class OpenAICodexProvider extends GenkitPlugin {
  OpenAICodexProvider({
    required this.accessTokenProvider,
    this.accountId,
    this.sessionId,
    this.models = const [],
    this.baseUrl = 'https://chatgpt.com/backend-api/codex/responses',
    this.httpClient,
    this.requestTimeout = const Duration(seconds: 30),
  });

  final OpenAICodexAccessTokenProvider accessTokenProvider;
  final String? accountId;
  final String? sessionId;
  final List<String> models;
  final String baseUrl;
  final http.Client? httpClient;
  final Duration requestTimeout;

  @override
  String get name => 'openai_codex';

  @override
  Future<List<Action<dynamic, dynamic, dynamic, dynamic>>> init() async {
    return [
      for (final model in models) _createModel(model),
    ];
  }

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    String actionType,
    String name,
  ) {
    if (actionType != 'model') return null;

    return _createModel(name);
  }

  Model<dynamic> _createModel(String modelName) {
    return Model<dynamic>(
      name: '$name/$modelName',
      fn: (req, ctx) async {
        if (req == null) throw ArgumentError.notNull('req');
        final body = _buildRequestBody(
          modelName: modelName,
          request: req,
          stream: ctx.streamingRequested,
        );

        if (ctx.streamingRequested) return _stream(body, ctx.sendChunk);

        return _complete(body);
      },
    );
  }

  Future<ModelResponse> _complete(Map<String, dynamic> body) async {
    final response = await _send(body);
    _throwIfRawError(response.statusCode, response.body);

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return _modelResponseFromJson(json);
  }

  Future<ModelResponse> _stream(
    Map<String, dynamic> body,
    void Function(ModelResponseChunk) sendChunk,
  ) async {
    final client = httpClient ?? http.Client();
    var sentChunks = false;
    try {
      for (var attempt = 0; ; attempt++) {
        try {
          final request = await _request(body);
          final response = await client
              .send(request)
              .timeout(
                requestTimeout,
              );
          final accumulator = _CodexStreamAccumulator();

          if (response.statusCode < 200 || response.statusCode >= 300) {
            final responseBody = await response.stream.bytesToString();
            _throwIfRawError(response.statusCode, responseBody);
          }

          await for (final line
              in response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            if (!line.startsWith('data:')) continue;
            final data = line.replaceFirst('data:', '').trim();
            if (data.isEmpty || data == '[DONE]') continue;

            final event = _decodeStreamEvent(data);
            final parts = accumulator.addEvent(event);
            if (parts.isNotEmpty) {
              sentChunks = true;
              sendChunk(ModelResponseChunk(index: 0, content: parts));
            }
          }

          return accumulator.toResponse();
        } on GenkitException catch (error) {
          if (!_isRetryableCodexError(error)) rethrow;
          if (attempt > 0 || sentChunks) {
            rethrow;
          }
        }
      }
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Map<String, dynamic> _buildRequestBody({
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

  Future<http.Response> _send(Map<String, dynamic> body) async {
    final request = await _request(body);
    final client = httpClient ?? http.Client();
    try {
      return http.Response.fromStream(
        await client.send(request).timeout(requestTimeout),
      );
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<http.Request> _request(Map<String, dynamic> body) async {
    final token = await accessTokenProvider();
    if (token.trim().isEmpty) {
      throw GenkitException(
        '[openai_codex] OAuth access token is required.',
        status: StatusCodes.INVALID_ARGUMENT,
      );
    }

    final accountId = this.accountId;
    final sessionId = this.sessionId;

    return http.Request('POST', Uri.parse(baseUrl))
      ..headers.addAll({
        'authorization': 'Bearer ${token.trim()}',
        'content-type': 'application/json',
        'originator': 'auravibes',
        'user-agent': 'AuraVibes',
        if (accountId != null && accountId.isNotEmpty)
          'ChatGPT-Account-Id': accountId,
        if (sessionId != null && sessionId.isNotEmpty) 'session-id': sessionId,
      })
      ..body = jsonEncode(body);
  }

  void _throwIfRawError(int statusCode, String body) {
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
    throw GenkitException(
      'OpenAI Codex stream parse error.',
      status: StatusCodes.INTERNAL,
      details: data,
      underlyingException: error,
      stackTrace: stackTrace,
    );
  }
}

ModelRef<Object?> openAICodexModel(String name) {
  return modelRef('openai_codex/$name');
}

const _codexInstructions =
    'You are a coding assistant. '
    'Answer clearly and use tools when appropriate.';

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
    {
      'role': role,
      'content': _contentToInput(message.content),
    },
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
      content.add({
        'type': 'input_image',
        'image_url': media.url,
      });
    }
  }

  if (content.isEmpty) return text.toString();
  if (text.isNotEmpty) {
    content.insert(0, {'type': 'input_text', 'text': '$text'});
  }

  return content;
}

Map<String, dynamic> _toolToJson(ToolDefinition tool) {
  return {
    'type': 'function',
    'name': tool.name,
    'description': tool.description,
    'parameters':
        tool.inputSchema ??
        <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{},
        },
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
      final details = _failedEventDetails(event);
      throw GenkitException(
        'OpenAI Codex API error: ${jsonEncode(details['error'])}',
        status: StatusCodes.INTERNAL,
        details: jsonEncode(details),
        stackTrace: StackTrace.current,
      );
    }
    if (type == 'response.completed') {
      final response = event['response'] as Map<String, dynamic>?;
      _usage = _usageFromJson(response?['usage'] as Map<String, dynamic>?);
      _finishReasonValue = FinishReason.stop;

      return const [];
    }
    if (type == 'response.output_item.done') {
      final item = event['item'] as Map<String, dynamic>?;
      if (item?['type'] == 'function_call') {
        _tools.addAll(
          _toolRequestsFromResponse({
            'output': [item],
          }),
        );
      }

      return const [];
    }
    if (type != 'response.output_text.delta') return const [];

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

bool _isRetryableCodexError(GenkitException error) {
  return error.status == StatusCodes.INTERNAL &&
      '${error.details}'.contains('server_error');
}
