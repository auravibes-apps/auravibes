import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../conversations/workers/conversation_worker.dart';
import '../model_connections/workers/model_catalog_sync_worker.dart';
import '../objects/object_cleanup_service.dart';
import 'worker_coordinator_repository.dart';
import 'recurring_worker_timer_set.dart';

class RecurringWorkerCoordinator {
  RecurringWorkerCoordinator(
    this.pod, {
    this.repository = const WorkerCoordinatorRepository(),
  });

  static const _heartbeat = Duration(seconds: 15);
  static const _executionLease = Duration(minutes: 5);

  final Serverpod pod;
  final WorkerCoordinatorRepository repository;
  late final String _ownerId = '${pod.serverId}:${const Uuid().v4()}';
  Timer? _heartbeatTimer;
  final _timers = RecurringWorkerTimerSet();
  final _tickTasks = <String, Future<void>>{};
  final _runCancellers = <void Function()>{};
  final _runningWorkers = <String>{};
  final _claimedSchedules = <String, RecurringWorkerSchedule>{};
  WorkerCoordinatorLease? _coordinator;
  int? _legacyCleanupFencingToken;
  bool _heartbeatInFlight = false;
  bool _stopped = false;
  int _generation = 0;

  Future<void>? _heartbeatTask;

  void start() {
    if (!_stopped && _heartbeatTimer != null) return;
    _stopped = false;
    final generation = ++_generation;
    _heartbeatTimer = Timer.periodic(
      _heartbeat,
      (_) => _startHeartbeat(generation),
    );
    _startHeartbeat(generation);
  }

  Future<void> stop() async {
    _stopped = true;
    _generation++;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _stopTimers();
    for (final cancel in _runCancellers) {
      cancel();
    }
    final coordinator = _coordinator;
    final activeTasks = <Future<void>>[
      ...[_heartbeatTask].whereType<Future<void>>(),
      ..._tickTasks.values,
    ];
    final stoppedCleanly = await Future.wait(activeTasks)
        .then((_) => true)
        .timeout(const Duration(seconds: 30), onTimeout: () => false);
    if (stoppedCleanly && coordinator != null) {
      await _releaseClaimedRuns(coordinator);
    }
    _coordinator = null;
  }

