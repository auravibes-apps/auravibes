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
    r'd2810af47c365c31584681a916b32c03e2a64944';

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
