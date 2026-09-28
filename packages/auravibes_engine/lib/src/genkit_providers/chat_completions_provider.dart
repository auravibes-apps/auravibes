// Required: Private workspace package API mirrors existing provider surface.
// Required: DTO fields stay grouped with their constructors.
// Required: Parser helpers keep compact return flow.
// Required: Protocol parsing uses fixed SSE and JSON offsets.

import 'dart:convert';

import 'package:auravibes_engine/src/genkit_providers/media_input.dart';
import 'package:auravibes_engine/src/model_capabilities.dart';
import 'package:genkit/plugin.dart';
import 'package:openai_dart/openai_dart.dart' as sdk;

class const ProviderTransportResponse({
  required final int statusCode,
  required final Stream<List<int>> body,
  final int? contentLength,
});

typedef ProviderTransport = Future<ProviderTransportResponse> Function(
  Map<String, dynamic> body,
);

class const ChatCompletionsModelDefinition({
  required final String name,
  final ModelInfo? info,
});

enum ToolSamplingPolicy {
  /// Sends ordinary tool schemas without strict sampling fields.
  off,

  /// Uses strict sampling when both capabilities and schema allow it.
  prefer,

  /// Requires strict sampling or rejects the request before transport.
  require;

  static ToolSamplingPolicy fromJson(Object? value) {
    if (value == null) return off;
    if (value case final String name) {
      for (final policy in values) {
        if (policy.name == name) return policy;
      }
    }

    throw const FormatException(
      'Tool sampling policy must be "off", "prefer", or "require".',
    );
  }
}

/// Why a required strict tool-sampling request was rejected.
enum ToolSamplingValidationReason {
  unsupportedProvider,
  unsupportedModel,
  incompatibleSchema,
}

/// A pre-transport strict tool-sampling validation failure.
final class ToolSamplingValidationException implements Exception {
  const new({required this.reason, required this.detail, this.toolName});

  final ToolSamplingValidationReason reason;
  final String detail;
  final String? toolName;

  @override
  String toString() {
    final tool = toolName == null ? '' : ' for tool "$toolName"';
    return 'Tool sampling validation failed$tool: $detail';
  }
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

class const ChatCompletionsCodec({
  required final String errorLabel,

  /// Parses provider-specific request config once into the resolved model
  /// name and the extra body entries to merge into the request.
  required final ({String model, Map<String, dynamic> extraBody}) Function(
    String modelName,
    Map<String, dynamic>? config,
  )
  customize,

  /// Whether this provider accepts OpenAI-compatible strict tool definitions.
  final bool supportsStrictToolSampling = false,
}) {
  Future<ModelResponse> complete(
    ProviderTransport transport,
    Map<String, dynamic> body,
  ) async {
    final response = await transport(body);
    final responseBody = await _boundedBody(response)
        .transform(utf8.decoder)
        .join();
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
    var eventCount = 0;
    var partCount = 0;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = await _boundedBody(response)
          .transform(utf8.decoder)
          .join();
      _throwIfRawError(response.statusCode, responseBody);
    }

    await for (final line in _boundedBody(
      response,
    ).transform(utf8.decoder).transform(const LineSplitter())) {
      if (!line.startsWith(_dataUrlPrefix)) continue;
      final data = line.replaceFirst(_dataUrlPrefix, '').trim();
      if (data == '[DONE]') break;
      if (data.isEmpty) continue;
      eventCount += 1;
      if (eventCount > _maxProviderEvents) _throwResponseLimit();

      final event = sdk.ChatStreamEvent.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );
      accumulator.add(event);

      final parts = _partsFromEvent(event);
      partCount += parts.length;
      if (partCount > _maxProviderParts) _throwResponseLimit();
      if (parts.isNotEmpty) {
        sendChunk(.new(index: 0, content: parts));
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
    ModelCapabilities? modelCapabilities,
  }) {
    final custom = customize(modelName, request.config);
    final tools = _toolsToJson(
      request.tools,
      policy: ToolSamplingPolicy.fromJson(
        request.config?['toolSamplingPolicy'],
      ),
      providerSupportsStrict: supportsStrictToolSampling,
      modelCapabilities: modelCapabilities,
    );

    return {
      'model': custom.model,
      'messages': request.messages.expand(_messageToJson).toList(),
      'stream': stream,
      if (stream) 'stream_options': {'include_usage': true},
      'tools': ?tools,
      ...custom.extraBody,
    };
  }

