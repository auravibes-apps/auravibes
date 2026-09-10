import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef WorkspaceStateRead = Future<ReadWorkspaceStateResponse> Function(
  ReadWorkspaceStateRequest request,
);
typedef WorkspaceStreamSubscribe = Stream<WorkspaceStreamEnvelope> Function(
  WorkspaceSubscribeRequest request,
);
typedef WorkspaceSecretPut = Future<PutWorkspaceSecretResponse> Function(
  PutWorkspaceSecretRequest request,
);
typedef WorkspaceSecretCall = Future<PutWorkspaceSecretResponse> Function({
  required String requestId,
  required WorkspaceSecretKind secretKind,
  required WorkspaceSecretScope scope,
  required String resourceId,
  String? secret,
  int? expectedRevision,
});
typedef WorkspaceCredentialMutation =
    Future<MutateWorkspaceCredentialResponse> Function(
      MutateWorkspaceCredentialRequest request,
    );
typedef WorkspaceCredentialCall =
    Future<MutateWorkspaceCredentialResponse> Function({
      required String requestId,
      required WorkspacePatchOperation resourceOperation,
      required WorkspaceSecretKind secretKind,
      required WorkspaceSecretScope scope,
      required String? secret,
      required bool clearSecret,
      int? expectedSecretRevision,
    });
typedef WorkspaceReconnectDelay = Future<void> Function(Duration duration);

class CloudWorkspaceStateGateway {
  static const _pageSize = 100;
  static const _stateReadTimeout = Duration(seconds: 15);
  static const _initialReconnectDelay = Duration(milliseconds: 250);
  static const _maxReconnectDelay = Duration(seconds: 8);
  new({
    required Client client,
    required this._workspace,
    this.readTimeout = _stateReadTimeout,
  }) : _client = client,
       _readState = client.workspaceState.read,
       _subscribe = client.workspaceStream.subscribe,
       _putSecret = null,
       _mutateCredential = null,
       _delay = _defaultDelay;

  new forTesting({
    required this._workspace,
    required this._readState,
    required this._subscribe,
    this._putSecret,
    this._mutateCredential,
    this._delay = _defaultDelay,
    this.readTimeout = _stateReadTimeout,
  }) : _client = null;

  @override
  final Duration readTimeout;
  @override
  final WorkspaceSecretPut? _putSecret;
  @override
  final CloudWorkspaceRef _workspace;
  @override
  final WorkspaceStateRead _readState;
  @override
  final WorkspaceStreamSubscribe _subscribe;
  @override
  final WorkspaceCredentialMutation? _mutateCredential;
  @override
  final WorkspaceReconnectDelay _delay;

  @override
  final Client? _client;
  @override
  Future<void> _readTail = .value();
  @override
  bool _disposed = false;
  @override
  final _disposedSignal = Completer<bool>();

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}

extension CloudWorkspaceStateGatewayCore on CloudWorkspaceStateGateway {
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
    int eventLimit = CloudWorkspaceStateGateway._pageSize,
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
      .new(
        workspaceId: _workspace.cloudWorkspaceId,
        requestId: requestId,
        operations: operations,
      ),
    ),
  );
}

extension CloudWorkspaceStateGatewaySecrets on CloudWorkspaceStateGateway {
  WorkspaceSecretCall get putSecret =>
      ({
        required requestId,
        required secretKind,
        required scope,
        required resourceId,
        secret,
        expectedRevision,
      }) => _putSecretRequest((
        requestId: requestId,
        secretKind: secretKind,
        scope: scope,
        resourceId: resourceId,
        secret: secret,
        expectedRevision: expectedRevision,
      ));

  Future<PutWorkspaceSecretResponse> _putSecretRequest(
    ({
      String requestId,
      WorkspaceSecretKind secretKind,
      WorkspaceSecretScope scope,
      String resourceId,
      String? secret,
      int? expectedRevision,
    })
    input,
  ) {
    final request = _buildPutSecretRequest(input);
    final putSecret = _putSecret;

    return CloudAppErrors.guardCall(
      .state,
      () =>
          putSecret?.call(request) ??
          _requiredClient.workspaceSecret.put(request),
    );
  }

  PutWorkspaceSecretRequest _buildPutSecretRequest(
    ({
      String requestId,
      WorkspaceSecretKind secretKind,
      WorkspaceSecretScope scope,
      String resourceId,
      String? secret,
      int? expectedRevision,
    })
    input,
  ) => PutWorkspaceSecretRequest(
    workspaceId: _workspace.cloudWorkspaceId,
    requestId: input.requestId,
    secretKind: input.secretKind,
    scope: input.scope,
    resourceId: input.resourceId,
    secret: input.secret,
    expectedRevision: input.expectedRevision,
  );

