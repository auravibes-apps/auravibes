// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([contextUsage])
class ConversationContextUsagePill extends ConsumerWidget {
  const ConversationContextUsagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(contextUsageProvider);
    final tooltip = _tooltip(data);
    final semanticValue = _semanticValue(data);
    final auraColors = context.auraColors;

    return Padding(
      padding: EdgeInsets.only(
        right: context.auraTheme.fromSpacing(.sm),
      ),
      child: AuraTooltip(
        message: tooltip,
        child: Semantics(
          child: AuraContainer(
            child: AuraRow(
              children: [
                AuraIcon(
                  data.level.icon,
                  size: AuraIconSize.extraSmall,
                  tint: data.level.iconTint,
                ),
                SizedBox(
                  width: 26,
                  child: AuraLinearProgressIndicator(
                    value: data.progress,
                    tint: data.level.iconTint ?? AuraTint.primary,
                    backgroundAlpha: 0.25,
                  ),
                ),
                AuraText(
                  child: Text(data.usageLabel),
                  style: AuraTextStyle.caption,
                ),
                AuraBadge.text(
                  child: Text(data.percentLabel),
                  variant: data.level.badgeVariant,
                  size: AuraBadgeSize.small,
                ),
              ],
              spacing: .xs,
              mainAxisSize: MainAxisSize.min,
            ),
            padding: const AuraEdgeInsetsGeometry.symmetric(
              horizontal: .sm,
              vertical: .xs,
            ),
            variant: AuraContainerVariant.surfaceVariant,
            borderRadius: context.auraTheme.fromBorderRadius(
              .full,
            ),
            border: Border.fromBorderSide(
              BorderSide(color: auraColors.outlineVariant),
            ),
          ),
          container: true,
          excludeSemantics: true,
          label: LocaleKeys.chats_screens_chat_conversation_context_usage_label
              .tr(),
          value: semanticValue,
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