  void _throwIfRawError(int statusCode, String responseBody) {
    if (statusCode >= 200 && statusCode < 300) return;

    throw GenkitException(
      '$errorLabel API request failed (HTTP $statusCode).',
      status: .fromHttpStatus(statusCode),
      details: _providerErrorDetail(responseBody),
    );
  }
}

const int _maxProviderResponseBytes = 4 * 1024 * 1024;
const int _maxProviderEvents = 10000;
const int _maxProviderParts = 10000;

Stream<List<int>> _boundedBody(ProviderTransportResponse response) async* {
  final contentLength = response.contentLength;
  if (contentLength != null && contentLength > _maxProviderResponseBytes) {
    _throwResponseLimit();
  }

  var receivedBytes = 0;
  await for (final bytes in response.body) {
    receivedBytes += bytes.length;
    if (receivedBytes > _maxProviderResponseBytes) _throwResponseLimit();
    yield bytes;
  }
}

Never _throwResponseLimit() => throw GenkitException(
  'Provider response exceeded the safe processing limit.',
  status: .RESOURCE_EXHAUSTED,
);

const _maxProviderErrorLength = 500;
const _providerErrorTruncationSuffix = '... [truncated]';

final _providerSecretPatterns = <RegExp>[
  RegExp(
    r"""([\"']?(?:authorization|proxy-authorization|x-api-key)[\"']?\s*[:=]\s*(?:[\"']?(?:[A-Za-z]+\s+)?))[^,\s}\"']+""",
    caseSensitive: false,
  ),
  RegExp(
    r"""([\"']?(?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|id[_-]?token|token|secret|password)[\"']?\s*[:=]\s*[\"']?)(?:Bearer\s+)?[^,\s}\"']+""",
    caseSensitive: false,
  ),
  RegExp(r'''\bBearer\s+[^\s,;}"']+''', caseSensitive: false),
  RegExp(r'\b(?:sk|rk)-[A-Za-z0-9][A-Za-z0-9_-]*', caseSensitive: false),
];

String? _providerErrorDetail(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return null;

  late final Object? decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException {
    return null;
  }

  final message = switch (decoded) {
    final Map<String, dynamic> value => _providerErrorMessage(value),
    _ => null,
  };
  if (message == null || message.trim().isEmpty) return null;

  return _sanitizeProviderError(message);
}

String? _providerErrorMessage(Map<String, dynamic> response) {
  final error = response['error'];
  if (error is Map<String, dynamic> && error['message'] is String) {
    return error['message'] as String;
  }

  final message = response['message'];
  return message is String ? message : null;
}

String _sanitizeProviderError(String message) {
  var sanitized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final pattern in _providerSecretPatterns) {
    sanitized = sanitized.replaceAllMapped(
      pattern,
      (match) =>
          '${match.groupCount > 0 ? match.group(1) ?? '' : ''}[REDACTED]',
    );
  }

  if (sanitized.length <= _maxProviderErrorLength) return sanitized;

  const prefixLength =
      _maxProviderErrorLength - _providerErrorTruncationSuffix.length;
  final prefix = sanitized.substring(0, prefixLength);
  return '$prefix$_providerErrorTruncationSuffix';
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

  final data = dataUrlPayload(media.url);
  if (data == null) {
    throw GenkitException(
      'Chat Completions media inputs require a data URL for files and audio.',
      status: .INVALID_ARGUMENT,
    );
  }
  if (contentType.startsWith('audio/')) {
    final format = audioFormat(contentType, 'Chat Completions');

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

const _dataUrlPrefix = 'data:';

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

List<Map<String, dynamic>>? _toolsToJson(
  List<ToolDefinition>? tools, {
  required ToolSamplingPolicy policy,
  required bool providerSupportsStrict,
  required ModelCapabilities? modelCapabilities,
}) {
  if (tools == null) return null;
  if (tools.isEmpty || policy == ToolSamplingPolicy.off) {
    return tools.map(_toolToJson).toList();
  }
  if (!providerSupportsStrict) {
    if (policy == ToolSamplingPolicy.require) {
      throw const ToolSamplingValidationException(
        reason: ToolSamplingValidationReason.unsupportedProvider,
        detail: 'The selected provider does not support strict tool sampling.',
      );
    }
    return tools.map(_toolToJson).toList();
  }
  if (modelCapabilities?.supportsStrictToolSampling != true) {
    if (policy == ToolSamplingPolicy.require) {
      throw const ToolSamplingValidationException(
        reason: ToolSamplingValidationReason.unsupportedModel,
        detail: 'The selected model does not support strict tool sampling.',
      );
    }
    return tools.map(_toolToJson).toList();
  }

  return tools.map((tool) {
    final issue = _strictSchemaIssue(tool.inputSchema);
    if (issue == null) return _toolToJson(tool, strict: true);
    if (policy == ToolSamplingPolicy.require) {
      throw ToolSamplingValidationException(
        reason: ToolSamplingValidationReason.incompatibleSchema,
        detail: issue,
        toolName: tool.name,
      );
    }
    return _toolToJson(tool);
  }).toList();
}

Map<String, dynamic> _toolToJson(ToolDefinition tool, {bool strict = false}) {
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
      if (strict) 'strict': true,
    },
  };
}

