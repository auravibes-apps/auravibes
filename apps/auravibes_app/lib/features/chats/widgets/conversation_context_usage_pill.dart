import 'package:auravibes_app/features/chats/providers/context_usage_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConversationContextUsagePill extends ConsumerWidget {
  const ConversationContextUsagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(contextUsageProvider);
    final tooltip = _tooltip(data);
    final semanticValue = _semanticValue(data);
    final auraColors = context.auraColors;

    return Padding(
      padding: const EdgeInsets.only(right: DesignSpacing.sm),
      child: AuraTooltip(
        message: tooltip,
        child: Semantics(
          label: LocaleKeys.chats_screens_chat_conversation_context_usage_label
              .tr(),
          value: semanticValue,
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
                  data.level.icon,
                  size: AuraIconSize.extraSmall,
                  color: data.level.iconColor,
                ),
                SizedBox(
                  width: 26,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      DesignBorderRadius.full,
                    ),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: data.progress.clamp(0.0, 1.0),
                      color: data.progressColor(auraColors),
                      backgroundColor: auraColors.onSurfaceVariant.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                ),
                AuraText(
                  style: AuraTextStyle.caption,
                  color: AuraColorVariant.onSurfaceVariant,
                  child: Text(data.usageLabel),
                ),
                AuraBadge.text(
                  size: AuraBadgeSize.small,
                  variant: data.level.badgeVariant,
                  child: Text(data.percentLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _tooltip(ContextUsageData data) {
  if (!data.hasLimit) {
    return LocaleKeys
        .chats_screens_chat_conversation_context_usage_limit_unavailable
        .tr();
  }

  return switch (data.level) {
    ContextUsageLevel.normal =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_normal
          .tr(namedArgs: data.tooltipArgs()),
    ContextUsageLevel.elevated =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_elevated
          .tr(namedArgs: data.tooltipArgs()),
    ContextUsageLevel.warning =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_warning
          .tr(namedArgs: data.tooltipArgs()),
    ContextUsageLevel.overflow =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_overflow
          .tr(
            namedArgs: {
              ...data.tooltipArgs(),
              'overflow': '${data.overflowTokens}',
            },
          ),
    ContextUsageLevel.unknown =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_limit_unavailable
          .tr(),
  };
}

String _semanticValue(ContextUsageData data) {
  const semanticLimitUnavailable = LocaleKeys
      .chats_screens_chat_conversation_context_usage_semantic_limit_unavailable;

  if (!data.hasLimit) {
    return semanticLimitUnavailable.tr(
      namedArgs: {'usage': data.usageLabel},
    );
  }

  return switch (data.level) {
    ContextUsageLevel.normal =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_normal
          .tr(
            namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
          ),
    ContextUsageLevel.elevated =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_elevated
          .tr(
            namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
          ),
    ContextUsageLevel.warning =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_warning
          .tr(
            namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
          ),
    ContextUsageLevel.overflow =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_overflow
          .tr(
            namedArgs: {
              'usage': data.usageLabel,
              'percent': '${data.percent}',
              'overflow': '${data.overflowTokens}',
            },
          ),
    ContextUsageLevel.unknown => semanticLimitUnavailable.tr(
      namedArgs: {'usage': data.usageLabel},
    ),
  };
}
