import 'dart:async';

import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_record_input.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef ModelUsageRequestDetails = ({
  String conversationId,
  String providerId,
  String modelId,
  ModelUsageRequestKind requestKind,
});

class const RecordModelUsageUsecase({
  required final ModelUsageRepository repository,
  required final Future<ApiModelEntity?> Function(
    String providerId,
    String modelId,
  )
  getModel,
}) {
  Stream<ChatResult<ChatMessage>> trackRequest({
    required ModelUsageRequestDetails request,
    required Stream<ChatResult<ChatMessage>> stream,
  }) => Stream<ChatResult<ChatMessage>>.multi(
    _ModelUsageStreamRecorder(
      usecase: this,
      request: request,
      stream: stream,
    ).listen,
  );

  Future<void> _recordRequest(
    ModelUsageRequestDetails request,
    ModelUsageRequestOutcome outcome,
    LanguageModelUsage? usage,
  ) async {
    final model = await _getModel(request);
    final (:costStatus, :costUsd) = _calculateCost(usage, model);
    await _persistRequest(
      .new(
        conversationId: request.conversationId,
        providerId: request.providerId,
        modelId: request.modelId,
        requestKind: request.requestKind,
        outcome: outcome,
        usage: usage,
        costStatus: costStatus,
        costUsd: costUsd,
      ),
    );
  }

  Future<ApiModelEntity?> _getModel(ModelUsageRequestDetails request) async {
    try {
      return await getModel(request.providerId, request.modelId);
    } on Object {
      return null;
    }
  }

  Future<void> _persistRequest(ModelUsageRecordInput request) async {
    try {
      final _ = await repository.recordRequest(request);
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

    final cost = _sumTokenCosts(usage, model);
    if (cost == null) return (costStatus: .unknown, costUsd: null);

    return (costStatus: .known, costUsd: cost);
  }

  double? _sumTokenCosts(LanguageModelUsage usage, ApiModelEntity model) {
    var total = 0.0;
    for (final (:tokens, :price) in _tokenCosts(usage, model)) {
      final tokenCost = _tokenCost(tokens, price);
      if (tokenCost == null) return null;
      total += tokenCost;
    }

    return total;
  }

  List<({int? tokens, double? price})> _tokenCosts(
    LanguageModelUsage usage,
    ApiModelEntity model,
  ) => [
    (tokens: usage.promptTokens, price: model.costInput),
    (tokens: usage.cacheReadInputTokens, price: model.costCacheRead),
    (tokens: usage.cacheCreationInputTokens, price: model.costCacheWrite),
    (tokens: usage.responseTokens, price: model.costOutput),
  ];

  double? _tokenCost(int? tokens, double? price) {
    if (tokens == null || tokens < 0) return null;
    if (tokens == 0) return 0;
    if (price == null || price < 0) return null;

    return tokens * price / 1000000;
  }
}

class _ModelUsageStreamRecorder({
  required final RecordModelUsageUsecase usecase,
  required final ModelUsageRequestDetails request,
  required final Stream<ChatResult<ChatMessage>> stream,
}) {
  LanguageModelUsage? usage;
  Future<void>? recordFuture;
  bool cancelled = false;

  void listen(MultiStreamController<ChatResult<ChatMessage>> controller) {
    _bindController(controller, _listenToStream(controller));
  }

  StreamSubscription<ChatResult<ChatMessage>> _listenToStream(
    MultiStreamController<ChatResult<ChatMessage>> controller,
  ) => stream.listen(
    (result) => _forwardResult(controller, result),
    onError: (Object error, StackTrace stackTrace) =>
        unawaited(_forwardError(controller, error, stackTrace)),
    onDone: () => unawaited(_closeAfterSuccess(controller)),
    cancelOnError: true,
  );

  Future<void> _forwardError(
    MultiStreamController<ChatResult<ChatMessage>> controller,
    Object error,
    StackTrace stackTrace,
  ) async {
    await _recordRequest(.failed);
    if (cancelled || controller.isClosed) return;
    controller.addError(error, stackTrace);
    final _ = await controller.close();
  }

  Future<void> _closeAfterSuccess(
    MultiStreamController<ChatResult<ChatMessage>> controller,
  ) async {
    await _recordRequest(.succeeded);
    if (cancelled || controller.isClosed) return;
    final _ = await controller.close();
  }

  void _forwardResult(
    MultiStreamController<ChatResult<ChatMessage>> controller,
    ChatResult<ChatMessage> result,
  ) {
    usage = result.usage ?? usage;
    controller.add(result);
  }

  void _bindController(
    MultiStreamController<ChatResult<ChatMessage>> controller,
    StreamSubscription<ChatResult<ChatMessage>> subscription,
  ) {
    controller
      ..onPause = subscription.pause
      ..onResume = subscription.resume
      ..onCancel = () => _cancel(subscription);
  }

  Future<void> _cancel(
    StreamSubscription<ChatResult<ChatMessage>> subscription,
  ) async {
    cancelled = true;
    await subscription.cancel();
    await _recordRequest(.failed);
  }

  Future<void> _recordRequest(ModelUsageRequestOutcome outcome) =>
      recordFuture ??= usecase._recordRequest(request, outcome, usage);
}
