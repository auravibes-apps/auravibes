// Required: Private workspace package API mirrors existing provider surface.
// Required: DTO fields stay grouped with their constructors.
// Required: Parser helpers keep compact return flow.
// Required: Protocol parsing uses fixed SSE and JSON offsets.

import 'dart:convert';

import 'package:genkit/plugin.dart';
import 'package:openai_dart/openai_dart.dart' as sdk;

class ProviderTransportResponse {
  const ProviderTransportResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final Stream<List<int>> body;
}

typedef ProviderTransport =
    Future<ProviderTransportResponse> Function(
      Map<String, dynamic> body,
    );

class ChatCompletionsModelDefinition {
  const ChatCompletionsModelDefinition({required this.name, this.info});

  final String name;
  final ModelInfo? info;
}

mixin ChatCompletionsSamplingOptions {
  double? get temperature;
  double? get topP;
  int? get maxTokens;
  List<String>? get stop;
  double? get presencePenalty;
  double? get frequencyPenalty;
  int? get seed;
  String? get user;

  Map<String, dynamic> toSamplingBody() => {
    'temperature': ?temperature,
    'top_p': ?topP,
    'max_tokens': ?maxTokens,
    'stop': ?stop,
    'presence_penalty': ?presencePenalty,
    'frequency_penalty': ?frequencyPenalty,
    'seed': ?seed,
    'user': ?user,
  };
}

class ChatCompletionsCodec {
  const ChatCompletionsCodec({
    required this.errorLabel,
    required this.customize,
  });
  final String errorLabel;

  /// Parses provider-specific request config once into the resolved model
  /// name and the extra body entries to merge into the request.
  final ({String model, Map<String, dynamic> extraBody}) Function(
    String modelName,
    Map<String, dynamic>? config,
  )
  customize;

  Future<ModelResponse> complete(
    ProviderTransport transport,
    Map<String, dynamic> body,
  ) async {
    final response = await transport(body);
    final responseBody = await response.body.transform(utf8.decoder).join();
    _throwIfRawError(response.statusCode, responseBody);

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
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

  Future<ModelResponse> stream(
    ProviderTransport transport,
    Map<String, dynamic> body,
    void Function(ModelResponseChunk) sendChunk,
  ) async {
    final response = await transport(body);
    final accumulator = sdk.ChatStreamAccumulator();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = await response.body.transform(utf8.decoder).join();
      _throwIfRawError(response.statusCode, responseBody);
    }

    await for (final line
        in response.body
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (!line.startsWith(_dataUrlPrefix)) continue;
      final data = line.replaceFirst(_dataUrlPrefix, '').trim();
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
  }

  Map<String, dynamic> buildRequestBody({
    required String modelName,
    required ModelRequest request,
    required bool stream,
  }) {
    final custom = customize(modelName, request.config);

    return {
      'model': custom.model,
      'messages': request.messages.expand(_messageToJson).toList(),
      'stream': stream,
      if (stream) 'stream_options': {'include_usage': true},
      'tools': ?request.tools?.map(_toolToJson).toList(),
      ...custom.extraBody,
    };
  }

  void _throwIfRawError(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;

    throw GenkitException(
      '$errorLabel API error: $body',
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
      content.add(_mediaToChatContent(part, media));
    }
  }

  if (content.isEmpty) return text.toString();
  if (text.isNotEmpty) content.insert(0, {'type': 'text', 'text': '$text'});

  return content;
}

Map<String, dynamic> _mediaToChatContent(Part part, Media media) {
  final contentType = media.contentType ?? '';
  if (contentType.startsWith('image/')) {
    return {
      'type': 'image_url',
      'image_url': {'url': media.url},
    };
  }

  final data = _dataUrlPayload(media.url);
  if (data == null) {
    throw GenkitException(
      'Chat Completions media inputs require a data URL for files and audio.',
      status: StatusCodes.INVALID_ARGUMENT,
    );
  }
  if (contentType.startsWith('audio/')) {
    final format = _audioFormat(contentType, 'Chat Completions');

    return {
      'type': 'input_audio',
      'input_audio': {'data': data, 'format': format},
    };
  }

  return {
    'type': 'file',
    'file': {
      'file_data': media.url,
      if (part.metadata?['filename'] case final String filename)
        'filename': filename,
    },
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

const _dataUrlPrefix = 'data:';

String _audioFormat(String contentType, String providerName) {
  if (contentType == 'audio/mpeg' || contentType == 'audio/mp3') return 'mp3';
  if (contentType == 'audio/wav' || contentType == 'audio/x-wav') return 'wav';

  throw GenkitException(
    '$providerName audio input supports only mp3 and wav.',
    status: StatusCodes.INVALID_ARGUMENT,
  );
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
