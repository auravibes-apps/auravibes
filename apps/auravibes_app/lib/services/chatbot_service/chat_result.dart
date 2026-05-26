import 'dart:convert';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:genkit/genkit.dart';

class ChatResult<T> {
  const ChatResult({
    required this.output,
    this.finishReason = FinishReason.unspecified,
    this.usage,
    this.metadata = const {},
    this.messages = const [],
    this.thinking,
  });

  final T output;
  final FinishReason finishReason;
  final LanguageModelUsage? usage;
  final Map<String, dynamic> metadata;
  final List<dynamic> messages;
  final String? thinking;
}

enum ChatMessageRole { system, user, model, tool }

class ChatMessageToolCall {
  ChatMessageToolCall(this.request);
  final ToolRequest request;
  String get callId => request.ref ?? '';
  String get toolName => request.name;
  dynamic get argumentsRaw => request.input;
}

class ChatMessageToolResult {
  ChatMessageToolResult(this.response);
  final ToolResponse response;
  String get callId => response.ref ?? '';
  dynamic get result => response.output;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    this.content = '',
    this.parts = const [],
    this.metadata = const {},
  });

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

  final ChatMessageRole role;
  final String content;
  final List<Part> parts;
  final Map<String, dynamic> metadata;

  List<ChatMessageToolCall> get toolCalls => parts
      .whereType<ToolRequestPart>()
      .map((p) => ChatMessageToolCall(p.toolRequest))
      .toList();
  List<ChatMessageToolResult> get toolResults => parts
      .whereType<ToolResponsePart>()
      .map((p) => ChatMessageToolResult(p.toolResponse))
      .toList();
  String get text => content.isNotEmpty
      ? content
      : parts.whereType<TextPart>().map((p) => p.text).join();

  // Required: allow copyWith to be called without passing metadata parameter
  // ignore: unnecessary-nullable
  ChatMessage copyWith({
    ChatMessageRole? role,
    String? content,
    List<Part>? parts,
    // ignore: unnecessary-nullable
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      parts: parts ?? this.parts,
      metadata: metadata ?? this.metadata,
    );
  }

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
  contentFilter,
  other,
  unspecified,
}

class LanguageModelUsage {
  const LanguageModelUsage({
    this.promptTokens,
    this.responseTokens,
    this.totalTokens,
  });

  final int? promptTokens;
  final int? responseTokens;
  final int? totalTokens;

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
      metadata: {...metadata, ...delta.metadata},
      messages: [...messages, ...delta.messages],
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
            argumentsRaw: tc.argumentsRaw is String
                ? tc.argumentsRaw as String
                : jsonEncode(tc.argumentsRaw),
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
      for (final part in output.parts.whereType<ReasoningPart>())
        if (part.reasoning.trim().isNotEmpty) part.reasoning,
      for (final message in messages)
        if (message is ChatMessage)
          for (final part in message.parts.whereType<ReasoningPart>())
            if (part.reasoning.trim().isNotEmpty) part.reasoning,
    ];

    if (chunks.isEmpty) return null;
    return chunks.reduce(_joinThinking).trim();
  }

  Map<String, Object?> get entityModelMetadata {
    return <String, Object?>{
      ...metadata,
      ...output.metadata,
      for (final message in messages)
        if (message is ChatMessage) ...message.metadata,
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
