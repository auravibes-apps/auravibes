import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../conversations/workers/conversation_job_dispatcher.dart';
import '../conversations/workers/conversation_worker.dart';
import '../model_connections/workers/model_catalog_sync_worker.dart';
import '../objects/object_cleanup_service.dart';
import '../sync/stream/sync_wakeups.dart';
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
  ConversationJobDispatcher? _conversationDispatcher;
  Session? _conversationListener;
  WorkerCoordinatorLease? _conversationDispatcherCoordinator;
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
    await _stopConversationDispatcher();
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
        await _stopConversationDispatcher();
        _coordinator = null;
        return;
      }
      if (!_sameCoordinator(_coordinator, coordinator)) {
        _coordinator = coordinator;
      }
      if (!_isActive(generation)) return;
      await _startConversationDispatcher(coordinator, generation);
      if (!_isActive(generation) ||
          !_sameCoordinator(_coordinator, coordinator)) {
        return;
      }
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
              onError: (Object error, StackTrace stackTrace) {
                session!.log(
                  'Worker coordinator lease renewal failed: '
                  'worker=${definition.key}, coordinator=${coordinator.ownerId}.',
                  level: LogLevel.error,
                  exception: error,
                  stackTrace: stackTrace,
                );
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

  Future<void> _startConversationDispatcher(
    WorkerCoordinatorLease coordinator,
    int generation,
  ) async {
    if (_conversationDispatcher != null &&
        _sameCoordinator(_conversationDispatcherCoordinator, coordinator)) {
      return;
    }
    await _stopConversationDispatcher();
    if (!_isActive(generation) ||
        !_sameCoordinator(_coordinator, coordinator)) {
      return;
    }
    final listener = await pod.createSession();
    if (!_isActive(generation) ||
        !_sameCoordinator(_coordinator, coordinator)) {
      await listener.close();
      return;
    }
    final dispatcher = ConversationJobDispatcher(
      drain: (isActive) async {
        final session = await pod.createSession();
        try {
          session.log(
            'Conversation dispatch drain started: '
            'coordinator=${coordinator.ownerId}, '
            'fencingToken=${coordinator.fencingToken}.',
            level: LogLevel.info,
          );
          await runConversationWorker(session, isActive: isActive);
        } finally {
          await session.close();
        }
      },
      onError: (error, stackTrace) {
        listener.log(
          'Conversation job dispatcher failed: '
          'coordinator=${coordinator.ownerId}, '
          'fencingToken=${coordinator.fencingToken}.',
          level: LogLevel.error,
          exception: error,
          stackTrace: stackTrace,
        );
      },
    );
    _conversationListener = listener;
    _conversationDispatcher = dispatcher;
    _conversationDispatcherCoordinator = coordinator;
    dispatcher.start(
      wakeups: listener.messages
          .createStream<ConversationJob>(SyncWakeups.conversationJobsChannel)
          .map((job) {
            listener.log(
              'Conversation job wake received: '
              'job=${job.id}, workspace=${job.workspaceId}, '
              'kind=${job.kind}, coordinator=${coordinator.ownerId}, '
              'fencingToken=${coordinator.fencingToken}.',
              level: LogLevel.info,
            );
          }),
      isActive: () =>
          _isActive(generation) &&
          _sameCoordinator(_coordinator, coordinator) &&
          _sameCoordinator(_conversationDispatcherCoordinator, coordinator),
    );
  }

  Future<void> _stopConversationDispatcher() async {
    final dispatcher = _conversationDispatcher;
    await dispatcher?.stop();
    final listener = _conversationListener;
    _conversationListener = null;
    await listener?.close();
    _conversationDispatcherCoordinator = null;
    _conversationDispatcher = null;
  }

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
