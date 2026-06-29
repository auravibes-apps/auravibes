import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/maybe_auto_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/should_compact_conversation_usecase.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockWorkspaceModelSelectionsRepository extends Mock
    implements WorkspaceModelSelectionRepository {}

class MockApiModelRepository extends Mock implements ApiModelRepository {}

class MockShouldCompactConversationUsecase extends Mock
    implements ShouldCompactConversationUsecase {}

class MockCompactConversationUsecase extends Mock
    implements CompactConversationUsecase {}

class MaybeAutoCompactFixture {
  MockConversationRepository? _mockConvRepo;
  MockWorkspaceModelSelectionsRepository? _mockModelRepo;
  MockApiModelRepository? _mockApiModelRepo;
  MockShouldCompactConversationUsecase? _mockShouldCompact;
  MockCompactConversationUsecase? _mockCompact;
  MaybeAutoCompactConversationUsecase? _usecase;

  MockConversationRepository get mockConvRepo =>
      _mockConvRepo ?? fail('Conversation repository fixture not initialized.');

  MockWorkspaceModelSelectionsRepository get mockModelRepo =>
      _mockModelRepo ??
      fail('Workspace model selection repository fixture not initialized.');

  MockApiModelRepository get mockApiModelRepo =>
      _mockApiModelRepo ??
      fail('API model repository fixture not initialized.');

  MockShouldCompactConversationUsecase get mockShouldCompact =>
      _mockShouldCompact ??
      fail('Should compact usecase fixture not initialized.');

  MockCompactConversationUsecase get mockCompact =>
      _mockCompact ?? fail('Compact usecase fixture not initialized.');

  MaybeAutoCompactConversationUsecase get usecase =>
      _usecase ?? fail('Usecase fixture not initialized.');

  void setUp() {
    final mockConvRepo = MockConversationRepository();
    final mockModelRepo = MockWorkspaceModelSelectionsRepository();
    final mockApiModelRepo = MockApiModelRepository();
    final mockShouldCompact = MockShouldCompactConversationUsecase();
    final mockCompact = MockCompactConversationUsecase();

    _mockConvRepo = mockConvRepo;
    _mockModelRepo = mockModelRepo;
    _mockApiModelRepo = mockApiModelRepo;
    _mockShouldCompact = mockShouldCompact;
    _mockCompact = mockCompact;
    _usecase = MaybeAutoCompactConversationUsecase(
      conversationRepository: mockConvRepo,
      workspaceModelSelectionsRepository: mockModelRepo,
      apiModelRepository: mockApiModelRepo,
      shouldCompactConversationUsecase: mockShouldCompact,
      compactConversationUsecase: mockCompact,
    );
  }
}

final _modelSelection = WorkspaceModelSelectionEntity(
  id: 'sel-1',
  modelId: 'model-1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  modelConnectionId: 'conn-1',
);

const _provider = ApiModelProviderEntity(
  id: 'provider-1',
  name: 'Test Provider',
  type: ModelProvidersType.openai,
);

final _connection = ModelConnectionEntity(
  id: 'conn-1',
  name: 'Test Conn',
  modelId: 'model-1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  workspaceId: 'ws-1',
  hasKey: true,
);

final _completion = WorkspaceModelSelectionWithConnectionEntity(
  workspaceModelSelection: _modelSelection,
  modelConnection: _connection,
  modelsProvider: _provider,
);

ApiModelEntity _makeModel() => const ApiModelEntity(
  modelProvider: 'provider-1',
  id: 'api-model-1',
  name: 'Test Model',
  limitContext: 128000,
  limitOutput: 4096,
  modalitiesInput: ['text'],
  modalitiesOutput: ['text'],
);

CompactionExecutionState _makeExecState(String id) => CompactionExecutionState(
  conversationId: id,
  trigger: CompactionTrigger.auto,
  startedAt: DateTime(2026),
  status: CompactionExecutionStatus.success,
);

