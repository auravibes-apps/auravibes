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
typedef WorkspaceSecretInput = ({
  String requestId,
  WorkspaceSecretKind secretKind,
  WorkspaceSecretScope scope,
  String resourceId,
  String? secret,
  int? expectedRevision,
});
typedef WorkspaceSecretCall = Future<PutWorkspaceSecretResponse> Function(
  WorkspaceSecretInput input,
);
typedef WorkspaceCredentialMutation =
    Future<MutateWorkspaceCredentialResponse> Function(
      MutateWorkspaceCredentialRequest request,
    );
typedef WorkspaceCredentialInput = ({
  String requestId,
  WorkspacePatchOperation resourceOperation,
  WorkspaceSecretKind secretKind,
  WorkspaceSecretScope scope,
  String? secret,
  bool clearSecret,
  int? expectedSecretRevision,
});
typedef WorkspaceCredentialCall =
    Future<MutateWorkspaceCredentialResponse> Function(
      WorkspaceCredentialInput input,
    );
typedef WorkspaceReconnectDelay = Future<void> Function(Duration duration);

typedef _PutSecretContext = ({
  CloudWorkspaceRef workspace,
  Client? client,
  WorkspaceSecretPut? putSecret,
  WorkspaceSecretInput input,
});
typedef _MutateCredentialContext = ({
  CloudWorkspaceRef workspace,
  Client? client,
  WorkspaceCredentialMutation? mutateCredential,
  WorkspaceCredentialInput input,
});
typedef _WatchUpdatesInput<T> = ({
  Set<String> resourceKinds,
  Future<({T value, int currentSequence})> Function() load,
  int lastSequence,
});
typedef _ConsumeEventsInput<T> = ({
  StreamIterator<WorkspaceStreamEnvelope> events,
  Set<String> resourceKinds,
  Future<({T value, int currentSequence})> Function() load,
  int lastSequence,
});
typedef _ConsumeEventInput<T> = ({
  WorkspaceStreamEnvelope event,
  int sequence,
  Set<String> resourceKinds,
  Future<({T value, int currentSequence})> Function() load,
});
typedef _CurrentEventInput<T> = ({
  _ConsumeEventsInput<T> input,
  WorkspaceStreamEnvelope event,
  int sequence,
});
typedef _ReadKindInput = ({
  WorkspaceResourceKind kind,
  int pageSize,
  List<WorkspaceResource> resources,
  Set<String> seenResourceIds,
  int? sequence,
});
typedef _ReadKindPageInput = ({
  _ReadKindInput input,
  String? cursor,
  int? currentSequence,
  Set<String> cursors,
});
typedef _ReadKindPageCursorInput = ({
  String? cursor,
  int? currentSequence,
  Set<String> cursors,
});
typedef _AppendResourcesInput = ({
  WorkspaceResourceKind kind,
  WorkspaceResourcePage page,
  List<WorkspaceResource> resources,
  Set<String> seenResourceIds,
});

class _WatchState {
  new(this.sequence, this.reconnectDelay);

  int sequence;
  Duration reconnectDelay;
}

class _ReadKindsInput {
  new(this.kinds, this.pageSize);

  final List<WorkspaceResourceKind> kinds;
  final int pageSize;
  final resources = <WorkspaceResource>[];
  final seenResourceIds = <String>{};
}

class _GatewayCallHandlers {
  new({
    required CloudWorkspaceRef workspace,
    required Client? client,
    required WorkspaceSecretPut? putSecret,
    required WorkspaceCredentialMutation? mutateCredential,
  }) : putSecretCall = _GatewaySecretCallHandler(
         workspace: workspace,
         client: client,
         putSecret: putSecret,
       ).call,
       mutateCredentialCall = _GatewayCredentialCallHandler(
         workspace: workspace,
         client: client,
         mutateCredential: mutateCredential,
       ).call;

  final WorkspaceSecretCall putSecretCall;
  final WorkspaceCredentialCall mutateCredentialCall;
}

