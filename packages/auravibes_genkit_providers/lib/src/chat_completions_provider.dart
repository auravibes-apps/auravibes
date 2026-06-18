// Required: Private workspace package API mirrors existing provider surface.
// ignore_for_file: public_member_api_docs
// Required: DTO fields stay grouped with their constructors.
// Required: Parser helpers keep compact return flow.
// Required: Protocol parsing uses fixed SSE and JSON offsets.

import 'dart:async';
import 'dart:convert';

import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart' as sdk;

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
    final completion = sdk.ChatCompletion.fromJson(json);
    if (completion.choices.isEmpty) {
      throw GenkitException('Model returned no choices.');
    }
    final choice = completion.choices.first;

    return ModelResponse(
      message: _messageFromAssistant(choice.message),
      finishReason: _mapFinishReason(choice.finishReason),
      usage: _toUsage(completion.usage),
      raw: json,
    );
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
      final accumulator = sdk.ChatStreamAccumulator();

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

        final event = sdk.ChatStreamEvent.fromJson(
          jsonDecode(data) as Map<String, dynamic>,
        );
        accumulator.add(event);

        final parts = _partsFromEvent(event);
        if (parts.isNotEmpty) {
          sendChunk(ModelResponseChunk(index: 0, content: parts));
        }
      }

      final completion = accumulator.toChatCompletion();
      if (completion.choices.isEmpty) {
        throw GenkitException('Model returned no choices.');
      }
      final choice = completion.choices.first;

      return ModelResponse(
        message: _messageFromAssistant(choice.message),
        finishReason: _mapFinishReason(choice.finishReason),
        usage: _toUsage(completion.usage),
        raw: completion.toJson(),
      );
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

Message _messageFromAssistant(sdk.AssistantMessage message) {
  final parts = <Part>[];

  final reasoning = message.reasoningContent ?? message.reasoning;
  if (reasoning != null && reasoning.isNotEmpty) {
    parts.add(ReasoningPart(reasoning: reasoning));
  }

  final content = message.content;
  if (content != null && content.isNotEmpty) {
    parts.add(TextPart(text: content));
  }

  final toolCalls = message.toolCalls;
  if (toolCalls != null) {
    for (final toolCall in toolCalls) {
      parts.add(_toolRequestFromToolCall(toolCall));
    }
  }

  return Message(role: Role.model, content: parts);
}

ToolRequestPart _toolRequestFromToolCall(sdk.ToolCall toolCall) {
  final arguments = toolCall.function.arguments;

  return ToolRequestPart(
    toolRequest: ToolRequest(
      ref: toolCall.id,
      name: toolCall.function.name,
      input: arguments.isNotEmpty
          ? jsonDecode(arguments) as Map<String, dynamic>?
          : null,
    ),
  );
}

List<Part> _partsFromEvent(sdk.ChatStreamEvent event) {
  final delta = event.choices?.firstOrNull?.delta;
  if (delta == null) return const [];

  final parts = <Part>[];
  final reasoning = delta.reasoningContent ?? delta.reasoning;
  if (reasoning != null && reasoning.isNotEmpty) {
    parts.add(ReasoningPart(reasoning: reasoning));
  }

  final content = delta.content;
  if (content != null && content.isNotEmpty) {
    parts.add(TextPart(text: content));
  }

  return parts;
}

FinishReason _mapFinishReason(sdk.FinishReason? reason) {
  if (reason == null) return FinishReason.unknown;

  return switch (reason) {
    sdk.FinishReason.stop ||
    sdk.FinishReason.toolCalls ||
    sdk.FinishReason.functionCall => FinishReason.stop,
    sdk.FinishReason.length => FinishReason.length,
    sdk.FinishReason.contentFilter => FinishReason.blocked,
    sdk.FinishReason.unknown => FinishReason.unknown,
  };
}

GenerationUsage? _toUsage(sdk.Usage? usage) {
  if (usage == null) return null;

  return GenerationUsage(
    inputTokens: usage.promptTokens.toDouble(),
    outputTokens: usage.completionTokens?.toDouble(),
    totalTokens: usage.totalTokens.toDouble(),
  );
}
