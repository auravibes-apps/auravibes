// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: missing-test-assertion
// Required: Tests verify usecase behavior through repository side effects.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
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
  key: 'key-v-1',
  modelId: 'model-1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  workspaceId: 'ws-1',
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
  modalitiesOuput: ['text'],
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

  late MockConversationRepository mockConvRepo;
  late MockWorkspaceModelSelectionsRepository mockModelRepo;
  late MockApiModelRepository mockApiModelRepo;
  late MockShouldCompactConversationUsecase mockShouldCompact;
  late MockCompactConversationUsecase mockCompact;
  late MaybeAutoCompactConversationUsecase usecase;

  setUp(() {
    mockConvRepo = MockConversationRepository();
    mockModelRepo = MockWorkspaceModelSelectionsRepository();
    mockApiModelRepo = MockApiModelRepository();
    mockShouldCompact = MockShouldCompactConversationUsecase();
    mockCompact = MockCompactConversationUsecase();
    usecase = MaybeAutoCompactConversationUsecase(
      conversationRepository: mockConvRepo,
      workspaceModelSelectionsRepository: mockModelRepo,
      apiModelRepository: mockApiModelRepo,
      shouldCompactConversationUsecase: mockShouldCompact,
      compactConversationUsecase: mockCompact,
    );
  });

  test('exits early when conversation not found', () async {
    when(
      () => mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => null);

    await usecase(conversationId: 'conv-1');

    final _ = verifyNever(
      () => mockCompact(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      ),
    );
  });

  test('exits early when conversation has no modelId', () async {
    when(
      () => mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv(modelId: null));

    await usecase(conversationId: 'conv-1');

    final _ = verifyNever(
      () => mockModelRepo.getWorkspaceModelSelectionById(any()),
    );
  });

  test('exits early when model selection not found', () async {
    when(
      () => mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => null);

    await usecase(conversationId: 'conv-1');

    final _ = verifyNever(
      () => mockApiModelRepo.getModelByProviderAndModelId(any(), any()),
    );
  });

  test('triggers compaction when decision says shouldCompact', () async {
    const decision = CompactionDecision(
      shouldCompact: true,
      reason: CompactionDecisionReason.eligible,
      trigger: CompactionTrigger.auto,
    );

    when(
      () => mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => _completion);
    when(
      () => mockApiModelRepo.getModelByProviderAndModelId(
        'provider-1',
        'model-1',
      ),
    ).thenAnswer((_) async => _makeModel());
    when(
      () => mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      ),
    ).thenAnswer((_) async => decision);
    when(
      () => mockCompact(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      ),
    ).thenAnswer((_) async => _makeExecState('conv-1'));

    await usecase(conversationId: 'conv-1');

    verify(
      () => mockCompact(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      ),
    ).called(1);
  });

  test('skips compaction when decision says shouldCompact is false', () async {
    const decision = CompactionDecision(
      shouldCompact: false,
      reason: CompactionDecisionReason.disabled,
      trigger: CompactionTrigger.auto,
    );

    when(
      () => mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => _completion);
    when(
      () => mockApiModelRepo.getModelByProviderAndModelId(
        'provider-1',
        'model-1',
      ),
    ).thenAnswer((_) async => _makeModel());
    when(
      () => mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      ),
    ).thenAnswer((_) async => decision);

    await usecase(conversationId: 'conv-1');

    final _ = verifyNever(
      () => mockCompact(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      ),
    );
  });

  test('uses default 4096 maxOutputTokens when apiModel is null', () async {
    const decision = CompactionDecision(
      shouldCompact: false,
      reason: CompactionDecisionReason.disabled,
      trigger: CompactionTrigger.auto,
    );

    when(
      () => mockConvRepo.getConversationById('conv-1'),
    ).thenAnswer((_) async => _makeConv());
    when(
      () => mockModelRepo.getWorkspaceModelSelectionById('comp-1'),
    ).thenAnswer((_) async => _completion);
    when(
      () => mockApiModelRepo.getModelByProviderAndModelId(
        'provider-1',
        'model-1',
      ),
    ).thenAnswer((_) async => null);
    when(
      () => mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
      ),
    ).thenAnswer((_) async => decision);

    await usecase(conversationId: 'conv-1');

    verify(
      () => mockShouldCompact(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
      ),
    ).called(1);
  });

  test('provider creates usecase with all dependencies', () {
    final container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWith((ref) => mockConvRepo),
        workspaceModelSelectionRepositoryProvider.overrideWith(
          (ref) => mockModelRepo,
        ),
        apiModelRepositoryProvider.overrideWith((ref) => mockApiModelRepo),
        shouldCompactConversationUsecaseProvider.overrideWith(
          (ref) => mockShouldCompact,
        ),
        compactConversationUsecaseProvider.overrideWith(
          (ref) => mockCompact,
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = container.read(maybeAutoCompactConversationUsecaseProvider);

    expect(result, isA<MaybeAutoCompactConversationUsecase>());
  });
}
