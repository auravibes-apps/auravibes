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
  final Future<PutWorkspaceSecretResponse> Function({
    required String requestId,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String resourceId,
    String? secret,
    int? expectedRevision,
  })
  _putSecret;
  final Future<MutateWorkspaceCredentialResponse> Function({
    required String requestId,
    required WorkspacePatchOperation resourceOperation,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String? secret,
    required bool clearSecret,
    int? expectedSecretRevision,
  })
  _mutateCredential;
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

  Stream<List<WorkspaceResource>> watchResources(
    List<WorkspaceResourceKind> kinds,
  ) => _watch(kinds);

  Stream<List<WorkspaceResource>> watch(WorkspaceResourceKind kind) =>
      watchResources([kind]);

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

  Future<PutWorkspaceSecretResponse> putSecret({
    required WorkspaceSecretKind kind,
    required WorkspaceSecretScope scope,
    required String resourceId,
    required String? secret,
    int? revision,
  }) {
    return _putSecret(
      requestId: const Uuid().v4(),
      secretKind: kind,
      scope: scope,
      resourceId: resourceId,
      secret: secret,
      expectedRevision: revision,
    );
  }

  Future<MutateWorkspaceCredentialResponse> mutateCredential({
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
  }) => _mutateCredential(
    requestId: const Uuid().v4(),
    resourceOperation: _resourceOperation((
      operation: operation,
      kind: kind,
      id: id,
      data: data,
      revision: resourceRevision,
    )),
    secretKind: secretKind,
    scope: scope,
    secret: secret,
    clearSecret: clearSecret,
    expectedSecretRevision: secretRevision,
  );
}

extension on CloudWorkspaceResourceStore {
  Future<void> createAll(
    Iterable<
      ({WorkspaceResourceKind kind, String id, Map<String, Object?> data})
    >
    resources,
  ) async {
    final _ = await _patch(
      requestId: const Uuid().v4(),
      operations: [
        for (final resource in resources)
          WorkspacePatchOperation(
            operation: .create,
            resourceKind: resource.kind,
            resourceId: resource.id,
            data: jsonEncode(resource.data),
            fieldMask: const [],
          ),
      ],
    );
  }

  Future<void> update({
    required WorkspaceResourceKind kind,
    required String id,
    required int revision,
    required Map<String, Object?> data,
  }) => _write((
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

  WorkspacePatchOperation _resourceOperation(
    ({
      WorkspacePatchOperationKind operation,
      WorkspaceResourceKind kind,
      String id,
      Map<String, Object?>? data,
      int? revision,
    })
    input,
  ) => WorkspacePatchOperation(
    operation: input.operation,
    resourceKind: input.kind,
    resourceId: input.id,
    data: input.data == null ? null : jsonEncode(input.data),
    fieldMask: const [],
    expectedRevision: input.revision,
  );

  Future<void> _write(
    ({
      WorkspacePatchOperationKind operation,
      WorkspaceResourceKind kind,
      String id,
      Map<String, Object?>? data,
      int? revision,
    })
    input,
  ) async {
    final _ = await _patch(
      requestId: const Uuid().v4(),
      operations: [
        WorkspacePatchOperation(
          operation: input.operation,
          resourceKind: input.kind,
          resourceId: input.id,
          data: input.data == null ? null : jsonEncode(input.data),
          fieldMask: const [],
          expectedRevision: input.revision,
        ),
      ],
    );
  }
}

Future<ReadWorkspaceStateResponse> _deferredRead(
  Future<CloudWorkspaceStateGateway?> gateway, {
  required List<WorkspaceResourcePageRequest> pages,
  required int eventLimit,
  int? afterSequence,
}) async => (await _requireGateway(gateway))
    .read(pages: pages, afterSequence: afterSequence, eventLimit: eventLimit);

WorkspaceResourceRead _deferredReadHandler(
  Future<CloudWorkspaceStateGateway?> gateway,
) {
  return ({
    required List<WorkspaceResourcePageRequest> pages,
    required int eventLimit,
    int? afterSequence,
  }) => _deferredRead(
    gateway,
    pages: pages,
    afterSequence: afterSequence,
    eventLimit: eventLimit,
  );
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

Future<PutWorkspaceSecretResponse> Function({
  required String requestId,
  required WorkspaceSecretKind secretKind,
  required WorkspaceSecretScope scope,
  required String resourceId,
  String? secret,
  int? expectedRevision,
})
_deferredPutSecretHandler(Future<CloudWorkspaceStateGateway?> gateway) {
  return ({
    required requestId,
    required secretKind,
    required scope,
    required resourceId,
    secret,
    expectedRevision,
  }) => _deferredPutSecret(
    gateway,
    requestId: requestId,
    secretKind: secretKind,
    scope: scope,
    resourceId: resourceId,
    secret: secret,
    expectedRevision: expectedRevision,
  );
}

Future<MutateWorkspaceCredentialResponse> Function({
  required String requestId,
  required WorkspacePatchOperation resourceOperation,
  required WorkspaceSecretKind secretKind,
  required WorkspaceSecretScope scope,
  required String? secret,
  required bool clearSecret,
  int? expectedSecretRevision,
})
_deferredMutateCredentialHandler(Future<CloudWorkspaceStateGateway?> gateway) {
  return ({
    required requestId,
    required resourceOperation,
    required secretKind,
    required scope,
    required secret,
    required clearSecret,
    expectedSecretRevision,
  }) => _deferredMutateCredential(
    gateway,
    requestId: requestId,
    resourceOperation: resourceOperation,
    secretKind: secretKind,
    scope: scope,
    secret: secret,
    clearSecret: clearSecret,
    expectedSecretRevision: expectedSecretRevision,
  );
}

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
    (await _requireGateway(gateway))
        .patch(requestId: requestId, operations: operations);

Future<PutWorkspaceSecretResponse> _deferredPutSecret(
  Future<CloudWorkspaceStateGateway?> gateway, {
  required String requestId,
  required WorkspaceSecretKind secretKind,
  required WorkspaceSecretScope scope,
  required String resourceId,
  String? secret,
  int? expectedRevision,
}) async => (await _requireGateway(gateway)).putSecret(
  requestId: requestId,
  secretKind: secretKind,
  scope: scope,
  resourceId: resourceId,
  secret: secret,
  expectedRevision: expectedRevision,
);

Future<MutateWorkspaceCredentialResponse> _deferredMutateCredential(
  Future<CloudWorkspaceStateGateway?> gateway, {
  required String requestId,
  required WorkspacePatchOperation resourceOperation,
  required WorkspaceSecretKind secretKind,
  required WorkspaceSecretScope scope,
  required String? secret,
  required bool clearSecret,
  int? expectedSecretRevision,
}) async => (await _requireGateway(gateway)).mutateCredential(
  requestId: requestId,
  resourceOperation: resourceOperation,
  secretKind: secretKind,
  scope: scope,
  secret: secret,
  clearSecret: clearSecret,
  expectedSecretRevision: expectedSecretRevision,
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
