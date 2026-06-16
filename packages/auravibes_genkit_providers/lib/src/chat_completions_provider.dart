// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: DTO fields stay grouped with their constructors.
// Required: Parser helpers keep compact return flow.
// Required: Protocol parsing uses fixed SSE and JSON offsets.

import 'dart:async';
import 'dart:convert';

import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

typedef ChatCompletionsApiKeyProvider = FutureOr<String> Function();
typedef ChatCompletionsOptionsParser<T extends Object> =
    T Function(Map<String, dynamic>? json);
typedef ChatCompletionsExtraBodyBuilder<T extends Object> =
    Map<String, dynamic> Function(T options);
typedef ChatCompletionsModelResolver<T extends Object> =
    String Function(String modelName, T options);

class ChatCompletionsModelDefinition {
  const ChatCompletionsModelDefinition({required this.name, this.info});

  final String name;
  final ModelInfo? info;
}

class ChatCompletionsProviderConfig<T extends Object> {
  const ChatCompletionsProviderConfig({
    required this.name,
    required this.baseUrl,
    required this.errorLabel,
    required this.parseOptions,
    required this.extraBody,
    this.resolveModel,
    this.apiKey,
    this.apiKeyProvider,
    this.models = const [],
    this.headers,
    this.httpClient,
    this.requestTimeout = const Duration(seconds: 30),
  });

  final String name;
  final String baseUrl;
  final String errorLabel;
  final ChatCompletionsOptionsParser<T> parseOptions;
  final ChatCompletionsExtraBodyBuilder<T> extraBody;
  final ChatCompletionsModelResolver<T>? resolveModel;
  final String? apiKey;
  final ChatCompletionsApiKeyProvider? apiKeyProvider;
  final List<ChatCompletionsModelDefinition> models;
  final Map<String, String>? headers;
  final http.Client? httpClient;
  final Duration requestTimeout;
}

class ChatCompletionsProvider<T extends Object> extends GenkitPlugin {
  ChatCompletionsProvider(this.config) {
    if (config.name.isEmpty || config.name.contains('/')) {
      throw GenkitException(
        'Plugin name must be non-empty and must not contain "/". '
        'Got: "${config.name}"',
        status: StatusCodes.INVALID_ARGUMENT,
      );
    }
    if (config.apiKey != null && config.apiKeyProvider != null) {
      throw GenkitException(
        'Provide either apiKey or apiKeyProvider, not both.',
        status: StatusCodes.INVALID_ARGUMENT,
      );
    }
  }

  final ChatCompletionsProviderConfig<T> config;

  @override
  String get name => config.name;

  @override
  Future<List<Action<dynamic, dynamic, dynamic, dynamic>>> init() async {
    return [
      for (final model in config.models) _createModel(model.name, model.info),
    ];
  }

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    String actionType,
    String name,
  ) {
    if (actionType != 'model') return null;

    return _createModel(name, null);
  }

  Model<dynamic> _createModel(String modelName, ModelInfo? info) {
    return Model<dynamic>(
      name: '${config.name}/$modelName',
      fn: (req, ctx) async {
        if (req == null) {
          throw ArgumentError.notNull('req');
        }
        final request = req;
        final options = config.parseOptions(request.config);
        final body = _buildRequestBody(
          modelName: modelName,
          request: request,
          options: options,
          stream: ctx.streamingRequested,
        );

        if (ctx.streamingRequested) {
          return _stream(body, ctx.sendChunk);
        }

        return _complete(body);
      },
      metadata: {'model': ?info?.toJson()},
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
    final request = await _request(body);
    final client = config.httpClient ?? http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(
            config.requestTimeout,
          );
      final accumulator = _StreamAccumulator();

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

        final chunk = jsonDecode(data) as Map<String, dynamic>;
        final parts = accumulator.addChunk(chunk);
        if (parts.isNotEmpty) {
          sendChunk(ModelResponseChunk(index: 0, content: parts));
        }
      }

      return accumulator.toResponse();
    } finally {
      if (config.httpClient == null) client.close();
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required String modelName,
    required ModelRequest request,
    required T options,
    required bool stream,
  }) {
    return {
      'model': config.resolveModel?.call(modelName, options) ?? modelName,
      'messages': request.messages.expand(_messageToJson).toList(),
      'stream': stream,
      if (stream) 'stream_options': {'include_usage': true},
      'tools': ?request.tools?.map(_toolToJson).toList(),
      ...config.extraBody(options),
    };
  }

  Future<http.Response> _send(Map<String, dynamic> body) async {
    final request = await _request(body);
    final client = config.httpClient ?? http.Client();
    try {
      return http.Response.fromStream(
        await client.send(request).timeout(config.requestTimeout),
      );
    } finally {
      if (config.httpClient == null) client.close();
    }
  }

  Future<http.Request> _request(Map<String, dynamic> body) async {
    final key = await _resolveApiKey();
    if (key == null || key.trim().isEmpty) {
      throw GenkitException(
        '[$name] API key is required.',
        status: StatusCodes.INVALID_ARGUMENT,
      );
    }

    return http.Request('POST', _chatCompletionsUri())
      ..headers.addAll({
        'authorization': 'Bearer ${key.trim()}',
        'content-type': 'application/json',
        ...?config.headers,
      })
      ..body = jsonEncode(body);
  }

  Uri _chatCompletionsUri() {
    final normalized = config.baseUrl.replaceFirst(RegExp(r'/$'), '');

    return Uri.parse('$normalized/chat/completions');
  }

  Future<String?> _resolveApiKey() async {
    final provider = config.apiKeyProvider;
    if (provider != null) return provider();

    return config.apiKey;
  }

  void _throwIfRawError(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;

    throw GenkitException(
      '${config.errorLabel} API error: $body',
      status: StatusCodes.fromHttpStatus(statusCode),
      details: body,
    );
  }
}

