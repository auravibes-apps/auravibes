// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

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
  Future<void> _switchQueue = Future<void>.value();
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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_queueSwitch(workspaceId, switchGeneration));
    });
  }

  Future<void> _queueSwitch(
    String workspaceId,
    int switchGeneration,
  ) async {
    final previousSwitch = _switchQueue;
    final completion = Completer<void>();
    _switchQueue = completion.future;

    try {
      await previousSwitch;
    } on Object catch (error, stackTrace) {
      _logger.severe('Workspace switch queue failed', error, stackTrace);
    }

    try {
      await _performSwitch(workspaceId, switchGeneration);
    } finally {
      completion.complete();
    }
  }

  Future<void> _performSwitch(
    String workspaceId,
    int switchGeneration,
  ) async {
    final startTime = DateTime.now();

    try {
      _logger.info('Workspace switch started');

      if (!ref.mounted || switchGeneration != _switchGeneration) return;
      state = WorkspaceSwitchState(
        status: SwitchStatus.loading,
        targetWorkspaceId: workspaceId,
      );

      final selectedWorkspaceId = await ref
          .read(selectWorkspaceUsecaseProvider)
          .call(workspaceId: workspaceId);

      if (!ref.mounted || switchGeneration != _switchGeneration) return;

      final router = ref.read(routerProvider);
      final location = '/workspaces/$selectedWorkspaceId/chat/new';
      router.go(location);

      final duration = DateTime.now().difference(startTime);
      _logger.info(
        'Workspace switch completed in ${duration.inMilliseconds}ms',
      );

      if (ref.mounted && switchGeneration == _switchGeneration) {
        state = const WorkspaceSwitchState();
      }
    } on Object catch (e) {
      _logger.severe('Workspace switch failed: $e');
      if (ref.mounted && switchGeneration == _switchGeneration) {
        state = WorkspaceSwitchState(
          status: SwitchStatus.error,
          targetWorkspaceId: workspaceId,
          errorLocalizationKey: LocaleKeys.workspace_management_switch_error,
        );
      }
    }
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
}
