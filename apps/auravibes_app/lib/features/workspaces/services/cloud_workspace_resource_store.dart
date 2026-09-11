import 'dart:convert';

import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef WorkspaceResourceRead = Future<ReadWorkspaceStateResponse> Function({
  required List<WorkspaceResourcePageRequest> pages,
  required int eventLimit,
  int? afterSequence,
});
typedef _WorkspaceSecretWrite = Future<PutWorkspaceSecretResponse> Function({
  required WorkspaceSecretKind kind,
  required WorkspaceSecretScope scope,
  required String resourceId,
  required String? secret,
  int? revision,
});
typedef _WorkspaceCredentialWrite =
    Future<MutateWorkspaceCredentialResponse> Function({
      required WorkspacePatchOperationKind operation,
      required WorkspaceResourceKind kind,
      required String id,
      required WorkspaceSecretKind secretKind,
      required WorkspaceSecretScope scope,
      required String? secret,
      bool clearSecret,
      Map<String, Object?>? data,
      int? resourceRevision,
      int? secretRevision,
    });
typedef _DeferredReadInput = ({
  Future<CloudWorkspaceStateGateway?> gateway,
  List<WorkspaceResourcePageRequest> pages,
  int eventLimit,
  int? afterSequence,
});
typedef _DeferredSecretInput = ({
  String requestId,
  WorkspaceSecretKind secretKind,
  WorkspaceSecretScope scope,
  String resourceId,
  String? secret,
  int? expectedRevision,
});
typedef _DeferredCredentialInput = ({
  String requestId,
  WorkspacePatchOperation resourceOperation,
  WorkspaceSecretKind secretKind,
  WorkspaceSecretScope scope,
  String? secret,
  bool clearSecret,
  int? expectedSecretRevision,
});
typedef _WorkspaceSecretInput = ({
  WorkspaceSecretKind kind,
  WorkspaceSecretScope scope,
  String resourceId,
  String? secret,
  int? revision,
});
typedef _WorkspaceResourceOperationInput = ({
  WorkspacePatchOperationKind operation,
  WorkspaceResourceKind kind,
  String id,
  Map<String, Object?>? data,
  int? revision,
});
typedef _WorkspaceCredentialInput = ({
  WorkspacePatchOperationKind operation,
  WorkspaceResourceKind kind,
  String id,
  WorkspaceSecretKind secretKind,
  WorkspaceSecretScope scope,
  String? secret,
  bool clearSecret,
  Map<String, Object?>? data,
  int? resourceRevision,
  int? secretRevision,
});
typedef _WorkspaceCredentialSend =
    Future<MutateWorkspaceCredentialResponse> Function(
      _WorkspaceCredentialInput input,
    );
typedef _WorkspaceSecretCall = Future<PutWorkspaceSecretResponse> Function({
  required String requestId,
  required WorkspaceSecretKind secretKind,
  required WorkspaceSecretScope scope,
  required String resourceId,
  String? secret,
  int? expectedRevision,
});
typedef _WorkspaceCredentialCall =
    Future<MutateWorkspaceCredentialResponse> Function({
      required String requestId,
      required WorkspacePatchOperation resourceOperation,
      required WorkspaceSecretKind secretKind,
      required WorkspaceSecretScope scope,
      required String? secret,
      required bool clearSecret,
      required int? expectedSecretRevision,
    });

class _SecretWriter {
  new(this._putSecret);

  final _WorkspaceSecretCall _putSecret;

  Future<PutWorkspaceSecretResponse> call({
    required WorkspaceSecretKind kind,
    required WorkspaceSecretScope scope,
    required String resourceId,
    required String? secret,
    int? revision,
  }) => _sendSecret(_putSecret, (
    kind: kind,
    scope: scope,
    resourceId: resourceId,
    secret: secret,
    revision: revision,
  ));
}

class _CredentialWriter {
  new(this._send);

  final _WorkspaceCredentialSend _send;

  Future<MutateWorkspaceCredentialResponse> call({
    required WorkspacePatchOperationKind operation,
    required WorkspaceResourceKind kind,
    required String id,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String? secret,
    bool clearSecret = false,
    Map<String, Object?>? data,
    int? resourceRevision,
    int? secretRevision,
  }) => _send((
    operation: operation,
    kind: kind,
    id: id,
    secretKind: secretKind,
    scope: scope,
    secret: secret,
    clearSecret: clearSecret,
    data: data,
    resourceRevision: resourceRevision,
    secretRevision: secretRevision,
  ));
}

class _CredentialSender {
  new(this._mutateCredential);

  final _WorkspaceCredentialCall _mutateCredential;

  Future<MutateWorkspaceCredentialResponse> call(
    _WorkspaceCredentialInput input,
  ) => _mutateCredential(
    requestId: const Uuid().v4(),
    resourceOperation: _credentialResourceOperation(input),
    secretKind: input.secretKind,
    scope: input.scope,
    secret: input.secret,
    clearSecret: input.clearSecret,
    expectedSecretRevision: input.secretRevision,
  );
}

