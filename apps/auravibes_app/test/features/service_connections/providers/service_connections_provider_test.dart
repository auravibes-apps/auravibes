import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  test('streams model and Connector Connections from local storage', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final workspace = await WorkspaceRepository(
      database,
    ).createWorkspace(const WorkspaceToCreate(name: 'Workspace', type: .local));
    await database
        .into(database.serviceConnections)
        .insert(
          ServiceConnectionsCompanion.insert(
            name: 'Notion CRM',
            serviceId: 'notion',
            kind: .customHttp,
            authenticationType: .apiKey,
            encryptedAuthValue: const Value('encrypted-secret'),
            workspaceId: workspace.id,
          ),
        );
    final modelRepository = _FakeModelConnectionRepository([
      _modelConnection(
        id: 'model-1',
        workspaceId: workspace.id,
        name: 'OpenAI Main',
        modelId: 'gpt-4.1',
      ),
    ]);
    addTearDown(modelRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider(workspace.id).overrideWithValue(
          AsyncData(
            WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: workspace.id)),
          ),
        ),
        appDatabaseProvider.overrideWithValue(database),
        modelConnectionRepositoryProvider.overrideWithValue(modelRepository),
      ],
    );
    addTearDown(container.dispose);

    final firstEmission = Completer<List<ServiceConnectionListItem>>();
    final subscription = container.listen(
      serviceConnectionsProvider(workspace.id),
      (_, next) {
        if (next case AsyncData(:final value)) {
          if (!firstEmission.isCompleted) firstEmission.complete(value);
        }
      },
    );
    addTearDown(subscription.close);

    final connectedItems = await firstEmission.future;

    expect(connectedItems.map((item) => item.name), [
      'Notion CRM',
      'OpenAI Main',
    ]);
    final connector = connectedItems.first;
    expect(connector.kind, ServiceConnectionListItemKind.connector);
    expect(connector.displayStatus, ServiceConnectionDisplayStatus.connected);
    expect(connector.toString(), isNot(contains('encrypted-secret')));
  });
}

class _FakeModelConnectionRepository(List<ModelConnectionEntity> initial)
    implements ModelConnectionRepository {
  final BehaviorSubject<List<ModelConnectionEntity>> _subject = .seeded(
    initial,
  );

  Future<void> dispose() => _subject.close();

  @override
  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) => throw UnimplementedError();

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate modelConnection, {
    ModelProviderVerification? verification,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteModelConnection(String modelConnectionId) =>
      throw UnimplementedError();

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(
    String modelConnectionId,
  ) => throw UnimplementedError();

  @override
  Future<List<ModelConnectionEntity>> getModelConnections(
    ModelConnectionFilter filter,
  ) => throw UnimplementedError();

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String modelConnectionId,
    ModelConnectionToUpdate modelConnection, {
    ModelProviderVerification? verification,
  }) => throw UnimplementedError();

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => _subject.stream;
}

ModelConnectionEntity _modelConnection({
  required String id,
  required String workspaceId,
  required String name,
  required String modelId,
}) {
  final timestamp = DateTime(2026);

  return ModelConnectionEntity(
    id: id,
    name: name,
    modelId: modelId,
    createdAt: timestamp,
    updatedAt: timestamp,
    workspaceId: workspaceId,
    hasKey: true,
  );
}