class _GatewaySecretCallHandler {
  new({
    required CloudWorkspaceRef workspace,
    required Client? client,
    required WorkspaceSecretPut? putSecret,
  }) : call = ((input) => _putSecretRequest((
         workspace: workspace,
         client: client,
         putSecret: putSecret,
         input: input,
       )));

  final WorkspaceSecretCall call;
}

class _GatewayCredentialCallHandler {
  new({
    required CloudWorkspaceRef workspace,
    required Client? client,
    required WorkspaceCredentialMutation? mutateCredential,
  }) : call = ((input) => _mutateCredentialRequest((
         workspace: workspace,
         client: client,
         mutateCredential: mutateCredential,
         input: input,
       )));

  final WorkspaceCredentialCall call;
}

abstract class _CloudWorkspaceStateGatewayBase {
  new(
    this.readTimeout,
    this._workspace,
    this._readState,
    this._subscribe,
    this._delay,
    this._client,
    this._calls,
  );

  final Duration readTimeout;
  final CloudWorkspaceRef _workspace;
  final WorkspaceStateRead _readState;
  final WorkspaceStreamSubscribe _subscribe;
  final WorkspaceReconnectDelay _delay;
  final Client? _client;
  final _GatewayCallHandlers _calls;
  Future<void> _readTail = .value();
  bool _disposed = false;
  final _disposedSignal = Completer<bool>();

  Future<ReadWorkspaceStateResponse> read({
    required List<WorkspaceResourcePageRequest> pages,
    int? afterSequence,
    int eventLimit,
  });
}

class CloudWorkspaceStateGateway extends _CloudWorkspaceStateGatewayBase
    with _CloudWorkspaceStateMutationApi, _CloudWorkspaceStateWatchApi {
  static const _pageSize = 100;
  static const _stateReadTimeout = Duration(seconds: 15);
  static const _initialReconnectDelay = Duration(milliseconds: 250);
  static const _maxReconnectDelay = Duration(seconds: 8);
  new({
    required Client client,
    required CloudWorkspaceRef workspace,
    Duration readTimeout = _stateReadTimeout,
  }) : super(
         readTimeout,
         workspace,
         client.workspaceState.read,
         client.workspaceStream.subscribe,
         _defaultDelay,
         client,
         .new(
           workspace: workspace,
           client: client,
           putSecret: null,
           mutateCredential: null,
         ),
       );

  new forTesting({
    required CloudWorkspaceRef workspace,
    required WorkspaceStateRead readState,
    required WorkspaceStreamSubscribe subscribe,
    WorkspaceSecretPut? putSecret,
    WorkspaceCredentialMutation? mutateCredential,
    WorkspaceReconnectDelay delay = _defaultDelay,
    Duration readTimeout = _stateReadTimeout,
  }) : super(
         readTimeout,
         workspace,
         readState,
         subscribe,
         delay,
         null,
         .new(
           workspace: workspace,
           client: null,
           putSecret: putSecret,
           mutateCredential: mutateCredential,
         ),
       );

  bool isDisposed() => _disposed;

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}

mixin _CloudWorkspaceStateMutationApi on _CloudWorkspaceStateGatewayBase {
  Future<PutWorkspaceSecretResponse> putSecret(WorkspaceSecretInput input) =>
      _calls.putSecretCall(input);

  Future<MutateWorkspaceCredentialResponse> mutateCredential(
    WorkspaceCredentialInput input,
  ) => _calls.mutateCredentialCall(input);
}

mixin _CloudWorkspaceStateWatchApi on _CloudWorkspaceStateGatewayBase {
  Client get client => _requireClient(_client);

  CloudWorkspaceRef get workspace => _workspace;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disposedSignal.complete(false);
  }

  @override
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
    () => _requireClient(_client).workspaceState.patch(
      .new(
        workspaceId: _workspace.cloudWorkspaceId,
        requestId: requestId,
        operations: operations,
      ),
    ),
  );

  Stream<List<WorkspaceResource>> watchResources(
    List<WorkspaceResourceKind> kinds, {
    int limit = CloudWorkspaceStateGateway._pageSize,
  }) => watch(
    kinds.map((kind) => kind.name).toSet(),
    () => _readResources(kinds, limit),
  );

  Stream<T> watch<T>(
    Set<String> resourceKinds,
    Future<({T value, int currentSequence})> Function() load,
  ) async* {
    if (_disposed) return;
    final snapshot = await load();
    yield snapshot.value;
    yield* _watchUpdates<T>((
      resourceKinds: resourceKinds,
      load: load,
      lastSequence: snapshot.currentSequence,
    ));
  }
}

