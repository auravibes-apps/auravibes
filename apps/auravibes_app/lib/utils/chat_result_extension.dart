import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:dartantic_ai/dartantic_ai.dart';

extension ChatResultConcat on ChatResult<ChatMessage> {
  ChatResult<ChatMessage> concat(ChatResult<ChatMessage> delta) {
    return ChatResult<ChatMessage>(
      output: output.concatenate(delta.output),
      finishReason: delta.finishReason != FinishReason.unspecified
          ? delta.finishReason
          : finishReason,
      usage: usage != null && delta.usage != null
          ? usage!.concat(delta.usage!)
          : delta.usage ?? usage,
      messages: [...messages, ...delta.messages],
      metadata: {...metadata, ...delta.metadata},
    );
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

  MessageMetadataEntity? get entityMetadata {
    final hasUsage =
        usage?.promptTokens != null ||
        usage?.responseTokens != null ||
        usage?.totalTokens != null;

    if (entityTools.isEmpty && !hasUsage) {
      return null;
    }

    return MessageMetadataEntity(
      toolCalls: entityTools,
      promptTokens: usage?.promptTokens,
      completionTokens: usage?.responseTokens,
      totalTokens: usage?.totalTokens,
    );
  }
}
