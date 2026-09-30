import 'dart:convert';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as sdk;
import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_exception.dart';
import 'package:genkit/genkit.dart';

abstract final class AnthropicMessageCodec {
  static sdk.InputMessage encode(Message message) => sdk.InputMessage(
    role: message.role == Role.model
        ? sdk.MessageRole.assistant
        : sdk.MessageRole.user,
    content: .blocks(message.content.expand(_inputParts).toList()),
  );

  static Message decode(sdk.Message message) => Message(
    role: .model,
    content: message.content.expand(_outputParts).toList(),
    metadata: {
      'cacheReadInputTokens': ?message.usage.cacheReadInputTokens,
      'cacheCreationInputTokens': ?message.usage.cacheCreationInputTokens,
    },
  );
}

Iterable<sdk.InputContentBlock> _inputParts(Part part) {
  if (part.text case final text?) return [sdk.TextInputBlock(text)];
  if (part.toolRequest case final request?) return [_toolRequest(request)];
  if (part.toolResponse case final response?) return [_toolResponse(response)];
  if (part.media case final media?) return [_mediaBlock(media)];

  return _reasoningParts(part);
}

sdk.InputContentBlock _toolRequest(ToolRequest request) =>
    sdk.InputContentBlock.toolUse(
      id: request.ref ?? '',
      name: request.name,
      input: (request.input as Map?)?.cast<String, Object?>() ?? {},
    );
sdk.InputContentBlock _toolResponse(ToolResponse response) =>
    sdk.InputContentBlock.toolResult(
      toolUseId: response.ref ?? '',
      content: _toolResultContent(response),
    );

Iterable<sdk.InputContentBlock> _reasoningParts(Part part) {
  final redacted = part.custom?['redactedThinking'];
  if (redacted is String) {
    return [sdk.RedactedThinkingInputBlock(data: redacted)];
  }
  final signature = _signature(part);
  if (signature == null) return const [];
  final reasoning = part.reasoning;
  if (reasoning == null) return const [];

  return [sdk.ThinkingInputBlock(thinking: reasoning, signature: signature)];
}

sdk.InputContentBlock _mediaBlock(Media media) {
  if (media.url.startsWith('data:')) return _dataMediaBlock(media.url);

  return media.contentType == 'application/pdf'
      ? sdk.InputContentBlock.document(.url(media.url))
      : sdk.InputContentBlock.image(.url(media.url));
}

sdk.InputContentBlock _dataMediaBlock(String url) {
  final data = Uri.tryParse(url)?.data;
  if (data == null || !data.isBase64) {
    throw const AnthropicRequestException('invalid_media');
  }
  if (data.mimeType == 'application/pdf') {
    return sdk.InputContentBlock.document(.base64Pdf(data.contentText));
  }

  return sdk.InputContentBlock.image(
    .fromJson({
      'type': 'base64',
      'media_type': data.mimeType,
      'data': data.contentText,
    }),
  );
}

Iterable<Part> _outputParts(sdk.ContentBlock block) {
  if (block case sdk.TextBlock(:final text)) return [TextPart(text: text)];
  if (block case sdk.ToolUseBlock(:final id, :final name, :final input)) {
    return [
      ToolRequestPart(
        toolRequest: .new(ref: id, name: name, input: input),
      ),
    ];
  }
  if (block is sdk.ThinkingBlock) return [_thinkingOutput(block)];
  if (block case sdk.RedactedThinkingBlock(:final data)) {
    return [
      CustomPart(custom: {'redactedThinking': data}),
    ];
  }

  return const [];
}

List<sdk.ToolResultContent> _toolResultContent(ToolResponse response) => [
  sdk.ToolResultContent.text(jsonEncode(response.output)),
  for (final raw in response.content ?? <Object?>[])
    ..._toolResultImages(_toolResultPart(raw)),
];

Iterable<sdk.ToolResultContent> _toolResultImages(Part part) {
  final media = part.media;
  if (media == null || !media.url.startsWith('data:')) return const [];
  final block = _mediaBlock(media);
  if (block is! sdk.ImageInputBlock) return const [];

  return [sdk.ToolResultContent.fromJson(block.toJson())];
}

Part _toolResultPart(Object? raw) {
  if (raw is! Map) {
    throw const AnthropicRequestException('invalid_tool_content');
  }

  return .fromJson(raw.cast<String, Object?>());
}

Part _thinkingOutput(sdk.ThinkingBlock block) => ReasoningPart(
  metadata: {'thoughtSignature': block.signature},
  reasoning: block.thinking,
);

String? _signature(Part part) {
  final value =
      part.metadata?['thoughtSignature'] ?? part.metadata?['signature'];

  return value is String && value.isNotEmpty ? value : null;
}
