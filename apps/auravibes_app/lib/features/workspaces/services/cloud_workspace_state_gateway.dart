import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef WorkspaceStateRead =
    Future<ReadWorkspaceStateResponse> Function(
      ReadWorkspaceStateRequest request,
    );
typedef WorkspaceStreamSubscribe =
    Stream<WorkspaceStreamEnvelope> Function(
      WorkspaceSubscribeRequest request,
    );
typedef WorkspaceSecretPut =
    Future<PutWorkspaceSecretResponse> Function(
      PutWorkspaceSecretRequest request,
    );
typedef WorkspaceCredentialMutation =
    Future<MutateWorkspaceCredentialResponse> Function(
      MutateWorkspaceCredentialRequest request,
    );
typedef WorkspaceReconnectDelay = Future<void> Function(Duration duration);

class CloudWorkspaceStateGateway {
  static const _pageSize = 100;
  static const _stateReadTimeout = Duration(seconds: 15);
  static const _initialReconnectDelay = Duration(milliseconds: 250);
  static const _maxReconnectDelay = Duration(seconds: 8);
  CloudWorkspaceStateGateway({
    required Client client,
    required CloudWorkspaceRef workspace,
    this.readTimeout = _stateReadTimeout,
  }) : _client = client,
       // Keep the public `workspace:` argument stable for gateway consumers.
       // ignore: prefer_initializing_formals
       _workspace = workspace,
       _readState = client.workspaceState.read,
       _subscribe = client.workspaceStream.subscribe,
       _putSecret = null,
       _mutateCredential = null,
       _delay = _defaultDelay;

  CloudWorkspaceStateGateway.forTesting({
    required this._workspace,
    required this._readState,
    required this._subscribe,
    this._putSecret,
    this._mutateCredential,
    this._delay = _defaultDelay,
    this.readTimeout = _stateReadTimeout,
  }) : _client = null;
  final Duration readTimeout;
  final WorkspaceSecretPut? _putSecret;
  final CloudWorkspaceRef _workspace;
  final WorkspaceStateRead _readState;
  final WorkspaceStreamSubscribe _subscribe;
  final WorkspaceCredentialMutation? _mutateCredential;
  final WorkspaceReconnectDelay _delay;

  final Client? _client;
  Future<void> _readTail = Future.value();
  bool _disposed = false;
  final _disposedSignal = Completer<bool>();

  bool get isDisposed => _disposed;

  Client get client => _requiredClient;

  CloudWorkspaceRef get workspace => _workspace;

  Client get _requiredClient {
    final client = _client;
    if (client == null) {
      throw StateError('Client operations are unavailable in test gateways');
    }

    return client;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disposedSignal.complete(false);
  }

  Future<ReadWorkspaceStateResponse> read({
    required List<WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    int eventLimit = _pageSize,
  }) {
    final request = ReadWorkspaceStateRequest(
      workspaceId: _workspace.cloudWorkspaceId,
      pages: pages,
      afterSequence: afterSequence,
      eventLimit: eventLimit,
    );
    final read = _enqueueRead(request);

    return CloudAppErrors.guardCall(.state, () => read.timeout(readTimeout));
  }

  Future<PatchWorkspaceStateResponse> patch({
    required String requestId,
    required List<WorkspacePatchOperation> operations,
  }) => CloudAppErrors.guardCall(
    .state,
    () => _requiredClient.workspaceState.patch(
      PatchWorkspaceStateRequest(
        workspaceId: _workspace.cloudWorkspaceId,
        requestId: requestId,
        operations: operations,
      ),
    ),
  );

  Future<PutWorkspaceSecretResponse> putSecret({
    required String requestId,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String resourceId,
    String? secret,
    int? expectedRevision,
  }) {
    final request = PutWorkspaceSecretRequest(
      workspaceId: _workspace.cloudWorkspaceId,
      requestId: requestId,
      secretKind: secretKind,
      scope: scope,
      resourceId: resourceId,
      secret: secret,
      expectedRevision: expectedRevision,
    );
    final putSecret = _putSecret;

    return CloudAppErrors.guardCall(
      .state,
      () =>
          putSecret?.call(request) ??
          _requiredClient.workspaceSecret.put(request),
    );
  }

  Future<MutateWorkspaceCredentialResponse> mutateCredential({
    required String requestId,
    required WorkspacePatchOperation resourceOperation,
    required WorkspaceSecretKind secretKind,
    required WorkspaceSecretScope scope,
    required String? secret,
    required bool clearSecret,
    int? expectedSecretRevision,
  }) {
    final request = MutateWorkspaceCredentialRequest(
      workspaceId: _workspace.cloudWorkspaceId,
      requestId: requestId,
      resourceOperation: resourceOperation,
      secretKind: secretKind,
      scope: scope,
      secret: secret,
      clearSecret: clearSecret,
      expectedSecretRevision: expectedSecretRevision,
    );
    final mutateCredential = _mutateCredential;

    return CloudAppErrors.guardCall(
      .state,
      () =>
          mutateCredential?.call(request) ??
          _requiredClient.workspaceState.mutateCredential(request),
    );
  }

