import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_totals.dart';
import 'package:auravibes_app/features/chats/providers/model_usage_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/number_formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ModelUsageDetailsSheet({
  required final String conversationId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _ModelUsageSheetViewport(conversationId: conversationId);
}

class const _ModelUsageSheetViewport({required final String conversationId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.8,
    child: SafeArea(
      top: false,
      child: _ModelUsageSheetBody(conversationId: conversationId),
    ),
  );
}

class const _ModelUsageSheetBody({required final String conversationId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        const _ModelUsageSheetTitle(),
        const SizedBox(height: 12),
        Expanded(child: _ModelUsageContent(conversationId: conversationId)),
      ],
    ),
  );
}

class const _ModelUsageSheetTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.chats_screens_chat_conversation_model_usage_title.tr(),
    style: Theme.of(context).textTheme.titleLarge,
  );
}

class const _ModelUsageContent({required final String conversationId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(
      modelUsageDetailsForConversationProvider(conversationId),
    );

    return _ModelUsageContentState(usage: usage, onRetry: () => _retry(ref));
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(modelUsageDetailsForConversationProvider(conversationId));
  }
}

class const _ModelUsageContentState({
  required final AsyncValue<ModelUsageConversationDetails> usage,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (usage) {
    AsyncData<ModelUsageConversationDetails>(value: final details) =>
      _ModelUsageData(records: details.records, totals: details.totals),
    AsyncError() => _ModelUsageLoadError(onRetry: onRetry),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _ModelUsageData({
  required final List<ModelUsageRecord> records,
  required final ModelUsageTotals totals,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return ListView(
      children: [
        _ModelUsageSummaryCard(totals: totals, locale: locale),
        const SizedBox(height: 12),
        ..._ModelUsageRequestRows.widgets(records, locale),
      ],
    );
  }
}

class const _ModelUsageSummaryCard({
  required final ModelUsageTotals totals,
  required final Locale locale,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            LocaleKeys.chats_screens_chat_conversation_model_usage_summary.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ..._ModelUsageMetricRows.summary(totals, locale),
        ],
      ),
    ),
  );
}

class const _ModelUsageRequestCard({
  required final ModelUsageRecord record,
  required final Locale locale,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            _ModelUsageValueFormatter.requestKindLabel(record.requestKind),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text('${record.providerId} / ${record.modelId}'),
          ..._ModelUsageMetricRows.request(record, locale),
        ],
      ),
    ),
  );
}

class const _ModelUsageMetric({
  required final String label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: .end)),
      ],
    ),
  );
}

class const _ModelUsageLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      children: [
        Text(
          LocaleKeys.chats_screens_chat_conversation_model_usage_load_error
              .tr(),
          textAlign: .center,
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            LocaleKeys.chats_screens_chat_conversation_model_usage_retry.tr(),
          ),
        ),
      ],
    ),
  );
}

class _ModelUsageRequestRows {
  static List<Widget> widgets(List<ModelUsageRecord> records, Locale locale) =>
      records.isEmpty
      ? [_empty()]
      : [
          for (final record in records)
            _ModelUsageRequestCard(record: record, locale: locale),
        ];

  static Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        LocaleKeys.chats_screens_chat_conversation_model_usage_empty.tr(),
        textAlign: .center,
      ),
    ),
  );
}

class _ModelUsageMetricRows {
  static List<Widget> summary(ModelUsageTotals totals, Locale locale) => [
    _metric(
      LocaleKeys.chats_screens_chat_conversation_model_usage_request_count.tr(),
      NumberFormatter.count(totals.requestCount, locale),
    ),
    _costMetric(totals.costStatus, totals.costUsd, locale),
    ..._promptRows(
      totals.promptTokens,
      totals.responseTokens,
      totals.totalTokens,
      locale,
    ),
    ..._cacheRows(
      totals.cacheReadInputTokens,
      totals.cacheCreationInputTokens,
      locale,
    ),
  ];

