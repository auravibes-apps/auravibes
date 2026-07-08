import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';

export 'package:auravibes_engine/auravibes_engine.dart'
    show
        $ChatMessageCopyWith,
        $ChatResultCopyWith,
        $LanguageModelUsageCopyWith,
        ChatFinishReason,
        ChatMessage,
        ChatMessageRole,
        ChatMessageToolCall,
        ChatResult,
        ChatResultConcat,
        LanguageModelUsage,
        joinThinking;

typedef FinishReason = ChatFinishReason;

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

  int get entityPromptTokens => usage?.promptTokens ?? 0;

  int get entityCompletionTokens => usage?.responseTokens ?? 0;

  int get entityTotalTokens {
    return usage?.totalTokens ?? (entityPromptTokens + entityCompletionTokens);
  }

  String get entityText => output.text;

  String? get entityThinking {
    final resultThinking = thinking?.trim().isNotEmpty ?? false;
    final chunks = <String>[
      if (thinking case final value? when resultThinking) value,
      if (!resultThinking)
        for (final part in output.parts)
          if (part.reasoning case final reasoning?
              when reasoning.trim().isNotEmpty)
            reasoning,
    ];

    if (chunks.isEmpty) return null;

    return chunks.reduce(joinThinking).trim();
  }

  Map<String, dynamic> get entityModelMetadata {
    return <String, dynamic>{
      ...metadata,
      ...output.metadata,
    }..removeWhere((_, value) => value == null);
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
