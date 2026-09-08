import 'dart:convert';

import 'package:auravibes_engine/src/chat_result.dart';
import 'package:auravibes_engine/src/tool_spec.dart';
import 'package:crypto/crypto.dart';

class const CompletionRequest({
  required final List<Map<String, Object?>> messages,
  final List<ToolSpec> tools = const [],
  final bool stream = true,
});

class const CompletionResult({
  required final ChatFinishReason finishReason,
  final LanguageModelUsage? usage,
  final Map<String, Object?> metadata = const {},
});

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

class const ProviderToolCallRecord({
  required final String id,
  required final String name,
  required final Map<String, Object?> arguments,
});

final _providerToolCallIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

String providerSafeToolCallId(String? value) {
  final raw = value ?? '';
  if (_providerToolCallIdPattern.hasMatch(raw)) return raw;

  final digest = sha256.convert(utf8.encode(raw)).bytes.take(16).toList();
  final alias = base64Url.encode(digest).replaceAll('=', '');
  return 'tool_$alias';
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
