import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudModelGateway {
  CloudModelGateway(this._stateGateway)
    : _testAndSync = null,
      _create = null,
      _list = null,
      _update = null,
      _delete = null,
      _listSelections = null,
      _listCatalogProviders = null,
      _listCatalogModels = null,
      _startCodexOAuth = null,
      _completeCodexOAuth = null;

  CloudModelGateway.forTesting({
    required this._stateGateway,
    this._testAndSync,
    this._create,
    this._list,
    this._update,
    this._delete,
    this._listSelections,
    this._listCatalogProviders,
    this._listCatalogModels,
    this._startCodexOAuth,
    this._completeCodexOAuth,
  });

  final CloudWorkspaceStateGateway _stateGateway;
  final Future<ModelSyncResult> Function(String connectionId)? _testAndSync;
  final Future<ModelConnectionView> Function(
    CreateModelConnectionRequest request,
  )?
  _create;
  final Future<List<ModelConnectionView>> Function(
    ListModelConnectionsRequest request,
  )?
  _list;
  final Future<ModelConnectionView> Function(
    UpdateModelConnectionRequest request,
  )?
  _update;
  final Future<void> Function(DeleteModelConnectionRequest request)? _delete;
  final Future<List<WorkspaceModelSelectionView>> Function(
    ListWorkspaceModelSelectionsRequest request,
  )?
  _listSelections;
  final Future<List<ApiModelProvider>> Function()? _listCatalogProviders;
  final Future<List<ApiModel>> Function({String? providerId})?
  _listCatalogModels;
  final Future<StartCodexOAuthResult> Function(String connectionId)?
  _startCodexOAuth;
  final Future<CompleteCodexOAuthResult> Function({
    required String transactionId,
    required String state,
    required String code,
  })?
  _completeCodexOAuth;
  int get _workspaceId => _stateGateway.workspace.cloudWorkspaceId;
  Client get _client => _stateGateway.client;

  Future<PutWorkspaceSecretResponse> putSecret({
    required String requestId,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String resourceId,
    required String secret,
    int? expectedRevision,
  }) => _stateGateway.putSecret(
    requestId: requestId,
    secretKind: secretKind,
    scope: scope,
    resourceId: resourceId,
    secret: secret,
    expectedRevision: expectedRevision,
  );

  Future<ModelSyncResult> testAndSyncModelConnection({
    required String connectionId,
  }) => guardCloudCall(
    .model,
    () =>
        _testAndSync?.call(connectionId) ??
        _client.modelConnection.testAndSync(
          TestAndSyncModelConnectionRequest(
            workspaceId: _workspaceId,
            connectionId: connectionId,
          ),
        ),
  );
  Future<ModelConnectionView> createModelConnection({
    required String connectionId,
    required String name,
    required String providerId,
    String? url,
  }) => guardCloudCall(
    .model,
    () {
      final request = CreateModelConnectionRequest(
        workspaceId: _workspaceId,
        requestId: const Uuid().v4(),
        connectionId: connectionId,
        name: name,
        providerId: providerId,
        url: url,
      );

      return _create?.call(request) ?? _client.modelConnection.create(request);
    },
  );
  Future<List<ModelConnectionView>> listModelConnections() {
    final request = ListModelConnectionsRequest(workspaceId: _workspaceId);

    return guardCloudCall(
      .model,
      () => _list?.call(request) ?? _client.modelConnection.list(request),
    );
  }

  Stream<List<ModelConnectionView>> watchModelConnections() =>
      _stateGateway.watch(
        const {'modelConnection', 'secretConfiguredState'},
        () async {
          final state = await _stateGateway.read(pages: const []);

          return (
            value: await listModelConnections(),
            currentSequence: state.currentSequence,
          );
        },
      );
  Future<ModelConnectionView> updateModelConnection({
    required String connectionId,
    required int expectedRevision,
    required String name,
    required String? url,
  }) => guardCloudCall(
    .model,
    () {
      final request = UpdateModelConnectionRequest(
        workspaceId: _workspaceId,
        requestId: const Uuid().v4(),
        connectionId: connectionId,
        expectedRevision: expectedRevision,
        name: name,
        url: url,
      );

      return _update?.call(request) ?? _client.modelConnection.update(request);
    },
  );
  Future<void> deleteModelConnection({
    required String connectionId,
    required int expectedRevision,
  }) => guardCloudCall(
    .model,
    () {
      final request = DeleteModelConnectionRequest(
        workspaceId: _workspaceId,
        requestId: const Uuid().v4(),
        connectionId: connectionId,
        expectedRevision: expectedRevision,
      );

      return _delete?.call(request) ?? _client.modelConnection.delete(request);
    },
  );
  Future<List<WorkspaceModelSelectionView>> listModelSelections() =>
      guardCloudCall(
        .model,
        () {
          final request = ListWorkspaceModelSelectionsRequest(
            workspaceId: _workspaceId,
          );

          return _listSelections?.call(request) ??
              _client.modelConnection.listSelections(request);
        },
      );
  Stream<List<WorkspaceModelSelectionView>> watchModelSelections() =>
      _stateGateway.watch(
        const {'modelConnection', 'secretConfiguredState'},
        () async {
          final state = await _stateGateway.read(pages: const []);

          return (
            value: await listModelSelections(),
            currentSequence: state.currentSequence,
          );
        },
      );
  Future<List<ApiModelProvider>> listModelCatalogProviders() => guardCloudCall(
    .model,
    () =>
        _listCatalogProviders?.call() ??
        _client.modelConnection.listCatalogProviders(),
  );
  Future<List<ApiModel>> listModelCatalogModels({String? providerId}) =>
      guardCloudCall(
        .model,
        () =>
            _listCatalogModels?.call(providerId: providerId) ??
            _client.modelConnection.listCatalogModels(providerId: providerId),
      );
  Future<StartCodexOAuthResult> startCodexOAuth({
    required String connectionId,
  }) => guardCloudCall(
    .oauth,
    () =>
        _startCodexOAuth?.call(connectionId) ??
        _client.codexOAuth.start(
          StartCodexOAuthRequest(
            workspaceId: _workspaceId,
            connectionId: connectionId,
          ),
        ),
  );
  Future<CompleteCodexOAuthResult> completeCodexOAuth({
    required String transactionId,
    required String state,
    required String code,
  }) => guardCloudCall(
    .oauth,
    () =>
        _completeCodexOAuth?.call(
          transactionId: transactionId,
          state: state,
          code: code,
        ) ??
        _client.codexOAuth.complete(
          CompleteCodexOAuthRequest(
            transactionId: transactionId,
            state: state,
            code: code,
          ),
        ),
  );
}
