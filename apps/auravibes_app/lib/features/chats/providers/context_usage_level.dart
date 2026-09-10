// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'context_usage_level.g.dart';

const _elevatedUsageRatio = 0.7;
const _warningUsageRatio = 0.85;
const _minimumUsagePercent = 0;
const _maximumUsagePercent = 100;

@riverpod
ContextUsageData contextUsage(
  Ref ref,
  String workspaceId,
  String conversationId,
) {
  final usedTokens = ref.watch(
    conversationUsedTokensProvider(workspaceId, conversationId),
  );
  final limitTokens = ref
      .watch(conversationContextLimitProvider(workspaceId, conversationId))
      .value;

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
  unknown;

  static ContextUsageLevel fromUsage({
    required int usedTokens,
    required int limitTokens,
  }) {
    if (usedTokens > limitTokens) return ContextUsageLevel.overflow;
    final ratio = limitTokens > 0 ? usedTokens / limitTokens : 0.0;
    if (ratio >= _warningUsageRatio) return ContextUsageLevel.warning;
    if (ratio >= _elevatedUsageRatio) return ContextUsageLevel.elevated;

    return ContextUsageLevel.normal;
  }

  AuraBadgeVariant get badgeVariant => switch (this) {
    .normal => AuraBadgeVariant.success,
    .elevated => AuraBadgeVariant.info,
    .warning => AuraBadgeVariant.warning,
    .overflow => AuraBadgeVariant.error,
    .unknown => AuraBadgeVariant.neutral,
  };

  IconData get icon => switch (this) {
    .normal => Icons.check_circle_outline,
    .elevated => Icons.info_outline,
    .warning => Icons.warning_amber_outlined,
    .overflow => Icons.priority_high,
    .unknown => Icons.help_outline,
  };

  AuraTint? get iconTint => switch (this) {
    .normal => AuraTint.success,
    .elevated => AuraTint.info,
    .warning => AuraTint.warning,
    .overflow => AuraTint.error,
    .unknown => null,
  };
}

class const ContextUsageData({
  required final int usedTokens,
  required final int normalizedLimit,
  required final bool hasLimit,
  required final int percent,
  required final double progress,
  required final ContextUsageLevel level,
  required final int overflowTokens,
  required final String usageLabel,
  required final String percentLabel,
}) {
  factory compute({required int usedTokens, required int? limitTokens}) {
    final normalizedLimit = _normalizeLimit(limitTokens);
    if (normalizedLimit == 0) {
      return _withoutLimit(usedTokens, normalizedLimit);
    }

    return _withLimit(usedTokens, normalizedLimit);
  }

  Map<String, String> tooltipArgs() => {
    'used': '$usedTokens',
    'limit': '$normalizedLimit',
    'percent': '$percent',
  };
}

int _normalizeLimit(int? limitTokens) {
  final limit = limitTokens ?? 0;
  return limit < 0 ? 0 : limit;
}

ContextUsageData _withoutLimit(int usedTokens, int normalizedLimit) =>
    ContextUsageData(
      usedTokens: usedTokens,
      normalizedLimit: normalizedLimit,
      hasLimit: false,
      percent: 0,
      progress: 0,
      level: .unknown,
      overflowTokens: 0,
      usageLabel: '${_compactFormat.format(usedTokens)}/--',
      percentLabel: '--',
    );

ContextUsageData _withLimit(int usedTokens, int normalizedLimit) {
  final percent = ((usedTokens / normalizedLimit) * 100).round();
  return _limitedUsageData(usedTokens, normalizedLimit, percent);
}

ContextUsageData _limitedUsageData(
  int usedTokens,
  int normalizedLimit,
  int percent,
) {
  return ContextUsageData(
    usedTokens: usedTokens,
    normalizedLimit: normalizedLimit,
    hasLimit: true,
    percent: percent,
    progress:
        percent.clamp(_minimumUsagePercent, _maximumUsagePercent) /
        _maximumUsagePercent,
    level: _usageLevel(usedTokens, normalizedLimit),
    overflowTokens: usedTokens - normalizedLimit,
    usageLabel:
        '${_compactFormat.format(usedTokens)}/${_compactFormat.format(normalizedLimit)}',
    percentLabel: '$percent%',
  );
}

ContextUsageLevel _usageLevel(int usedTokens, int normalizedLimit) =>
    ContextUsageLevel.fromUsage(
      usedTokens: usedTokens,
      limitTokens: normalizedLimit,
    );

// Ponytail. Top-level compact format; default locale follows Intl.systemLocale.
// Upgrade path. Thread the app locale through a provider if the device locale
// differs from the app locale.
final NumberFormat _compactFormat = .compact();
