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
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(
      modelUsageRecordsForConversationProvider(conversationId),
    );
    final totals = ref.watch(
      modelUsageTotalsForConversationProvider(conversationId),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                LocaleKeys.chats_screens_chat_conversation_model_usage_title
                    .tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch ((records: records, totals: totals)) {
                  (
                    records: AsyncData<List<ModelUsageRecord>>(
                      value: final recordValues,
                    ),
                    totals: AsyncData<ModelUsageTotals>(
                      value: final totalValues,
                    ),
                  ) =>
                    _ModelUsageData(records: recordValues, totals: totalValues),
                  (records: AsyncError(), totals: _) ||
                  (
                    records: _,
                    totals: AsyncError(),
                  ) => _ModelUsageLoadError(onRetry: () => _retry(ref)),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(modelUsageRecordsForConversationProvider(conversationId))
      ..invalidate(modelUsageTotalsForConversationProvider(conversationId));
  }
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
        if (records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                LocaleKeys.chats_screens_chat_conversation_model_usage_empty
                    .tr(),
                textAlign: .center,
              ),
            ),
          )
        else
          for (final record in records)
            _ModelUsageRequestCard(record: record, locale: locale),
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
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_request_count
                .tr(),
            value: NumberFormatter.count(totals.requestCount, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_estimated_cost
                .tr(),
            value: _costValue(totals.costStatus, totals.costUsd, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_prompt_tokens
                .tr(),
            value: _tokenValue(totals.promptTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_response_tokens
                .tr(),
            value: _tokenValue(totals.responseTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_total_tokens
                .tr(),
            value: _tokenValue(totals.totalTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_cache_read_tokens
                .tr(),
            value: _tokenValue(totals.cacheReadInputTokens, locale),
          ),
          _ModelUsageMetric(
            label: _cacheCreationTokenLabel(),
            value: _tokenValue(totals.cacheCreationInputTokens, locale),
          ),
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
            _requestKindLabel(record.requestKind),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text('${record.providerId} / ${record.modelId}'),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_outcome
                .tr(),
            value: _requestOutcomeLabel(record.outcome),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_prompt_tokens
                .tr(),
            value: _tokenValue(record.usage?.promptTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_response_tokens
                .tr(),
            value: _tokenValue(record.usage?.responseTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_total_tokens
                .tr(),
            value: _tokenValue(record.usage?.totalTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_cache_read_tokens
                .tr(),
            value: _tokenValue(record.usage?.cacheReadInputTokens, locale),
          ),
          _ModelUsageMetric(
            label: _cacheCreationTokenLabel(),
            value: _tokenValue(record.usage?.cacheCreationInputTokens, locale),
          ),
          _ModelUsageMetric(
            label: LocaleKeys
                .chats_screens_chat_conversation_model_usage_estimated_cost
                .tr(),
            value: _costValue(record.costStatus, record.costUsd, locale),
          ),
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

String _tokenValue(int? value, Locale locale) => value == null
    ? LocaleKeys.chats_screens_chat_conversation_model_usage_unknown.tr()
    : NumberFormatter.count(value, locale);

String _cacheCreationTokenLabel() => LocaleKeys
    .chats_screens_chat_conversation_model_usage_cache_creation_tokens
    .tr();

String _costValue(
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

String _requestKindLabel(ModelUsageRequestKind kind) => switch (kind) {
  .generation =>
    LocaleKeys.chats_screens_chat_conversation_model_usage_kind_generation.tr(),
  .compaction =>
    LocaleKeys.chats_screens_chat_conversation_model_usage_kind_compaction.tr(),
  .cacheWarm =>
    LocaleKeys.chats_screens_chat_conversation_model_usage_kind_cache_warm.tr(),
};

String _requestOutcomeLabel(ModelUsageRequestOutcome outcome) =>
    switch (outcome) {
      .succeeded =>
        LocaleKeys.chats_screens_chat_conversation_model_usage_outcome_succeeded
            .tr(),
      .failed =>
        LocaleKeys.chats_screens_chat_conversation_model_usage_outcome_failed
            .tr(),
    };