List<Map<String, dynamic>> _messageToJson(Message message) {
  if (message.role == Role.tool) {
    return message.content
        .map((part) {
          final response = part.toolResponse;
          if (response == null) return null;

          return {
            'role': 'tool',
            'tool_call_id': response.ref,
            'content': jsonEncode(response.output),
          };
        })
        .nonNulls
        .toList();
  }

  return [
    {
      'role': _roleToJson(message.role),
      'content': _contentToJson(message.content),
      'tool_calls': ?_toolCallsToJson(message.content),
    },
  ];
}

String _roleToJson(Role role) {
  if (role == Role.system) return 'system';
  if (role == Role.user) return 'user';
  if (role == Role.model) return 'assistant';

  return role.value;
}

Object? _contentToJson(List<Part> parts) {
  final content = <Map<String, dynamic>>[];
  final text = StringBuffer();

  for (final part in parts) {
    if (part.isText) {
      text.write(part.text);
    } else if (part.isMedia) {
      final media = part.media;
      if (media == null) continue;
      content.add({
        'type': 'image_url',
        'image_url': {'url': media.url},
      });
    }
  }

  if (content.isEmpty) return text.toString();
  if (text.isNotEmpty) content.insert(0, {'type': 'text', 'text': '$text'});

  return content;
}

List<Map<String, dynamic>>? _toolCallsToJson(List<Part> parts) {
  final toolCalls = parts
      .map((part) {
        final tool = part.toolRequest;
        if (tool == null) return null;

        return {
          'id': tool.ref,
          'type': 'function',
          'function': {
            'name': tool.name,
            'arguments': jsonEncode(tool.input ?? const <String, dynamic>{}),
          },
        };
      })
      .nonNulls
      .toList();

  return toolCalls.isEmpty ? null : toolCalls;
}

Map<String, dynamic> _toolToJson(ToolDefinition tool) {
  return {
    'type': 'function',
    'function': {
      'name': tool.name,
      'description': tool.description,
      'parameters':
          tool.inputSchema ??
          <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{},
          },
    },
  };
}

ModelResponse _modelResponseFromJson(Map<String, dynamic> json) {
  final choices = json['choices'] as List? ?? const [];
  if (choices.isEmpty) throw GenkitException('Model returned no choices.');
  final choice = choices.firstOrNull as Map<String, dynamic>;
  final message = choice['message'] as Map<String, dynamic>? ?? const {};

  return ModelResponse(
    message: _messageFromJson(message),
    finishReason: _finishReason(choice['finish_reason'] as String?),
    usage: _usageFromJson(json['usage'] as Map<String, dynamic>?),
    raw: json,
  );
}

Message _messageFromJson(Map<String, dynamic> message) {
  final parts = <Part>[];
  final reasoning = message['reasoning_content'] ?? message['reasoning'];
  if (reasoning is String && reasoning.isNotEmpty) {
    parts.add(ReasoningPart(reasoning: reasoning));
  }

  final content = message['content'];
  if (content is String && content.isNotEmpty) {
    parts.add(TextPart(text: content));
  }

  final toolCalls = message['tool_calls'] as List? ?? const [];
  for (final toolCall in toolCalls.cast<Map<String, dynamic>>()) {
    parts.add(_toolRequestFromJson(toolCall));
  }

  return Message(role: Role.model, content: parts);
}

