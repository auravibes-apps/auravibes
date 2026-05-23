import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/api_model_providers_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/model_connections_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository_impl.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'model_connection_repository_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiModelProvidersDao>(),
  MockSpec<ModelConnectionsDao>(),
  MockSpec<WorkspaceModelSelectionsDao>(),
  MockSpec<EncryptionService>(),
  MockSpec<ModelProviderServices>(),
])
void main() {
  group('ModelConnectionRepositoryImpl', () {
    late MockApiModelProvidersDao mockProvidersDao;
    late MockModelConnectionsDao mockConnectionsDao;
    late MockWorkspaceModelSelectionsDao mockSelectionsDao;
    late MockEncryptionService mockEncryptionService;
    late MockModelProviderServices mockModelProviderServices;
    late _TestAppDatabase database;
    late ModelConnectionRepositoryImpl repository;

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
      repository = ModelConnectionRepositoryImpl(
        database: database,
        encryptionService: mockEncryptionService,
        modelProviderServices: mockModelProviderServices,
      );
    });

    tearDown(() async {
      await database.close();
    });

    final now = DateTime(2026);

    const providerRow = ApiModelProvidersTable(
      id: 'openai',
      name: 'OpenAI',
      type: ModelProvidersTableType.openai,
      url: 'https://api.openai.com',
    );

    final connectionRow = ModelConnectionTable(
      id: 'conn-1',
      name: 'My Connection',
      modelId: 'openai',
      keyValue: 'encrypted-key',
      keySuffix: 'abc123',
      workspaceId: 'ws-1',
      createdAt: now,
      updatedAt: now,
    );

    group('createModelConnection', () {
      test(
        'throws ModelConnectionModelNotFoundException when provider missing',
        () async {
          when(
            mockProvidersDao.getProviderById('openai'),
          ).thenAnswer((_) async => null);

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            key: 'sk-test-api-key-123456',
            workspaceId: 'ws-1',
            modelId: 'openai',
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
          when(
            mockProvidersDao.getProviderById('openai'),
          ).thenAnswer((_) async => noTypeProvider);

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            key: 'sk-test-api-key-123456',
            workspaceId: 'ws-1',
            modelId: 'openai',
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
          when(
            mockProvidersDao.getProviderById('openai'),
          ).thenAnswer((_) async => providerRow);
          when(
            mockEncryptionService.encrypt('sk-test-api-key-123456'),
          ).thenAnswer((_) async => 'encrypted-key');
          when(
            mockModelProviderServices.getWorkspaceModelSelections(any),
          ).thenAnswer((_) async => null);

          const toCreate = ModelConnectionToCreate(
            name: 'Test',
            key: 'sk-test-api-key-123456',
            workspaceId: 'ws-1',
            modelId: 'openai',
          );

          await expectLater(
            repository.createModelConnection(toCreate),
            throwsA(isA<ModelConnectionNoModelsException>()),
          );
        },
      );

      test('creates connection and model selections', () async {
        when(
          mockProvidersDao.getProviderById('openai'),
        ).thenAnswer((_) async => providerRow);
        when(
          mockEncryptionService.encrypt('sk-test-api-key-123456'),
        ).thenAnswer((_) async => 'encrypted-key');
        when(
          mockModelProviderServices.getWorkspaceModelSelections(any),
        ).thenAnswer(
          (_) async => [
            const WorkspaceModelSelectionToCreate(
              modelId: 'gpt-4',
              modelConnectionId: '',
            ),
          ],
        );
        when(
          mockConnectionsDao.insertModelConnection(any),
        ).thenAnswer((_) async => connectionRow);
        when(mockSelectionsDao.insertWorkspaceModelSelections(any)).thenAnswer((
          _,
        ) async {
          return;
        });

        const toCreate = ModelConnectionToCreate(
          name: 'Test',
          key: 'sk-test-api-key-123456',
          workspaceId: 'ws-1',
          modelId: 'openai',
        );

        final result = await repository.createModelConnection(toCreate);

        expect(result.id, 'conn-1');
        expect(result.name, 'My Connection');
        expect(result.modelId, 'openai');
        expect(result.workspaceId, 'ws-1');
        verify(mockConnectionsDao.insertModelConnection(any)).called(1);
        verify(mockSelectionsDao.insertWorkspaceModelSelections(any)).called(1);
      });
    });

    group('getModelConnections', () {
      test('returns empty list when no workspaces in filter', () async {
        const filter = ModelConnectionFilter();

        final result = await repository.getModelConnections(filter);

        expect(result, isEmpty);
      });

      test('returns mapped connections for workspaces', () async {
        when(
          mockConnectionsDao.getAllModelConnectionsByWorkspace(
            workspaceIds: anyNamed('workspaceIds'),
          ),
        ).thenAnswer((_) async => [connectionRow]);

        const filter = ModelConnectionFilter(workspaces: ['ws-1']);
        final result = await repository.getModelConnections(filter);

        expect(result, hasLength(1));
        expect(result.firstOrNull?.id, 'conn-1');
        expect(result.firstOrNull?.name, 'My Connection');
        expect(result.firstOrNull?.key, 'encrypted-key');
        expect(result.firstOrNull?.keySuffix, 'abc123');
        expect(result.firstOrNull?.workspaceId, 'ws-1');
      });
    });

    group('deleteModelConnection', () {
      test('deletes existing connection', () async {
        when(
          mockConnectionsDao.getModelConnectionById('conn-1'),
        ).thenAnswer((_) async => connectionRow);
        when(mockConnectionsDao.deleteModelConnection('conn-1')).thenAnswer((
          _,
        ) async {
          return;
        });

        await repository.deleteModelConnection('conn-1');

        verify(mockConnectionsDao.deleteModelConnection('conn-1')).called(1);
      });

      test('throws when connection not found', () async {
        when(
          mockConnectionsDao.getModelConnectionById('nonexistent'),
        ).thenAnswer((_) async => null);

        await expectLater(
          repository.deleteModelConnection('nonexistent'),
          throwsA(isA<ModelConnectionException>()),
        );
      });
    });
  });
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(
    this._providersDao,
    this._connectionsDao,
    this._selectionsDao,
  ) : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final ApiModelProvidersDao _providersDao;
  final ModelConnectionsDao _connectionsDao;
  final WorkspaceModelSelectionsDao _selectionsDao;

  @override
  ApiModelProvidersDao get apiModelProvidersDao => _providersDao;

  @override
  ModelConnectionsDao get modelConnectionsDao => _connectionsDao;

  @override
  WorkspaceModelSelectionsDao get workspaceModelSelectionsDao => _selectionsDao;
}