  void _startHeartbeat(int generation) {
    if (_heartbeatTask != null) return;
    final task = _guard('heartbeat', _heartbeatOnce(generation));
    _heartbeatTask = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_heartbeatTask, task)) _heartbeatTask = null;
      }),
    );
  }

  void _startTick(_WorkerDefinition definition, int generation) {
    if (_tickTasks.containsKey(definition.key)) return;
    final task = _guard(definition.key, _tick(definition, generation));
    _tickTasks[definition.key] = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_tickTasks[definition.key], task)) {
          _tickTasks.remove(definition.key);
        }
      }),
    );
  }

  Future<void> _guard(String operation, Future<void> task) async {
    try {
      await task;
    } on Object catch (error, stackTrace) {
      try {
        final session = await pod.createSession();
        try {
          session.log(
            'Recurring worker coordinator $operation failed.',
            level: LogLevel.error,
            exception: error,
            stackTrace: stackTrace,
          );
        } finally {
          await session.close();
        }
      } on Object {
        // The server may already be shutting down.
      }
    }
  }

  Future<void> _heartbeatOnce(int generation) async {
    if (!_isActive(generation) || _heartbeatInFlight) return;
    _heartbeatInFlight = true;
    Session? session;
    try {
      session = await pod.createSession();
      final coordinator = await repository.acquireCoordinator(
        session,
        ownerId: _ownerId,
      );
      if (!_isActive(generation)) return;
      if (coordinator == null) {
        _stopTimers();
        _coordinator = null;
        return;
      }
      if (!_sameCoordinator(_coordinator, coordinator)) {
        _coordinator = coordinator;
      }
      if (Platform.environment['AURAVIBES_RECURRING_WORKERS_CUTOVER'] !=
          'drained') {
        _stopTimers();
        _coordinator = null;
        session.log(
          'Recurring workers require a drained legacy rollout. Set '
          'AURAVIBES_RECURRING_WORKERS_CUTOVER=drained after old replicas stop.',
          level: LogLevel.error,
        );
        return;
      }
      if (_legacyCleanupFencingToken != coordinator.fencingToken) {
        await session.db.unsafeQuery(
          'DELETE FROM serverpod_future_call WHERE identifier IN '
          '(@conversation, @catalog, @cleanup)',
          parameters: QueryParameters.named({
            'conversation': conversationWorkerFutureCallIdentifier,
            'catalog': modelCatalogSyncWorkerFutureCallIdentifier,
            'cleanup': objectCleanupFutureCallIdentifier,
          }),
        );
        _legacyCleanupFencingToken = coordinator.fencingToken;
      }
      if (!_isActive(generation)) return;
      for (final definition in _definitions) {
        await repository.seedSchedule(session, workerKey: definition.key);
        if (!_isActive(generation)) return;
        _timers.schedule(
          definition.key,
          definition.pollInterval,
          () => _startTick(definition, generation),
        );
        _startTick(definition, generation);
      }
    } finally {
      try {
        await session?.close();
      } finally {
        _heartbeatInFlight = false;
      }
    }
  }

  Future<void> _tick(_WorkerDefinition definition, int generation) async {
    if (!_isActive(generation) || !_runningWorkers.add(definition.key)) return;
    final coordinator = _coordinator;
    if (coordinator == null) {
      _runningWorkers.remove(definition.key);
      return;
    }
    Session? session;
    try {
      session = await pod.createSession();
      if (!_isActive(generation) ||
          !_sameCoordinator(_coordinator, coordinator)) {
        return;
      }
      final schedule = await repository.claimDueRun(
        session,
        workerKey: definition.key,
        coordinator: coordinator,
        executionLease: _executionLease,
      );
      if (schedule == null ||
          !_isActive(generation) ||
          !_sameCoordinator(_coordinator, coordinator)) {
        return;
      }
      _claimedSchedules[definition.key] = schedule;
      var leaseLost = false;
      Future<void>? renewalInFlight;
      Future<bool> renewRun() async {
        final renewalSession = await pod.createSession();
        try {
          return repository.renewRun(
            renewalSession,
            schedule: schedule,
            coordinator: coordinator,
            executionLease: _executionLease,
          );
        } finally {
          await renewalSession.close();
        }
      }

      void renew() {
        if (!_isActive(generation) ||
            !_sameCoordinator(_coordinator, coordinator)) {
          leaseLost = true;
          return;
        }
        if (renewalInFlight != null) return;
        renewalInFlight = renewRun()
            .then(
              (renewed) {
                if (!renewed) leaseLost = true;
              },
              onError: (_, _) {
                leaseLost = true;
              },
            )
            .whenComplete(() => renewalInFlight = null);
      }

      final renewal = Timer.periodic(
        const Duration(seconds: 30),
        (_) => renew(),
      );
      void cancelRun() {
        leaseLost = true;
        renewal.cancel();
      }

      _runCancellers.add(cancelRun);
      try {
        await definition.run(
          session,
          coordinator: coordinator,
          isActive: () =>
              !leaseLost &&
              _isActive(generation) &&
              _sameCoordinator(_coordinator, coordinator),
        );
      } finally {
        cancelRun();
        _runCancellers.remove(cancelRun);
      }
      await renewalInFlight;
      if (!leaseLost &&
          _isActive(generation) &&
          _sameCoordinator(_coordinator, coordinator)) {
        await repository.completeRun(
          session,
          schedule: schedule,
          coordinator: coordinator,
          interval: definition.interval,
        );
      }
    } finally {
      try {
        await session?.close();
      } finally {
        _runningWorkers.remove(definition.key);
      }
    }
  }

  bool _isActive(int generation) => !_stopped && generation == _generation;

  bool _sameCoordinator(
    WorkerCoordinatorLease? first,
    WorkerCoordinatorLease second,
  ) =>
      first?.ownerId == second.ownerId &&
      first?.fencingToken == second.fencingToken;

  Future<void> _releaseClaimedRuns(WorkerCoordinatorLease coordinator) async {
    if (_claimedSchedules.isEmpty) return;
    final session = await pod.createSession();
    try {
      for (final schedule in _claimedSchedules.values) {
        await repository.releaseRun(
          session,
          schedule: schedule,
          coordinator: coordinator,
        );
      }
      _claimedSchedules.clear();
    } finally {
      await session.close();
    }
  }

  void _stopTimers() {
    _timers.cancelAll();
  }
}

class _WorkerDefinition {
  const _WorkerDefinition(
    this.key,
    this.interval,
    this.pollInterval,
    this.run,
  );

  final String key;
  final Duration interval;
  final Duration pollInterval;
  final Future<void> Function(
    Session, {
    required WorkerCoordinatorLease coordinator,
    required bool Function() isActive,
  })
  run;
}

final _definitions = [
  _WorkerDefinition(
    'conversation',
    const Duration(seconds: 1),
    const Duration(seconds: 1),
    (session, {required coordinator, required isActive}) =>
        runConversationWorker(session, isActive: isActive),
  ),
  _WorkerDefinition(
    'modelCatalogSync',
    ModelCatalogSyncWorker.interval,
    const Duration(minutes: 1),
    runModelCatalogSyncWorker,
  ),
  _WorkerDefinition(
    'objectCleanup',
    objectCleanupInterval,
    const Duration(minutes: 1),
    (session, {required coordinator, required isActive}) =>
        runObjectCleanupWorker(
          session,
          coordinator: coordinator,
          isActive: isActive,
        ),
  ),
];
