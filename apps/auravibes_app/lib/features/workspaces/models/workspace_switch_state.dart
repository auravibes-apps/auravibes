import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_switch_state.freezed.dart';

/// Status of a workspace switch operation.
enum SwitchStatus {
  /// No switch in progress.
  idle,

  /// A switch is currently in progress.
  loading,

  /// The last switch attempt failed.
  error,
}

/// Immutable state for the workspace switcher.
///
/// Tracks whether a switch is idle, loading, or failed, along with
/// the target workspace and any error message.
@freezed
abstract class WorkspaceSwitchState with _$WorkspaceSwitchState {
  /// Creates a new [WorkspaceSwitchState].
  const factory WorkspaceSwitchState({
    @Default(SwitchStatus.idle) SwitchStatus status,
    String? targetWorkspaceId,
    String? errorLocalizationKey,
  }) = _WorkspaceSwitchState;
}