  WorkspaceCredentialCall get mutateCredential =>
      ({
        required requestId,
        required resourceOperation,
        required secretKind,
        required scope,
        required secret,
        required clearSecret,
        expectedSecretRevision,
      }) => _mutateCredentialRequest((
        requestId: requestId,
        resourceOperation: resourceOperation,
        secretKind: secretKind,
        scope: scope,
        secret: secret,
        clearSecret: clearSecret,
        expectedSecretRevision: expectedSecretRevision,
      ));

  Future<MutateWorkspaceCredentialResponse> _mutateCredentialRequest(
    ({
      String requestId,
      WorkspacePatchOperation resourceOperation,
      WorkspaceSecretKind secretKind,
      WorkspaceSecretScope scope,
      String? secret,
      bool clearSecret,
      int? expectedSecretRevision,
    })
    input,
  ) {
    final request = _credentialRequest(input);
    final mutateCredential = _mutateCredential;

    return CloudAppErrors.guardCall(
      .state,
      () =>
          mutateCredential?.call(request) ??
          _requiredClient.workspaceState.mutateCredential(request),
    );
  }

  MutateWorkspaceCredentialRequest _credentialRequest(
    ({
      String requestId,
      WorkspacePatchOperation resourceOperation,
      WorkspaceSecretKind secretKind,
      WorkspaceSecretScope scope,
      String? secret,
      bool clearSecret,
      int? expectedSecretRevision,
    })
    input,
  ) => MutateWorkspaceCredentialRequest(
    workspaceId: _workspace.cloudWorkspaceId,
    requestId: input.requestId,
    resourceOperation: input.resourceOperation,
    secretKind: input.secretKind,
    scope: input.scope,
    secret: input.secret,
    clearSecret: input.clearSecret,
    expectedSecretRevision: input.expectedSecretRevision,
  );
}

extension CloudWorkspaceStateGatewayWatch on CloudWorkspaceStateGateway {
  Stream<List<WorkspaceResource>> watchResources(
    List<WorkspaceResourceKind> kinds, {
    int limit = CloudWorkspaceStateGateway._pageSize,
  }) => watch(
    kinds.map((kind) => kind.name).toSet(),
    () => _loadResources(kinds, limit),
  );

  Future<({List<WorkspaceResource> value, int currentSequence})> _loadResources(
    List<WorkspaceResourceKind> kinds,
    int limit,
  ) async {
    final snapshot = await _readAll(
      kinds,
      limit.clamp(1, CloudWorkspaceStateGateway._pageSize),
    );

    return (
      value: snapshot.resources,
      currentSequence: snapshot.currentSequence,
    );
  }

  Stream<T> watch<T>(
    Set<String> resourceKinds,
    Future<({T value, int currentSequence})> Function() load,
  ) async* {
    if (_disposed) return;
    final snapshot = await load();
    yield snapshot.value;
    yield* _watchUpdates(
      resourceKinds: resourceKinds,
      load: load,
      lastSequence: snapshot.currentSequence,
    );
  }

  Stream<T> _watchUpdates<T>({
    required Set<String> resourceKinds,
    required Future<({T value, int currentSequence})> Function() load,
    required int lastSequence,
  }) async* {
    var reconnectDelay = CloudWorkspaceStateGateway._initialReconnectDelay;
    var sequence = lastSequence;
    while (!_disposed) {
      final cycle = _watchCycle<T>(
        resourceKinds: resourceKinds,
        load: load,
        lastSequence: sequence,
      );
      await for (final update in cycle) {
        final next = _nextWatchState(update);
        sequence = next.sequence;
        reconnectDelay = next.reconnectDelay;
        if (next.shouldYield) yield next.value as T;
      }
      await _waitForReconnect(reconnectDelay);
      reconnectDelay = _nextReconnectDelay(reconnectDelay);
    }
  }

  ({int sequence, Duration reconnectDelay, T? value, bool shouldYield})
  _nextWatchState(({T? value, bool shouldYield, int lastSequence}) update) => (
    sequence: update.lastSequence,
    reconnectDelay: CloudWorkspaceStateGateway._initialReconnectDelay,
    value: update.value,
    shouldYield: update.shouldYield,
  );