ConversationEntity _makeConv({
  String id = 'conv-1',
  String workspaceId = 'ws-1',
  String? modelId = 'comp-1',
}) {
  return ConversationEntity(
    id: id,
    title: 'Test',
    workspaceId: workspaceId,
    isPinned: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    modelId: modelId,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(CompactionTrigger.auto);
  });

  final fixture = MaybeAutoCompactFixture();

  setUp(fixture.setUp);

  test('exits early when conversation not found', () async {
    when(
      () => fixture.mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => null);

    await expectLater(fixture.usecase(conversationId: 'conv-1'), completes);

    expect(
      () => verifyNever(
        () => fixture.mockCompact(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
        ),
      ),
      returnsNormally,
    );
  });

  test('exits early when conversation has no modelId', () async {
    when(
      () => fixture.mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv(modelId: null));

    await expectLater(fixture.usecase(conversationId: 'conv-1'), completes);

    expect(
      () => verifyNever(
        () => fixture.mockModelRepo.getWorkspaceModelSelectionById(any()),
      ),
      returnsNormally,
    );
  });

  test('exits early when model selection not found', () async {
    when(
      () => fixture.mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => fixture.mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => null);

    await expectLater(fixture.usecase(conversationId: 'conv-1'), completes);

    expect(
      () => verifyNever(
        () => fixture.mockApiModelRepo.getModelByProviderAndModelId(
          any(),
          any(),
        ),
      ),
      returnsNormally,
    );
  });

  test('triggers compaction when decision says shouldCompact', () async {
    const decision = CompactionDecision(
      shouldCompact: true,
      reason: CompactionDecisionReason.eligible,
      trigger: CompactionTrigger.auto,
    );

    when(
      () => fixture.mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => fixture.mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => _completion);
    when(
      () => fixture.mockApiModelRepo.getModelByProviderAndModelId(
        'provider-1',
        'model-1',
      ),
    ).thenAnswer((_) async => _makeModel());
    when(
      () => fixture.mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      ),
    ).thenAnswer((_) async => decision);
    when(
      () => fixture.mockCompact(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      ),
    ).thenAnswer((_) async => _makeExecState('conv-1'));

    await fixture.usecase(conversationId: 'conv-1');

    expect(
      () => verify(
        () => fixture.mockCompact(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
        ),
      ).called(1),
      returnsNormally,
    );
  });

  test('skips compaction when decision says shouldCompact is false', () async {
    const decision = CompactionDecision(
      shouldCompact: false,
      reason: CompactionDecisionReason.disabled,
      trigger: CompactionTrigger.auto,
    );

    when(
      () => fixture.mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => fixture.mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => _completion);
    when(
      () => fixture.mockApiModelRepo.getModelByProviderAndModelId(
        'provider-1',
        'model-1',
      ),
    ).thenAnswer((_) async => _makeModel());
    when(
      () => fixture.mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      ),
    ).thenAnswer((_) async => decision);

    await expectLater(fixture.usecase(conversationId: 'conv-1'), completes);

    expect(
      () => verifyNever(
        () => fixture.mockCompact(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
        ),
      ),
      returnsNormally,
    );
  });

  test('uses default 4096 maxOutputTokens when apiModel is null', () async {
    const decision = CompactionDecision(
      shouldCompact: false,
      reason: CompactionDecisionReason.disabled,
      trigger: CompactionTrigger.auto,
    );

    when(
      () => fixture.mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => fixture.mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => _completion);
    when(
      () => fixture.mockApiModelRepo.getModelByProviderAndModelId(
        'provider-1',
        'model-1',
      ),
    ).thenAnswer((_) async => null);
    when(
      () => fixture.mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
      ),
    ).thenAnswer((_) async => decision);

    await expectLater(fixture.usecase(conversationId: 'conv-1'), completes);

    expect(
      () => verify(
        () => fixture.mockShouldCompact(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
        ),
      ).called(1),
      returnsNormally,
    );
  });

  test('provider creates usecase with all dependencies', () {
    final container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWith(
          (ref) => fixture.mockConvRepo,
        ),
        workspaceModelSelectionRepositoryProvider.overrideWith(
          (ref) => fixture.mockModelRepo,
        ),
        apiModelRepositoryProvider.overrideWith(
          (ref) => fixture.mockApiModelRepo,
        ),
        shouldCompactConversationUsecaseProvider.overrideWith(
          (ref) => fixture.mockShouldCompact,
        ),
        compactConversationUsecaseProvider.overrideWith(
          (ref) => fixture.mockCompact,
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = container.read(maybeAutoCompactConversationUsecaseProvider);

    expect(result, isA<MaybeAutoCompactConversationUsecase>());
  });
}
