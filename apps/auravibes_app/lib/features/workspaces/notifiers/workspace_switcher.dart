// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';
import 'dart:collection';

import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_switcher.g.dart';

final _logger = Logger('WorkspaceSwitcher');

/// Provider that manages workspace switching with debounce, loading guard,
/// error handling, and structured logging of switch timing.
///
/// Uses a plain Notifier instead of AsyncNotifier because the switch
/// action is a transient mutation, not initialized state. Per the Mutation
/// State Contract, manual AsyncValue toggling is avoided; the state object
/// itself tracks idle/loading/error status.
@Riverpod(keepAlive: true)
class WorkspaceSwitcher({
  @visibleForTesting
  final Duration debounceDuration = const Duration(milliseconds: 300),
}) extends _$WorkspaceSwitcher
    with _WorkspaceSwitcherActions, _WorkspaceSwitcherTransitionActions {
  Timer? _debounceTimer;
  final _switchQueue = Queue<({String workspaceId, int generation})>();
  var _isProcessingQueue = false;
  var _switchGeneration = 0;

  @override
  WorkspaceSwitchState build() {
    final _ = ref.onDispose(() => _debounceTimer?.cancel());

    return const WorkspaceSwitchState();
  }

  /// Initiates a switch to the given workspace.
  ///
  /// Rapid calls are debounced so only the last selection is processed.
  /// If a pending switch has not yet started it is cancelled.
  void switchToWorkspace(String workspaceId) {
    _debounceTimer?.cancel();
    final switchGeneration = ++_switchGeneration;

    _debounceTimer = .new(debounceDuration, () {
      _queueSwitch(workspaceId, switchGeneration);
    });
  }

  /// Cancels any pending debounced switch.
  void cancelPendingSwitch() {
    ref.read(draftExitRegistryProvider).releaseApprovals();
    _debounceTimer?.cancel();
    _switchGeneration++;
    state = const WorkspaceSwitchState();
  }

  /// Clears the current error state and returns to idle.
  void clearError() {
    state = const WorkspaceSwitchState();
  }
}

mixin _WorkspaceSwitcherActions on _$WorkspaceSwitcher {
  void _queueSwitch(String workspaceId, int switchGeneration) {
    final switcher = this as WorkspaceSwitcher;
    switcher._switchQueue.add((
      workspaceId: workspaceId,
      generation: switchGeneration,
    ));
    if (switcher._isProcessingQueue) return;

    switcher._isProcessingQueue = true;
    unawaited(_drainSwitchQueue());
  }

  Future<void> _drainSwitchQueue() async {
    final switcher = this as WorkspaceSwitcher;
    try {
      await _drainSwitchQueueRequests(switcher);
    } finally {
      switcher._isProcessingQueue = false;
    }
  }

  Future<void> _performSwitch(String workspaceId, int switchGeneration) async {
    final switcher = this as WorkspaceSwitcher;

    try {
      await _performSwitchRequest(switcher, workspaceId, switchGeneration);
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        ref.read(draftExitRegistryProvider).releaseApprovals();
      }
      _logger.severe('Workspace switch failed', error, stackTrace);
      _setSwitchError(switcher, workspaceId, switchGeneration);
    }
  }

  void _setSwitchError(
    WorkspaceSwitcher switcher,
    String workspaceId,
    int switchGeneration,
  ) {
    if (!switcher._isCurrent(switchGeneration)) return;
    switcher.state = WorkspaceSwitchState(
      status: .error,
      targetWorkspaceId: workspaceId,
      errorLocalizationKey: LocaleKeys.workspace_management_switch_error,
    );
  }
}

