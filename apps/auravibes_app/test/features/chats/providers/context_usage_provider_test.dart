import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContextUsageLevel', () {
    group('fromUsage', () {
      test('returns normal when ratio < 0.70', () {
        expect(
          ContextUsageLevel.fromUsage(usedTokens: 10, limitTokens: 100),
          ContextUsageLevel.normal,
        );
      });

      test('returns elevated when ratio >= 0.70', () {
        expect(
          ContextUsageLevel.fromUsage(usedTokens: 70, limitTokens: 100),
          ContextUsageLevel.elevated,
        );
      });

      test('returns warning when ratio >= 0.85', () {
        expect(
          ContextUsageLevel.fromUsage(usedTokens: 85, limitTokens: 100),
          ContextUsageLevel.warning,
        );
      });

      test('returns overflow when usedTokens > limitTokens', () {
        expect(
          ContextUsageLevel.fromUsage(usedTokens: 101, limitTokens: 100),
          ContextUsageLevel.overflow,
        );
      });

      test('returns overflow when usedTokens > limitTokens at 0', () {
        expect(
          ContextUsageLevel.fromUsage(usedTokens: 10, limitTokens: 0),
          ContextUsageLevel.overflow,
        );
      });

      test('returns normal when both are 0', () {
        expect(
          ContextUsageLevel.fromUsage(usedTokens: 0, limitTokens: 0),
          ContextUsageLevel.normal,
        );
      });
    });

    group('badgeVariant', () {
      test('maps each level to expected variant', () {
        expect(ContextUsageLevel.normal.badgeVariant.name, 'success');
        expect(ContextUsageLevel.elevated.badgeVariant.name, 'info');
        expect(ContextUsageLevel.warning.badgeVariant.name, 'warning');
        expect(ContextUsageLevel.overflow.badgeVariant.name, 'error');
        expect(ContextUsageLevel.unknown.badgeVariant.name, 'neutral');
      });
    });

    group('icon', () {
      test('returns non-null IconData for each level', () {
        for (final level in ContextUsageLevel.values) {
          expect(level.icon, isNotNull);
        }
      });
    });

    group('iconTint', () {
      test('maps each level to expected tint', () {
        expect(ContextUsageLevel.normal.iconTint?.name, 'success');
        expect(ContextUsageLevel.elevated.iconTint?.name, 'info');
        expect(ContextUsageLevel.warning.iconTint?.name, 'warning');
        expect(ContextUsageLevel.overflow.iconTint?.name, 'error');
        expect(ContextUsageLevel.unknown.iconTint, isNull);
      });
    });
  });

  group('ContextUsageData', () {
    group('compute', () {
      test('returns unknown level when no limit', () {
        final data = ContextUsageData.compute(
          usedTokens: 500,
          limitTokens: null,
        );
        expect(data.level, ContextUsageLevel.unknown);
        expect(data.hasLimit, isFalse);
        expect(data.percent, 0);
        expect(data.progress, 0);
        expect(data.overflowTokens, 0);
        expect(data.usageLabel, '500/--');
        expect(data.percentLabel, '--');
      });

      test('returns unknown level when limit is 0', () {
        final data = ContextUsageData.compute(
          usedTokens: 500,
          limitTokens: 0,
        );
        expect(data.level, ContextUsageLevel.unknown);
        expect(data.hasLimit, isFalse);
      });

      test('returns unknown level when limit is negative', () {
        final data = ContextUsageData.compute(
          usedTokens: 500,
          limitTokens: -1,
        );
        expect(data.level, ContextUsageLevel.unknown);
        expect(data.hasLimit, isFalse);
        expect(data.normalizedLimit, 0);
      });

      test('computes normal usage correctly', () {
        final data = ContextUsageData.compute(
          usedTokens: 50,
          limitTokens: 100,
        );
        expect(data.level, ContextUsageLevel.normal);
        expect(data.hasLimit, isTrue);
        expect(data.percent, 50);
        expect(data.progress, 0.5);
        expect(data.overflowTokens, -50);
        expect(data.usageLabel, '50/100');
        expect(data.percentLabel, '50%');
      });

      test('computes elevated usage correctly', () {
        final data = ContextUsageData.compute(
          usedTokens: 7500,
          limitTokens: 10000,
        );
        expect(data.level, ContextUsageLevel.elevated);
        expect(data.percent, 75);
        expect(data.progress, 0.75);
      });

      test('computes warning usage correctly', () {
        final data = ContextUsageData.compute(
          usedTokens: 8500,
          limitTokens: 10000,
        );
        expect(data.level, ContextUsageLevel.warning);
        expect(data.percent, 85);
      });

      test('computes overflow correctly', () {
        final data = ContextUsageData.compute(
          usedTokens: 11000,
          limitTokens: 10000,
        );
        expect(data.level, ContextUsageLevel.overflow);
        expect(data.overflowTokens, 1000);
        expect(data.progress, 1.0);
      });

      test('clamps progress to 1.0 when percent exceeds 100', () {
        final data = ContextUsageData.compute(
          usedTokens: 20000,
          limitTokens: 10000,
        );
        expect(data.progress, 1.0);
      });

      test('tooltipArgs returns expected values', () {
        final data = ContextUsageData.compute(
          usedTokens: 500,
          limitTokens: 1000,
        );
        expect(data.tooltipArgs(), {
          'used': '500',
          'limit': '1000',
          'percent': '50',
        });
      });

      test('formats compact tokens for thousands', () {
        final data = ContextUsageData.compute(
          usedTokens: 1500,
          limitTokens: 10000,
        );
        expect(data.usageLabel, contains('K'));
      });

      test('formats compact tokens for millions', () {
        final data = ContextUsageData.compute(
          usedTokens: 1500000,
          limitTokens: 2000000,
        );
        expect(data.usageLabel, contains('M'));
      });

      test('formats compact tokens for exact thousands', () {
        final data = ContextUsageData.compute(
          usedTokens: 1000,
          limitTokens: 10000,
        );
        expect(data.usageLabel, '1K/10K');
      });

      test('formats compact tokens for exact millions', () {
        final data = ContextUsageData.compute(
          usedTokens: 1000000,
          limitTokens: 2000000,
        );
        expect(data.usageLabel, '1M/2M');
      });

      test('formats compact tokens for values under 1000', () {
        final data = ContextUsageData.compute(
          usedTokens: 999,
          limitTokens: 999,
        );
        expect(data.usageLabel, '999/999');
      });
    });
  });
}