extension on _CloudWorkspaceStateGatewayBase {
  Future<({List<WorkspaceResource> value, int currentSequence})> _readResources(
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
}

Future<PutWorkspaceSecretResponse> _putSecretRequest(
  _PutSecretContext context,
) {
  return _guardPutSecret(context, _putSecretRequestBody(context));
}

PutWorkspaceSecretRequest _putSecretRequestBody(_PutSecretContext context) {
  final input = context.input;

  return PutWorkspaceSecretRequest(
    workspaceId: context.workspace.cloudWorkspaceId,
    requestId: input.requestId,
    secretKind: input.secretKind,
    scope: input.scope,
    resourceId: input.resourceId,
    secret: input.secret,
    expectedRevision: input.expectedRevision,
  );
}

Future<PutWorkspaceSecretResponse> _guardPutSecret(
  _PutSecretContext context,
  PutWorkspaceSecretRequest request,
) {
  final putSecret = context.putSecret;

  return CloudAppErrors.guardCall(
    .state,
    () =>
        putSecret?.call(request) ??
        _requireClient(context.client).workspaceSecret.put(request),
  );
}

Future<MutateWorkspaceCredentialResponse> _mutateCredentialRequest(
  _MutateCredentialContext context,
) {
  return _guardMutateCredential(context, _mutateCredentialRequestBody(context));
}

MutateWorkspaceCredentialRequest _mutateCredentialRequestBody(
  _MutateCredentialContext context,
) {
  final input = context.input;

  return MutateWorkspaceCredentialRequest(
    workspaceId: context.workspace.cloudWorkspaceId,
    requestId: input.requestId,
    resourceOperation: input.resourceOperation,
    secretKind: input.secretKind,
    scope: input.scope,
    secret: input.secret,
    clearSecret: input.clearSecret,
    expectedSecretRevision: input.expectedSecretRevision,
  );
}

Future<MutateWorkspaceCredentialResponse> _guardMutateCredential(
  _MutateCredentialContext context,
  MutateWorkspaceCredentialRequest request,
) {
  final mutateCredential = context.mutateCredential;

  return CloudAppErrors.guardCall(
    .state,
    () =>
        mutateCredential?.call(request) ??
        _requireClient(context.client).workspaceState.mutateCredential(request),
  );
}

Client _requireClient(Client? client) =>
    client ??
    (throw StateError('Client operations are unavailable in test gateways'));

extension CloudWorkspaceStateGatewayWatch on _CloudWorkspaceStateGatewayBase {
  Stream<T> _watchUpdates<T>(_WatchUpdatesInput<T> input) async* {
    final watchState = _WatchState(
      input.lastSequence,
      CloudWorkspaceStateGateway._initialReconnectDelay,
    );
    while (!_disposed) {
      yield* _watchUpdateCycle(input, watchState);
    }
  }

