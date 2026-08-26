import 'dart:convert';

import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudWorkspaceResourceStore {
  CloudWorkspaceResourceStore(CloudWorkspaceStateGateway gateway)
    : _watch = gateway.watchResources,
      _patch = gateway.patch,
      _putSecret = gateway.putSecret,
      _mutateCredential = gateway.mutateCredential;

  CloudWorkspaceResourceStore.deferred(
    Future<CloudWorkspaceStateGateway?> gateway,
  ) : _watch = ((kinds) async* {
        yield* (await _requireGateway(gateway)).watchResources(kinds);
      }),
      _patch = (({required requestId, required operations}) async =>
          await (await _requireGateway(
            gateway,
          )).patch(requestId: requestId, operations: operations)),
      _putSecret =
          (({
            required requestId,
            required secretKind,
            required scope,
            required resourceId,
            secret,
            expectedRevision,
          }) async => await (await _requireGateway(gateway)).putSecret(
            requestId: requestId,
            secretKind: secretKind,
            scope: scope,
            resourceId: resourceId,
            secret: secret,
            expectedRevision: expectedRevision,
          )),
      _mutateCredential =
          (({
            required requestId,
            required resourceOperation,
            required secretKind,
            required scope,
            required secret,
            required clearSecret,
            expectedSecretRevision,
          }) async => await (await _requireGateway(gateway)).mutateCredential(
            requestId: requestId,
            resourceOperation: resourceOperation,
            secretKind: secretKind,
            scope: scope,
            secret: secret,
            clearSecret: clearSecret,
            expectedSecretRevision: expectedSecretRevision,
          ));

  const CloudWorkspaceResourceStore.forTesting({
    required this._watch,
    required this._patch,
    required this._putSecret,
    required this._mutateCredential,
  });

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

  Stream<List<WorkspaceResource>> watch(WorkspaceResourceKind kind) =>
      _watch([kind]);

  Future<void> create({
    required WorkspaceResourceKind kind,
    required String id,
    required Map<String, Object?> data,
  }) => _write(
    operation: WorkspacePatchOperationKind.create,
    kind: kind,
    id: id,
    data: data,
  );

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
            operation: WorkspacePatchOperationKind.create,
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
  }) => _write(
    operation: WorkspacePatchOperationKind.update,
    kind: kind,
    id: id,
    data: data,
    revision: revision,
  );

  Future<void> delete({
    required WorkspaceResourceKind kind,
    required String id,
    required int revision,
  }) => _write(
    operation: WorkspacePatchOperationKind.delete,
    kind: kind,
    id: id,
    revision: revision,
  );

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
    resourceOperation: WorkspacePatchOperation(
      operation: operation,
      resourceKind: kind,
      resourceId: id,
      data: data == null ? null : jsonEncode(data),
      fieldMask: const [],
      expectedRevision: resourceRevision,
    ),
    secretKind: secretKind,
    scope: scope,
    secret: secret,
    clearSecret: clearSecret,
    expectedSecretRevision: secretRevision,
  );

  Future<void> _write({
    required WorkspacePatchOperationKind operation,
    required WorkspaceResourceKind kind,
    required String id,
    Map<String, Object?>? data,
    int? revision,
  }) async {
    final _ = await _patch(
      requestId: const Uuid().v4(),
      operations: [
        WorkspacePatchOperation(
          operation: operation,
          resourceKind: kind,
          resourceId: id,
          data: data == null ? null : jsonEncode(data),
          fieldMask: const [],
          expectedRevision: revision,
        ),
      ],
    );
  }
}

Future<CloudWorkspaceStateGateway> _requireGateway(
  Future<CloudWorkspaceStateGateway?> gateway,
) async {
  return await gateway ??
      (throw const CloudAppException(
        localizationKey: LocaleKeys.cloud_errors_unavailable,
        context: CloudOperationContext.state,
        code: 'gatewayUnavailable',
      ));
}