ToolRequestPart _toolRequestFromJson(Map<String, dynamic> toolCall) {
  final function = toolCall['function'] as Map<String, dynamic>? ?? const {};
  final arguments = function['arguments'];

  return ToolRequestPart(
    toolRequest: ToolRequest(
      ref: toolCall['id'] as String?,
      name: function['name'] as String? ?? '',
      input: arguments is String && arguments.isNotEmpty
          ? jsonDecode(arguments) as Map<String, dynamic>?
          : null,
    ),
  );
}

GenerationUsage? _usageFromJson(Map<String, dynamic>? usage) {
  if (usage == null) return null;

  return GenerationUsage(
    inputTokens: (usage['prompt_tokens'] as num?)?.toDouble(),
    outputTokens: (usage['completion_tokens'] as num?)?.toDouble(),
    totalTokens: (usage['total_tokens'] as num?)?.toDouble(),
  );
}

FinishReason _finishReason(String? reason) {
  return switch (reason) {
    'stop' => FinishReason.stop,
    'length' => FinishReason.length,
    'content_filter' => FinishReason.blocked,
    'tool_calls' => FinishReason.stop,
    _ => FinishReason.unknown,
  };
}

class _StreamAccumulator {
  final StringBuffer _text = StringBuffer();
  final StringBuffer _reasoning = StringBuffer();
  final Map<int, _ToolCallDelta> _toolCalls = {};
  FinishReason _finishReasonValue = FinishReason.unknown;
  GenerationUsage? _usage;

  List<Part> addChunk(Map<String, dynamic> chunk) {
    _usage = _usageFromJson(chunk['usage'] as Map<String, dynamic>?) ?? _usage;

    final choices = chunk['choices'] as List? ?? const [];
    if (choices.isEmpty) return const [];
    final choice = choices.firstOrNull as Map<String, dynamic>;
    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) _finishReasonValue = _finishReason(finishReason);

    final delta = choice['delta'] as Map<String, dynamic>? ?? const {};
    final parts = <Part>[];

    final reasoning = delta['reasoning_content'] ?? delta['reasoning'];
    if (reasoning is String && reasoning.isNotEmpty) {
      _reasoning.write(reasoning);
      parts.add(ReasoningPart(reasoning: reasoning));
    }

    final content = delta['content'];
    if (content is String && content.isNotEmpty) {
      _text.write(content);
      parts.add(TextPart(text: content));
    }

    final toolCalls = delta['tool_calls'] as List? ?? const [];
    toolCalls.cast<Map<String, dynamic>>().forEach(_addToolCallDelta);

    return parts;
  }

  ModelResponse toResponse() {
    final parts = <Part>[];
    if (_reasoning.isNotEmpty) {
      parts.add(ReasoningPart(reasoning: _reasoning.toString()));
    }
    if (_text.isNotEmpty) parts.add(TextPart(text: _text.toString()));
    parts.addAll(_toolCalls.values.map((delta) => delta.toPart()));

    return ModelResponse(
      message: Message(role: Role.model, content: parts),
      finishReason: _finishReasonValue,
      usage: _usage,
    );
  }

  void _addToolCallDelta(Map<String, dynamic> toolCall) {
    final index = toolCall['index'] as int? ?? _toolCalls.length;
    final delta = _toolCalls.putIfAbsent(index, _ToolCallDelta.new);
    final function = toolCall['function'] as Map<String, dynamic>?;
    if (function == null) {
      delta.id ??= toolCall['id'] as String?;

      return;
    }

    delta
      ..id ??= toolCall['id'] as String?
      ..name ??= function['name'] as String?
      ..arguments.write(function['arguments'] as String? ?? '');
  }
}

class _ToolCallDelta {
  String? id;
  String? name;
  final StringBuffer arguments = StringBuffer();

  ToolRequestPart toPart() {
    final rawArguments = arguments.toString();

    return ToolRequestPart(
      toolRequest: ToolRequest(
        ref: id,
        name: name ?? '',
        input: rawArguments.isNotEmpty
            ? jsonDecode(rawArguments) as Map<String, dynamic>?
            : null,
      ),
    );
  }
}
