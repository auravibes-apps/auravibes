// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_agent_hook_settings_usecase_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceAgentHookSettingsUsecase)
final workspaceAgentHookSettingsUsecaseProvider =
    WorkspaceAgentHookSettingsUsecaseProvider._();

final class WorkspaceAgentHookSettingsUsecaseProvider
    extends
        $FunctionalProvider<
          WorkspaceAgentHookSettingsUsecase,
          WorkspaceAgentHookSettingsUsecase,
          WorkspaceAgentHookSettingsUsecase
        >
    with $Provider<WorkspaceAgentHookSettingsUsecase> {
  WorkspaceAgentHookSettingsUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceAgentHookSettingsUsecaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceAgentHookSettingsUsecaseHash();

  @$internal
  @override
  $ProviderElement<WorkspaceAgentHookSettingsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceAgentHookSettingsUsecase create(Ref ref) {
    return workspaceAgentHookSettingsUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceAgentHookSettingsUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceAgentHookSettingsUsecase>(
        value,
      ),
    );
  }
}

String _$workspaceAgentHookSettingsUsecaseHash() =>
    r'd46d70aaa82c44caa3eb2cce9963c5c7566a4cdf';
