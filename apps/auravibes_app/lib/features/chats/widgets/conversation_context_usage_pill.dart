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

    return _ConversationContextUsagePillView(data: data);
  }
}

class const _ConversationContextUsagePillView({
  required final ContextUsageData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.auraTheme.fromSpacing(.sm)),
      child: AuraTooltip(
        message: _tooltip(data),
        child: _ConversationContextUsageSemantics(
          data: data,
          semanticValue: _semanticValue(data),
        ),
      ),
    );
  }
}

class const _ConversationContextUsageSemantics({
  required final ContextUsageData data,
  required final String semanticValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Semantics(
      child: _ConversationContextUsageContainer(
        data: data,
        outlineColor: auraColors.outlineVariant,
      ),
      container: true,
      excludeSemantics: true,
      label: LocaleKeys.chats_screens_chat_conversation_context_usage_label
          .tr(),
      value: semanticValue,
    );
  }
}

class const _ConversationContextUsageContainer({
  required final ContextUsageData data,
  required final Color outlineColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraContainer(
    child: _ConversationContextUsageRow(data: data),
    padding: const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .sm,
      vertical: .xs,
    ),
    variant: .surfaceVariant,
    borderRadius: context.auraTheme.fromBorderRadius(.full),
    border: .fromBorderSide(.new(color: outlineColor)),
  );
}

class const _ConversationContextUsageRow({required final ContextUsageData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        _ConversationContextUsageIcon(data: data),
        _ConversationContextUsageProgress(data: data),
        _ConversationContextUsageLabels(data: data),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    );
  }
}

class const _ConversationContextUsageIcon({
  required final ContextUsageData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraIcon(data.level.icon, size: .extraSmall, tint: data.level.iconTint);
}

class const _ConversationContextUsageProgress({
  required final ContextUsageData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    child: AuraLinearProgressIndicator(
      value: data.progress,
      tint: data.level.iconTint ?? AuraTint.primary,
      backgroundAlpha: 0.25,
    ),
  );
}

class const _ConversationContextUsageLabels({
  required final ContextUsageData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      AuraText(child: Text(data.usageLabel), style: .caption),
      AuraBadge.text(
        child: Text(data.percentLabel),
        variant: data.level.badgeVariant,
        size: .small,
      ),
    ],
    spacing: .xs,
    mainAxisSize: .min,
  );
}

String _tooltip(ContextUsageData data) {
  if (!data.hasLimit) return _contextUsageLimitUnavailable();

  final tooltipArgs = data.tooltipArgs();

  return switch (data.level) {
    .overflow => _overflowTooltip(data, tooltipArgs),
    .unknown => _contextUsageLimitUnavailable(),
    _ => _standardTooltip(data.level, tooltipArgs),
  };
}

String _contextUsageLimitUnavailable() => LocaleKeys
    .chats_screens_chat_conversation_context_usage_limit_unavailable
    .tr();

String _standardTooltip(
  ContextUsageLevel level,
  Map<String, String> tooltipArgs,
) {
  final key = switch (level) {
    .normal =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_normal,
    .elevated =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_elevated,
    .warning =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_warning,
    _ =>
      LocaleKeys
          .chats_screens_chat_conversation_context_usage_limit_unavailable,
  };

  return key.tr(namedArgs: tooltipArgs);
}

String _overflowTooltip(
  ContextUsageData data,
  Map<String, String> tooltipArgs,
) => LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_overflow
    .tr(namedArgs: {...tooltipArgs, 'overflow': '${data.overflowTokens}'});

String _semanticValue(ContextUsageData data) {
  if (!data.hasLimit) return _semanticLimitUnavailable(data.usageLabel);

  return switch (data.level) {
    .overflow => _overflowSemanticValue(data),
    .unknown => _semanticLimitUnavailable(data.usageLabel),
    _ => _standardSemanticValue(data.level, data),
  };
}

String _semanticLimitUnavailable(String usage) => LocaleKeys
    .chats_screens_chat_conversation_context_usage_semantic_limit_unavailable
    .tr(namedArgs: {'usage': usage});

String _standardSemanticValue(ContextUsageLevel level, ContextUsageData data) {
  final key = switch (level) {
    .normal =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_normal,
    .elevated =>
      LocaleKeys
          .chats_screens_chat_conversation_context_usage_semantic_elevated,
    .warning =>
      LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_warning,
    .overflow || .unknown => null,
  };

  if (key == null) return _semanticLimitUnavailable(data.usageLabel);

  return key.tr(
    namedArgs: {'usage': data.usageLabel, 'percent': '${data.percent}'},
  );
}

String _overflowSemanticValue(ContextUsageData data) => LocaleKeys
    .chats_screens_chat_conversation_context_usage_semantic_overflow
    .tr(
      namedArgs: {
        'usage': data.usageLabel,
        'percent': '${data.percent}',
        'overflow': '${data.overflowTokens}',
      },
    );
