import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ModelConnectionRepository', () {
    var mockProvidersDao = MockApiModelProvidersDao();
    var mockConnectionsDao = MockModelConnectionsDao();
    var mockSelectionsDao = MockWorkspaceModelSelectionsDao();
    var mockEncryptionService = MockEncryptionService();
    var mockModelProviderServices = MockModelProviderServices();
    var database = _TestAppDatabase(
      MockApiModelProvidersDao(),
      MockModelConnectionsDao(),
      MockWorkspaceModelSelectionsDao(),
    );
    var repository = ModelConnectionRepository(
      database: database,
      encryptionService: mockEncryptionService,
      modelProviderServices: mockModelProviderServices,
    );

    tearDownAll(() async {
      await database.close();
    });

    setUp(() {
      mockProvidersDao = MockApiModelProvidersDao();
      mockConnectionsDao = MockModelConnectionsDao();
      mockSelectionsDao = MockWorkspaceModelSelectionsDao();
      mockEncryptionService = MockEncryptionService();
      mockModelProviderServices = MockModelProviderServices();
      database = _TestAppDatabase(
        mockProvidersDao,
        mockConnectionsDao,
        mockSelectionsDao,
      );
      repository = ModelConnectionRepository(
        database: database,
        encryptionService: mockEncryptionService,
        modelProviderServices: mockModelProviderServices,
      );
      when(() => mockSelectionsDao.getByModelConnectionId(any()))
          .thenAnswer((_) async => const []);
      when(() => mockSelectionsDao.deleteByIds(any()))
          .thenAnswer((_) async => 0);
      when(() => mockSelectionsDao.insertWorkspaceModelSelections(any()))
          .thenAnswer((_) async {
            return;
          });
    });

    tearDown(() async {
      await database.close();
    });

    final now = DateTime(2026);
    final testKeyPayload = ServiceConnectionAuthCodec.encodeSecret(
      const ServiceConnectionSecretApiKey(apiKey: 'sk-test-api-key-123456'),
    );
    final newKeyPayload = ServiceConnectionAuthCodec.encodeSecret(
      const ServiceConnectionSecretApiKey(apiKey: 'new-api-key-123456'),
    );
    final existingKeyPayload = ServiceConnectionAuthCodec.encodeSecret(
      const ServiceConnectionSecretApiKey(apiKey: 'plain-existing-key'),
    );

    const providerRow = ApiModelProvidersTable(
      id: 'openai',
      name: 'OpenAI',
      type: .openai,
      url: 'https://api.openai.com',
    );

    final connectionRow = ServiceConnectionTable(
      id: 'conn-1',
      createdAt: now,
      updatedAt: now,
      name: 'My Connection',
      serviceId: 'openai',
      kind: .modelProvider,
      authenticationType: .apiKey,
      encryptedAuthValue: 'encrypted-key',
      keySuffix: 'abc123',
      workspaceId: 'ws-1',
      isEnabled: true,
    );

    group('createModelConnection', () {
      test(
        'throws ModelConnectionModelNotFoundException when provider missing',
        () async {
          when(() => mockProvidersDao.getProviderById('openai'))
              .thenAnswer((_) async => null);

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            workspaceId: 'ws-1',
            modelId: 'openai',
            key: 'sk-test-api-key-123456',
          );

          await expectLater(
            repository.createModelConnection(toCreate),
            throwsA(isA<ModelConnectionModelNotFoundException>()),
          );
        },
      );

      test(
        'throws ModelConnectionNoTypeException when provider has no type',
        () async {
          const noTypeProvider = ApiModelProvidersTable(
            id: 'openai',
            name: 'OpenAI',
          );
          when(() => mockProvidersDao.getProviderById('openai'))
              .thenAnswer((_) async => noTypeProvider);

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            workspaceId: 'ws-1',
            modelId: 'openai',
            key: 'sk-test-api-key-123456',
          );

          await expectLater(
            repository.createModelConnection(toCreate),
            throwsA(isA<ModelConnectionNoTypeException>()),
          );
        },
      );

      test(
        'throws ModelConnectionNoModelsException when models null',
        () async {
          when(() => mockProvidersDao.getProviderById('openai'))
              .thenAnswer((_) async => providerRow);
          when(() => mockEncryptionService.encrypt(testKeyPayload))
              .thenAnswer((_) async => 'encrypted-key');
          when(
            () => mockModelProviderServices.getWorkspaceModelSelections(any()),
          ).thenAnswer((_) async => null);

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            workspaceId: 'ws-1',
            modelId: 'openai',
            key: 'sk-test-api-key-123456',
          );

          await expectLater(
            repository.createModelConnection(toCreate),
            throwsA(isA<ModelConnectionNoModelsException>()),
          );
        },
      );

      test('creates connection and model selections', () async {
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.encrypt(testKeyPayload))
            .thenAnswer((_) async => 'encrypted-key');
        when(() => mockModelProviderServices.getWorkspaceModelSelections(any()))
            .thenAnswer(
              (_) async => [
                const WorkspaceModelSelectionToCreate(
                  modelId: 'gpt-4',
                  modelConnectionId: '',
                ),
              ],
            );
        when(() => mockConnectionsDao.insertModelConnection(any()))
            .thenAnswer((_) async => connectionRow);
        when(() => mockSelectionsDao.insertWorkspaceModelSelections(any()))
            .thenAnswer((_) async {
              return;
            });

        const toCreate = ModelConnectionToCreate(
          name: 'Test',
          workspaceId: 'ws-1',
          modelId: 'openai',
          key: 'sk-test-api-key-123456',
        );

        final result = await repository.createModelConnection(toCreate);

        expect(result.id, 'conn-1');
        expect(result.name, 'My Connection');
        expect(result.modelId, 'openai');
        expect(result.workspaceId, 'ws-1');
        verify(() => mockConnectionsDao.insertModelConnection(any())).called(1);
        verify(() => mockSelectionsDao.insertWorkspaceModelSelections(any()))
            .called(1);
      });

      test('does not persist the complete value of a short API key', () async {
        final shortKeyConnectionRow = connectionRow.copyWith(
          keySuffix: const Value(null),
        );
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.encrypt(any()))
            .thenAnswer((_) async => 'encrypted-key');
        when(() => mockModelProviderServices.getWorkspaceModelSelections(any()))
            .thenAnswer((_) async => const []);
        when(() => mockConnectionsDao.insertModelConnection(any()))
            .thenAnswer((_) async => shortKeyConnectionRow);
        when(() => mockSelectionsDao.insertWorkspaceModelSelections(any()))
            .thenAnswer((_) => Future.value());

        final _ = await repository.createModelConnection(
          const ModelConnectionToCreate(
            name: 'Test',
            workspaceId: 'ws-1',
            modelId: 'openai',
            key: '123456',
          ),
        );

        final connection =
            verify(() => mockConnectionsDao.insertModelConnection(captureAny()))
                    .captured
                    .single
                as ServiceConnectionsCompanion;
        expect(connection.keySuffix.value, isNull);
      });

      test('verified create reuses discovered model ids', () async {
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.encrypt(testKeyPayload))
            .thenAnswer((_) async => 'encrypted-key');
        when(() => mockConnectionsDao.insertModelConnection(any()))
            .thenAnswer((_) async => connectionRow);
        when(() => mockSelectionsDao.insertWorkspaceModelSelections(any()))
            .thenAnswer((_) async {
              return;
            });
        final verification = ModelProviderVerification.fromRequest(
          request: const ModelProviderVerificationRequest(
            workspaceId: 'ws-1',
            providerId: 'openai',
            connectionId: null,
            expectedRevision: null,
            url: null,
            key: 'sk-test-api-key-123456',
          ),
          modelIds: const ['gpt-4', 'gpt-4o'],
        );

        final _ = await repository.createModelConnection(
          const ModelConnectionToCreate(
            name: 'Test',
            workspaceId: 'ws-1',
            modelId: 'openai',
            key: 'sk-test-api-key-123456',
          ),
          verification: verification,
        );

        final _ = verifyNever(
          () => mockModelProviderServices.getWorkspaceModelSelections(any()),
        );
        final selections =
            verify(
                  () => mockSelectionsDao.insertWorkspaceModelSelections(
                    captureAny(),
                  ),
                ).captured.single
                as List<WorkspaceModelSelectionsCompanion>;
        expect(selections.map((selection) => selection.modelId.value), [
          'gpt-4',
          'gpt-4o',
        ]);
      });

      test('rejects mismatched verification before persistence', () async {
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.encrypt(testKeyPayload))
            .thenAnswer((_) async => 'encrypted-key');

        final verification = ModelProviderVerification.fromRequest(
          request: const ModelProviderVerificationRequest(
            workspaceId: 'ws-1',
            providerId: 'openai',
            connectionId: null,
            expectedRevision: null,
            url: null,
            key: 'different-key-123456',
          ),
          modelIds: const ['gpt-4'],
        );

        await expectLater(
          repository.createModelConnection(
            const ModelConnectionToCreate(
              name: 'Test',
              workspaceId: 'ws-1',
              modelId: 'openai',
              key: 'sk-test-api-key-123456',
            ),
            verification: verification,
          ),
          throwsA(isA<ProviderVerificationMismatchException>()),
        );

        final _ = verifyNever(
          () => mockConnectionsDao.insertModelConnection(any()),
        );
        final _ = verifyNever(
          () => mockSelectionsDao.insertWorkspaceModelSelections(any()),
        );
      });

      test('creates OAuth connection with supplied model ids', () async {
        final issuedAt = DateTime(2026);
        final oauthRow = ServiceConnectionTable(
          id: 'conn-oauth',
          createdAt: now,
          updatedAt: now,
          name: 'Codex',
          serviceId: ModelProviderOAuthProfiles.providerId,
          kind: .modelProvider,
          authenticationType: .oauth2,
          encryptedAuthValue: 'encrypted-token',
          keySuffix: 'access',
          metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
            const ServiceConnectionMetadata(accountId: 'account-1'),
          ),
          workspaceId: 'ws-1',
          isEnabled: true,
        );
        when(() => mockEncryptionService.encrypt(any()))
            .thenAnswer((_) async => 'encrypted-token');
        when(() => mockConnectionsDao.insertModelConnection(any()))
            .thenAnswer((_) async => oauthRow);
        when(() => mockSelectionsDao.insertWorkspaceModelSelections(any()))
            .thenAnswer((_) async {
              return;
            });

        final result = await repository.createModelConnection(
          .new(
            name: 'Codex',
            workspaceId: 'ws-1',
            modelId: ModelProviderOAuthProfiles.providerId,
            authMode: ModelProviderAuthMode.oauth2,
            oauthToken: OAuthTokenEntity(
              accessToken: 'codex-access',
              issuedAt: issuedAt,
              refreshToken: 'codex-refresh',
              idToken: 'codex-id',
              expiresIn: 3600,
            ),
            oauthMetadata: const ServiceConnectionMetadata(
              accountId: 'account-1',
            ),
            modelIds: const ['gpt-5.5'],
          ),
        );

        final connection =
            verify(() => mockConnectionsDao.insertModelConnection(captureAny()))
                    .captured
                    .single
                as ServiceConnectionsCompanion;
        final selections =
            verify(
                  () => mockSelectionsDao.insertWorkspaceModelSelections(
                    captureAny(),
                  ),
                ).captured.single
                as List<WorkspaceModelSelectionsCompanion>;

        expect(result.id, 'conn-oauth');
        expect(
          connection.serviceId.value,
          ModelProviderOAuthProfiles.providerId,
        );
        expect(
          connection.authenticationType.value,
          ServiceAuthenticationTypeTable.oauth2,
        );
        expect(connection.metadataJson.value, contains('account-1'));
        expect(selections.map((selection) => selection.modelId.value), [
          'gpt-5.5',
        ]);
      });

      test(
        'ignores catalog URL when validating an openrouter connection',
        () async {
          const openRouterProvider = ApiModelProvidersTable(
            id: 'openrouter',
            name: 'OpenRouter',
            type: .openrouter,
            url: 'https://openrouter.ai/api/v1',
          );
          final openRouterConnectionRow = ServiceConnectionTable(
            id: 'conn-1',
            createdAt: now,
            updatedAt: now,
            name: 'OpenRouter Connection',
            serviceId: 'openrouter',
            kind: .modelProvider,
            authenticationType: .apiKey,
            encryptedAuthValue: 'encrypted-key',
            keySuffix: '123456',
            workspaceId: 'ws-1',
            isEnabled: true,
          );
          when(() => mockProvidersDao.getProviderById('openrouter'))
              .thenAnswer((_) async => openRouterProvider);
          when(() => mockEncryptionService.encrypt(testKeyPayload))
              .thenAnswer((_) async => 'encrypted-key');
          when(
            () => mockModelProviderServices.getWorkspaceModelSelections(
              any<ModelProvider>(),
            ),
          ).thenAnswer(
            (_) async => [
              const WorkspaceModelSelectionToCreate(
                modelId: 'anthropic/claude-sonnet-4',
                modelConnectionId: '',
              ),
            ],
          );
          when(
            () => mockConnectionsDao.insertModelConnection(
              any<ServiceConnectionsCompanion>(),
            ),
          ).thenAnswer((_) async => openRouterConnectionRow);
          when(
            () => mockSelectionsDao.insertWorkspaceModelSelections(
              any<List<WorkspaceModelSelectionsCompanion>>(),
            ),
          ).thenAnswer((_) async {
            return;
          });

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            workspaceId: 'ws-1',
            modelId: 'openrouter',
            key: 'sk-test-api-key-123456',
          );

          final result = await repository.createModelConnection(toCreate);
          final capturedProvider =
              verify(
                    () => mockModelProviderServices.getWorkspaceModelSelections(
                      captureAny<ModelProvider>(),
                    ),
                  ).captured.single
                  as ModelProvider;

          expect(result.modelId, 'openrouter');
          expect(capturedProvider.type, CredentialsModelType.openrouter);
          expect(capturedProvider.url, isNull);
        },
      );
    });

    group('getModelConnections', () {
      test('returns empty list when no workspaces in filter', () async {
        const filter = ModelConnectionFilter();

        final result = await repository.getModelConnections(filter);

        expect(result, isEmpty);
      });

      test('returns mapped connections for workspaces', () async {
        when(
          () => mockConnectionsDao.getAllModelConnectionsByWorkspace(
            workspaceIds: any(named: 'workspaceIds'),
          ),
        ).thenAnswer((_) async => [connectionRow]);

        const filter = ModelConnectionFilter(workspaces: ['ws-1']);
        final result = await repository.getModelConnections(filter);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'conn-1');
        expect(result.firstOrNull?.name, 'My Connection');
        expect(result.firstOrNull?.hasKey, isTrue);
        expect(result.firstOrNull?.keySuffix, 'abc123');
        expect(result.firstOrNull?.workspaceId, 'ws-1');
      });
    });

    group('updateModelConnection', () {
      test('preserves encrypted key when key is unchanged', () async {
        final updatedRow = connectionRow.copyWith(
          name: 'Renamed Connection',
          url: const Value('https://proxy.example.com'),
        );
        when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
            .thenAnswer((_) async => connectionRow);
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.decrypt('encrypted-key'))
            .thenAnswer((_) async => existingKeyPayload);
        when(() => mockModelProviderServices.getWorkspaceModelSelections(any()))
            .thenAnswer((_) async => const []);
        when(() => mockConnectionsDao.updateModelConnection('conn-1', any()))
            .thenAnswer((_) async => updatedRow);

        final result = await repository.updateModelConnection(
          'conn-1',
          const ModelConnectionToUpdate(
            name: 'Renamed Connection',
            url: 'https://proxy.example.com',
          ),
        );

        expect(result.name, 'Renamed Connection');
        expect(result.hasKey, isTrue);
        final _ = verifyNever(() => mockEncryptionService.encrypt(any()));
        final _ = verify(() => mockEncryptionService.decrypt('encrypted-key'))
            .called(1);
      });

      test(
        'name-only update preserves a legacy key without decrypting it',
        () async {
          final existingRow = connectionRow.copyWith(
            encryptedAuthValue: const Value('legacy-api-key'),
          );
          final updatedRow = existingRow.copyWith(name: 'Renamed Connection');
          when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
              .thenAnswer((_) async => existingRow);
          when(() => mockConnectionsDao.updateModelConnection('conn-1', any()))
              .thenAnswer((_) async => updatedRow);

          final result = await repository.updateModelConnection(
            'conn-1',
            const ModelConnectionToUpdate(name: 'Renamed Connection'),
          );

          expect(result.name, 'Renamed Connection');
          final companion =
              verify(
                    () => mockConnectionsDao.updateModelConnection(
                      'conn-1',
                      captureAny(),
                    ),
                  ).captured.single
                  as ServiceConnectionsCompanion;
          expect(companion.encryptedAuthValue.present, isFalse);
          expect(companion.keySuffix.present, isFalse);
          final _ = verifyNever(() => mockEncryptionService.decrypt(any()));
          final _ = verifyNever(
            () => mockModelProviderServices.getWorkspaceModelSelections(any()),
          );
        },
      );

      test('verified URL update tests stored key once', () async {
        final updatedRow = connectionRow.copyWith(
          url: const Value('https://proxy.example.com'),
        );
        when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
            .thenAnswer((_) async => connectionRow);
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.decrypt('encrypted-key'))
            .thenAnswer((_) async => existingKeyPayload);
        when(() => mockModelProviderServices.getWorkspaceModelSelections(any()))
            .thenAnswer(
              (_) async => const [
                WorkspaceModelSelectionToCreate(
                  modelId: 'gpt-4o',
                  modelConnectionId: '',
                ),
              ],
            );
        when(() => mockConnectionsDao.updateModelConnection('conn-1', any()))
            .thenAnswer((_) async => updatedRow);

        final verification = await repository.verifyModelConnection(
          const ModelProviderVerificationRequest(
            workspaceId: 'ws-1',
            providerId: 'openai',
            connectionId: 'conn-1',
            expectedRevision: null,
            url: 'https://proxy.example.com',
            key: null,
          ),
        );
        final _ = await repository.updateModelConnection(
          'conn-1',
          const ModelConnectionToUpdate(url: 'https://proxy.example.com'),
          verification: verification,
        );

        verify(
          () => mockModelProviderServices.getWorkspaceModelSelections(any()),
        ).called(1);
      });

      test('encrypts replacement key', () async {
        final updatedRow = connectionRow.copyWith(
          encryptedAuthValue: const Value('encrypted-new-key'),
          keySuffix: const Value('123456'),
        );
        when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
            .thenAnswer((_) async => connectionRow);
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.encrypt(newKeyPayload))
            .thenAnswer((_) async => 'encrypted-new-key');
        when(() => mockModelProviderServices.getWorkspaceModelSelections(any()))
            .thenAnswer((_) async => const []);
        when(() => mockConnectionsDao.updateModelConnection('conn-1', any()))
            .thenAnswer((_) async => updatedRow);

        final result = await repository.updateModelConnection(
          'conn-1',
          const ModelConnectionToUpdate(key: 'new-api-key-123456'),
        );

        expect(result.hasKey, isTrue);
        expect(result.keySuffix, '123456');
        final _ = verifyNever(() => mockEncryptionService.decrypt(any()));
        final _ = verify(() => mockEncryptionService.encrypt(newKeyPayload))
            .called(1);
      });

      test(
        'name-only update preserves URL without provider verification',
        () async {
          final existingRow = connectionRow.copyWith(
            url: const Value('https://proxy.example.com'),
          );
          final updatedRow = existingRow.copyWith(name: 'Renamed Connection');
          when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
              .thenAnswer((_) async => existingRow);
          when(() => mockProvidersDao.getProviderById('openai'))
              .thenAnswer((_) async => providerRow);
          when(() => mockEncryptionService.decrypt('encrypted-key'))
              .thenAnswer((_) async => existingKeyPayload);
          when(
            () => mockModelProviderServices.getWorkspaceModelSelections(any()),
          ).thenAnswer((_) async => const []);
          when(() => mockConnectionsDao.updateModelConnection('conn-1', any()))
              .thenAnswer((_) async => updatedRow);

          final result = await repository.updateModelConnection(
            'conn-1',
            const ModelConnectionToUpdate(name: 'Renamed Connection'),
          );

          expect(result.url, 'https://proxy.example.com');
          final companion =
              verify(
                    () => mockConnectionsDao.updateModelConnection(
                      'conn-1',
                      captureAny(),
                    ),
                  ).captured.single
                  as ServiceConnectionsCompanion;
          expect(companion.url.present, isFalse);
          final _ = verifyNever(
            () => mockModelProviderServices.getWorkspaceModelSelections(any()),
          );
        },
      );

      test('preserves existing selection ids for unchanged models', () async {
        final existingRow = connectionRow.copyWith(
          url: const Value('https://old.proxy.example.com'),
        );
        final updatedRow = existingRow.copyWith(
          name: 'Renamed Connection',
          url: const Value('https://proxy.example.com'),
        );
        final existingSelection = WorkspaceModelSelectionTable(
          id: 'selection-existing',
          createdAt: now,
          updatedAt: now,
          modelId: 'gpt-4',
          modelConnectionId: 'conn-1',
        );
        final removedSelection = WorkspaceModelSelectionTable(
          id: 'selection-removed',
          createdAt: now,
          updatedAt: now,
          modelId: 'old-model',
          modelConnectionId: 'conn-1',
        );
        when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
            .thenAnswer((_) async => existingRow);
        when(() => mockProvidersDao.getProviderById('openai'))
            .thenAnswer((_) async => providerRow);
        when(() => mockEncryptionService.decrypt('encrypted-key'))
            .thenAnswer((_) async => existingKeyPayload);
        when(() => mockModelProviderServices.getWorkspaceModelSelections(any()))
            .thenAnswer(
              (_) async => const [
                WorkspaceModelSelectionToCreate(
                  modelId: 'gpt-4',
                  modelConnectionId: '',
                ),
                WorkspaceModelSelectionToCreate(
                  modelId: 'new-model',
                  modelConnectionId: '',
                ),
              ],
            );
        when(() => mockConnectionsDao.updateModelConnection('conn-1', any()))
            .thenAnswer((_) async => updatedRow);
        when(() => mockSelectionsDao.getByModelConnectionId('conn-1'))
            .thenAnswer((_) async => [existingSelection, removedSelection]);

        final result = await repository.updateModelConnection(
          'conn-1',
          const ModelConnectionToUpdate(
            name: 'Renamed Connection',
            url: 'https://proxy.example.com',
          ),
        );

        expect(result.id, 'conn-1');
        expect(result.url, 'https://proxy.example.com');
        final _ = verify(
          () => mockSelectionsDao.deleteByIds({'selection-removed'}),
        ).called(1);
        final captured =
            verify(
                  () => mockSelectionsDao.insertWorkspaceModelSelections(
                    captureAny(),
                  ),
                ).captured.last
                as List<WorkspaceModelSelectionsCompanion>;
        expect(captured, hasLength(1));
        expect(captured.single.modelId.value, 'new-model');
        expect(captured.single.modelConnectionId.value, 'conn-1');
      });
    });

    group('deleteModelConnection', () {
      test('deletes existing connection', () async {
        when(() => mockConnectionsDao.getModelConnectionById('conn-1'))
            .thenAnswer((_) async => connectionRow);
        when(() => mockConnectionsDao.deleteModelConnection('conn-1'))
            .thenAnswer((_) async {
              return;
            });

        await repository.deleteModelConnection('conn-1');

        expect(
          () =>
              verify(() => mockConnectionsDao.deleteModelConnection('conn-1'))
                  .called(1),
          returnsNormally,
        );
      });

      test('throws when connection not found', () async {
        when(() => mockConnectionsDao.getModelConnectionById('nonexistent'))
            .thenAnswer((_) async => null);

        await expectLater(
          repository.deleteModelConnection('nonexistent'),
          throwsA(isA<ModelConnectionException>()),
        );
      });
    });
  });
}

class _TestAppDatabase(
  final ApiModelProvidersDao _providersDao,
  final ModelConnectionsDao _connectionsDao,
  final WorkspaceModelSelectionsDao _selectionsDao,
) extends AppDatabase {
  this : super(connection: DatabaseConnection(NativeDatabase.memory()));

  @override
  ApiModelProvidersDao get apiModelProvidersDao => _providersDao;

  @override
  ModelConnectionsDao get modelConnectionsDao => _connectionsDao;

  @override
  WorkspaceModelSelectionsDao get workspaceModelSelectionsDao => _selectionsDao;
}
