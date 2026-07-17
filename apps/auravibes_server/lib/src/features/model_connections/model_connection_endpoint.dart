import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'repositories/model_catalog_repository.dart';
import 'repositories/model_connection_repository.dart';
import 'usecases/model_catalog_usecases.dart';
import 'usecases/model_connection_usecases.dart';

class ModelConnectionEndpoint extends Endpoint {
  ModelConnectionUseCases get _useCases =>
      ModelConnectionUseCases(ModelConnectionRepository());
  ModelCatalogUseCases get _catalogUseCases =>
      ModelCatalogUseCases(ModelCatalogRepository());

  Future<List<ApiModelProvider>> listCatalogProviders(Session session) async {
    await const AuthenticatedAccountResolver()(session);
    return _catalogUseCases.listProviders(session);
  }

  Future<List<ApiModel>> listCatalogModels(
    Session session, {
    String? providerId,
  }) async {
    await const AuthenticatedAccountResolver()(session);
    return _catalogUseCases.listModels(session, providerId: providerId);
  }

  Future<ModelConnectionView> create(
    Session session,
    CreateModelConnectionRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final connection = await _useCases.create(
      session,
      userId: account.userId,
      request: request,
    );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return connection;
  }

  Future<List<ModelConnectionView>> list(
    Session session,
    ListModelConnectionsRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.list(session, userId: account.userId, request: request);
  }

  Future<ModelConnectionView> update(
    Session session,
    UpdateModelConnectionRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final connection = await _useCases.update(
      session,
      userId: account.userId,
      request: request,
    );
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return connection;
  }

  Future<void> delete(
    Session session,
    DeleteModelConnectionRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await _useCases.delete(session, userId: account.userId, request: request);
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
  }

  Future<List<WorkspaceModelSelectionView>> listSelections(
    Session session,
    ListWorkspaceModelSelectionsRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.listSelections(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ModelSyncResult> testAndSync(
    Session session,
    TestAndSyncModelConnectionRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.testAndSync(
      session,
      userId: account.userId,
      request: request,
    );
  }
}
