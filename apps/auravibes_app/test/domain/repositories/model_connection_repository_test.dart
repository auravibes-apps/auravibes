// ignore_for_file: cascade_invocations
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubModelConnectionRepository implements ModelConnectionRepository {
  List<ModelConnectionEntity> connections = [];
  List<ModelConnectionEntity> created = [];
  List<String> deleted = [];

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async {
    return connections;
  }

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection,
  ) async {
    final entity = ModelConnectionEntity(
      id: 'mc-${created.length}',
      name: modelConnection.name,
      key: modelConnection.key,
      modelId: modelConnection.modelId,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      workspaceId: modelConnection.workspaceId,
      url: modelConnection.url,
    );
    created.add(entity);
    return entity;
  }

  @override
  Future<void> deleteModelConnection(String modelConnectionId) async {
    deleted.add(modelConnectionId);
  }
}

void main() {
  group('ModelConnectionRepository', () {
    test('getModelConnections returns list', () async {
      final repo = _StubModelConnectionRepository();

      final result = await repo.getModelConnections(
        const ModelConnectionFilter(),
      );

      expect(result, isEmpty);
    });

    test('getModelConnections with filter returns connections', () async {
      final repo = _StubModelConnectionRepository();
      repo.connections = [
        ModelConnectionEntity(
          id: 'mc-1',
          name: 'OpenAI',
          key: 'key-1',
          modelId: 'gpt-4',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          workspaceId: 'ws-1',
        ),
      ];

      final result = await repo.getModelConnections(
        const ModelConnectionFilter(
          types: [CredentialsModelType.openai],
        ),
      );

      expect(result, hasLength(1));
      expect(result.firstOrNull?.name, 'OpenAI');
    });

    test('createModelConnection returns entity', () async {
      final repo = _StubModelConnectionRepository();
      const toCreate = ModelConnectionToCreate(
        name: 'Anthropic',
        key: 'sk-ant-test',
        workspaceId: 'ws-1',
        modelId: 'claude-3',
        url: 'https://api.anthropic.com',
      );

      final result = await repo.createModelConnection(toCreate);

      expect(result.name, 'Anthropic');
      expect(result.workspaceId, 'ws-1');
      expect(result.modelId, 'claude-3');
      expect(result.url, 'https://api.anthropic.com');
      expect(repo.created, hasLength(1));
    });

    test('deleteModelConnection removes connection', () async {
      final repo = _StubModelConnectionRepository();

      await repo.deleteModelConnection('mc-1');

      expect(repo.deleted, ['mc-1']);
    });
  });

  group('ModelConnectionException', () {
    test('contains message', () {
      const ex = ModelConnectionException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = ModelConnectionException('oops');
      expect(ex.toString(), 'ModelConnectionException: oops');
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = ModelConnectionException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('ModelConnectionNoModelsException', () {
    test('contains model id in message', () {
      const ex = ModelConnectionNoModelsException('provider-1');
      expect(ex, isA<ModelConnectionException>());
      expect(ex.modelId, 'provider-1');
      expect(ex.toString(), contains('provider-1'));
      expect(ex.toString(), contains('not found models'));
    });

    test('includes cause when provided', () {
      final cause = Exception('api error');
      final ex = ModelConnectionNoModelsException('p-1', cause);
      expect(ex.cause, cause);
    });
  });

  group('ModelConnectionModelNotFoundException', () {
    test('contains model id in message', () {
      const ex = ModelConnectionModelNotFoundException('model-1');
      expect(ex, isA<ModelConnectionException>());
      expect(ex.modelId, 'model-1');
      expect(ex.toString(), contains('model-1'));
      expect(ex.toString(), contains('not found'));
    });
  });

  group('ModelConnectionNoTypeException', () {
    test('contains model id in message', () {
      const ex = ModelConnectionNoTypeException('model-1');
      expect(ex, isA<ModelConnectionException>());
      expect(ex.modelId, 'model-1');
      expect(ex.toString(), contains('model-1'));
      expect(ex.toString(), contains('has no type'));
    });
  });
}
