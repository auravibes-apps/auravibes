// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';
import 'dart:collection';

import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
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
class WorkspaceSwitcher extends _$WorkspaceSwitcher {
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

    _debounceTimer = .new(const Duration(milliseconds: 300), () {
      _queueSwitch(workspaceId, switchGeneration);
    });
  }

  /// Cancels any pending debounced switch.
  void cancelPendingSwitch() {
    _debounceTimer?.cancel();
    _switchGeneration++;
    state = const WorkspaceSwitchState();
  }

  /// Clears the current error state and returns to idle.
  void clearError() {
    state = const WorkspaceSwitchState();
  }

  void _queueSwitch(String workspaceId, int switchGeneration) {
    _switchQueue.add((workspaceId: workspaceId, generation: switchGeneration));
    if (_isProcessingQueue) return;

    _isProcessingQueue = true;
    unawaited(_drainSwitchQueue());
  }

  Future<void> _drainSwitchQueue() async {
    try {
      while (_switchQueue.isNotEmpty) {
        final request = _switchQueue.removeFirst();
        await _performSwitch(request.workspaceId, request.generation);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _performSwitch(String workspaceId, int switchGeneration) async {
    final startTime = DateTime.now();

    try {
      _logger.info('Workspace switch started');

      if (!_beginSwitch(workspaceId, switchGeneration)) return;
      final selectedWorkspaceId = await _selectWorkspace(workspaceId);

      if (!_isCurrent(switchGeneration)) return;
      _completeSwitch(selectedWorkspaceId, startTime, switchGeneration);
    } on Object catch (error, stackTrace) {
      _logger.severe('Workspace switch failed', error, stackTrace);
      _setSwitchError(workspaceId, switchGeneration);
    }
  }

  bool _beginSwitch(String workspaceId, int switchGeneration) {
    if (!_isCurrent(switchGeneration)) return false;
    state = WorkspaceSwitchState(
      status: .loading,
      targetWorkspaceId: workspaceId,
    );

    return true;
  }

  Future<String> _selectWorkspace(String workspaceId) =>
      ref.read(selectWorkspaceUsecaseProvider).call(workspaceId: workspaceId);

  bool _isCurrent(int switchGeneration) =>
      ref.mounted && switchGeneration == _switchGeneration;

  void _completeSwitch(
    String workspaceId,
    DateTime startTime,
    int switchGeneration,
  ) {
    ref.read(routerProvider).go('/workspaces/$workspaceId/chat/new');
    final duration = DateTime.now().difference(startTime);
    _logger.info('Workspace switch completed in ${duration.inMilliseconds}ms');
    if (_isCurrent(switchGeneration)) state = const WorkspaceSwitchState();
  }

  void _setSwitchError(String workspaceId, int switchGeneration) {
    if (!_isCurrent(switchGeneration)) return;
    state = WorkspaceSwitchState(
      status: .error,
      targetWorkspaceId: workspaceId,
      errorLocalizationKey: LocaleKeys.workspace_management_switch_error,
    );
  }
}
