import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  group('providerSafeToolCallId', () {
    test('preserves valid provider IDs unchanged', () {
      const providerId = '019fe8fe-bea6-739f-b5d7-79077b42c3d1';

      expect(providerSafeToolCallId(providerId), providerId);
    });

    test('aliases invalid and oversized IDs deterministically', () {
      final longA = List.filled(80, 'a').join();
      final first = providerSafeToolCallId('skill context:$longA');
      final repeated = providerSafeToolCallId('skill context:$longA');
      final second = providerSafeToolCallId(
        'skill context:${longA.substring(1)}b',
      );

      expect(first, repeated);
      expect(first, isNot(second));
      expect(first, matches(RegExp(r'^[A-Za-z0-9_-]{1,64}$')));
      expect(first.length, lessThanOrEqualTo(64));
    });

    test('uses the same alias for tool call and result', () {
      final originalId = 'user tool:${List.filled(80, 'x').join()}';
      final result = providerToolExchangeMessages(
        [
          ProviderToolCallRecord(
            id: originalId,
            name: 'tool',
            arguments: const {'x': 1},
          ),
        ],
        resultsByCallId: {originalId: 'ok'},
      );

      final requestId =
          ((result.first['tool_calls']! as List).single
              as Map<String, Object?>)['id'];
      final responseId = result.last['tool_call_id'];

      expect(requestId, responseId);
      expect((requestId! as String).length, lessThanOrEqualTo(64));
    });
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