  Stream<({T? value, bool shouldYield, int lastSequence})> _watchCycle<T>({
    required Set<String> resourceKinds,
    required Future<({T value, int currentSequence})> Function() load,
    required int lastSequence,
  }) async* {
    final events = StreamIterator(_subscribeToWorkspace(lastSequence));
    try {
      await for (final update in _consumeEvents<T>(
        events: events,
        resourceKinds: resourceKinds,
        load: load,
        lastSequence: lastSequence,
      )) {
        yield update;
      }
    } on CloudWorkspaceException catch (error) {
      _handleCloudWorkspaceException(error);
    } on CloudAppException catch (error) {
      _handleCloudAppException(error);
    } on Object catch (_) {
      _handleOtherWatchException();
    } finally {
      final _ = await events.cancel();
    }
  }

  Stream<WorkspaceStreamEnvelope> _subscribeToWorkspace(int lastSequence) =>
      _subscribe(
        .new(
          workspaceId: _workspace.cloudWorkspaceId,
          afterSequence: lastSequence,
          activeTurnIds: const [],
        ),
      );

  Duration _nextReconnectDelay(Duration delay) => Duration(
    milliseconds: (delay.inMilliseconds * 2).clamp(
      CloudWorkspaceStateGateway._initialReconnectDelay.inMilliseconds,
      CloudWorkspaceStateGateway._maxReconnectDelay.inMilliseconds,
    ),
  );

  void _handleCloudWorkspaceException(CloudWorkspaceException error) {
    if (_isTerminal(error.code)) {
      CloudAppErrors.translateException(error, .state);
    }
  }

  void _handleCloudAppException(CloudAppException error) {
    if (_isTerminalCode(error.code)) throw error;
  }

  void _handleOtherWatchException() {
    if (_disposed) return;
  }

  Future<void> _waitForReconnect(Duration reconnectDelay) {
    if (_disposed) return Future.value();

    return Future.any([_delay(reconnectDelay), _disposedSignal.future]);
  }
}

extension on CloudWorkspaceStateGateway {
  Stream<({T? value, bool shouldYield, int lastSequence})> _consumeEvents<T>({
    required StreamIterator<WorkspaceStreamEnvelope> events,
    required Set<String> resourceKinds,
    required Future<({T value, int currentSequence})> Function() load,
    required int lastSequence,
  }) async* {
    var sequence = lastSequence;
    while (await Future.any([events.moveNext(), _disposedSignal.future])) {
      final event = events.current;
      if (_isStaleEvent(event, sequence)) continue;
      final update = await _consumeEvent(
        event: event,
        sequence: sequence,
        resourceKinds: resourceKinds,
        load: load,
      );
      sequence = update.lastSequence;
      yield update;
    }
  }

  Future<({T? value, bool shouldYield, int lastSequence})> _consumeEvent<T>({
    required WorkspaceStreamEnvelope event,
    required int sequence,
    required Set<String> resourceKinds,
    required Future<({T value, int currentSequence})> Function() load,
  }) async {
    final hasGap = event.sequence != sequence + 1;
    if (!hasGap && !_affectsResources(event, resourceKinds)) {
      return (value: null, shouldYield: false, lastSequence: event.sequence);
    }

    final snapshot = await load();
    return (
      value: snapshot.value,
      shouldYield: true,
      lastSequence: snapshot.currentSequence,
    );
  }

  bool _isStaleEvent(WorkspaceStreamEnvelope event, int sequence) =>
      event.sequence <= sequence;

  bool _affectsResources(
    WorkspaceStreamEnvelope event,
    Set<String> resourceKinds,
  ) =>
      event.kind == WorkspaceStreamEnvelopeKind.workspaceInvalidated &&
      resourceKinds.contains(event.resourceKind);

  bool _isTerminalCode(String? code) =>
      code == CloudWorkspaceErrorCode.authenticationRequired.name ||
      code == CloudWorkspaceErrorCode.membershipRequired.name ||
      code == CloudWorkspaceErrorCode.workspaceNotFound.name;
}