String? _strictSchemaIssue(Map<String, dynamic>? schema) {
  if (schema == null) return r'$.type must be "object".';

  return _schemaNodeIssue(schema, r'$', root: true);
}

String? _schemaNodeIssue(
  Map<String, dynamic> schema,
  String path, {
  bool root = false,
}) {
  final type = _schemaType(schema['type']);
  if (type == null) {
    return '$path.type must name one supported type, optionally with null.';
  }
  if (root && (type.name != 'object' || type.nullable)) {
    return r'$.type must be "object".';
  }

  return switch (type.name) {
    'object' => _objectSchemaIssue(schema, path),
    'array' => _arraySchemaIssue(schema, path),
    _ => null,
  };
}

({String name, bool nullable})? _schemaType(Object? value) {
  const supported = {
    'array',
    'boolean',
    'integer',
    'null',
    'number',
    'object',
    'string',
  };
  if (value is String && supported.contains(value)) {
    return (name: value, nullable: false);
  }
  if (value is! List || value.length != 2 || !value.contains('null')) {
    return null;
  }
  final names = value.whereType<String>().toSet();
  if (names.length != 2 || names.length != value.length) return null;
  final name = names.singleWhere((name) => name != 'null');
  if (!supported.contains(name)) return null;

  return (name: name, nullable: true);
}

String? _objectSchemaIssue(Map<String, dynamic> schema, String path) {
  final properties = _stringMap(schema['properties']);
  if (properties == null) return '$path.properties must be an object.';
  if (schema['additionalProperties'] != false) {
    return '$path.additionalProperties must be false.';
  }
  final required = schema['required'];
  if (required is! List || !required.every((name) => name is String)) {
    return '$path.required must list every property.';
  }
  final requiredNames = required.cast<String>().toSet();
  if (requiredNames.length != required.length ||
      requiredNames.length != properties.length ||
      !requiredNames.containsAll(properties.keys)) {
    return '$path.required must list every property exactly once.';
  }

  for (final entry in properties.entries) {
    final child = _stringMap(entry.value);
    if (child == null) return '$path.properties.${entry.key} must be a schema.';
    final issue = _schemaNodeIssue(child, '$path.properties.${entry.key}');
    if (issue != null) return issue;
  }
  return null;
}

String? _arraySchemaIssue(Map<String, dynamic> schema, String path) {
  final items = _stringMap(schema['items']);
  if (items == null) return '$path.items must be a schema.';

  return _schemaNodeIssue(items, '$path.items');
}

Map<String, dynamic>? _stringMap(Object? value) {
  if (value is! Map || !value.keys.every((key) => key is String)) return null;
  return Map<String, dynamic>.from(value);
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

  return Message(role: .model, content: parts);
}

ToolRequestPart _toolRequestFromToolCall(sdk.ToolCall toolCall) {
  final arguments = toolCall.function.arguments;

  return ToolRequestPart(
    toolRequest: .new(
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
