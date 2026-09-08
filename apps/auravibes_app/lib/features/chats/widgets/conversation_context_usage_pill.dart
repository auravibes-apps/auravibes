// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/chats/providers/context_usage_level.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ConversationContextUsagePill({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(contextUsageProvider(workspaceId, conversationId));
    final tooltip = _tooltip(data);
    final semanticValue = _semanticValue(data);
    final auraColors = context.auraColors;

    return Padding(
      padding: EdgeInsets.only(right: context.auraTheme.fromSpacing(.sm)),
      child: AuraTooltip(
        message: tooltip,
        child: Semantics(
          child: AuraContainer(
            child: AuraRow(
              children: [
                AuraIcon(
                  data.level.icon,
                  size: .extraSmall,
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
                AuraText(child: Text(data.usageLabel), style: .caption),
                AuraBadge.text(
                  child: Text(data.percentLabel),
                  variant: data.level.badgeVariant,
                  size: .small,
                ),
              ],
              spacing: .xs,
              mainAxisSize: .min,
            ),
            padding: const AuraEdgeInsetsGeometry.symmetric(
              horizontal: .sm,
              vertical: .xs,
            ),
            variant: .surfaceVariant,
            borderRadius: context.auraTheme.fromBorderRadius(.full),
            border: .fromBorderSide(.new(color: auraColors.outlineVariant)),
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
  final tooltipArgs = data.tooltipArgs();

  return switch (data.level) {
    .normal =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_normal
          .tr(namedArgs: tooltipArgs),
    .elevated =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_elevated
          .tr(namedArgs: tooltipArgs),
    .warning =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_warning
          .tr(namedArgs: tooltipArgs),
    .overflow =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_overflow
          .tr(
            namedArgs: {...tooltipArgs, 'overflow': '${data.overflowTokens}'},
          ),
    .unknown =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_limit_unavailable
          .tr(),
  };
}

String _semanticValue(ContextUsageData data) {
  const semanticLimitUnavailable = LocaleKeys
      .chats_screens_chat_conversation_context_usage_semantic_limit_unavailable;

  if (!data.hasLimit) {
    return semanticLimitUnavailable.tr(namedArgs: {'usage': data.usageLabel});
  }

  return switch (data.level) {
    .normal =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_normal
          .tr(
            namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
          ),
    .elevated =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_elevated
          .tr(
            namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
          ),
    .warning =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_warning
          .tr(
            namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
          ),
    .overflow =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_overflow
          .tr(
            namedArgs: {
              'usage': data.usageLabel,
              'percent': '${data.percent}',
              'overflow': '${data.overflowTokens}',
            },
          ),
    .unknown => semanticLimitUnavailable.tr(
      namedArgs: {'usage': data.usageLabel},
    ),
  };
}
