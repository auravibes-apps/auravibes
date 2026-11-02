// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_agent_hook_settings_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceAgentHookSettingsRepository)
final workspaceAgentHookSettingsRepositoryProvider =
    WorkspaceAgentHookSettingsRepositoryProvider._();

final class WorkspaceAgentHookSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceAgentHookSettingsRepository,
          WorkspaceAgentHookSettingsRepository,
          WorkspaceAgentHookSettingsRepository
        >
    with $Provider<WorkspaceAgentHookSettingsRepository> {
  WorkspaceAgentHookSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceAgentHookSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceAgentHookSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceAgentHookSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceAgentHookSettingsRepository create(Ref ref) {
    return workspaceAgentHookSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceAgentHookSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<WorkspaceAgentHookSettingsRepository>(value),
    );
  }
}

String _$workspaceAgentHookSettingsRepositoryHash() =>
    r'f67f93afdcf19ed2643d309e2cf558d47f22d9f3';
