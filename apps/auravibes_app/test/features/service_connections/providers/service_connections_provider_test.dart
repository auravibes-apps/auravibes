import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/domain/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

AppDatabase _inMemoryDatabase() =>
    AppDatabase(connection: NativeDatabase.memory());

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('serviceConnectionsProvider', () {
    test(
      'combines model providers and skill credentials sorted by name',
      () async {
        final modelRepository = _FakeModelConnectionRepository([
          _modelConnection(
            id: 'model-1',
            workspaceId: 'workspace-1',
            name: 'OpenAI Main',
            modelId: 'gpt-4.1',
            keySuffix: 'sk-1',
          ),
        ]);
        final definitionRepository = _FakeDefinitionsRepository([
          _definition(
            id: 'definition-1',
            workspaceId: 'workspace-1',
            title: 'GitHub',
          ),
        ]);
        final credentialRepository = _FakeCredentialsRepository([
          _credential(
            id: 'credential-1',
            workspaceId: 'workspace-1',
            credentialDefinitionId: 'definition-1',
            name: 'GitHub Token',
            keySuffix: 'gh-1',
          ),
          _credential(
            id: 'credential-2',
            workspaceId: 'workspace-1',
            credentialDefinitionId: 'missing-definition',
            name: 'Stale Token',
            keySuffix: 'stale',
          ),
        ]);
        addTearDown(modelRepository.dispose);
        addTearDown(definitionRepository.dispose);
        addTearDown(credentialRepository.dispose);
        final database = _inMemoryDatabase();
        addTearDown(database.close);
        final container = _container(
          modelRepository: modelRepository,
          definitionRepository: definitionRepository,
          credentialRepository: credentialRepository,
          database: database,
        );
        addTearDown(container.dispose);
        final firstEmission = Completer<List<ServiceConnectionListItem>>();
        final subscription = container.listen(
          serviceConnectionsProvider('workspace-1'),
          (_, next) {
            if (next case AsyncData(:final value)) {
              if (!firstEmission.isCompleted) firstEmission.complete(value);
            }
          },
        );
        addTearDown(subscription.close);

        final items = await firstEmission.future;

        expect(modelRepository.watchedFilter?.workspaces, ['workspace-1']);
        expect(definitionRepository.watchedWorkspaceId, 'workspace-1');
        expect(credentialRepository.watchedWorkspaceId, 'workspace-1');
        expect(items.map((item) => item.name), [
          'GitHub Token',
          'OpenAI Main',
          'Stale Token',
        ]);
        expect(items.map((item) => item.kind), [
          ServiceConnectionListItemKind.skillCredential,
          ServiceConnectionListItemKind.modelProvider,
          ServiceConnectionListItemKind.skillCredential,
        ]);
        expect(items.firstOrNull?.serviceName, 'GitHub');
        expect(items.firstOrNull?.credentialDefinitionId, 'definition-1');
        expect(items[1].serviceName, 'gpt-4.1');
        expect(items[1].credentialDefinitionId, isNull);
        expect(items[2].serviceName, isNull);
        expect(items[2].credentialDefinitionId, 'missing-definition');
      },
    );

    test('emits updated items when repository streams change', () async {
      final modelRepository = _FakeModelConnectionRepository([
        _modelConnection(
          id: 'model-1',
          workspaceId: 'workspace-1',
          name: 'OpenAI Main',
          modelId: 'gpt-4.1',
        ),
      ]);
      final definitionRepository = _FakeDefinitionsRepository(const []);
      final credentialRepository = _FakeCredentialsRepository(const []);
      addTearDown(modelRepository.dispose);
      addTearDown(definitionRepository.dispose);
      addTearDown(credentialRepository.dispose);
      final database = _inMemoryDatabase();
      addTearDown(database.close);
      final container = _container(
        modelRepository: modelRepository,
        definitionRepository: definitionRepository,
        credentialRepository: credentialRepository,
        database: database,
      );
      addTearDown(container.dispose);
      final secondEmission = Completer<List<ServiceConnectionListItem>>();
      var dataEmissions = 0;
      final subscription = container.listen(
        serviceConnectionsProvider('workspace-1'),
        (_, next) {
          if (next case AsyncData(:final value)) {
            dataEmissions += 1;
            if (dataEmissions == 2 && !secondEmission.isCompleted) {
              secondEmission.complete(value);
            }
          }
        },
      );
      addTearDown(subscription.close);

      final initialItems = await container.read(
        serviceConnectionsProvider('workspace-1').future,
      );
      modelRepository.emit([
        _modelConnection(
          id: 'model-2',
          workspaceId: 'workspace-1',
          name: 'Anthropic Main',
          modelId: 'claude-sonnet-4',
        ),
        ...modelRepository.current,
      ]);
      final updatedItems = await secondEmission.future;

      expect(initialItems.map((item) => item.name), ['OpenAI Main']);
      expect(updatedItems.map((item) => item.name), [
        'Anthropic Main',
        'OpenAI Main',
      ]);
    });
  });
}

