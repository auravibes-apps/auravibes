import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/agent_run_replay.dart';

void main() {
  for (final scenario in const [
    'partial-stream-multi-tool',
    'cancellation-after-partial-output',
    'retry-after-explicit-rate-limit',
    'non-retryable-provider-error',
  ]) {
    test('replays $scenario through engine orchestration', () async {
      final fixtures = loadAgentRunReplayFixtures();
      final fixture = fixtures.singleWhere((item) => item.scenario == scenario);
      final actual = await AgentRunReplayHarness(fixture).replay();
      final expectedJson = fixture.expected.toJson();
      final actualJson = actual.toJson();

      expect(
        actualJson,
        expectedJson,
        reason: _divergenceReason(fixture, expectedJson, actualJson),
      );
    });
  }

  test('fixture validation reports scenario and the diverging event', () async {
    const path = 'test/fixtures/agent_run_replay/partial_multi_tool.json';
    final json =
        jsonDecode(await File(path).readAsString()) as Map<String, Object?>;
    final events = (json['events']! as List).cast<Map<String, Object?>>();
    events[1]['unsupported'] = true;

    expect(
      () => AgentRunReplayFixture.fromJson(
        json,
        sourceName: 'partial_multi_tool.json',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('partial-stream-multi-tool'),
            contains('chunk-2'),
            contains('unsupported'),
          ),
        ),
      ),
    );
  });
}

String _divergenceReason(
  AgentRunReplayFixture fixture,
  Map<String, Object?> expected,
  Map<String, Object?> actual,
) {
  for (final field in expected.keys) {
    final expectedValue = expected[field];
    final actualValue = actual[field];
    if (jsonEncode(expectedValue) == jsonEncode(actualValue)) continue;

    if (expectedValue is List && actualValue is List) {
      final index = _firstDifference(expectedValue, actualValue);
      final eventId =
          _eventIdAt(expectedValue, index) ?? _eventIdAt(actualValue, index);
      final location = eventId == null
          ? '$field[$index]'
          : '$field[$index] near "$eventId"';

      return 'Scenario "${fixture.scenario}" diverged at $location.';
    }

    return 'Scenario "${fixture.scenario}" diverged in "$field".';
  }

  return 'Scenario "${fixture.scenario}" diverged.';
}

int _firstDifference(Object? expected, Object? actual) {
  if (expected is List && actual is List) {
    final limit = expected.length < actual.length
        ? expected.length
        : actual.length;
    for (var index = 0; index < limit; index++) {
      if (jsonEncode(expected[index]) != jsonEncode(actual[index])) {
        return index;
      }
    }

    return limit;
  }

  return 0;
}

String? _eventIdAt(Object? value, int index) {
  if (value is List && index < value.length) {
    final item = value[index];
    if (item is Map && item['eventId'] is String) {
      return item['eventId'] as String;
    }
    if (item is Map && item['id'] is String) return item['id'] as String;
    if (item is String) {
      final eventId = item.split(':').last;
      if (eventId.isNotEmpty && !RegExp(r'^\d+$').hasMatch(eventId)) {
        return eventId;
      }
    }
  }

  return null;
}
