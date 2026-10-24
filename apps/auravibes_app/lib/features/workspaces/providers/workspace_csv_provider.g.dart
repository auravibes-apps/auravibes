// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_csv_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceCsvUsecase)
final workspaceCsvUsecaseProvider = WorkspaceCsvUsecaseFamily._();

final class WorkspaceCsvUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceCsvUsecase>,
          WorkspaceCsvUsecase,
          FutureOr<WorkspaceCsvUsecase>
        >
    with
        $FutureModifier<WorkspaceCsvUsecase>,
        $FutureProvider<WorkspaceCsvUsecase> {
  WorkspaceCsvUsecaseProvider._({
    required WorkspaceCsvUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceCsvUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceCsvUsecaseHash();

  @override
  String toString() {
    return r'workspaceCsvUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceCsvUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceCsvUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceCsvUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceCsvUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceCsvUsecaseHash() =>
    r'fe7094ffeab159b378dbc7cba5e79901b4e9f3fd';

final class WorkspaceCsvUsecaseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceCsvUsecase>, String> {
  WorkspaceCsvUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceCsvUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceCsvUsecaseProvider call(String workspaceId) =>
      WorkspaceCsvUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceCsvUsecaseProvider';
}