class CloudWorkspaceResourceStore {
  new(CloudWorkspaceStateGateway gateway)
    : _read = gateway.read,
      _watch = gateway.watchResources,
      _patch = gateway.patch,
      _putSecret = gateway.putSecret,
      _mutateCredential = gateway.mutateCredential;

  new deferred(Future<CloudWorkspaceStateGateway?> gateway)
    : _read = _deferredReadHandler(gateway),
      _watch = _deferredWatchHandler(gateway),
      _patch = _deferredPatchHandler(gateway),
      _putSecret = _deferredPutSecretHandler(gateway),
      _mutateCredential = _deferredMutateCredentialHandler(gateway);

  const new forTesting({
    required this._watch,
    required this._patch,
    required this._putSecret,
    required this._mutateCredential,
    this._read = _unsupportedRead,
  });

  final WorkspaceResourceRead _read;
  final Stream<List<WorkspaceResource>> Function(
    List<WorkspaceResourceKind> kinds,
  )
  _watch;
  final Future<PatchWorkspaceStateResponse> Function({
    required String requestId,
    required List<WorkspacePatchOperation> operations,
  })
  _patch;
  final _WorkspaceSecretCall _putSecret;
  final _WorkspaceCredentialCall _mutateCredential;

  Future<ReadWorkspaceStateResponse> read({
    required List<WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    int eventLimit = 100,
  }) =>
      _read(pages: pages, afterSequence: afterSequence, eventLimit: eventLimit);

  Future<PatchWorkspaceStateResponse> patch({
    required String requestId,
    required List<WorkspacePatchOperation> operations,
  }) => _patch(requestId: requestId, operations: operations);
}

_WorkspaceSecretWrite _secretWriter(_WorkspaceSecretCall putSecret) =>
    _SecretWriter(putSecret).call;

Future<PutWorkspaceSecretResponse> _sendSecret(
  _WorkspaceSecretCall putSecret,
  _WorkspaceSecretInput input,
) => putSecret(
  requestId: const Uuid().v4(),
  secretKind: input.kind,
  scope: input.scope,
  resourceId: input.resourceId,
  secret: input.secret,
  expectedRevision: input.revision,
);

WorkspacePatchOperation _resourceOperation(
  _WorkspaceResourceOperationInput input,
) => WorkspacePatchOperation(
  operation: input.operation,
  resourceKind: input.kind,
  resourceId: input.id,
  data: input.data == null ? null : jsonEncode(input.data),
  fieldMask: const [],
  expectedRevision: input.revision,
);

WorkspacePatchOperation _credentialResourceOperation(
  _WorkspaceCredentialInput input,
) => _resourceOperation((
  operation: input.operation,
  kind: input.kind,
  id: input.id,
  data: input.data,
  revision: input.resourceRevision,
));

_WorkspaceCredentialWrite _credentialWriter(_WorkspaceCredentialSend send) =>
    _CredentialWriter(send).call;

extension CloudWorkspaceResourceStoreAccess on CloudWorkspaceResourceStore {
  _WorkspaceSecretWrite get putSecret => _secretWriter(_putSecret);

  _WorkspaceCredentialWrite get mutateCredential =>
      _credentialWriter(_CredentialSender(_mutateCredential).call);

  Stream<List<WorkspaceResource>> watchResources(
    List<WorkspaceResourceKind> kinds,
  ) => _watch(kinds);

  Stream<List<WorkspaceResource>> watch(WorkspaceResourceKind kind) =>
      watchResources([kind]);
}

extension CloudWorkspaceResourceStoreWrites on CloudWorkspaceResourceStore {
  Future<void> create({
    required WorkspaceResourceKind kind,
    required String id,
    required Map<String, Object?> data,
  }) => _write((
    operation: .create,
    kind: kind,
    id: id,
    data: data,
    revision: null,
  ));

  Future<void> createAll(
    Iterable<
      ({WorkspaceResourceKind kind, String id, Map<String, Object?> data})
    >
    resources,
  ) async {
    final _ = await _patch(
      requestId: const Uuid().v4(),
      operations: _createOperations(resources),
    );
  }

  _WorkspaceUpdate get update =>
      ({required kind, required id, required revision, required data}) =>
          _write((
            operation: .update,
            kind: kind,
            id: id,
            data: data,
            revision: revision,
          ));

  Future<void> delete({
    required WorkspaceResourceKind kind,
    required String id,
    required int revision,
  }) => _write((
    operation: .delete,
    kind: kind,
    id: id,
    data: null,
    revision: revision,
  ));

  Future<void> _write(_WorkspaceResourceOperationInput input) async {
    final _ = await _patch(
      requestId: const Uuid().v4(),
      operations: [_resourceOperation(input)],
    );
  }

  List<WorkspacePatchOperation> _createOperations(
    Iterable<
      ({WorkspaceResourceKind kind, String id, Map<String, Object?> data})
    >
    resources,
  ) => [
    for (final resource in resources)
      WorkspacePatchOperation(
        operation: .create,
        resourceKind: resource.kind,
        resourceId: resource.id,
        data: jsonEncode(resource.data),
        fieldMask: const [],
      ),
  ];
}

