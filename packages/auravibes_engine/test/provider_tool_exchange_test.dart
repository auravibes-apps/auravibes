import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('sanitizes IDs and preserves exchange order', () {
    expect(providerSafeToolCallId('a b'), 'tool_61_20_62');
    expect(
      providerSafeToolCallId('a b'),
      isNot(providerSafeToolCallId('a_x20_b')),
    );
    final result = providerToolExchangeMessages(
      [
        const ProviderToolCallRecord(
          id: 'a b',
          name: 'tool',
          arguments: {'x': 1},
        ),
      ],
      resultsByCallId: const {'a b': 'ok'},
    );
    expect(result.map((item) => item['role']), ['assistant', 'tool']);
    expect(
      chatFinishReason(hasToolCalls: true, providerValue: 'stop'),
      ChatFinishReason.toolCalls,
    );
  });

  test('normalizes completion values without transport concerns', () {
    final result = normalizeCompletionResult(
      hasToolCalls: false,
      providerFinishReason: 'length',
      promptTokens: 2,
      responseTokens: 3,
      totalTokens: 5,
    );
    expect(result.finishReason, ChatFinishReason.length);
    expect(result.usage?.totalTokens, 5);
  });
}