extension on CloudWorkspaceStateGateway {
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
      final result = await _readAttempt(kinds, pageSize);
      if (result != null) return result;
    }
    _malformedSnapshot('incoherentSnapshot');
  }

  Future<({List<WorkspaceResource> resources, int currentSequence})?>
  _readAttempt(List<WorkspaceResourceKind> kinds, int pageSize) async {
    final resources = <WorkspaceResource>[];
    final seenResourceIds = <String>{};
    final result = await _readKinds(
      kinds,
      pageSize,
      resources,
      seenResourceIds,
    );
    if (!result.coherent) return null;

    return (resources: resources, currentSequence: result.sequence ?? 0);
  }

  Future<({int? sequence, bool coherent})> _readKinds(
    List<WorkspaceResourceKind> kinds,
    int pageSize,
    List<WorkspaceResource> resources,
    Set<String> seenResourceIds,
  ) async {
    int? sequence;
    for (final kind in kinds) {
      final result = await _readKind((
        kind: kind,
        pageSize: pageSize,
        resources: resources,
        seenResourceIds: seenResourceIds,
        sequence: sequence,
      ));
      sequence = result.sequence;
      if (!result.coherent) return (sequence: sequence, coherent: false);
    }

    return (sequence: sequence, coherent: true);
  }

  Future<({int? sequence, bool coherent})> _readKind(
    ({
      WorkspaceResourceKind kind,
      int pageSize,
      List<WorkspaceResource> resources,
      Set<String> seenResourceIds,
      int? sequence,
    })
    input,
  ) async {
    final cursors = <String>{};
    var currentSequence = input.sequence;
    String? cursor;
    do {
      final result = await _readKindPage(
        input: input,
        cursor: cursor,
        currentSequence: currentSequence,
        cursors: cursors,
      );
      currentSequence = result.sequence;
      cursor = result.cursor;
      if (!result.coherent) return (sequence: currentSequence, coherent: false);
    } while (cursor != null);

    return (sequence: currentSequence, coherent: true);
  }

  Future<({int? sequence, String? cursor, bool coherent})> _readKindPage({
    required ({
      WorkspaceResourceKind kind,
      int pageSize,
      List<WorkspaceResource> resources,
      Set<String> seenResourceIds,
      int? sequence,
    })
    input,
    required String? cursor,
    required int? currentSequence,
    required Set<String> cursors,
  }) async {
    final state = await _readPage(input.kind, cursor, input.pageSize);
    final nextSequence = currentSequence ?? state.currentSequence;
    if (state.currentSequence != nextSequence) {
      return (sequence: nextSequence, cursor: cursor, coherent: false);
    }

    final page = _validatedPage(state, input.kind);
    _appendResources(
      kind: input.kind,
      page: page,
      resources: input.resources,
      seenResourceIds: input.seenResourceIds,
    );
    final nextCursor = page.nextResourceId;
    _validateCursor(nextCursor, cursors);

    return (sequence: nextSequence, cursor: nextCursor, coherent: true);
  }
}

extension on CloudWorkspaceStateGateway {
  Future<ReadWorkspaceStateResponse> _readPage(
    WorkspaceResourceKind kind,
    String? cursor,
    int pageSize,
  ) => read(
    pages: [
      WorkspaceResourcePageRequest(
        resourceKind: kind,
        afterResourceId: cursor,
        limit: pageSize,
      ),
    ],
  );

  WorkspaceResourcePage _validatedPage(
    ReadWorkspaceStateResponse state,
    WorkspaceResourceKind kind,
  ) {
    if (state.pages.length != 1 || state.pages.single.resourceKind != kind) {
      _malformedSnapshot('unexpectedPage');
    }

    return state.pages.single;
  }

  void _appendResources({
    required WorkspaceResourceKind kind,
    required WorkspaceResourcePage page,
    required List<WorkspaceResource> resources,
    required Set<String> seenResourceIds,
  }) {
    for (final resource in page.resources) {
      if (resource.resourceKind != kind) {
        _malformedSnapshot('unexpectedKind');
      }
      if (seenResourceIds.add('${kind.name}/${resource.resourceId}')) {
        resources.add(resource);
      }
    }
  }

  void _validateCursor(String? cursor, Set<String> cursors) {
    if (cursor != null && (cursor.isEmpty || !cursors.add(cursor))) {
      _malformedSnapshot('invalidCursor');
    }
  }

  Never _malformedSnapshot(String code) => throw CloudAppException(
    localizationKey: LocaleKeys.cloud_errors_malformed_resource,
    context: .resource,
    code: code,
  );

  bool _isTerminal(CloudWorkspaceErrorCode code) =>
      code == CloudWorkspaceErrorCode.authenticationRequired ||
      code == CloudWorkspaceErrorCode.membershipRequired ||
      code == CloudWorkspaceErrorCode.workspaceNotFound;
}
