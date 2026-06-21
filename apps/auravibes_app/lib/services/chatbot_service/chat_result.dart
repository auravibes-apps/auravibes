// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genkit/genkit.dart';

part 'chat_result.freezed.dart';

@freezed
abstract class ChatResult<T> with _$ChatResult<T> {
  const factory ChatResult({
    required T output,
    @Default(FinishReason.unspecified) FinishReason finishReason,
    LanguageModelUsage? usage,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
    String? thinking,
  }) = _ChatResult<T>;
}

enum ChatMessageRole { system, user, model, tool }

class ChatMessageToolCall {
  ChatMessageToolCall(this.request);
  final ToolRequest request;
  String get callId => request.ref ?? '';
  String get toolName => request.name;
  String get argumentsRaw => jsonEncode(request.input);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required ChatMessageRole role,
    @Default('') String content,
    @Default(<Part>[]) List<Part> parts,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _ChatMessage;

  const ChatMessage._();

  factory ChatMessage.user(String content, {List<Part> parts = const []}) =>
      ChatMessage(role: ChatMessageRole.user, content: content, parts: parts);

  factory ChatMessage.system(String content, {List<Part> parts = const []}) =>
      ChatMessage(role: ChatMessageRole.system, content: content, parts: parts);

  factory ChatMessage.model(
    String content, {
    List<Part> parts = const [],
    Map<String, dynamic> metadata = const {},
  }) => ChatMessage(
    role: ChatMessageRole.model,
    content: content,
    parts: parts,
    metadata: metadata,
  );

  List<ChatMessageToolCall> get toolCalls => parts
      .whereType<ToolRequestPart>()
      .map((p) => ChatMessageToolCall(p.toolRequest))
      .toList();
  String get text => content.isNotEmpty
      ? content
      : parts.whereType<TextPart>().map((p) => p.text).join();

  ChatMessage concatenate(ChatMessage delta) {
    final newContent = content + delta.content;
    final newParts = [...parts, ...delta.parts];
    final newMetadata = {...metadata, ...delta.metadata};

    return ChatMessage(
      role: role,
      content: newContent,
      parts: newParts,
      metadata: newMetadata,
    );
  }
}

enum FinishReason {
  stop,
  length,
  toolCalls,
  interrupted,
  contentFilter,
  other,
  unspecified,
}

@freezed
abstract class LanguageModelUsage with _$LanguageModelUsage {
  const factory LanguageModelUsage({
    int? promptTokens,
    int? responseTokens,
    int? totalTokens,
  }) = _LanguageModelUsage;

  const LanguageModelUsage._();

  LanguageModelUsage concat(LanguageModelUsage other) {
    return LanguageModelUsage(
      promptTokens: _add(promptTokens, other.promptTokens),
      responseTokens: _add(responseTokens, other.responseTokens),
      totalTokens: _add(totalTokens, other.totalTokens),
    );
  }

  static int? _add(int? a, int? b) {
    if (a == null && b == null) return null;

    return (a ?? 0) + (b ?? 0);
  }
}

extension ChatResultConcat on ChatResult<ChatMessage> {
  ChatResult<ChatMessage> concat(ChatResult<ChatMessage> delta) {
    final outputMetadata = {...output.metadata, ...delta.output.metadata};
    final currentUsage = usage;
    final deltaUsage = delta.usage;
    final combinedUsage = currentUsage != null && deltaUsage != null
        ? currentUsage.concat(deltaUsage)
        : deltaUsage ?? currentUsage;

    return ChatResult<ChatMessage>(
      output: output
          .copyWith(metadata: outputMetadata)
          .concatenate(delta.output.copyWith(metadata: outputMetadata)),
      finishReason: delta.finishReason != FinishReason.unspecified
          ? delta.finishReason
          : finishReason,
      usage: combinedUsage,
      metadata: {...metadata, ...delta.metadata},
      thinking: _concatThinking(thinking, delta.thinking),
    );
  }

  static String? _concatThinking(String? current, String? delta) {
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

    return chunks.reduce(_joinThinking).trim();
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

String _joinThinking(String current, String delta) {
  final needsSeparator =
      current.trim().isNotEmpty &&
      delta.trim().isNotEmpty &&
      !RegExp(r'\s$').hasMatch(current) &&
      !RegExp(r'^\s').hasMatch(delta);

  return needsSeparator ? '$current $delta' : '$current$delta';
}