  static List<Widget> request(ModelUsageRecord record, Locale locale) => [
    _outcome(record.outcome),
    ..._promptRows(
      record.usage?.promptTokens,
      record.usage?.responseTokens,
      record.usage?.totalTokens,
      locale,
    ),
    ..._cacheRows(
      record.usage?.cacheReadInputTokens,
      record.usage?.cacheCreationInputTokens,
      locale,
    ),
    _costMetric(record.costStatus, record.costUsd, locale),
  ];

  static List<Widget> _promptRows(
    int? prompt,
    int? response,
    int? total,
    Locale locale,
  ) => [
    _tokenMetric(
      LocaleKeys.chats_screens_chat_conversation_model_usage_prompt_tokens.tr(),
      prompt,
      locale,
    ),
    _tokenMetric(
      LocaleKeys.chats_screens_chat_conversation_model_usage_response_tokens
          .tr(),
      response,
      locale,
    ),
    _tokenMetric(
      LocaleKeys.chats_screens_chat_conversation_model_usage_total_tokens.tr(),
      total,
      locale,
    ),
  ];

  static List<Widget> _cacheRows(int? read, int? creation, Locale locale) => [
    _tokenMetric(
      LocaleKeys.chats_screens_chat_conversation_model_usage_cache_read_tokens
          .tr(),
      read,
      locale,
    ),
    _tokenMetric(
      LocaleKeys
          .chats_screens_chat_conversation_model_usage_cache_creation_tokens
          .tr(),
      creation,
      locale,
    ),
  ];

  static Widget _tokenMetric(String label, int? value, Locale locale) =>
      _metric(label, _ModelUsageValueFormatter.tokenValue(value, locale));

  static Widget _costMetric(
    ModelUsageCostStatus status,
    double? costUsd,
    Locale locale,
  ) => _metric(
    LocaleKeys.chats_screens_chat_conversation_model_usage_estimated_cost.tr(),
    _ModelUsageValueFormatter.costValue(status, costUsd, locale),
  );

  static Widget _outcome(ModelUsageRequestOutcome outcome) => _metric(
    LocaleKeys.chats_screens_chat_conversation_model_usage_outcome.tr(),
    _ModelUsageValueFormatter.outcomeLabel(outcome),
  );

  static Widget _metric(String label, String value) =>
      _ModelUsageMetric(label: label, value: value);
}

class _ModelUsageValueFormatter {
  static String tokenValue(int? value, Locale locale) => value == null
      ? LocaleKeys.chats_screens_chat_conversation_model_usage_unknown.tr()
      : NumberFormatter.count(value, locale);

  static String costValue(
    ModelUsageCostStatus status,
    double? costUsd,
    Locale locale,
  ) => status != ModelUsageCostStatus.known || costUsd == null
      ? LocaleKeys.chats_screens_chat_conversation_model_usage_unknown.tr()
      : NumberFormat.currency(
          locale: locale.toLanguageTag(),
          name: 'USD',
          decimalDigits: 6,
        ).format(costUsd);

  static String requestKindLabel(ModelUsageRequestKind kind) => switch (kind) {
    .generation =>
      LocaleKeys.chats_screens_chat_conversation_model_usage_kind_generation
          .tr(),
    .compaction =>
      LocaleKeys.chats_screens_chat_conversation_model_usage_kind_compaction
          .tr(),
    .cacheWarm =>
      LocaleKeys.chats_screens_chat_conversation_model_usage_kind_cache_warm
          .tr(),
  };

  static String outcomeLabel(ModelUsageRequestOutcome outcome) =>
      switch (outcome) {
        .succeeded =>
          LocaleKeys
              .chats_screens_chat_conversation_model_usage_outcome_succeeded
              .tr(),
        .failed =>
          LocaleKeys.chats_screens_chat_conversation_model_usage_outcome_failed
              .tr(),
      };
}