  Stream<List<WorkspaceResource>> watchResources(
    List<WorkspaceResourceKind> kinds, {
    int limit = _pageSize,
  }) => watch(
    kinds.map((kind) => kind.name).toSet(),
    () async {
      final snapshot = await _readAll(kinds, limit.clamp(1, _pageSize));

      return (
        value: snapshot.resources,
        currentSequence: snapshot.currentSequence,
      );
    },
  );

  Stream<T> watch<T>(
    Set<String> resourceKinds,
    Future<({T value, int currentSequence})> Function() load,
  ) async* {
    if (_disposed) return;
    var snapshot = await load();
    var lastSequence = snapshot.currentSequence;
    yield snapshot.value;

    var reconnectDelay = _initialReconnectDelay;
    while (!_disposed) {
      final events = StreamIterator(
        _subscribe(
          WorkspaceSubscribeRequest(
            workspaceId: _workspace.cloudWorkspaceId,
            afterSequence: lastSequence,
            activeTurnIds: const [],
          ),
        ),
      );
      try {
        while (await Future.any([
          events.moveNext(),
          _disposedSignal.future,
        ])) {
          final event = events.current;
          if (event.sequence <= lastSequence) continue;

          final hasGap = event.sequence != lastSequence + 1;
          lastSequence = event.sequence;
          reconnectDelay = _initialReconnectDelay;
          final affectsResources =
              event.kind == WorkspaceStreamEnvelopeKind.workspaceInvalidated &&
              resourceKinds.contains(event.resourceKind);
          if (!hasGap && !affectsResources) continue;

          snapshot = await load();
          lastSequence = snapshot.currentSequence;
          yield snapshot.value;
        }
      } on CloudWorkspaceException catch (error) {
        if (_isTerminal(error.code)) {
          CloudAppErrors.translateException(error, CloudOperationContext.state);
        }
      } on CloudAppException catch (error) {
        if (_isTerminalCode(error.code)) {
          rethrow;
        }
      } on Object catch (_) {
        if (_disposed) return;
      } finally {
        final _ = await events.cancel();
      }
      if (_disposed) return;
      await Future.any([
        _delay(reconnectDelay),
        _disposedSignal.future,
      ]);
      reconnectDelay = Duration(
        milliseconds: (reconnectDelay.inMilliseconds * 2).clamp(
          _initialReconnectDelay.inMilliseconds,
          _maxReconnectDelay.inMilliseconds,
        ),
      );
    }
  }

  static bool _isTerminalCode(String? code) =>
      code == CloudWorkspaceErrorCode.authenticationRequired.name ||
      code == CloudWorkspaceErrorCode.membershipRequired.name ||
      code == CloudWorkspaceErrorCode.workspaceNotFound.name;

  Future<ReadWorkspaceStateResponse> _enqueueRead(
    ReadWorkspaceStateRequest request,
  ) async {
    final previousRead = _readTail;
    final completion = Completer<void>();
    _readTail = completion.future;
    await previousRead;
    try {
      return await _readState(request);
    } finally {
      completion.complete();
    }
  }

  Future<({List<WorkspaceResource> resources, int currentSequence})> _readAll(
    List<WorkspaceResourceKind> kinds,
    int pageSize,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final resources = <WorkspaceResource>[];
      final seenResourceIds = <String>{};
      int? sequence;
      var coherent = true;
      for (final kind in kinds) {
        final cursors = <String>{};
        String? cursor;
        do {
          final state = await read(
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: kind,
                afterResourceId: cursor,
                limit: pageSize,
              ),
            ],
          );
          sequence ??= state.currentSequence;
          if (state.currentSequence != sequence) {
            coherent = false;
            break;
          }
          if (state.pages.length != 1 ||
              state.pages.single.resourceKind != kind) {
            _malformedSnapshot('unexpectedPage');
          }
          final page = state.pages.single;
          for (final resource in page.resources) {
            if (resource.resourceKind != kind) {
              _malformedSnapshot('unexpectedKind');
            }
            if (seenResourceIds.add('${kind.name}/${resource.resourceId}')) {
              resources.add(resource);
            }
          }
          cursor = page.nextResourceId;
          if (cursor != null && (cursor.isEmpty || !cursors.add(cursor))) {
            _malformedSnapshot('invalidCursor');
          }
        } while (cursor != null);
        if (!coherent) break;
      }
      if (coherent) {
        return (resources: resources, currentSequence: sequence ?? 0);
      }
    }
    _malformedSnapshot('incoherentSnapshot');
  }

  Never _malformedSnapshot(String code) => throw CloudAppException(
    localizationKey: LocaleKeys.cloud_errors_malformed_resource,
    context: CloudOperationContext.resource,
    code: code,
  );

  static bool _isTerminal(CloudWorkspaceErrorCode code) =>
      code == CloudWorkspaceErrorCode.authenticationRequired ||
      code == CloudWorkspaceErrorCode.membershipRequired ||
      code == CloudWorkspaceErrorCode.workspaceNotFound;

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}
