// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_trash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceTrashUsecase)
final workspaceTrashUsecaseProvider = WorkspaceTrashUsecaseFamily._();

final class WorkspaceTrashUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ManageWorkspaceTrashUsecase>,
          ManageWorkspaceTrashUsecase,
          FutureOr<ManageWorkspaceTrashUsecase>
        >
    with
        $FutureModifier<ManageWorkspaceTrashUsecase>,
        $FutureProvider<ManageWorkspaceTrashUsecase> {
  WorkspaceTrashUsecaseProvider._({
    required WorkspaceTrashUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTrashUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTrashUsecaseHash();

  @override
  String toString() {
    return r'workspaceTrashUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ManageWorkspaceTrashUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ManageWorkspaceTrashUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceTrashUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTrashUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTrashUsecaseHash() =>
    r'eff60642b03848025cb62b2d8e3cc0d5aa4bb9d5';

final class WorkspaceTrashUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ManageWorkspaceTrashUsecase>,
          String
        > {
  WorkspaceTrashUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceTrashUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTrashUsecaseProvider call(String workspaceId) =>
      WorkspaceTrashUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceTrashUsecaseProvider';
}

@ProviderFor(workspaceTrash)
final workspaceTrashProvider = WorkspaceTrashFamily._();

final class WorkspaceTrashProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceTrashBatch>>,
          List<WorkspaceTrashBatch>,
          FutureOr<List<WorkspaceTrashBatch>>
        >
    with
        $FutureModifier<List<WorkspaceTrashBatch>>,
        $FutureProvider<List<WorkspaceTrashBatch>> {
  WorkspaceTrashProvider._({
    required WorkspaceTrashFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceTrashProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceTrashHash();

  @override
  String toString() {
    return r'workspaceTrashProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceTrashBatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceTrashBatch>> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceTrash(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceTrashProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceTrashHash() => r'9b6de9f556ca8eadfcec3b30696173fd5c4b90bb';

final class WorkspaceTrashFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<WorkspaceTrashBatch>>, String> {
  WorkspaceTrashFamily._()
    : super(
        retry: null,
        name: r'workspaceTrashProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceTrashProvider call(String workspaceId) =>
      WorkspaceTrashProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceTrashProvider';
}

@ProviderFor(workspaceDeletedReference)
final workspaceDeletedReferenceProvider = WorkspaceDeletedReferenceFamily._();

final class WorkspaceDeletedReferenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceDeletedReference?>,
          WorkspaceDeletedReference?,
          FutureOr<WorkspaceDeletedReference?>
        >
    with
        $FutureModifier<WorkspaceDeletedReference?>,
        $FutureProvider<WorkspaceDeletedReference?> {
  WorkspaceDeletedReferenceProvider._({
    required WorkspaceDeletedReferenceFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceDeletedReferenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceDeletedReferenceHash();

  @override
  String toString() {
    return r'workspaceDeletedReferenceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceDeletedReference?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceDeletedReference?> create(Ref ref) {
    final argument = this.argument as (String, String, String);
    return workspaceDeletedReference(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceDeletedReferenceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceDeletedReferenceHash() =>
    r'665895bcdf29d128b71a93a71b8b0a214c2c4958';

final class WorkspaceDeletedReferenceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceDeletedReference?>,
          (String, String, String)
        > {
  WorkspaceDeletedReferenceFamily._()
    : super(
        retry: null,
        name: r'workspaceDeletedReferenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceDeletedReferenceProvider call(
    String workspaceId,
    String tableId,
    String recordId,
  ) => WorkspaceDeletedReferenceProvider._(
    argument: (workspaceId, tableId, recordId),
    from: this,
  );

  @override
  String toString() => r'workspaceDeletedReferenceProvider';
}