ProviderContainer _container({
  required ModelConnectionRepository modelRepository,
  required SkillCredentialDefinitionsRepository definitionRepository,
  required SkillCredentialsRepository credentialRepository,
  required AppDatabase database,
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      modelConnectionRepositoryProvider.overrideWithValue(modelRepository),
      skillCredentialDefinitionsRepositoryProvider.overrideWithValue(
        definitionRepository,
      ),
      skillCredentialsRepositoryProvider.overrideWithValue(
        credentialRepository,
      ),
    ],
  );
}

class _FakeModelConnectionRepository implements ModelConnectionRepository {
  _FakeModelConnectionRepository(List<ModelConnectionEntity> initial)
    : _subject = BehaviorSubject.seeded(initial);

  final BehaviorSubject<List<ModelConnectionEntity>> _subject;
  ModelConnectionFilter? watchedFilter;

  List<ModelConnectionEntity> get current => _subject.value;

  void emit(List<ModelConnectionEntity> value) {
    _subject.add(value);
  }

  Future<void> dispose() => _subject.close();

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteModelConnection(String modelConnectionId) {
    throw UnimplementedError();
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(
    String modelConnectionId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) {
    watchedFilter = filter;

    return _subject.stream;
  }
}

class _FakeDefinitionsRepository
    implements SkillCredentialDefinitionsRepository {
  _FakeDefinitionsRepository(List<SkillCredentialDefinitionEntity> initial)
    : _subject = BehaviorSubject.seeded(initial);

  final BehaviorSubject<List<SkillCredentialDefinitionEntity>> _subject;
  String? watchedWorkspaceId;

  Future<void> dispose() => _subject.close();

  @override
  Future<SkillCredentialDefinitionEntity> createDefinition(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteDefinition(String definitionId) {
    throw UnimplementedError();
  }

  @override
  Future<SkillCredentialDefinitionEntity?> getDefinitionById(
    String definitionId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SkillCredentialDefinitionEntity?> getDefinitionBySlug(
    String workspaceId,
    String slug,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<SkillCredentialDefinitionEntity>> getDefinitions(
    String workspaceId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<SkillCredentialDefinitionEntity> updateDefinition(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<List<SkillCredentialDefinitionEntity>> watchDefinitions(
    String workspaceId,
  ) {
    watchedWorkspaceId = workspaceId;

    return _subject.stream;
  }
}

class _FakeCredentialsRepository implements SkillCredentialsRepository {
  _FakeCredentialsRepository(List<SkillCredentialEntity> initial)
    : _subject = BehaviorSubject.seeded(initial);

  final BehaviorSubject<List<SkillCredentialEntity>> _subject;
  String? watchedWorkspaceId;

  Future<void> dispose() => _subject.close();

  @override
  Future<SkillCredentialEntity> createCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCredential(String credentialId) {
    throw UnimplementedError();
  }

  @override
  Future<SkillCredentialEntity?> getCredentialById(String credentialId) {
    throw UnimplementedError();
  }

  @override
  Future<SkillCredentialForEdit?> getCredentialForEdit(String credentialId) {
    throw UnimplementedError();
  }

  @override
  Future<List<SkillCredentialEntity>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SkillCredentialEntity> updateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<List<SkillCredentialEntity>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    watchedWorkspaceId = workspaceId;

    return _subject.stream;
  }
}

ModelConnectionEntity _modelConnection({
  required String id,
  required String workspaceId,
  required String name,
  required String modelId,
  String? keySuffix,
}) {
  final timestamp = DateTime(2026);

  return ModelConnectionEntity(
    id: id,
    name: name,
    key: 'secret-key',
    modelId: modelId,
    createdAt: timestamp,
    updatedAt: timestamp,
    workspaceId: workspaceId,
    keySuffix: keySuffix,
  );
}

SkillCredentialEntity _credential({
  required String id,
  required String workspaceId,
  required String credentialDefinitionId,
  required String name,
  String? keySuffix,
}) {
  final timestamp = DateTime(2026);

  return SkillCredentialEntity(
    id: id,
    workspaceId: workspaceId,
    credentialDefinitionId: credentialDefinitionId,
    name: name,
    attributes: const {},
    isEnabled: true,
    createdAt: timestamp,
    updatedAt: timestamp,
    keySuffix: keySuffix,
  );
}

SkillCredentialDefinitionEntity _definition({
  required String id,
  required String workspaceId,
  required String title,
}) {
  final timestamp = DateTime(2026);

  return SkillCredentialDefinitionEntity(
    id: id,
    workspaceId: workspaceId,
    title: title,
    slug: title.toLowerCase(),
    attributesJson: '{}',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
