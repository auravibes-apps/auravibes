// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genkit/genkit.dart';

part 'chat_result.freezed.dart';

@freezed
abstract class ChatResult<T> with _$ChatResult<T> {
  const factory({
    required T output,
    @Default(ChatFinishReason.unspecified) ChatFinishReason finishReason,
    LanguageModelUsage? usage,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
    String? thinking,
  }) = _ChatResult<T>;
}

enum ChatMessageRole { system, user, model, tool }

class ChatMessageToolCall(final ToolRequest request) {
  String get callId => request.ref ?? '';

  String get toolName => request.name;

  String get argumentsRaw => jsonEncode(request.input);
}

@freezed
abstract class const ChatMessage._() with _$ChatMessage {
  const factory({
    required ChatMessageRole role,
    @Default('') String content,
    @Default(<Part>[]) List<Part> parts,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _ChatMessage;

  factory user(String content, {List<Part> parts = const []}) =>
      ChatMessage(role: ChatMessageRole.user, content: content, parts: parts);

  factory system(String content, {List<Part> parts = const []}) =>
      ChatMessage(role: ChatMessageRole.system, content: content, parts: parts);

  factory model(
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

enum ChatFinishReason {
  stop,
  length,
  toolCalls,
  interrupted,
  contentFilter,
  other,
  unspecified,
}

@freezed
abstract class const LanguageModelUsage._() with _$LanguageModelUsage {
  const factory({int? promptTokens, int? responseTokens, int? totalTokens}) =
      _LanguageModelUsage;

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
      finishReason: delta.finishReason != ChatFinishReason.unspecified
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

    return joinThinking(current, delta);
  }
}

String joinThinking(String current, String delta) {
  final needsSeparator =
      current.trim().isNotEmpty &&
      delta.trim().isNotEmpty &&
      !RegExp(r'\s$').hasMatch(current) &&
      !RegExp(r'^\s').hasMatch(delta);

  return needsSeparator ? '$current $delta' : '$current$delta';
}