  Stream<({T? value, bool shouldYield, int lastSequence})> _watchCycle<T>(
    _WatchUpdatesInput<T> input,
  ) async* {
    final events = StreamIterator(_subscribeToWorkspace(input.lastSequence));
    try {
      yield* _consumeEvents<T>(_consumeEventsInput(input, events));
    } on Object catch (error) {
      _handleWatchError(error);
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

  Future<void> _waitForReconnect(Duration reconnectDelay) async {
    if (_disposed) return;

    await Future.any([_delay(reconnectDelay), _disposedSignal.future]);
  }
}

Stream<T> _yieldWatchValues<T>(
  Stream<({T? value, bool shouldYield, int lastSequence})> cycle,
  _WatchState state,
) async* {
  await for (final update in cycle) {
    state
      ..sequence = update.lastSequence
      ..reconnectDelay = CloudWorkspaceStateGateway._initialReconnectDelay;
    if (!update.shouldYield) continue;
    yield update.value as T;
  }
}

({T? value, bool shouldYield, int lastSequence}) _ignoredEvent<T>(
  int sequence,
) => (value: null, shouldYield: false, lastSequence: sequence);

({T? value, bool shouldYield, int lastSequence}) _loadedEvent<T>(
  ({T value, int currentSequence}) snapshot,
) => (
  value: snapshot.value,
  shouldYield: true,
  lastSequence: snapshot.currentSequence,
);

extension on _CloudWorkspaceStateGatewayBase {
  Stream<T> _watchUpdateCycle<T>(
    _WatchUpdatesInput<T> input,
    _WatchState watchState,
  ) async* {
    try {
      await for (final value in _yieldWatchValues(
        _watchCycle<T>(_watchCycleInput(input, watchState.sequence)),
        watchState,
      )) {
        yield value;
      }
    } on Object catch (error) {
      _handleWatchError(error);
    }
    await _waitForReconnect(watchState.reconnectDelay);
    _advanceReconnect(watchState);
  }

  _WatchUpdatesInput<T> _watchCycleInput<T>(
    _WatchUpdatesInput<T> input,
    int lastSequence,
  ) => (
    resourceKinds: input.resourceKinds,
    load: input.load,
    lastSequence: lastSequence,
  );

  void _advanceReconnect(_WatchState watchState) {
    watchState.reconnectDelay = _nextReconnectDelay(watchState.reconnectDelay);
  }

  _ConsumeEventsInput<T> _consumeEventsInput<T>(
    _WatchUpdatesInput<T> input,
    StreamIterator<WorkspaceStreamEnvelope> events,
  ) => (
    events: events,
    resourceKinds: input.resourceKinds,
    load: input.load,
    lastSequence: input.lastSequence,
  );

  void _handleWatchError(Object error) {
    switch (error) {
      case final CloudWorkspaceException error:
        _handleCloudWorkspaceException(error);
      case final CloudAppException error:
        _handleCloudAppException(error);
      default:
        _handleOtherWatchException();
    }
  }

  Future<bool> _hasNextEvent(StreamIterator<WorkspaceStreamEnvelope> events) =>
      Future.any([events.moveNext(), _disposedSignal.future]);

  Future<({T? value, bool shouldYield, int lastSequence})?> _nextEventUpdate<T>(
    _ConsumeEventsInput<T> input,
    int sequence,
  ) => _consumeCurrentEvent<T>((
    input: input,
    event: input.events.current,
    sequence: sequence,
  ));

  Stream<({T? value, bool shouldYield, int lastSequence})> _consumeEvents<T>(
    _ConsumeEventsInput<T> input,
  ) async* {
    var sequence = input.lastSequence;
    while (await _hasNextEvent(input.events)) {
      final update = await _nextEventUpdate(input, sequence);
      if (update == null) continue;
      sequence = update.lastSequence;
      yield update;
    }
  }

  Future<({T? value, bool shouldYield, int lastSequence})?>
  _consumeCurrentEvent<T>(_CurrentEventInput<T> input) async {
    if (_isStaleEvent(input.event, input.sequence)) return null;

    return await _consumeEvent<T>((
      event: input.event,
      sequence: input.sequence,
      resourceKinds: input.input.resourceKinds,
      load: input.input.load,
    ));
  }

  Future<({T? value, bool shouldYield, int lastSequence})> _consumeEvent<T>(
    _ConsumeEventInput<T> input,
  ) async {
    final event = input.event;
    if (event.sequence == input.sequence + 1 &&
        !_affectsResources(event, input.resourceKinds)) {
      return _ignoredEvent(event.sequence);
    }

    return _loadedEvent(await input.load());
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

extension on _CloudWorkspaceStateGatewayBase {
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
    final input = _ReadKindsInput(kinds, pageSize);
    final result = await _readKinds(input);
    if (!result.coherent) return null;

    return (resources: input.resources, currentSequence: result.sequence ?? 0);
  }

  Future<({int? sequence, bool coherent})> _readKinds(
    _ReadKindsInput input,
  ) async {
    int? sequence;
    for (final kind in input.kinds) {
      final result = await _readKind(_readKindInput(input, kind, sequence));
      sequence = result.sequence;
      if (!result.coherent) return (sequence: sequence, coherent: false);
    }

    return (sequence: sequence, coherent: true);
  }

  _ReadKindInput _readKindInput(
    _ReadKindsInput input,
    WorkspaceResourceKind kind,
    int? sequence,
  ) => (
    kind: kind,
    pageSize: input.pageSize,
    resources: input.resources,
    seenResourceIds: input.seenResourceIds,
    sequence: sequence,
  );

  Future<({int? sequence, bool coherent})> _readKind(_ReadKindInput input) =>
      _readKindPages(input, <String>{});

  _ReadKindPageInput _readKindPageInput(
    _ReadKindInput input,
    _ReadKindPageCursorInput cursorInput,
  ) => (
    input: input,
    cursor: cursorInput.cursor,
    currentSequence: cursorInput.currentSequence,
    cursors: cursorInput.cursors,
  );

  Future<({int? sequence, String? cursor, bool coherent})> _readKindPage(
    _ReadKindPageInput input,
  ) async {
    final state = await _readPage(
      input.input.kind,
      input.cursor,
      input.input.pageSize,
    );

    return _processReadKindPage(input, state);
  }

  Future<({int? sequence, bool coherent})> _readKindPages(
    _ReadKindInput input,
    Set<String> cursors,
  ) async {
    var result = await _readKindPage(
      _readKindPageInput(input, (
        cursor: null,
        currentSequence: input.sequence,
        cursors: cursors,
      )),
    );
    while (result.coherent && result.cursor != null) {
      result = await _readKindPage(
        _readKindPageInput(input, (
          cursor: result.cursor,
          currentSequence: result.sequence,
          cursors: cursors,
        )),
      );
    }

    return (sequence: result.sequence, coherent: result.coherent);
  }

  ({int? sequence, String? cursor, bool coherent}) _processReadKindPage(
    _ReadKindPageInput input,
    ReadWorkspaceStateResponse state,
  ) {
    final nextSequence = input.currentSequence ?? state.currentSequence;
    if (state.currentSequence != nextSequence) {
      return _incoherentPage(nextSequence, input.cursor);
    }

    final page = _validatedPage(state, input.input.kind);
    final nextCursor = _appendPageResources(input, page);

    return _coherentPage(nextSequence, nextCursor);
  }

  ({int? sequence, String? cursor, bool coherent}) _incoherentPage(
    int sequence,
    String? cursor,
  ) => (sequence: sequence, cursor: cursor, coherent: false);

  ({int? sequence, String? cursor, bool coherent}) _coherentPage(
    int sequence,
    String? cursor,
  ) => (sequence: sequence, cursor: cursor, coherent: true);

  String? _appendPageResources(
    _ReadKindPageInput input,
    WorkspaceResourcePage page,
  ) {
    _appendResources((
      kind: input.input.kind,
      page: page,
      resources: input.input.resources,
      seenResourceIds: input.input.seenResourceIds,
    ));
    final nextCursor = page.nextResourceId;
    _validateCursor(nextCursor, input.cursors);

    return nextCursor;
  }
}

extension on _CloudWorkspaceStateGatewayBase {
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

  void _appendResources(_AppendResourcesInput input) {
    for (final resource in input.page.resources) {
      _appendResource(input, resource);
    }
  }

  void _appendResource(
    _AppendResourcesInput input,
    WorkspaceResource resource,
  ) {
    if (resource.resourceKind != input.kind) {
      _malformedSnapshot('unexpectedKind');
    }
    if (!input.seenResourceIds.add(
      '${input.kind.name}/${resource.resourceId}',
    )) {
      return;
    }
    input.resources.add(resource);
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
