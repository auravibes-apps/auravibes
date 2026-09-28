// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_configuration_archive_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceConfigurationArchiveUsecase)
final workspaceConfigurationArchiveUsecaseProvider =
    WorkspaceConfigurationArchiveUsecaseProvider._();

final class WorkspaceConfigurationArchiveUsecaseProvider
    extends
        $FunctionalProvider<
          WorkspaceConfigurationArchiveUsecase,
          WorkspaceConfigurationArchiveUsecase,
          WorkspaceConfigurationArchiveUsecase
        >
    with $Provider<WorkspaceConfigurationArchiveUsecase> {
  WorkspaceConfigurationArchiveUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceConfigurationArchiveUsecaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceConfigurationArchiveUsecaseHash();

  @$internal
  @override
  $ProviderElement<WorkspaceConfigurationArchiveUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceConfigurationArchiveUsecase create(Ref ref) {
    return workspaceConfigurationArchiveUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceConfigurationArchiveUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<WorkspaceConfigurationArchiveUsecase>(value),
    );
  }
}

String _$workspaceConfigurationArchiveUsecaseHash() =>
    r'ae7bbd39a895cadcd11bb21e456fb8f41a2e8718';
