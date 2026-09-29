import 'dart:async';

import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const RecordModelUsageUsecase({
  required final ModelUsageRepository repository,
  required final Future<ApiModelEntity?> Function(
    String providerId,
    String modelId,
  )
  getModel,
}) {
  Stream<ChatResult<ChatMessage>> trackRequest({
    required String conversationId,
    required String providerId,
    required String modelId,
    required ModelUsageRequestKind requestKind,
    required Stream<ChatResult<ChatMessage>> stream,
  }) {
    LanguageModelUsage? usage;
    Future<void>? recordFuture;
    var cancelled = false;

    Future<void> recordRequest(ModelUsageRequestOutcome outcome) =>
        recordFuture ??= _recordRequest(
          conversationId: conversationId,
          providerId: providerId,
          modelId: modelId,
          requestKind: requestKind,
          outcome: outcome,
          usage: usage,
        );

    return Stream<ChatResult<ChatMessage>>.multi((controller) {
      Future<void> forwardError(Object error, StackTrace stackTrace) async {
        await recordRequest(.failed);
        if (cancelled || controller.isClosed) return;
        controller.addError(error, stackTrace);
        final _ = await controller.close();
      }

      Future<void> closeAfterSuccess() async {
        await recordRequest(.succeeded);
        if (!cancelled && !controller.isClosed) {
          final _ = await controller.close();
        }
      }

      final sourceSubscription = stream.listen(
        (result) {
          usage = result.usage ?? usage;
          controller.add(result);
        },
        onError: (Object error, StackTrace stackTrace) =>
            unawaited(forwardError(error, stackTrace)),
        onDone: () => unawaited(closeAfterSuccess()),
        cancelOnError: true,
      );
      controller
        ..onPause = sourceSubscription.pause
        ..onResume = sourceSubscription.resume
        ..onCancel = () async {
          cancelled = true;
          await sourceSubscription.cancel();
          await recordRequest(.failed);
        };
    });
  }

  Future<void> _recordRequest({
    required String conversationId,
    required String providerId,
    required String modelId,
    required ModelUsageRequestKind requestKind,
    required ModelUsageRequestOutcome outcome,
    required LanguageModelUsage? usage,
  }) async {
    ApiModelEntity? model;
    try {
      model = await getModel(providerId, modelId);
    } on Object {
      model = null;
    }

    final (:costStatus, :costUsd) = _calculateCost(usage, model);
    try {
      final _ = await repository.recordRequest(
        .new(
          conversationId: conversationId,
          providerId: providerId,
          modelId: modelId,
          requestKind: requestKind,
          outcome: outcome,
          usage: usage,
          costStatus: costStatus,
          costUsd: costUsd,
        ),
      );
    } on Object {
      // Usage persistence must not fail a model request.
    }
  }

  ({ModelUsageCostStatus costStatus, double? costUsd}) _calculateCost(
    LanguageModelUsage? usage,
    ApiModelEntity? model,
  ) {
    if (usage == null || model == null) {
      return (costStatus: .unknown, costUsd: null);
    }

    final tokenCosts = [
      (tokens: usage.promptTokens, price: model.costInput),
      (tokens: usage.cacheReadInputTokens, price: model.costCacheRead),
      (tokens: usage.cacheCreationInputTokens, price: model.costCacheWrite),
      (tokens: usage.responseTokens, price: model.costOutput),
    ];
    var cost = 0.0;
    for (final (:tokens, :price) in tokenCosts) {
      if (tokens == null || tokens < 0) {
        return (costStatus: .unknown, costUsd: null);
      }
      if (tokens == 0) continue;
      if (price == null || price < 0) {
        return (costStatus: .unknown, costUsd: null);
      }
      cost += tokens * price / 1000000;
    }

    return (costStatus: .known, costUsd: cost);
  }
}
