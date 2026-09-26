import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses valid model overrides and ignores invalid fields', () {
    final settings = CompactionSettings.fromJson({
      'usagePercentageThreshold': 80,
      'modelOverrides': {
        'provider/model-a': {'reserveTokens': 256, 'keepRecentTokens': -1},
        'provider/model-b': {'reserveTokens': 'bad', 'keepRecentTokens': 512},
      },
    });

    expect(settings.usagePercentageThreshold, 80);
    expect(settings.modelOverrides['provider/model-a']?.reserveTokens, 256);
    expect(
      settings.modelOverrides['provider/model-a']?.keepRecentTokens,
      isNull,
    );
    expect(settings.modelOverrides['provider/model-b']?.reserveTokens, isNull);
    expect(settings.modelOverrides['provider/model-b']?.keepRecentTokens, 512);
  });

  test('round trips model overrides through JSON', () {
    final settings = CompactionSettings.fromJson({
      'modelOverrides': {
        'provider/model': {'reserveTokens': 128, 'keepRecentTokens': 256},
      },
    });

    expect(CompactionSettings.fromJson(settings.toJson()), settings);
  });

  test('malformed override map leaves other settings readable', () {
    final settings = CompactionSettings.fromJson({
      'usagePercentageThreshold': 75,
      'modelOverrides': 'invalid',
    });

    expect(settings.usagePercentageThreshold, 75);
    expect(settings.modelOverrides, isEmpty);
  });
}
