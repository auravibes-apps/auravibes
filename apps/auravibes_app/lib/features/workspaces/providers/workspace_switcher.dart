// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
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
@riverpod
class WorkspaceSwitcher extends _$WorkspaceSwitcher {
  Timer? _debounceTimer;

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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_performSwitch(workspaceId));
    });
  }

  Future<void> _performSwitch(String workspaceId) async {
    final startTime = DateTime.now();
    _logger.info('Workspace switch started: target=$workspaceId');

    if (!ref.mounted) return;
    state = WorkspaceSwitchState(
      status: SwitchStatus.loading,
      targetWorkspaceId: workspaceId,
    );

    try {
      final router = ref.read(routerProvider);
      final location = NewChatRoute(workspaceId: workspaceId).location;
      router.go(location);

      final duration = DateTime.now().difference(startTime);
      _logger.info(
        'Workspace switch completed in ${duration.inMilliseconds}ms',
      );

      if (ref.mounted) {
        state = const WorkspaceSwitchState();
      }
    } on Exception catch (e) {
      _logger.severe('Workspace switch failed: $e');
      if (ref.mounted) {
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
  }

  /// Clears the current error state and returns to idle.
  void clearError() {
    state = const WorkspaceSwitchState();
  }
}