typedef _WorkspaceUpdate = Future<void> Function({
  required WorkspaceResourceKind kind,
  required String id,
  required int revision,
  required Map<String, Object?> data,
});

class _DeferredPutSecretCall {
  new(this._gateway);

  final Future<CloudWorkspaceStateGateway?> _gateway;

  Future<PutWorkspaceSecretResponse> call({
    required String requestId,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String resourceId,
    String? secret,
    int? expectedRevision,
  }) => _deferredPutSecret(_gateway, (
    requestId: requestId,
    secretKind: secretKind,
    scope: scope,
    resourceId: resourceId,
    secret: secret,
    expectedRevision: expectedRevision,
  ));
}

class _DeferredMutateCredentialCall {
  new(this._gateway);

  final Future<CloudWorkspaceStateGateway?> _gateway;

  Future<MutateWorkspaceCredentialResponse> call({
    required String requestId,
    required WorkspacePatchOperation resourceOperation,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String? secret,
    required bool clearSecret,
    required int? expectedSecretRevision,
  }) => _deferredMutateCredential(_gateway, (
    requestId: requestId,
    resourceOperation: resourceOperation,
    secretKind: secretKind,
    scope: scope,
    secret: secret,
    clearSecret: clearSecret,
    expectedSecretRevision: expectedSecretRevision,
  ));
}

Future<ReadWorkspaceStateResponse> _deferredRead(
  _DeferredReadInput input,
) async => await (await _requireGateway(input.gateway)).read(
  pages: input.pages,
  eventLimit: input.eventLimit,
  afterSequence: input.afterSequence,
);

WorkspaceResourceRead _deferredReadHandler(
  Future<CloudWorkspaceStateGateway?> gateway,
) {
  return ({
    required List<WorkspaceResourcePageRequest> pages,
    required int eventLimit,
    int? afterSequence,
  }) => _deferredRead((
    gateway: gateway,
    pages: pages,
    eventLimit: eventLimit,
    afterSequence: afterSequence,
  ));
}

Stream<List<WorkspaceResource>> Function(List<WorkspaceResourceKind>)
_deferredWatchHandler(Future<CloudWorkspaceStateGateway?> gateway) {
  return (kinds) => _deferredWatch(gateway, kinds);
}

Future<PatchWorkspaceStateResponse> Function({
  required String requestId,
  required List<WorkspacePatchOperation> operations,
})
_deferredPatchHandler(Future<CloudWorkspaceStateGateway?> gateway) {
  return ({required requestId, required operations}) =>
      _deferredPatch(gateway, requestId: requestId, operations: operations);
}

_WorkspaceSecretCall _deferredPutSecretHandler(
  Future<CloudWorkspaceStateGateway?> gateway,
) => _DeferredPutSecretCall(gateway).call;

_WorkspaceCredentialCall _deferredMutateCredentialHandler(
  Future<CloudWorkspaceStateGateway?> gateway,
) => _DeferredMutateCredentialCall(gateway).call;

Stream<List<WorkspaceResource>> _deferredWatch(
  Future<CloudWorkspaceStateGateway?> gateway,
  List<WorkspaceResourceKind> kinds,
) async* {
  yield* (await _requireGateway(gateway)).watchResources(kinds);
}

Future<PatchWorkspaceStateResponse> _deferredPatch(
  Future<CloudWorkspaceStateGateway?> gateway, {
  required String requestId,
  required List<WorkspacePatchOperation> operations,
}) async =>
    await (await _requireGateway(gateway))
        .patch(requestId: requestId, operations: operations);

Future<PutWorkspaceSecretResponse> _deferredPutSecret(
  Future<CloudWorkspaceStateGateway?> gateway,
  _DeferredSecretInput input,
) async => await (await _requireGateway(gateway)).putSecret(
  requestId: input.requestId,
  secretKind: input.secretKind,
  scope: input.scope,
  resourceId: input.resourceId,
  secret: input.secret,
  expectedRevision: input.expectedRevision,
);

Future<MutateWorkspaceCredentialResponse> _deferredMutateCredential(
  Future<CloudWorkspaceStateGateway?> gateway,
  _DeferredCredentialInput input,
) async => await (await _requireGateway(gateway)).mutateCredential(
  requestId: input.requestId,
  resourceOperation: input.resourceOperation,
  secretKind: input.secretKind,
  scope: input.scope,
  secret: input.secret,
  clearSecret: input.clearSecret,
  expectedSecretRevision: input.expectedSecretRevision,
);

Future<ReadWorkspaceStateResponse> _unsupportedRead({
  required List<WorkspaceResourcePageRequest> pages,
  required int eventLimit,
  int? afterSequence,
}) => throw UnimplementedError('$pages$afterSequence$eventLimit');

Future<CloudWorkspaceStateGateway> _requireGateway(
  Future<CloudWorkspaceStateGateway?> gateway,
) async {
  return await gateway ??
      (throw const CloudAppException(
        localizationKey: LocaleKeys.cloud_errors_unavailable,
        context: .state,
        code: 'gatewayUnavailable',
      ));
}
