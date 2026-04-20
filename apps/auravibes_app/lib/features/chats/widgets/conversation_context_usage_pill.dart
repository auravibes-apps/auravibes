import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConversationContextUsagePill extends HookConsumerWidget {
  const ConversationContextUsagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usedTokens = ref.watch(conversationUsedTokensProvider);
    final contextLimitAsync = ref.watch(conversationContextLimitProvider);
    final viewModel = useMemoized(() {
      return switch (contextLimitAsync) {
        AsyncData(:final value) => _ContextUsageViewModel.fromUsage(
          usedTokens: usedTokens,
          limitTokens: value,
        ),
        AsyncLoading() ||
        AsyncError() => _ContextUsageViewModel.limitUnavailable(usedTokens),
      };
    }, [usedTokens, contextLimitAsync]);
    final auraColors = context.auraColors;

    return Padding(
      padding: const EdgeInsets.only(right: DesignSpacing.sm),
      child: AuraTooltip(
        message: viewModel.tooltip,
        child: Semantics(
          label: LocaleKeys.chats_screens_chat_conversation_context_usage_label
              .tr(),
          value: viewModel.semanticValue,
          container: true,
          excludeSemantics: true,
          child: AuraContainer(
            padding: const AuraEdgeInsetsGeometry.symmetric(
              horizontal: AuraSpacing.sm,
              vertical: AuraSpacing.xs,
            ),
            borderRadius: context.auraTheme.borderRadius.full,
            backgroundColor: AuraColorVariant.surfaceVariant,
            border: Border.all(color: auraColors.outlineVariant),
            child: AuraRow(
              mainAxisSize: MainAxisSize.min,
              spacing: AuraSpacing.xs,
              children: [
                AuraIcon(
                  viewModel.icon,
                  size: AuraIconSize.extraSmall,
                  color: viewModel.iconColor,
                ),
                SizedBox(
                  width: 26,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      DesignBorderRadius.full,
                    ),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: viewModel.progress.clamp(0.0, 1.0),
                      color: viewModel.progressColor(auraColors),
                      backgroundColor: auraColors.onSurfaceVariant.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                ),
                AuraText(
                  style: AuraTextStyle.caption,
                  color: AuraColorVariant.onSurfaceVariant,
                  child: Text(viewModel.usageLabel),
                ),
                AuraBadge.text(
                  size: AuraBadgeSize.small,
                  variant: viewModel.badgeVariant,
                  child: Text(viewModel.percentLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextUsageViewModel {
  const _ContextUsageViewModel({
    required this.usageLabel,
    required this.percentLabel,
    required this.tooltip,
    required this.semanticValue,
    required this.badgeVariant,
    required this.icon,
    required this.iconColor,
    required this.level,
    required this.progress,
  });

  factory _ContextUsageViewModel.fromUsage({
    required int usedTokens,
    required int? limitTokens,
  }) {
    final normalizedLimit = (limitTokens ?? 0) < 0 ? 0 : (limitTokens ?? 0);
    final hasLimit = normalizedLimit > 0;
    final percent = hasLimit
        ? ((usedTokens / normalizedLimit) * 100).round()
        : 0;
    final progress = percent.clamp(0, 100) / 100;

    const _s = LocaleKeys
        // ignore: lines_longer_than_80_chars - generated LocaleKeys name
        .chats_screens_chat_conversation_context_usage_semantic_limit_unavailable;
    final usageLabel = hasLimit
        ? '${_formatCompactTokens(usedTokens)}/${_formatCompactTokens(normalizedLimit)}'
        : '${_formatCompactTokens(usedTokens)}/--';

    if (!hasLimit) {
      return _ContextUsageViewModel(
        usageLabel: usageLabel,
        percentLabel: '--',
        tooltip: LocaleKeys
            .chats_screens_chat_conversation_context_usage_limit_unavailable
            .tr(),
        semanticValue: _s.tr(
          namedArgs: {'usage': usageLabel},
        ),
        badgeVariant: AuraBadgeVariant.neutral,
        icon: Icons.help_outline,
        iconColor: AuraColorVariant.onSurfaceVariant,
        level: _ContextUsageLevel.unknown,
        progress: 0,
      );
    }

    final level = _ContextUsageLevel.fromPercent(percent);
    final overflowTokens = usedTokens - normalizedLimit;
    final tooltip = switch (level) {
      _ContextUsageLevel.normal =>
        LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_normal
            .tr(
              namedArgs: _tooltipArgs(
                usedTokens: usedTokens,
                limitTokens: normalizedLimit,
                percent: percent,
              ),
            ),
      _ContextUsageLevel.elevated =>
        LocaleKeys
            .chats_screens_chat_conversation_context_usage_tooltip_elevated
            .tr(
              namedArgs: _tooltipArgs(
                usedTokens: usedTokens,
                limitTokens: normalizedLimit,
                percent: percent,
              ),
            ),
      _ContextUsageLevel.warning =>
        LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_warning
            .tr(
              namedArgs: _tooltipArgs(
                usedTokens: usedTokens,
                limitTokens: normalizedLimit,
                percent: percent,
              ),
            ),
      _ContextUsageLevel.overflow =>
        LocaleKeys
            .chats_screens_chat_conversation_context_usage_tooltip_overflow
            .tr(
              namedArgs: {
                ..._tooltipArgs(
                  usedTokens: usedTokens,
                  limitTokens: normalizedLimit,
                  percent: percent,
                ),
                'overflow': '$overflowTokens',
              },
            ),
      _ContextUsageLevel.unknown =>
        LocaleKeys
            .chats_screens_chat_conversation_context_usage_limit_unavailable
            .tr(),
    };

    final semanticValue = switch (level) {
      _ContextUsageLevel.normal =>
        LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_normal
            .tr(
              namedArgs: {
                'usage': usageLabel,
                'percent': '$percent',
              },
            ),
      _ContextUsageLevel.elevated =>
        LocaleKeys
            .chats_screens_chat_conversation_context_usage_semantic_elevated
            .tr(
              namedArgs: {
                'usage': usageLabel,
                'percent': '$percent',
              },
            ),
      _ContextUsageLevel.warning =>
        LocaleKeys
            .chats_screens_chat_conversation_context_usage_semantic_warning
            .tr(
              namedArgs: {
                'usage': usageLabel,
                'percent': '$percent',
              },
            ),
      _ContextUsageLevel.overflow =>
        LocaleKeys
            .chats_screens_chat_conversation_context_usage_semantic_overflow
            .tr(
              namedArgs: {
                'usage': usageLabel,
                'percent': '$percent',
                'overflow': '$overflowTokens',
              },
            ),
      _ContextUsageLevel.unknown => _s.tr(
        namedArgs: {'usage': usageLabel},
      ),
    };

    return _ContextUsageViewModel(
      usageLabel: usageLabel,
      percentLabel: '$percent%',
      tooltip: tooltip,
      semanticValue: semanticValue,
      badgeVariant: level.badgeVariant,
      icon: level.icon,
      iconColor: level.iconColor,
      level: level,
      progress: progress,
    );
  }

  factory _ContextUsageViewModel.limitUnavailable(int usedTokens) {
    final usageLabel = '${_formatCompactTokens(usedTokens)}/--';
    const semanticLimitUnavailable = LocaleKeys
        // ignore: lines_longer_than_80_chars - generated LocaleKeys name
        .chats_screens_chat_conversation_context_usage_semantic_limit_unavailable;

    return _ContextUsageViewModel(
      usageLabel: usageLabel,
      percentLabel: '--',
      tooltip: LocaleKeys
          .chats_screens_chat_conversation_context_usage_limit_unavailable
          .tr(),
      semanticValue: semanticLimitUnavailable.tr(
        namedArgs: {'usage': usageLabel},
      ),
      badgeVariant: AuraBadgeVariant.neutral,
      icon: Icons.help_outline,
      iconColor: AuraColorVariant.onSurfaceVariant,
      level: _ContextUsageLevel.unknown,
      progress: 0,
    );
  }

  final String usageLabel;
  final String percentLabel;
  final String tooltip;
  final String semanticValue;
  final AuraBadgeVariant badgeVariant;
  final IconData icon;
  final AuraColorVariant iconColor;
  final _ContextUsageLevel level;
  final double progress;

  Color progressColor(AuraColorScheme colors) {
    return switch (level) {
      _ContextUsageLevel.normal => colors.success,
      _ContextUsageLevel.elevated => colors.info,
      _ContextUsageLevel.warning => colors.warning,
      _ContextUsageLevel.overflow => colors.error,
      _ContextUsageLevel.unknown => colors.onSurfaceVariant,
    };
  }
}

Map<String, String> _tooltipArgs({
  required int usedTokens,
  required int limitTokens,
  required int percent,
}) {
  return {
    'used': '$usedTokens',
    'limit': '$limitTokens',
    'percent': '$percent',
  };
}

enum _ContextUsageLevel {
  normal,
  elevated,
  warning,
  overflow,
  unknown
  ;

  static _ContextUsageLevel fromPercent(int percent) {
    if (percent > 100) return _ContextUsageLevel.overflow;
    if (percent >= 85) return _ContextUsageLevel.warning;
    if (percent >= 70) return _ContextUsageLevel.elevated;
    return _ContextUsageLevel.normal;
  }

  AuraBadgeVariant get badgeVariant {
    return switch (this) {
      _ContextUsageLevel.normal => AuraBadgeVariant.success,
      _ContextUsageLevel.elevated => AuraBadgeVariant.info,
      _ContextUsageLevel.warning => AuraBadgeVariant.warning,
      _ContextUsageLevel.overflow => AuraBadgeVariant.error,
      _ContextUsageLevel.unknown => AuraBadgeVariant.neutral,
    };
  }

  IconData get icon {
    return switch (this) {
      _ContextUsageLevel.normal => Icons.check_circle_outline,
      _ContextUsageLevel.elevated => Icons.info_outline,
      _ContextUsageLevel.warning => Icons.warning_amber_outlined,
      _ContextUsageLevel.overflow => Icons.priority_high,
      _ContextUsageLevel.unknown => Icons.help_outline,
    };
  }

  AuraColorVariant get iconColor {
    return switch (this) {
      _ContextUsageLevel.normal => AuraColorVariant.success,
      _ContextUsageLevel.elevated => AuraColorVariant.info,
      _ContextUsageLevel.warning => AuraColorVariant.warning,
      _ContextUsageLevel.overflow => AuraColorVariant.error,
      _ContextUsageLevel.unknown => AuraColorVariant.onSurfaceVariant,
    };
  }
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
