import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';

extension ChatResultEntities on ChatResult<ChatMessage> {
  List<MessageToolCallEntity> get entityTools {
    final allToolCalls = output.toolCalls;
    if (allToolCalls.isEmpty) return [];

    return allToolCalls
        .map(
          (tc) => MessageToolCallEntity(
            id: tc.callId,
            name: tc.toolName,
            argumentsRaw: tc.argumentsRaw,
          ),
        )
        .toList();
  }

  String get entityText => output.text;

  String? get entityThinking => _entityThinking(this);

  Map<String, dynamic> get entityModelMetadata {
    return <String, dynamic>{...metadata, ...output.metadata}
      ..removeWhere((_, value) => value == null);
  }

  MessageMetadataEntity? get entityMetadata {
    return _toEntityMetadata(this);
  }

  int entityPromptTokens() => usage?.promptTokens ?? 0;

  int entityCompletionTokens() => usage?.responseTokens ?? 0;

  int entityTotalTokens() =>
      usage?.totalTokens ?? (entityPromptTokens() + entityCompletionTokens());
}

MessageMetadataEntity? _toEntityMetadata(ChatResult<ChatMessage> result) {
  final toolCalls = result.entityTools;
  final thinking = result.entityThinking;
  final modelMetadata = result.entityModelMetadata;
  if (!_hasEntityMetadata(toolCalls, thinking, modelMetadata, result)) {
    return null;
  }

  return _newEntityMetadata(
    result,
    toolCalls: toolCalls,
    thinking: thinking,
    modelMetadata: modelMetadata,
  );
}

bool _hasEntityMetadata(
  List<MessageToolCallEntity> toolCalls,
  String? thinking,
  Map<String, dynamic> modelMetadata,
  ChatResult<ChatMessage> result,
) =>
    toolCalls.isNotEmpty ||
    _hasUsage(result) ||
    thinking != null ||
    modelMetadata.isNotEmpty;

MessageMetadataEntity _newEntityMetadata(
  ChatResult<ChatMessage> result, {
  required List<MessageToolCallEntity> toolCalls,
  required String? thinking,
  required Map<String, dynamic> modelMetadata,
}) => MessageMetadataEntity(
  toolCalls: toolCalls,
  promptTokens: result.usage?.promptTokens,
  completionTokens: result.usage?.responseTokens,
  totalTokens: result.usage?.totalTokens,
  thinking: thinking,
  modelMetadata: modelMetadata,
);

bool _hasUsage(ChatResult<ChatMessage> result) =>
    result.usage?.promptTokens != null ||
    result.usage?.responseTokens != null ||
    result.usage?.totalTokens != null;

String? _entityThinking(ChatResult<ChatMessage> result) {
  final chunks = _thinkingChunks(result);
  if (chunks.isEmpty) return null;

  return chunks.reduce(joinThinking).trim();
}

List<String> _thinkingChunks(ChatResult<ChatMessage> result) => [
  ..._resultThinking(result),
  ..._partThinking(result),
];

List<String> _resultThinking(ChatResult<ChatMessage> result) {
  final thinking = result.thinking;
  if (thinking == null || thinking.trim().isEmpty) return [];

  return [thinking];
}

List<String> _partThinking(ChatResult<ChatMessage> result) => [
  if (result.thinking?.trim().isEmpty ?? true)
    for (final part in result.output.parts)
      if (part.reasoning case final reasoning? when reasoning.trim().isNotEmpty)
        reasoning,
];
