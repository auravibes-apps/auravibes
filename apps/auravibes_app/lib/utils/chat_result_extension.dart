import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:dartantic_ai/dartantic_ai.dart';

extension ChatResultConcat on ChatResult<ChatMessage> {
  ChatResult<ChatMessage> concat(ChatResult<ChatMessage> delta) {
    final outputMetadata = {...output.metadata, ...delta.output.metadata};
    return ChatResult<ChatMessage>(
      output: output
          .copyWith(metadata: outputMetadata)
          .concatenate(delta.output.copyWith(metadata: outputMetadata)),
      finishReason: delta.finishReason != FinishReason.unspecified
          ? delta.finishReason
          : finishReason,
      usage: usage != null && delta.usage != null
          ? usage!.concat(delta.usage!)
          : delta.usage ?? usage,
      thinking: _concatThinking(thinking, delta.thinking),
      messages: [...messages, ...delta.messages],
      metadata: {...metadata, ...delta.metadata},
    );
  }

  String? _concatThinking(String? current, String? delta) {
    if (delta == null || delta.isEmpty) return current;
    if (current == null || current.isEmpty) return delta;
    return _joinThinking(current, delta);
  }
}

extension ChatResultEntities on ChatResult<ChatMessage> {
  List<MessageToolCallEntity> get entityTools {
    final allToolCalls = output.toolCalls;
    if (allToolCalls.isEmpty) return [];

    return allToolCalls
        .map(
          (tc) => MessageToolCallEntity(
            argumentsRaw: tc.argumentsRaw,
            id: tc.callId,
            name: tc.toolName,
          ),
        )
        .toList();
  }

  int get entityPromptTokens => usage?.promptTokens ?? 0;

  int get entityCompletionTokens => usage?.responseTokens ?? 0;

  int get entityTotalTokens {
    return usage?.totalTokens ?? (entityPromptTokens + entityCompletionTokens);
  }

  String get entityText => output.text;

  String? get entityThinking {
    final chunks = <String>[
      if (thinking case final value? when value.trim().isNotEmpty) value,
      for (final part in output.parts.whereType<ThinkingPart>())
        if (part.text.trim().isNotEmpty) part.text,
      for (final message in messages)
        for (final part in message.parts.whereType<ThinkingPart>())
          if (part.text.trim().isNotEmpty) part.text,
    ];

    if (chunks.isEmpty) return null;
    return chunks.reduce(_joinThinking).trim();
  }

  Map<String, Object?> get entityModelMetadata {
    final metadata = <String, Object?>{
      ...output.metadata,
      for (final message in messages) ...message.metadata,
    }..removeWhere((_, value) => value == null);
    return metadata;
  }

  MessageMetadataEntity? get entityMetadata {
    final hasUsage =
        usage?.promptTokens != null ||
        usage?.responseTokens != null ||
        usage?.totalTokens != null;

    if (entityTools.isEmpty &&
        !hasUsage &&
        entityThinking == null &&
        entityModelMetadata.isEmpty) {
      return null;
    }

    return MessageMetadataEntity(
      toolCalls: entityTools,
      promptTokens: usage?.promptTokens,
      completionTokens: usage?.responseTokens,
      totalTokens: usage?.totalTokens,
      thinking: entityThinking,
      modelMetadata: entityModelMetadata,
    );
  }
}

String _joinThinking(String current, String delta) {
  final needsSeparator =
      current.trim().isNotEmpty &&
      delta.trim().isNotEmpty &&
      !RegExp(r'\s$').hasMatch(current) &&
      !RegExp(r'^\s').hasMatch(delta);
  return needsSeparator ? '$current $delta' : '$current$delta';
}
