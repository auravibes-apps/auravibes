import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef _PutSecret = WorkspaceSecretCall;

typedef _CreateModelConnection = Future<ModelConnectionView> Function({
  required String connectionId,
  required String name,
  required String providerId,
  String? url,
});

typedef _UpdateModelConnection = Future<ModelConnectionView> Function({
  required String connectionId,
  required int expectedRevision,
  required String name,
  required String? url,
});

class CloudModelGateway {
  new(this._stateGateway)
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

  new forTesting({
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
  _PutSecret get putSecret => _stateGateway.putSecret;
  int get _workspaceId => _stateGateway.workspace.cloudWorkspaceId;
  Client get _client => _stateGateway.client;

  Future<List<ModelConnectionView>> listModelConnections() {
    final request = ListModelConnectionsRequest(workspaceId: _workspaceId);

    return CloudAppErrors.guardCall(
      .model,
      () => _list?.call(request) ?? _client.modelConnection.list(request),
    );
  }

  Future<ModelSyncResult> testAndSyncModelConnection({
    required String connectionId,
  }) => CloudAppErrors.guardCall(
    .model,
    () =>
        _testAndSync?.call(connectionId) ??
        _client.modelConnection.testAndSync(
          .new(workspaceId: _workspaceId, connectionId: connectionId),
        ),
  );
}

extension CloudModelGatewayConnections on CloudModelGateway {
  _CreateModelConnection get createModelConnection =>
      ({required connectionId, required name, required providerId, url}) =>
          _createModelConnection((
            connectionId: connectionId,
            name: name,
            providerId: providerId,
            url: url,
          ));

  Future<ModelConnectionView> _createModelConnection(
    ({String connectionId, String name, String providerId, String? url}) value,
  ) {
    final request = _createRequest(_workspaceId, value);

    return CloudAppErrors.guardCall(
      .model,
      () => _create?.call(request) ?? _client.modelConnection.create(request),
    );
  }

  Stream<List<ModelConnectionView>> watchModelConnections() => _stateGateway
      .watch(const {'modelConnection', 'secretConfiguredState'}, () async {
        final state = await _stateGateway.read(pages: const []);

        return (
          value: await listModelConnections(),
          currentSequence: state.currentSequence,
        );
      });
  _UpdateModelConnection get updateModelConnection =>
      ({
        required connectionId,
        required expectedRevision,
        required name,
        required url,
      }) => _updateModelConnection((
        connectionId: connectionId,
        expectedRevision: expectedRevision,
        name: name,
        url: url,
      ));

  Future<ModelConnectionView> _updateModelConnection(
    ({String connectionId, int expectedRevision, String name, String? url})
    value,
  ) {
    final request = _updateRequest(_workspaceId, value);

    return CloudAppErrors.guardCall(
      .model,
      () => _update?.call(request) ?? _client.modelConnection.update(request),
    );
  }

  Future<void> deleteModelConnection({
    required String connectionId,
    required int expectedRevision,
  }) => _deleteModelConnection((
    connectionId: connectionId,
    expectedRevision: expectedRevision,
  ));

  Future<void> _deleteModelConnection(
    ({String connectionId, int expectedRevision}) value,
  ) {
    final request = _deleteRequest(_workspaceId, value);

    return CloudAppErrors.guardCall(
      .model,
      () => _delete?.call(request) ?? _client.modelConnection.delete(request),
    );
  }
}

extension CloudModelGatewaySelections on CloudModelGateway {
  Future<List<WorkspaceModelSelectionView>> listModelSelections() {
    final request = ListWorkspaceModelSelectionsRequest(
      workspaceId: _workspaceId,
    );

    return CloudAppErrors.guardCall(
      .model,
      () =>
          _listSelections?.call(request) ??
          _client.modelConnection.listSelections(request),
    );
  }

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
}

extension CloudModelGatewayCatalog on CloudModelGateway {
  Future<List<ApiModelProvider>> listModelCatalogProviders() =>
      CloudAppErrors.guardCall(
        .model,
        () =>
            _listCatalogProviders?.call() ??
            _client.modelConnection.listCatalogProviders(),
      );
  Future<List<ApiModel>> listModelCatalogModels({String? providerId}) =>
      CloudAppErrors.guardCall(
        .model,
        () =>
            _listCatalogModels?.call(providerId: providerId) ??
            _client.modelConnection.listCatalogModels(providerId: providerId),
      );
  Future<StartCodexOAuthResult> startCodexOAuth({
    required String connectionId,
  }) => CloudAppErrors.guardCall(
    .oauth,
    () =>
        _startCodexOAuth?.call(connectionId) ??
        _client.codexOAuth.start(
          .new(workspaceId: _workspaceId, connectionId: connectionId),
        ),
  );
  Future<CompleteCodexOAuthResult> completeCodexOAuth({
    required String transactionId,
    required String state,
    required String code,
  }) => _completeCodexOAuthRequest((
    transactionId: transactionId,
    state: state,
    code: code,
  ));

  Future<CompleteCodexOAuthResult> _completeCodexOAuthRequest(
    ({String transactionId, String state, String code}) value,
  ) {
    final request = _completeRequest(value);

    return CloudAppErrors.guardCall(
      .oauth,
      () => _completeCodexOAuthCall(value, request),
    );
  }

  Future<CompleteCodexOAuthResult> _completeCodexOAuthCall(
    ({String transactionId, String state, String code}) value,
    CompleteCodexOAuthRequest request,
  ) =>
      _completeCodexOAuth?.call(
        transactionId: value.transactionId,
        state: value.state,
        code: value.code,
      ) ??
      _client.codexOAuth.complete(request);
}

CreateModelConnectionRequest _createRequest(
  int workspaceId,
  ({String connectionId, String name, String providerId, String? url}) value,
) => .new(
  workspaceId: workspaceId,
  requestId: const Uuid().v4(),
  connectionId: value.connectionId,
  name: value.name,
  providerId: value.providerId,
  url: value.url,
);

UpdateModelConnectionRequest _updateRequest(
  int workspaceId,
  ({String connectionId, int expectedRevision, String name, String? url}) value,
) => .new(
  workspaceId: workspaceId,
  requestId: const Uuid().v4(),
  connectionId: value.connectionId,
  expectedRevision: value.expectedRevision,
  name: value.name,
  url: value.url,
);

DeleteModelConnectionRequest _deleteRequest(
  int workspaceId,
  ({String connectionId, int expectedRevision}) value,
) => .new(
  workspaceId: workspaceId,
  requestId: const Uuid().v4(),
  connectionId: value.connectionId,
  expectedRevision: value.expectedRevision,
);

CompleteCodexOAuthRequest _completeRequest(
  ({String transactionId, String state, String code}) value,
) => .new(
  transactionId: value.transactionId,
  state: value.state,
  code: value.code,
);
