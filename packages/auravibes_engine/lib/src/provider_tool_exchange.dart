import 'dart:convert';

import 'package:auravibes_engine/src/chat_result.dart';
import 'package:auravibes_engine/src/tool_spec.dart';

class CompletionRequest {
  const CompletionRequest({
    required this.messages,
    this.tools = const [],
    this.stream = true,
  });

  final List<Map<String, Object?>> messages;
  final List<ToolSpec> tools;
  final bool stream;
}

class CompletionResult {
  const CompletionResult({
    required this.finishReason,
    this.usage,
    this.metadata = const {},
  });

  final ChatFinishReason finishReason;
  final LanguageModelUsage? usage;
  final Map<String, Object?> metadata;
}

CompletionResult normalizeCompletionResult({
  required bool hasToolCalls,
  required String? providerFinishReason,
  int? promptTokens,
  int? responseTokens,
  int? totalTokens,
  Map<String, Object?> metadata = const {},
}) => CompletionResult(
  finishReason: chatFinishReason(
    hasToolCalls: hasToolCalls,
    providerValue: providerFinishReason,
  ),
  usage: promptTokens == null && responseTokens == null && totalTokens == null
      ? null
      : LanguageModelUsage(
          promptTokens: promptTokens,
          responseTokens: responseTokens,
          totalTokens: totalTokens,
        ),
  metadata: Map.unmodifiable(metadata),
);

class ProviderToolCallRecord {
  const ProviderToolCallRecord({
    required this.id,
    required this.name,
    required this.arguments,
  });
  final String id;
  final String name;
  final Map<String, Object?> arguments;
}

String providerSafeToolCallId(String? value) {
  final raw = value ?? '';
  if (raw.isEmpty) return 'tool_empty';
  final encoded = raw.codeUnits.map((unit) => unit.toRadixString(16)).join('_');
  return 'tool_$encoded';
}

List<Map<String, Object?>> providerToolExchangeMessages(
  Iterable<ProviderToolCallRecord> calls, {
  String? assistantContent,
  Map<String, Object?>? resultsByCallId,
}) {
  final records = calls.toList(growable: false);
  if (records.isEmpty) return const [];
  return [
    {
      'role': 'assistant',
      'content': assistantContent,
      'tool_calls': [
        for (final call in records)
          {
            'id': providerSafeToolCallId(call.id),
            'type': 'function',
            'function': {
              'name': call.name,
              'arguments': jsonEncode(call.arguments),
            },
          },
      ],
    },
    for (final call in records)
      {
        'role': 'tool',
        'tool_call_id': providerSafeToolCallId(call.id),
        'content': resultsByCallId?[call.id] ?? '',
      },
  ];
}

List<Map<String, Object?>> composeProviderRequestMessages({
  required Iterable<Map<String, Object?>> baseMessages,
  Iterable<Map<String, Object?>> toolExchanges = const [],
}) => [...baseMessages, ...toolExchanges];

ChatFinishReason chatFinishReason({
  required bool hasToolCalls,
  required String? providerValue,
}) {
  if (hasToolCalls) return ChatFinishReason.toolCalls;
  return switch (providerValue) {
    null => ChatFinishReason.unspecified,
    'stop' => ChatFinishReason.stop,
    'length' => ChatFinishReason.length,
    'interrupted' => ChatFinishReason.interrupted,
    _ => ChatFinishReason.other,
  };
}