mixin _WorkspaceSwitcherTransitionActions on _$WorkspaceSwitcher {
  bool _beginSwitch(String workspaceId, int switchGeneration) {
    if (!_isCurrent(switchGeneration)) return false;
    state = WorkspaceSwitchState(
      status: .loading,
      targetWorkspaceId: workspaceId,
    );

    return true;
  }

  Future<String> _selectWorkspace(String workspaceId, int generation) => ref
      .read(selectWorkspaceUsecaseProvider)
      .call(workspaceId: workspaceId, isCurrent: () => _isCurrent(generation));

  bool _isCurrent(int switchGeneration) =>
      ref.mounted &&
      switchGeneration == (this as WorkspaceSwitcher)._switchGeneration;

  void _completeSwitch(
    String workspaceId,
    DateTime startTime,
    int switchGeneration,
  ) {
    final router = ref.read(routerProvider);
    ref.read(draftExitRegistryProvider).completeActiveTransition(router);
    router.go('/workspaces/$workspaceId/chat/new');
    final duration = DateTime.now().difference(startTime);
    _logger.info('Workspace switch completed in ${duration.inMilliseconds}ms');
    if (_isCurrent(switchGeneration)) state = const WorkspaceSwitchState();
  }

  Future<void> _performSwitchAttempt(_SwitchAttempt attempt) async {
    final switcher = attempt.switcher;
    if (!_beginSwitchAttempt(switcher, attempt)) return;
    if (!await _authorizeSwitch(switcher, attempt)) return;

    final selectedWorkspaceId = await _selectAndReleaseIfStale(
      switcher,
      attempt,
    );
    _completeSwitchIfCurrent(switcher, selectedWorkspaceId, attempt);
  }

  bool _beginSwitchAttempt(WorkspaceSwitcher switcher, _SwitchAttempt attempt) {
    _logger.info('Workspace switch started');

    return switcher._beginSwitch(attempt.workspaceId, attempt.switchGeneration);
  }

  Future<String> _selectAndReleaseIfStale(
    WorkspaceSwitcher switcher,
    _SwitchAttempt attempt,
  ) async {
    final workspaceId = await switcher._selectWorkspace(
      attempt.workspaceId,
      attempt.switchGeneration,
    );
    if (!switcher._isCurrent(attempt.switchGeneration)) {
      ref.read(draftExitRegistryProvider).releaseApprovals();
    }

    return workspaceId;
  }

  Future<bool> _authorizeSwitch(
    WorkspaceSwitcher switcher,
    _SwitchAttempt attempt,
  ) async {
    final registry = ref.read(draftExitRegistryProvider);
    final router = ref.read(routerProvider);
    final allowed = await registry.canExitActive(router);
    if (!switcher._isCurrent(attempt.switchGeneration)) {
      registry.releaseApprovals();

      return false;
    }
    if (!allowed) {
      switcher.state = const WorkspaceSwitchState();
      registry.releaseApprovals();

      return false;
    }
    registry.holdActiveApproval(router);

    return true;
  }
}

Future<void> _performSwitchRequest(
  WorkspaceSwitcher switcher,
  String workspaceId,
  int switchGeneration,
) {
  final attempt = (
    switcher: switcher,
    workspaceId: workspaceId,
    switchGeneration: switchGeneration,
    startTime: DateTime.now(),
  );

  return switcher._performSwitchAttempt(attempt);
}

Future<void> _drainSwitchQueueRequests(WorkspaceSwitcher switcher) async {
  while (switcher._switchQueue.isNotEmpty) {
    final request = switcher._switchQueue.removeFirst();
    await switcher._performSwitch(request.workspaceId, request.generation);
  }
}

typedef _SwitchAttempt = ({
  WorkspaceSwitcher switcher,
  String workspaceId,
  int switchGeneration,
  DateTime startTime,
});

void _completeSwitchIfCurrent(
  WorkspaceSwitcher switcher,
  String workspaceId,
  _SwitchAttempt attempt,
) {
  if (!switcher._isCurrent(attempt.switchGeneration)) return;
  switcher._completeSwitch(
    workspaceId,
    attempt.startTime,
    attempt.switchGeneration,
  );
}
