import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_connections_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeModelConnectionRepository implements ModelConnectionRepository {
  _FakeModelConnectionRepository([this.connections = const []]);
  final List<ModelConnectionEntity> connections;

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) async {
    if (filter.workspaces.isEmpty) return [];
    return connections
        .where((c) => filter.workspaces.contains(c.workspaceId))
        .toList();
  }

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
}

void main() {
  group('listWorkspaceModelConnectionsProvider', () {
    test('returns connections for given workspace', () async {
      final connections = [
        ModelConnectionEntity(
          id: 'conn-1',
          name: 'OpenAI Key',
          key: 'encrypted-key',
          modelId: 'gpt-4',
          workspaceId: 'ws-1',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        ModelConnectionEntity(
          id: 'conn-2',
          name: 'Anthropic Key',
          key: 'encrypted-key-2',
          modelId: 'claude-3',
          workspaceId: 'ws-2',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _FakeModelConnectionRepository(connections),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        listWorkspaceModelConnectionsProvider(workspaceId: 'ws-1').future,
      );
      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'conn-1');
    });

    test('returns empty list when no connections match', () async {
      final container = ProviderContainer(
        overrides: [
          modelConnectionRepositoryProvider.overrideWithValue(
            _FakeModelConnectionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        listWorkspaceModelConnectionsProvider(workspaceId: 'ws-1').future,
      );
      expect(result, isEmpty);
    });
  });
}
