// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceHistoryUsecase)
final workspaceHistoryUsecaseProvider = WorkspaceHistoryUsecaseFamily._();

final class WorkspaceHistoryUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ManageWorkspaceHistoryUsecase>,
          ManageWorkspaceHistoryUsecase,
          FutureOr<ManageWorkspaceHistoryUsecase>
        >
    with
        $FutureModifier<ManageWorkspaceHistoryUsecase>,
        $FutureProvider<ManageWorkspaceHistoryUsecase> {
  WorkspaceHistoryUsecaseProvider._({
    required WorkspaceHistoryUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceHistoryUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceHistoryUsecaseHash();

  @override
  String toString() {
    return r'workspaceHistoryUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ManageWorkspaceHistoryUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ManageWorkspaceHistoryUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceHistoryUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceHistoryUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceHistoryUsecaseHash() =>
    r'b5790ec091b7a86d182cccc3bc92d9aec3b8e003';

final class WorkspaceHistoryUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ManageWorkspaceHistoryUsecase>,
          String
        > {
  WorkspaceHistoryUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceHistoryUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceHistoryUsecaseProvider call(String workspaceId) =>
      WorkspaceHistoryUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceHistoryUsecaseProvider';
}

@ProviderFor(workspaceHistoryPolicy)
final workspaceHistoryPolicyProvider = WorkspaceHistoryPolicyFamily._();

final class WorkspaceHistoryPolicyProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceHistoryPolicy>,
          WorkspaceHistoryPolicy,
          FutureOr<WorkspaceHistoryPolicy>
        >
    with
        $FutureModifier<WorkspaceHistoryPolicy>,
        $FutureProvider<WorkspaceHistoryPolicy> {
  WorkspaceHistoryPolicyProvider._({
    required WorkspaceHistoryPolicyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceHistoryPolicyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceHistoryPolicyHash();

  @override
  String toString() {
    return r'workspaceHistoryPolicyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceHistoryPolicy> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceHistoryPolicy> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceHistoryPolicy(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceHistoryPolicyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceHistoryPolicyHash() =>
    r'3d89341642d1ade4afda27d120d0e29bed292f7f';

final class WorkspaceHistoryPolicyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceHistoryPolicy>, String> {
  WorkspaceHistoryPolicyFamily._()
    : super(
        retry: null,
        name: r'workspaceHistoryPolicyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceHistoryPolicyProvider call(String workspaceId) =>
      WorkspaceHistoryPolicyProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceHistoryPolicyProvider';
}
