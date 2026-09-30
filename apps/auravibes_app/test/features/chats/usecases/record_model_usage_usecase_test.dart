import 'dart:async';

import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_record_input.dart';
import 'package:auravibes_app/features/chats/usecases/record_model_usage_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModelUsageRepository extends Mock implements ModelUsageRepository;

class _Fixture {
  factory() {
    final repository = MockModelUsageRepository();

    return _Fixture._(
      repository,
      .new(repository: repository, getModel: (_, _) async => _pricedModel()),
    );
  }

  new _(this.repository, this.usecase);

  final MockModelUsageRepository repository;
  final RecordModelUsageUsecase usecase;

  ModelUsageRecordInput get recordedInput =>
      verify(() => repository.recordRequest(captureAny())).captured.single
          as ModelUsageRecordInput;

  void setUp() {
    registerFallbackValue(
      const ModelUsageRecordInput(
        conversationId: '',
        providerId: '',
        modelId: '',
        requestKind: .generation,
        outcome: .succeeded,
        usage: null,
        costStatus: .unknown,
      ),
    );
    when(() => repository.recordRequest(any())).thenAnswer((invocation) async {
      final input =
          invocation.positionalArguments.single as ModelUsageRecordInput;

      return .new(
        id: 'usage-1',
        conversationId: input.conversationId,
        providerId: input.providerId,
        modelId: input.modelId,
        requestKind: input.requestKind,
        outcome: input.outcome,
        usage: input.usage,
        costStatus: input.costStatus,
        costUsd: input.costUsd,
        createdAt: DateTime.utc(2026),
      );
    });
  }
}

void main() {
  final fixture = _Fixture();

  setUp(fixture.setUp);

  test('records complete usage and calculates all four token prices', () async {
    const usage = LanguageModelUsage(
      promptTokens: 1000000,
      responseTokens: 500000,
      cacheReadInputTokens: 250000,
      cacheCreationInputTokens: 125000,
    );

    await fixture.usecase
        .trackRequest(
          conversationId: 'conv-1',
          providerId: 'anthropic',
          modelId: 'model-1',
          requestKind: .generation,
          stream: .value(
            .new(output: ChatMessage.model('reply'), usage: usage),
          ),
        )
        .drain<void>();

    final input = fixture.recordedInput;
    expect(input.outcome, ModelUsageRequestOutcome.succeeded);
    expect(input.usage, usage);
    expect(input.costStatus, ModelUsageCostStatus.known);
    expect(input.costUsd, 5.25);
  });

  test('leaves cost unknown when a cache count is absent', () async {
    await fixture.usecase
        .trackRequest(
          conversationId: 'conv-1',
          providerId: 'anthropic',
          modelId: 'model-1',
          requestKind: .cacheWarm,
          stream: .value(
            const .new(
              output: .new(role: .model),
              usage: .new(
                promptTokens: 1,
                responseTokens: 1,
                cacheReadInputTokens: 0,
              ),
            ),
          ),
        )
        .drain<void>();

    final input = fixture.recordedInput;
    expect(input.requestKind, ModelUsageRequestKind.cacheWarm);
    expect(input.usage?.cacheCreationInputTokens, isNull);
    expect(input.costStatus, ModelUsageCostStatus.unknown);
    expect(input.costUsd, isNull);
  });

  test(
    'leaves cost unknown when positive usage has no matching price',
    () async {
      final usecase = RecordModelUsageUsecase(
        repository: fixture.repository,
        getModel: (_, _) async => _pricedModel(costCacheWrite: null),
      );

      await usecase
          .trackRequest(
            conversationId: 'conv-1',
            providerId: 'anthropic',
            modelId: 'model-1',
            requestKind: .generation,
            stream: .value(
              const .new(
                output: .new(role: .model),
                usage: .new(
                  promptTokens: 0,
                  responseTokens: 0,
                  cacheReadInputTokens: 0,
                  cacheCreationInputTokens: 1,
                ),
              ),
            ),
          )
          .drain<void>();

      final input = fixture.recordedInput;
      expect(input.costStatus, ModelUsageCostStatus.unknown);
      expect(input.costUsd, isNull);
    },
  );

  test('records failed compaction requests with unknown cost', () async {
    final stream = fixture.usecase.trackRequest(
      conversationId: 'conv-1',
      providerId: 'anthropic',
      modelId: 'model-1',
      requestKind: .compaction,
      stream: .error(StateError('provider failed')),
    );

    await expectLater(stream, emitsError(isA<StateError>()));

    final input = fixture.recordedInput;
    expect(input.requestKind, ModelUsageRequestKind.compaction);
    expect(input.outcome, ModelUsageRequestOutcome.failed);
    expect(input.usage, isNull);
    expect(input.costStatus, ModelUsageCostStatus.unknown);
  });

  test(
    'records canceled streams as failed without waiting for provider done',
    () async {
      final controller = StreamController<ChatResult<ChatMessage>>();
      final subscription = fixture.usecase
          .trackRequest(
            conversationId: 'conv-1',
            providerId: 'anthropic',
            modelId: 'model-1',
            requestKind: .generation,
            stream: controller.stream,
          )
          .listen(null);
      await Future<void>.delayed(.zero);

      final _ = await subscription.cancel().timeout(const .new(seconds: 2));

      final input = fixture.recordedInput;
      expect(input.outcome, ModelUsageRequestOutcome.failed);
      final _ = await controller.close();
    },
  );
}

ApiModelEntity _pricedModel({
  double? costInput = 2,
  double? costOutput = 4,
  double? costCacheRead = 1,
  double? costCacheWrite = 8,
}) => .new(
  modelProvider: 'anthropic',
  id: 'model-1',
  name: 'Test',
  limitContext: 1000,
  limitOutput: 1000,
  modalitiesInput: const ['text'],
  modalitiesOutput: const ['text'],
  costInput: costInput,
  costOutput: costOutput,
  costCacheRead: costCacheRead,
  costCacheWrite: costCacheWrite,
);
