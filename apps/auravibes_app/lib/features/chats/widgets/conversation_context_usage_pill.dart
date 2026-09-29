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
    final locale = Localizations.localeOf(context);

    return Padding(
      padding: EdgeInsets.only(right: context.auraTheme.fromSpacing(.sm)),
      child: AuraTooltip(
        message: _tooltip(data, locale),
        child: _ConversationContextUsageSemantics(
          data: data,
          locale: locale,
          semanticValue: _semanticValue(data, locale),
        ),
      ),
    );
  }
}

class const _ConversationContextUsageSemantics({
  required final ContextUsageData data,
  required final Locale locale,
  required final String semanticValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Semantics(
      child: _ConversationContextUsageContainer(
        data: data,
        locale: locale,
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
  required final Locale locale,
  required final Color outlineColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraContainer(
    child: _ConversationContextUsageRow(data: data, locale: locale),
    padding: const AuraEdgeInsetsGeometry.symmetric(
      horizontal: .sm,
      vertical: .xs,
    ),
    variant: .surfaceVariant,
    borderRadius: context.auraTheme.fromBorderRadius(.full),
    border: .fromBorderSide(.new(color: outlineColor)),
  );
}

class const _ConversationContextUsageRow({
  required final ContextUsageData data,
  required final Locale locale,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        _ConversationContextUsageIcon(data: data),
        if (data.hasLimit) _ConversationContextUsageProgress(data: data),
        _ConversationContextUsageLabels(data: data, locale: locale),
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
  required final Locale locale,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => data.hasLimit
      ? _LimitedContextUsageLabels(data: data, locale: locale)
      : _UnavailableContextUsageLabel(data: data, locale: locale);
}

class const _UnavailableContextUsageLabel({
  required final ContextUsageData data,
  required final Locale locale,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_context_usage_label_unavailable
          .tr(namedArgs: {'used': data.usageLabelFor(locale)}),
    ),
    style: .caption,
  );
}

class const _LimitedContextUsageLabels({
  required final ContextUsageData data,
  required final Locale locale,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      AuraText(child: Text(data.usageLabelFor(locale)), style: .caption),
      AuraBadge.text(
        child: Text(data.percentLabelFor(locale)),
        variant: data.level.badgeVariant,
        size: .small,
      ),
    ],
    spacing: .xs,
    mainAxisSize: .min,
  );
}

String _tooltip(ContextUsageData data, Locale locale) {
  if (!data.hasLimit) return _contextUsageLimitUnavailable();

  final tooltipArgs = data.tooltipArgsFor(locale);

  return switch (data.level) {
    .overflow => _overflowTooltip(data, tooltipArgs, locale),
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
  Locale locale,
) => LocaleKeys.chats_screens_chat_conversation_context_usage_tooltip_overflow
    .tr(namedArgs: {...tooltipArgs, 'overflow': data.overflowCountFor(locale)});

String _semanticValue(ContextUsageData data, Locale locale) {
  if (!data.hasLimit) {
    return _semanticLimitUnavailable(data.usageLabelFor(locale));
  }

  return switch (data.level) {
    .overflow => _overflowSemanticValue(data, locale),
    .unknown => _semanticLimitUnavailable(data.usageLabelFor(locale)),
    _ => _standardSemanticValue(data.level, data, locale),
  };
}

String _semanticLimitUnavailable(String usage) => LocaleKeys
    .chats_screens_chat_conversation_context_usage_semantic_limit_unavailable
    .tr(namedArgs: {'usage': usage});

String _standardSemanticValue(
  ContextUsageLevel level,
  ContextUsageData data,
  Locale locale,
) {
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

  if (key == null) {
    return _semanticLimitUnavailable(data.usageLabelFor(locale));
  }

  return key.tr(
    namedArgs: {
      'usage': data.usageLabelFor(locale),
      'percent': data.percentValueFor(locale),
    },
  );
}

String _overflowSemanticValue(ContextUsageData data, Locale locale) =>
    LocaleKeys.chats_screens_chat_conversation_context_usage_semantic_overflow
        .tr(
          namedArgs: {
            'usage': data.usageLabelFor(locale),
            'percent': data.percentValueFor(locale),
            'overflow': data.overflowCountFor(locale),
          },
        );
