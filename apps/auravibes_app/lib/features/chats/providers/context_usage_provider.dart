import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'context_usage_provider.g.dart';

@Riverpod(
  dependencies: [conversationUsedTokens, conversationContextLimit],
)
ContextUsageData contextUsage(Ref ref) {
  final usedTokens = ref.watch(conversationUsedTokensProvider);
  final limitTokens = ref.watch(conversationContextLimitProvider).value;
  return ContextUsageData.compute(
    usedTokens: usedTokens,
    limitTokens: limitTokens,
  );
}

enum ContextUsageLevel {
  normal,
  elevated,
  warning,
  overflow,
  unknown
  ;

  static ContextUsageLevel fromUsage({
    required int usedTokens,
    required int limitTokens,
  }) {
    if (usedTokens > limitTokens) return ContextUsageLevel.overflow;
    final ratio = limitTokens > 0 ? usedTokens / limitTokens : 0.0;
    if (ratio >= 0.85) return ContextUsageLevel.warning;
    if (ratio >= 0.70) return ContextUsageLevel.elevated;
    return ContextUsageLevel.normal;
  }

  AuraBadgeVariant get badgeVariant => switch (this) {
    ContextUsageLevel.normal => AuraBadgeVariant.success,
    ContextUsageLevel.elevated => AuraBadgeVariant.info,
    ContextUsageLevel.warning => AuraBadgeVariant.warning,
    ContextUsageLevel.overflow => AuraBadgeVariant.error,
    ContextUsageLevel.unknown => AuraBadgeVariant.neutral,
  };

  IconData get icon => switch (this) {
    ContextUsageLevel.normal => Icons.check_circle_outline,
    ContextUsageLevel.elevated => Icons.info_outline,
    ContextUsageLevel.warning => Icons.warning_amber_outlined,
    ContextUsageLevel.overflow => Icons.priority_high,
    ContextUsageLevel.unknown => Icons.help_outline,
  };

  AuraColorVariant get iconColor => switch (this) {
    ContextUsageLevel.normal => AuraColorVariant.success,
    ContextUsageLevel.elevated => AuraColorVariant.info,
    ContextUsageLevel.warning => AuraColorVariant.warning,
    ContextUsageLevel.overflow => AuraColorVariant.error,
    ContextUsageLevel.unknown => AuraColorVariant.onSurfaceVariant,
  };
}

class ContextUsageData {
  const ContextUsageData({
    required this.usedTokens,
    required this.normalizedLimit,
    required this.hasLimit,
    required this.percent,
    required this.progress,
    required this.level,
    required this.overflowTokens,
    required this.usageLabel,
    required this.percentLabel,
  });

  factory ContextUsageData.compute({
    required int usedTokens,
    required int? limitTokens,
  }) {
    final normalizedLimit = (limitTokens ?? 0) < 0 ? 0 : (limitTokens ?? 0);
    final hasLimit = normalizedLimit > 0;
    final percent = hasLimit
        ? ((usedTokens / normalizedLimit) * 100).round()
        : 0;
    final progress = percent.clamp(0, 100) / 100;

    final usageLabel = hasLimit
        ? '${_formatCompactTokens(usedTokens)}/${_formatCompactTokens(normalizedLimit)}'
        : '${_formatCompactTokens(usedTokens)}/--';

    if (!hasLimit) {
      return ContextUsageData(
        usedTokens: usedTokens,
        normalizedLimit: normalizedLimit,
        hasLimit: false,
        percent: 0,
        progress: 0,
        level: ContextUsageLevel.unknown,
        overflowTokens: 0,
        usageLabel: usageLabel,
        percentLabel: '--',
      );
    }

    final level = ContextUsageLevel.fromUsage(
      usedTokens: usedTokens,
      limitTokens: normalizedLimit,
    );
    final overflowTokens = usedTokens - normalizedLimit;

    return ContextUsageData(
      usedTokens: usedTokens,
      normalizedLimit: normalizedLimit,
      hasLimit: true,
      percent: percent,
      progress: progress,
      level: level,
      overflowTokens: overflowTokens,
      usageLabel: usageLabel,
      percentLabel: '$percent%',
    );
  }

  final int usedTokens;
  final int normalizedLimit;
  final bool hasLimit;
  final int percent;
  final double progress;
  final ContextUsageLevel level;
  final int overflowTokens;
  final String usageLabel;
  final String percentLabel;

  Map<String, String> tooltipArgs() => {
    'used': '$usedTokens',
    'limit': '$normalizedLimit',
    'percent': '$percent',
  };

  Color progressColor(AuraColorScheme colors) => switch (level) {
    ContextUsageLevel.normal => colors.success,
    ContextUsageLevel.elevated => colors.info,
    ContextUsageLevel.warning => colors.warning,
    ContextUsageLevel.overflow => colors.error,
    ContextUsageLevel.unknown => colors.onSurfaceVariant,
  };
}

String _formatCompactTokens(int value) {
  if (value >= 1000000) {
    final formatted = value % 1000000 == 0
        ? (value / 1000000).toStringAsFixed(0)
        : (value / 1000000).toStringAsFixed(1);
    return '${formatted}m';
  }

  if (value >= 1000) {
    final k = value / 1000;
    final formatted = value % 1000 == 0
        ? k.toStringAsFixed(0)
        : k.toStringAsFixed(1);
    final roundedK = double.tryParse(formatted);
    if (roundedK != null && roundedK >= 1000) {
      final m = roundedK / 1000;
      final mFormatted = m.truncateToDouble() == m
          ? m.toStringAsFixed(0)
          : m.toStringAsFixed(1);
      return '${mFormatted}m';
    }
    return '${formatted}k';
  }

  return '$value';
}
